# Infrastructure Decision Tree

**Purpose:** Automatic decision-making guide for AI agents to determine when infrastructure is required for a feature.

**Critical:** AI agents MUST read this file when asked to implement ANY feature to determine infrastructure requirements.

---

## Decision Tree: Does This Feature Need Infrastructure?

### START HERE

When a user asks for a feature, evaluate it against this decision tree:

```
Feature Request
    |
    ├─ Does it involve FILE STORAGE? ────────────────────────────> YES → NEEDS INFRASTRUCTURE (S3)
    │   Examples:
    │   - User profile pictures
    │   - Document uploads
    │   - File attachments
    │   - Image galleries
    │   - Video uploads
    │   - PDF storage
    │
    ├─ Does it involve IMAGE/VIDEO PROCESSING? ──────────────────> YES → NEEDS INFRASTRUCTURE (Lambda + S3)
    │   Examples:
    │   - Image resizing/thumbnails
    │   - Video transcoding
    │   - Image optimization
    │   - Watermarking
    │   - Format conversion
    │
    ├─ Does it involve BACKGROUND JOBS? ─────────────────────────> YES → NEEDS INFRASTRUCTURE (SQS + Lambda)
    │   Examples:
    │   - Send emails
    │   - Generate reports
    │   - Data export
    │   - Batch processing
    │   - Scheduled tasks
    │
    ├─ Does it involve EMAIL SENDING? ───────────────────────────> YES → NEEDS INFRASTRUCTURE (SES)
    │   Examples:
    │   - Transactional emails
    │   - Notifications
    │   - Newsletters
    │   - Password resets
    │
    ├─ Does it involve REAL-TIME COMMUNICATION? ─────────────────> YES → NEEDS INFRASTRUCTURE (WebSocket/AppSync)
    │   Examples:
    │   - Chat systems
    │   - Live notifications
    │   - Collaborative editing
    │   - Real-time dashboards
    │
    ├─ Does it involve CONTENT DELIVERY/CACHING? ────────────────> YES → NEEDS INFRASTRUCTURE (CloudFront)
    │   Examples:
    │   - Static asset delivery
    │   - API caching
    │   - Media streaming
    │   - Global content distribution
    │
    ├─ Does it involve SEARCH FUNCTIONALITY? ────────────────────> YES → NEEDS INFRASTRUCTURE (ElasticSearch/OpenSearch)
    │   Examples:
    │   - Full-text search
    │   - Faceted search
    │   - Autocomplete
    │   - Search analytics
    │
    ├─ Does it involve EXTERNAL API WEBHOOKS? ───────────────────> YES → NEEDS INFRASTRUCTURE (API Gateway + Lambda)
    │   Examples:
    │   - Payment webhooks (Stripe)
    │   - OAuth callbacks
    │   - Third-party integrations
    │
    ├─ Does it involve ANALYTICS/METRICS? ───────────────────────> YES → NEEDS INFRASTRUCTURE (CloudWatch/Kinesis)
    │   Examples:
    │   - User behavior tracking
    │   - Performance metrics
    │   - Custom dashboards
    │   - Event streaming
    │
    ├─ Does it involve BLOB/BINARY DATA? ────────────────────────> YES → NEEDS INFRASTRUCTURE (S3)
    │   Examples:
    │   - Database backups
    │   - Log archives
    │   - Data exports
    │   - Binary assets
    │
    └─ Otherwise ────────────────────────────────────────────────> NO → Backend + Frontend Only
        Examples:
        - CRUD operations (database only)
        - Authentication/Authorization
        - Business logic
        - Data validation
        - API endpoints
```

---

## Quick Reference: Feature → Infrastructure Mapping

| Feature Type | Required Infrastructure | Backend Integration | Frontend Impact |
|-------------|------------------------|---------------------|-----------------|
| **File Upload** | S3 + CloudFront | Presigned URLs, S3 SDK | Upload widget, progress bar |
| **Image Processing** | S3 + Lambda | S3 events, Lambda triggers | Upload + preview |
| **Background Jobs** | SQS + Lambda | SQS SDK, job queuing | Job status polling |
| **Email Sending** | SES | SES SDK | Email templates |
| **Real-time Features** | WebSocket/AppSync | WebSocket server/GraphQL subscriptions | WebSocket client |
| **Content Delivery** | CloudFront | CDN URLs | Asset URLs update |
| **Search** | OpenSearch | Search SDK | Search UI components |
| **Webhooks** | API Gateway + Lambda | Webhook handlers | Callback handling |
| **Analytics** | CloudWatch/Kinesis | Metrics SDK | Event tracking |
| **Blob Storage** | S3 | S3 SDK | Download links |

---

## Infrastructure Detection Algorithm for AI

When processing a feature request, run this algorithm:

### Step 1: Analyze Feature Description

**Extract keywords and match against patterns:**

```
IF description contains:
  - "upload", "file", "attachment", "document", "photo", "image", "video"
    → Flag: FILE_STORAGE_NEEDED (S3)

  - "resize", "thumbnail", "compress", "convert", "process image/video"
    → Flag: IMAGE_PROCESSING_NEEDED (Lambda + S3)

  - "background", "async", "queue", "job", "scheduled", "delayed"
    → Flag: BACKGROUND_JOBS_NEEDED (SQS + Lambda)

  - "email", "notification", "send message", "mail"
    → Flag: EMAIL_SENDING_NEEDED (SES)

  - "real-time", "live", "websocket", "chat", "instant"
    → Flag: REALTIME_NEEDED (WebSocket/AppSync)

  - "search", "find", "filter", "query", "autocomplete"
    → Flag: SEARCH_NEEDED (OpenSearch) [only if complex search required]

  - "webhook", "callback", "external API", "third-party"
    → Flag: WEBHOOK_NEEDED (API Gateway + Lambda)

  - "analytics", "tracking", "metrics", "logging", "monitoring"
    → Flag: ANALYTICS_NEEDED (CloudWatch/Kinesis)

  - "cache", "CDN", "deliver", "distribute"
    → Flag: CDN_NEEDED (CloudFront)
```

### Step 2: Determine Infrastructure Components

```
FOR each flag in flags:
  - Identify required Terraform module
  - Identify required AWS SDK
  - Identify required environment variables
  - Identify backend integration points
  - Identify frontend integration points
```

### Step 3: Plan Implementation Order

```
1. Infrastructure (Terraform)
2. Shared Types (TypeScript)
3. Backend (with AWS SDK integration)
4. Frontend (with infrastructure-aware endpoints)
5. Testing (with real infrastructure)
```

---

## Examples: Feature → Infrastructure Decision

### Example 1: "Add user profile picture upload"

**Analysis:**
- Contains keyword: "upload", "picture"
- **Decision:** NEEDS INFRASTRUCTURE

**Required Infrastructure:**
- S3 bucket for uploads
- CloudFront CDN for delivery
- Lambda for image resizing (optional but recommended)

**Implementation Plan:**
1. Create `infrastructure/terraform/features/profile-pictures/`
2. Define S3 + CloudFront + Lambda modules
3. Deploy infrastructure
4. Create backend endpoints (presigned URLs)
5. Create frontend upload component

---

### Example 2: "Add user registration with email verification"

**Analysis:**
- Contains keyword: "email"
- **Decision:** NEEDS INFRASTRUCTURE (partially)

**Required Infrastructure:**
- SES for sending verification emails

**Implementation Plan:**
1. Create `infrastructure/terraform/features/email-verification/`
2. Define SES module
3. Deploy infrastructure
4. Create backend email service (SES SDK)
5. Create frontend email verification flow

---

### Example 3: "Add pagination to user list"

**Analysis:**
- No infrastructure keywords
- Pure database query feature
- **Decision:** NO INFRASTRUCTURE NEEDED

**Implementation Plan:**
1. Create backend repository method (pagination)
2. Create backend endpoint
3. Create frontend pagination component

---

### Example 4: "Add document upload with virus scanning"

**Analysis:**
- Contains keywords: "upload", "document", "scanning"
- **Decision:** NEEDS INFRASTRUCTURE

**Required Infrastructure:**
- S3 bucket for document storage
- Lambda for virus scanning (ClamAV)
- SQS for async scanning queue
- SNS for scan result notifications

**Implementation Plan:**
1. Create `infrastructure/terraform/features/document-upload-with-scanning/`
2. Define S3 + Lambda + SQS + SNS modules
3. Deploy infrastructure
4. Create backend upload + scanning service
5. Create frontend upload + status component

---

## AI Agent Workflow

When a user asks for a feature, AI agents MUST follow this workflow:

### Phase 0: Infrastructure Analysis (NEW)

```
1. Read this file (INFRASTRUCTURE-DECISION-TREE.md)
2. Analyze feature request against decision tree
3. Determine infrastructure requirements
4. If infrastructure needed:
   a. Read INFRASTRUCTURE.md for implementation patterns
   b. Read INFRASTRUCTURE-PATTERNS.md for specific service patterns
   c. Plan infrastructure creation as Phase 1
5. If no infrastructure needed:
   a. Skip to Phase 1 (Shared Types)
```

### Phase 1: Infrastructure (if needed)

```
1. Create feature directory: infrastructure/terraform/features/[feature-name]/
2. Create Terraform files:
   - main.tf (resources)
   - variables.tf (inputs)
   - outputs.tf (outputs for backend)
   - README.md (documentation)
3. Plan deployment: ./scripts/infra-plan.sh dev
4. Deploy: ./scripts/infra-deploy.sh dev
5. Document environment variables in backend
```

### Phase 2: Shared Types

```
1. Define entity schemas
2. Define DTOs
3. Build types: cd shared-types && npm run build
```

### Phase 3: Backend

```
1. Create feature directory: repos/backend/src/features/[feature-name]/
2. Integrate with infrastructure:
   - Import AWS SDK
   - Read environment variables from infrastructure outputs
   - Implement infrastructure-aware services
3. Create routes, services, repositories
4. Write tests
```

### Phase 4: Frontend

```
1. Create feature directory: repos/frontend/src/features/[feature-name]/
2. Integrate with backend infrastructure endpoints:
   - File upload components
   - Progress tracking
   - Error handling
3. Create UI components
4. Write tests
```

### Phase 5: Integration Testing

```
1. Start dev servers: ./scripts/dev.sh
2. Test end-to-end with real infrastructure
3. Verify infrastructure integration
```

---

## Infrastructure Decision Checklist for AI

Before implementing a feature, AI must answer these questions:

- [ ] Does this feature store files/media? → S3
- [ ] Does this feature process images/videos? → Lambda + S3
- [ ] Does this feature run background jobs? → SQS + Lambda
- [ ] Does this feature send emails? → SES
- [ ] Does this feature need real-time updates? → WebSocket/AppSync
- [ ] Does this feature need content caching/delivery? → CloudFront
- [ ] Does this feature need advanced search? → OpenSearch
- [ ] Does this feature receive webhooks? → API Gateway + Lambda
- [ ] Does this feature track analytics? → CloudWatch/Kinesis
- [ ] Does this feature store binary data? → S3

**If ANY checkbox is checked → Infrastructure is required**

---

## Common Mistakes to Avoid

### ❌ WRONG: Implementing file upload without infrastructure

```typescript
// Backend - storing files in filesystem (BAD!)
const filePath = path.join(__dirname, 'uploads', file.name);
fs.writeFileSync(filePath, file.data);
```

**Why wrong:** Not scalable, no redundancy, no CDN

### ✅ CORRECT: Implementing file upload with infrastructure

```typescript
// Backend - using S3 (GOOD!)
const uploadUrl = await s3Service.generatePresignedUrl(file.name);
return { uploadUrl, s3Key };
```

---

### ❌ WRONG: Processing images synchronously in API endpoint

```typescript
// Backend - blocking image resize (BAD!)
router.post('/upload', (req, res) => {
  const resized = sharp(req.file).resize(200, 200).toBuffer();
  res.json({ resized });
});
```

**Why wrong:** Blocks API, no scalability, timeout issues

### ✅ CORRECT: Processing images asynchronously with Lambda

```typescript
// Backend - trigger Lambda for processing (GOOD!)
router.post('/upload', async (req, res) => {
  await s3.upload(file);
  await sqs.sendMessage({ s3Key, operation: 'resize' });
  res.json({ status: 'processing' });
});
```

---

## Summary

**For AI Agents:**

1. **ALWAYS read this file first** when implementing features
2. **Run the decision tree** on the feature description
3. **If infrastructure is needed:**
   - Add Infrastructure phase before Shared Types phase
   - Read INFRASTRUCTURE.md for implementation details
   - Create Terraform modules in infrastructure/terraform/features/
   - Deploy infrastructure before backend development
   - Document environment variables
4. **If no infrastructure is needed:**
   - Proceed directly to Shared Types phase
   - Follow standard backend + frontend workflow

**Key Principle:** Infrastructure is just another layer of the stack. When needed, it's developed alongside backend and frontend, maintaining the same type-safe, feature-aligned architecture.
