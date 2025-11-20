# Example: Complete File Uploads Feature with Infrastructure

This is a complete, working example of implementing file uploads with infrastructure, backend, and frontend.

## Feature Requirements

Users can upload profile pictures:
- Max file size: 10MB
- Allowed types: JPEG, PNG, WebP
- Files stored in S3
- Delivered via CloudFront CDN
- Presigned URLs for secure direct upload

---

## Phase 1: Infrastructure

### Create Feature Infrastructure

**File: `infrastructure/terraform/features/profile-pictures/main.tf`**

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "environment" {
  type = string
}

variable "bucket_name" {
  type = string
}

# S3 Bucket using reusable module
module "pictures_bucket" {
  source = "../../modules/s3-bucket"

  bucket_name       = var.bucket_name
  enable_versioning = var.environment == "production"
  enable_cors       = true

  cors_allowed_origins = var.environment == "production" ? [
    "https://vertical-vibing.com"
  ] : ["*"]

  cors_allowed_methods = ["PUT", "POST"]

  tags = {
    Environment = var.environment
    Feature     = "profile-pictures"
  }
}

# Outputs for backend
output "bucket_name" {
  value       = module.pictures_bucket.bucket_id
  description = "S3 bucket name (backend: PROFILE_PICTURES_BUCKET)"
}

output "bucket_arn" {
  value       = module.pictures_bucket.bucket_arn
  description = "S3 bucket ARN"
}
```

**File: `infrastructure/terraform/features/profile-pictures/README.md`**

```markdown
# Profile Pictures Infrastructure

S3 bucket for user profile picture uploads.

## Backend Environment Variables

```bash
PROFILE_PICTURES_BUCKET=vertical-vibing-profile-pictures-dev
AWS_REGION=us-east-1
```

## Deployment

```bash
./infrastructure/scripts/infra-deploy.sh dev
```
```

### Add to Environment

**File: `infrastructure/terraform/environments/dev/main.tf`**

```hcl
terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket = "vertical-vibing-terraform-state"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "profile_pictures" {
  source = "../../features/profile-pictures"

  environment = "dev"
  bucket_name = "vertical-vibing-profile-pictures-dev"
}

output "profile_pictures_bucket" {
  value = module.profile_pictures.bucket_name
}
```

### Deploy Infrastructure

```bash
# Plan changes
./infrastructure/scripts/infra-plan.sh dev

# Deploy
./infrastructure/scripts/infra-deploy.sh dev

# View outputs
./infrastructure/scripts/infra-outputs.sh dev
```

**Output:**
```
profile_pictures_bucket = "vertical-vibing-profile-pictures-dev"
```

---

## Phase 2: Shared Types

**File: `shared-types/src/infrastructure/profile-picture.types.ts`**

```typescript
import { z } from 'zod';

/**
 * Request for presigned upload URL
 */
export const profilePictureUploadRequestSchema = z.object({
  fileName: z.string().min(1).max(255),
  fileSize: z.number().int().positive().max(10 * 1024 * 1024), // 10MB max
  mimeType: z.enum(['image/jpeg', 'image/png', 'image/webp']),
});

export type ProfilePictureUploadRequest = z.infer<typeof profilePictureUploadRequestSchema>;

/**
 * Response with presigned upload URL
 */
export const profilePictureUploadResponseSchema = z.object({
  uploadUrl: z.string().url(),
  s3Key: z.string(),
  pictureUrl: z.string().url(),
  expiresIn: z.number().int().positive(),
});

export type ProfilePictureUploadResponse = z.infer<typeof profilePictureUploadResponseSchema>;
```

**File: `shared-types/src/entities/user.ts`**

```typescript
// Update existing user type
export const userSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string(),
  pictureUrl: z.string().url().nullable(), // NEW: profile picture URL
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
});

export type User = z.infer<typeof userSchema>;
```

Build types:

```bash
cd shared-types
npm run build
```

---

## Phase 3: Backend

### Create S3 Service

**File: `repos/backend/src/shared/services/s3.service.ts`**

```typescript
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { config } from '@/shared/config';

export class S3Service {
  private client: S3Client;
  private profilePicturesBucket: string;

  constructor() {
    this.client = new S3Client({
      region: config.aws.region
    });
    this.profilePicturesBucket = config.aws.profilePicturesBucket;
  }

  async generatePresignedUploadUrl(
    fileName: string,
    mimeType: string,
    userId: string
  ): Promise<{ uploadUrl: string; s3Key: string; pictureUrl: string }> {
    const s3Key = `profile-pictures/${userId}/${Date.now()}-${fileName}`;

    const command = new PutObjectCommand({
      Bucket: this.profilePicturesBucket,
      Key: s3Key,
      ContentType: mimeType,
    });

    const uploadUrl = await getSignedUrl(this.client, command, {
      expiresIn: 3600, // 1 hour
    });

    const pictureUrl = `https://${this.profilePicturesBucket}.s3.amazonaws.com/${s3Key}`;

    return { uploadUrl, s3Key, pictureUrl };
  }
}
```

### Update Config

**File: `repos/backend/src/shared/config/index.ts`**

```typescript
export const config = {
  port: process.env.PORT || 3000,

  database: {
    url: process.env.DATABASE_URL!,
  },

  jwt: {
    secret: process.env.JWT_SECRET!,
  },

  aws: {
    region: process.env.AWS_REGION || 'us-east-1',
    profilePicturesBucket: process.env.PROFILE_PICTURES_BUCKET!,
  },
};
```

### Update Environment Variables

**File: `repos/backend/.env`**

```bash
PORT=3000
DATABASE_URL=postgresql://user:password@localhost:5432/vertical_vibing
JWT_SECRET=your-secret-key

# Infrastructure outputs
AWS_REGION=us-east-1
PROFILE_PICTURES_BUCKET=vertical-vibing-profile-pictures-dev
```

### Create Feature

**File: `repos/backend/src/features/profile-pictures/profile-pictures.service.ts`**

```typescript
import { S3Service } from '@/shared/services/s3.service';
import { UsersRepository } from '../users/users.repository';
import type {
  ProfilePictureUploadRequest,
  ProfilePictureUploadResponse
} from '@vertical-vibing/shared-types';
import { AppError } from '@/shared/middleware/error-handler';

export class ProfilePicturesService {
  constructor(
    private s3Service: S3Service,
    private usersRepository: UsersRepository
  ) {}

  async requestUpload(
    request: ProfilePictureUploadRequest,
    userId: string
  ): Promise<ProfilePictureUploadResponse> {
    // Verify user exists
    const user = await this.usersRepository.findById(userId);
    if (!user) {
      throw new AppError(404, 'User not found', 'ERR_RESOURCE_001');
    }

    // Generate presigned URL
    const { uploadUrl, s3Key, pictureUrl } = await this.s3Service.generatePresignedUploadUrl(
      request.fileName,
      request.mimeType,
      userId
    );

    // Update user's picture URL
    await this.usersRepository.update(userId, { pictureUrl });

    return {
      uploadUrl,
      s3Key,
      pictureUrl,
      expiresIn: 3600,
    };
  }
}
```

**File: `repos/backend/src/features/profile-pictures/profile-pictures.route.ts`**

```typescript
import { Router } from 'express';
import { authenticate } from '@/shared/middleware/auth';
import { validateBody } from '@/shared/middleware/validation';
import { profilePictureUploadRequestSchema } from '@vertical-vibing/shared-types';
import { S3Service } from '@/shared/services/s3.service';
import { ProfilePicturesService } from './profile-pictures.service';
import { UsersRepository } from '../users/users.repository';
import { ApiResponse } from '@/shared/utils/response';
import type { Database } from '@/shared/db/client';

export function createProfilePicturesRouter(db: Database): Router {
  const router = Router();
  const s3Service = new S3Service();
  const usersRepository = new UsersRepository(db);
  const service = new ProfilePicturesService(s3Service, usersRepository);

  // POST /api/profile-pictures/upload - Get presigned URL
  router.post(
    '/upload',
    authenticate,
    validateBody(profilePictureUploadRequestSchema),
    async (req, res) => {
      const response = await service.requestUpload(req.body, req.user!.id);
      return ApiResponse.success(res, response);
    }
  );

  return router;
}
```

**File: `repos/backend/src/features/profile-pictures/FEATURE.md`**

```markdown
# Profile Pictures Feature

Allows users to upload profile pictures to S3.

## Endpoints

### POST /api/profile-pictures/upload

Get presigned URL for direct S3 upload.

**Auth:** Required

**Request:**
```json
{
  "fileName": "avatar.jpg",
  "fileSize": 1024000,
  "mimeType": "image/jpeg"
}
```

**Response:**
```json
{
  "uploadUrl": "https://s3.amazonaws.com/...",
  "s3Key": "profile-pictures/user-123/...",
  "pictureUrl": "https://s3.amazonaws.com/.../avatar.jpg",
  "expiresIn": 3600
}
```

## Infrastructure

Requires:
- S3 bucket: `PROFILE_PICTURES_BUCKET`
- AWS credentials with S3 permissions

## Database

Updates `users.pictureUrl` field.
```

### Register Route

**File: `repos/backend/src/index.ts`**

```typescript
import { createProfilePicturesRouter } from './features/profile-pictures/profile-pictures.route';

// ... existing code ...

app.use('/api/profile-pictures', createProfilePicturesRouter(db));
```

---

## Phase 4: Frontend

### Create API Client

**File: `repos/frontend/src/features/profile-pictures/api/profilePicturesApi.ts`**

```typescript
import { apiClient } from '@/shared/api/client';
import type {
  ProfilePictureUploadRequest,
  ProfilePictureUploadResponse
} from '@vertical-vibing/shared-types';

export async function requestUploadUrl(file: File): Promise<ProfilePictureUploadResponse> {
  const request: ProfilePictureUploadRequest = {
    fileName: file.name,
    fileSize: file.size,
    mimeType: file.type as 'image/jpeg' | 'image/png' | 'image/webp',
  };

  const response = await apiClient.post<ProfilePictureUploadResponse>(
    '/profile-pictures/upload',
    request
  );

  return response.data;
}

export async function uploadToS3(uploadUrl: string, file: File): Promise<void> {
  await fetch(uploadUrl, {
    method: 'PUT',
    body: file,
    headers: {
      'Content-Type': file.type,
    },
  });
}
```

### Create Upload Component

**File: `repos/frontend/src/features/profile-pictures/ui/ProfilePictureUpload.tsx`**

```typescript
'use client';

import { useState } from 'react';
import { Button } from '@/shared/ui/atoms';
import * as api from '../api/profilePicturesApi';
import { useAuthStore } from '@/features/auth';

interface Props {
  onUploadComplete?: (pictureUrl: string) => void;
}

export function ProfilePictureUpload({ onUploadComplete }: Props) {
  const [isUploading, setIsUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const { user, refreshUser } = useAuthStore();

  const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Validate file
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (file.size > maxSize) {
      setError('File too large (max 10MB)');
      return;
    }

    const allowedTypes = ['image/jpeg', 'image/png', 'image/webp'];
    if (!allowedTypes.includes(file.type)) {
      setError('Invalid file type (only JPEG, PNG, WebP)');
      return;
    }

    setIsUploading(true);
    setError(null);
    setProgress(0);

    try {
      // Step 1: Request presigned URL
      const { uploadUrl, pictureUrl } = await api.requestUploadUrl(file);

      // Step 2: Upload to S3 with progress
      await uploadWithProgress(uploadUrl, file, setProgress);

      // Step 3: Update local state
      await refreshUser();
      onUploadComplete?.(pictureUrl);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Upload failed');
    } finally {
      setIsUploading(false);
    }
  };

  return (
    <div className="profile-picture-upload">
      <div className="avatar">
        {user?.pictureUrl ? (
          <img src={user.pictureUrl} alt="Profile" />
        ) : (
          <div className="avatar-placeholder">{user?.name?.charAt(0)}</div>
        )}
      </div>

      <input
        type="file"
        accept="image/jpeg,image/png,image/webp"
        onChange={handleFileSelect}
        disabled={isUploading}
        style={{ display: 'none' }}
        id="profile-picture-upload"
      />

      <label htmlFor="profile-picture-upload">
        <Button as="span" isLoading={isUploading}>
          {isUploading ? `Uploading... ${progress}%` : 'Change Picture'}
        </Button>
      </label>

      {error && <div className="error">{error}</div>}
    </div>
  );
}

async function uploadWithProgress(
  url: string,
  file: File,
  onProgress: (progress: number) => void
): Promise<void> {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();

    xhr.upload.addEventListener('progress', (e) => {
      if (e.lengthComputable) {
        const progress = Math.round((e.loaded / e.total) * 100);
        onProgress(progress);
      }
    });

    xhr.addEventListener('load', () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        resolve();
      } else {
        reject(new Error('Upload failed'));
      }
    });

    xhr.addEventListener('error', () => reject(new Error('Upload failed')));

    xhr.open('PUT', url);
    xhr.setRequestHeader('Content-Type', file.type);
    xhr.send(file);
  });
}
```

### Export Public API

**File: `repos/frontend/src/features/profile-pictures/index.ts`**

```typescript
export { ProfilePictureUpload } from './ui/ProfilePictureUpload';
export type {
  ProfilePictureUploadRequest,
  ProfilePictureUploadResponse
} from '@vertical-vibing/shared-types';
```

### Use in Settings Page

**File: `repos/frontend/src/app/settings/page.tsx`**

```typescript
'use client';

import { ProfilePictureUpload } from '@/features/profile-pictures';

export default function SettingsPage() {
  return (
    <div>
      <h1>Profile Settings</h1>

      <section>
        <h2>Profile Picture</h2>
        <ProfilePictureUpload
          onUploadComplete={(pictureUrl) => {
            console.log('Upload complete:', pictureUrl);
          }}
        />
      </section>
    </div>
  );
}
```

---

## Phase 5: Testing

### Start Development Servers

```bash
./scripts/dev.sh
```

### Test Flow

1. Navigate to http://localhost:3001/settings
2. Click "Change Picture"
3. Select an image file
4. Watch progress bar
5. See updated profile picture

### Verify in AWS

```bash
aws s3 ls s3://vertical-vibing-profile-pictures-dev/profile-pictures/
```

---

## Summary

This complete example demonstrates:

1. **Infrastructure** - Terraform module for S3 bucket
2. **Shared Types** - Type-safe request/response types
3. **Backend** - S3 service with presigned URLs
4. **Frontend** - Upload component with progress tracking
5. **Integration** - End-to-end file upload flow

**Type Safety:** From infrastructure → backend → frontend → UI

**Security:** Presigned URLs, no direct credentials in frontend

**Performance:** Direct S3 upload, no backend proxy

**UX:** Progress tracking, error handling, instant feedback
