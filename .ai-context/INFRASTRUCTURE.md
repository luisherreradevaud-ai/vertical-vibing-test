# Infrastructure as Code Guide

**Purpose:** Comprehensive guide for developing cloud infrastructure alongside full-stack features using Terraform and AWS.

**Philosophy:** Infrastructure is code. It's developed, versioned, and tested alongside backend and frontend.

---

## Infrastructure Architecture

### Directory Structure

```
vertical-vibing/
├── infrastructure/
│   ├── terraform/
│   │   ├── modules/              # Reusable Terraform modules
│   │   │   ├── s3-bucket/
│   │   │   ├── lambda/
│   │   │   ├── rds/
│   │   │   ├── cdn/
│   │   │   ├── sqs/
│   │   │   ├── ses/
│   │   │   └── api-gateway/
│   │   ├── features/             # Feature-specific infrastructure
│   │   │   ├── file-uploads/
│   │   │   ├── email-notifications/
│   │   │   └── image-processing/
│   │   └── environments/         # Environment configurations
│   │       ├── dev/
│   │       ├── staging/
│   │       └── production/
│   ├── scripts/                  # Infrastructure automation
│   └── docs/                     # Infrastructure documentation
├── repos/
│   ├── backend/                  # Backend integrates with infrastructure
│   └── frontend/                 # Frontend uses infrastructure-aware endpoints
├── shared-types/                 # Types include infrastructure-related types
└── .ai-context/                  # AI context includes infrastructure guides
```

---

## Core Principles

### 1. Feature-Aligned Infrastructure

Infrastructure is organized by feature, not by resource type.

**✅ GOOD:**
```
infrastructure/terraform/features/
├── file-uploads/           # All infrastructure for file upload feature
│   ├── s3-bucket.tf
│   ├── cloudfront.tf
│   └── outputs.tf
└── email-notifications/    # All infrastructure for email feature
    ├── ses.tf
    ├── templates.tf
    └── outputs.tf
```

**❌ BAD:**
```
infrastructure/terraform/
├── s3/                     # Resources grouped by type (bad for features)
│   ├── uploads-bucket.tf
│   └── backups-bucket.tf
└── cloudfront/
    ├── uploads-cdn.tf
    └── static-cdn.tf
```

### 2. Infrastructure Outputs = Backend Inputs

Terraform outputs become backend environment variables.

**Terraform Output:**
```hcl
# infrastructure/terraform/features/file-uploads/outputs.tf
output "uploads_bucket_name" {
  value = aws_s3_bucket.uploads.id
  description = "S3 bucket name for file uploads"
}

output "uploads_cdn_domain" {
  value = aws_cloudfront_distribution.uploads.domain_name
  description = "CloudFront domain for uploads"
}
```

**Backend Environment Variable:**
```bash
# repos/backend/.env
UPLOADS_BUCKET_NAME=vertical-vibing-uploads-dev
UPLOADS_CDN_DOMAIN=d123456789.cloudfront.net
```

### 3. Type Safety Across Infrastructure

Infrastructure-related types are defined in shared-types.

```typescript
// shared-types/src/infrastructure/s3.types.ts
export interface PresignedUploadRequest {
  fileName: string;
  fileSize: number;
  mimeType: string;
}

export interface PresignedUploadResponse {
  uploadUrl: string;
  s3Key: string;
  cdnUrl: string;
  expiresIn: number;
}
```

### 4. Environment Parity

Same infrastructure code across dev, staging, and production (with variable differences).

```hcl
# infrastructure/terraform/environments/dev/main.tf
module "file_uploads" {
  source = "../../features/file-uploads"

  environment = "dev"
  bucket_name = "vertical-vibing-uploads-dev"
  enable_versioning = false  # Dev doesn't need versioning
}

# infrastructure/terraform/environments/production/main.tf
module "file_uploads" {
  source = "../../features/file-uploads"

  environment = "production"
  bucket_name = "vertical-vibing-uploads-prod"
  enable_versioning = true   # Production needs versioning
}
```

---

## Full-Stack Feature with Infrastructure

### Complete Workflow

When implementing a feature that requires infrastructure:

```
Phase 0: Infrastructure Analysis
  └─> Read INFRASTRUCTURE-DECISION-TREE.md
  └─> Determine infrastructure requirements

Phase 1: Infrastructure Development
  └─> Create Terraform modules
  └─> Deploy to dev environment
  └─> Document outputs

Phase 2: Shared Types
  └─> Define infrastructure-related types
  └─> Build types package

Phase 3: Backend Development
  └─> Integrate with infrastructure via AWS SDK
  └─> Read environment variables from infrastructure outputs
  └─> Implement infrastructure-aware services

Phase 4: Frontend Development
  └─> Use infrastructure-aware backend endpoints
  └─> Handle infrastructure-specific UI (upload progress, etc.)

Phase 5: Testing
  └─> Test with real infrastructure in dev
  └─> Verify end-to-end integration
```

---

## Example: File Upload Feature

### Phase 1: Infrastructure

**Create feature infrastructure:**

```hcl
# infrastructure/terraform/features/file-uploads/main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Variables
variable "environment" {
  type = string
}

variable "bucket_name" {
  type = string
}

# S3 Bucket
resource "aws_s3_bucket" "uploads" {
  bucket = var.bucket_name

  tags = {
    Environment = var.environment
    Feature     = "file-uploads"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_cors_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["*"]  # Configure based on environment
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "uploads" {
  enabled = true

  origin {
    domain_name = aws_s3_bucket.uploads.bucket_regional_domain_name
    origin_id   = "S3-${var.bucket_name}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.uploads.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.bucket_name}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Environment = var.environment
    Feature     = "file-uploads"
  }
}

resource "aws_cloudfront_origin_access_identity" "uploads" {
  comment = "OAI for ${var.bucket_name}"
}

# Outputs
output "bucket_name" {
  value       = aws_s3_bucket.uploads.id
  description = "S3 bucket name for uploads"
}

output "bucket_arn" {
  value       = aws_s3_bucket.uploads.arn
  description = "S3 bucket ARN"
}

output "cdn_domain" {
  value       = aws_cloudfront_distribution.uploads.domain_name
  description = "CloudFront domain for uploads CDN"
}

output "cdn_id" {
  value       = aws_cloudfront_distribution.uploads.id
  description = "CloudFront distribution ID"
}
```

**Create environment configuration:**

```hcl
# infrastructure/terraform/environments/dev/main.tf
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

module "file_uploads" {
  source = "../../features/file-uploads"

  environment = "dev"
  bucket_name = "vertical-vibing-uploads-dev"
}

# Output for easy reference
output "file_uploads_bucket" {
  value = module.file_uploads.bucket_name
}

output "file_uploads_cdn" {
  value = module.file_uploads.cdn_domain
}
```

**Create README:**

```markdown
# File Uploads Infrastructure

S3 + CloudFront infrastructure for file upload feature.

## Resources

- S3 Bucket: Stores uploaded files
- CloudFront Distribution: CDN for fast file delivery
- Origin Access Identity: Secure S3 access

## Outputs

- `bucket_name`: S3 bucket name (for backend)
- `cdn_domain`: CloudFront domain (for frontend URLs)

## Environment Variables

Backend requires these environment variables:

```bash
UPLOADS_BUCKET_NAME=<bucket_name>
AWS_REGION=us-east-1
UPLOADS_CDN_DOMAIN=<cdn_domain>
```

## Deployment

```bash
# Plan
./scripts/infra-plan.sh dev

# Apply
./scripts/infra-deploy.sh dev
```
```

### Phase 2: Shared Types

```typescript
// shared-types/src/infrastructure/uploads.types.ts
import { z } from 'zod';

/**
 * Request for presigned upload URL
 */
export const presignedUploadRequestSchema = z.object({
  fileName: z.string().min(1).max(255),
  fileSize: z.number().int().positive().max(100 * 1024 * 1024), // 100MB max
  mimeType: z.string().regex(/^[a-z]+\/[a-z0-9\-\+\.]+$/i),
});

export type PresignedUploadRequest = z.infer<typeof presignedUploadRequestSchema>;

/**
 * Response with presigned upload URL
 */
export const presignedUploadResponseSchema = z.object({
  uploadUrl: z.string().url(),
  s3Key: z.string(),
  cdnUrl: z.string().url(),
  expiresIn: z.number().int().positive(),
});

export type PresignedUploadResponse = z.infer<typeof presignedUploadResponseSchema>;

/**
 * File upload entity
 */
export const fileUploadSchema = z.object({
  id: z.string().uuid(),
  userId: z.string().uuid(),
  fileName: z.string(),
  s3Key: z.string(),
  fileSize: z.number().int().positive(),
  mimeType: z.string(),
  cdnUrl: z.string().url(),
  createdAt: z.string().datetime(),
});

export type FileUpload = z.infer<typeof fileUploadSchema>;
```

### Phase 3: Backend Development

```typescript
// repos/backend/src/shared/services/s3.service.ts
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { config } from '@/shared/config';

export class S3Service {
  private client: S3Client;
  private bucketName: string;
  private cdnDomain: string;

  constructor() {
    this.client = new S3Client({
      region: config.aws.region
    });
    this.bucketName = config.aws.uploadsBucket;
    this.cdnDomain = config.aws.uploadsCdnDomain;
  }

  async generatePresignedUploadUrl(
    fileName: string,
    mimeType: string,
    userId: string
  ): Promise<{ uploadUrl: string; s3Key: string; cdnUrl: string }> {
    const s3Key = `uploads/${userId}/${Date.now()}-${fileName}`;

    const command = new PutObjectCommand({
      Bucket: this.bucketName,
      Key: s3Key,
      ContentType: mimeType,
    });

    const uploadUrl = await getSignedUrl(this.client, command, {
      expiresIn: 3600, // 1 hour
    });

    const cdnUrl = `https://${this.cdnDomain}/${s3Key}`;

    return { uploadUrl, s3Key, cdnUrl };
  }

  getCdnUrl(s3Key: string): string {
    return `https://${this.cdnDomain}/${s3Key}`;
  }
}
```

```typescript
// repos/backend/src/shared/config/index.ts
export const config = {
  aws: {
    region: process.env.AWS_REGION || 'us-east-1',
    uploadsBucket: process.env.UPLOADS_BUCKET_NAME!,
    uploadsCdnDomain: process.env.UPLOADS_CDN_DOMAIN!,
  },
  // ... other config
};
```

```typescript
// repos/backend/src/features/file-uploads/uploads.service.ts
import { S3Service } from '@/shared/services/s3.service';
import { FileUploadsRepository } from './uploads.repository';
import type {
  PresignedUploadRequest,
  PresignedUploadResponse,
  FileUpload
} from '@vertical-vibing/shared-types';

export class FileUploadsService {
  constructor(
    private s3Service: S3Service,
    private repository: FileUploadsRepository
  ) {}

  async requestUpload(
    request: PresignedUploadRequest,
    userId: string
  ): Promise<PresignedUploadResponse> {
    const { uploadUrl, s3Key, cdnUrl } = await this.s3Service.generatePresignedUploadUrl(
      request.fileName,
      request.mimeType,
      userId
    );

    // Create database record (pending upload)
    await this.repository.create({
      userId,
      fileName: request.fileName,
      s3Key,
      fileSize: request.fileSize,
      mimeType: request.mimeType,
      cdnUrl,
      status: 'pending',
    });

    return {
      uploadUrl,
      s3Key,
      cdnUrl,
      expiresIn: 3600,
    };
  }

  async confirmUpload(s3Key: string, userId: string): Promise<FileUpload> {
    const upload = await this.repository.findByS3Key(s3Key);

    if (!upload || upload.userId !== userId) {
      throw new AppError(404, 'Upload not found', 'ERR_RESOURCE_001');
    }

    return this.repository.update(upload.id, { status: 'completed' });
  }
}
```

```typescript
// repos/backend/src/features/file-uploads/uploads.route.ts
import { Router } from 'express';
import { authenticate } from '@/shared/middleware/auth';
import { validateBody } from '@/shared/middleware/validation';
import { presignedUploadRequestSchema } from '@vertical-vibing/shared-types';
import { S3Service } from '@/shared/services/s3.service';
import { FileUploadsService } from './uploads.service';
import { FileUploadsRepository } from './uploads.repository';
import { ApiResponse } from '@/shared/utils/response';

export function createFileUploadsRouter(db: Database): Router {
  const router = Router();
  const s3Service = new S3Service();
  const repository = new FileUploadsRepository(db);
  const service = new FileUploadsService(s3Service, repository);

  // POST /api/uploads/request - Get presigned URL
  router.post(
    '/request',
    authenticate,
    validateBody(presignedUploadRequestSchema),
    async (req, res) => {
      const response = await service.requestUpload(req.body, req.user!.id);
      return ApiResponse.success(res, response);
    }
  );

  // POST /api/uploads/confirm - Confirm upload completed
  router.post(
    '/confirm',
    authenticate,
    async (req, res) => {
      const { s3Key } = req.body;
      const upload = await service.confirmUpload(s3Key, req.user!.id);
      return ApiResponse.success(res, upload);
    }
  );

  // GET /api/uploads - List user's uploads
  router.get(
    '/',
    authenticate,
    async (req, res) => {
      const uploads = await repository.findByUserId(req.user!.id);
      return ApiResponse.success(res, uploads);
    }
  );

  return router;
}
```

### Phase 4: Frontend Development

```typescript
// repos/frontend/src/features/file-uploads/api/uploadsApi.ts
import { apiClient } from '@/shared/api/client';
import type {
  PresignedUploadRequest,
  PresignedUploadResponse,
  FileUpload
} from '@vertical-vibing/shared-types';

export async function requestUploadUrl(file: File): Promise<PresignedUploadResponse> {
  const request: PresignedUploadRequest = {
    fileName: file.name,
    fileSize: file.size,
    mimeType: file.type,
  };

  const response = await apiClient.post<PresignedUploadResponse>(
    '/uploads/request',
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

export async function confirmUpload(s3Key: string): Promise<FileUpload> {
  const response = await apiClient.post<FileUpload>('/uploads/confirm', { s3Key });
  return response.data;
}

export async function getUserUploads(): Promise<FileUpload[]> {
  const response = await apiClient.get<FileUpload[]>('/uploads');
  return response.data;
}
```

```typescript
// repos/frontend/src/features/file-uploads/ui/FileUploadButton.tsx
'use client';

import { useState } from 'react';
import { Button } from '@/shared/ui/atoms';
import * as api from '../api/uploadsApi';
import type { FileUpload } from '@vertical-vibing/shared-types';

interface Props {
  onUploadComplete?: (upload: FileUpload) => void;
  accept?: string;
  maxSize?: number;
}

export function FileUploadButton({
  onUploadComplete,
  accept = '*/*',
  maxSize = 100 * 1024 * 1024 // 100MB
}: Props) {
  const [isUploading, setIsUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState<string | null>(null);

  const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (file.size > maxSize) {
      setError(`File too large (max ${maxSize / 1024 / 1024}MB)`);
      return;
    }

    setIsUploading(true);
    setError(null);
    setProgress(0);

    try {
      // Step 1: Request presigned URL
      const { uploadUrl, s3Key, cdnUrl } = await api.requestUploadUrl(file);

      // Step 2: Upload to S3 with progress
      await uploadWithProgress(uploadUrl, file, setProgress);

      // Step 3: Confirm upload
      const upload = await api.confirmUpload(s3Key);

      onUploadComplete?.(upload);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Upload failed');
    } finally {
      setIsUploading(false);
    }
  };

  return (
    <div>
      <input
        type="file"
        accept={accept}
        onChange={handleFileSelect}
        disabled={isUploading}
        style={{ display: 'none' }}
        id="file-upload"
      />
      <label htmlFor="file-upload">
        <Button as="span" isLoading={isUploading}>
          {isUploading ? `Uploading... ${progress}%` : 'Upload File'}
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

---

## Infrastructure Best Practices

### 1. Always Use Modules

Reusable modules ensure consistency.

```hcl
# ✅ GOOD: Using module
module "uploads" {
  source = "../../modules/s3-bucket"
  bucket_name = var.bucket_name
}

# ❌ BAD: Inline resources
resource "aws_s3_bucket" "uploads" {
  # ... lots of configuration
}
```

### 2. Tag Everything

Tags enable cost tracking and organization.

```hcl
tags = {
  Environment = var.environment
  Feature     = "file-uploads"
  ManagedBy   = "terraform"
  Team        = "engineering"
}
```

### 3. Use Remote State

Store Terraform state in S3 with locking.

```hcl
terraform {
  backend "s3" {
    bucket         = "vertical-vibing-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
```

### 4. Document Outputs

Every output should have a description.

```hcl
output "bucket_name" {
  value       = aws_s3_bucket.uploads.id
  description = "S3 bucket name for uploads (use in backend UPLOADS_BUCKET_NAME)"
}
```

### 5. Environment-Specific Variables

Use tfvars files for environment differences.

```hcl
# environments/dev/terraform.tfvars
environment           = "dev"
enable_versioning     = false
deletion_protection   = false

# environments/production/terraform.tfvars
environment           = "production"
enable_versioning     = true
deletion_protection   = true
```

---

## Summary

**Infrastructure Development:**
1. Create feature-specific Terraform modules
2. Deploy infrastructure
3. Document outputs as environment variables
4. Integrate with backend via AWS SDK
5. Use infrastructure-aware endpoints in frontend

**Key Principle:** Infrastructure is developed alongside features, maintaining type safety and architectural consistency from cloud resources to UI components.
