# Infrastructure as Code

Cloud infrastructure for Vertical Vibing using Terraform and AWS.

## Structure

```
infrastructure/
├── terraform/
│   ├── modules/              # Reusable Terraform modules
│   │   ├── s3-bucket/        # S3 bucket module
│   │   ├── lambda/           # Lambda function module (coming soon)
│   │   ├── cdn/              # CloudFront CDN module (coming soon)
│   │   └── ...
│   ├── features/             # Feature-specific infrastructure
│   │   └── (feature-name)/   # Infrastructure for specific features
│   └── environments/         # Environment configurations
│       ├── dev/              # Development environment
│       ├── staging/          # Staging environment
│       └── production/       # Production environment
├── scripts/                  # Infrastructure automation scripts
│   ├── infra-plan.sh         # Plan infrastructure changes
│   ├── infra-deploy.sh       # Deploy infrastructure
│   ├── infra-destroy.sh      # Destroy infrastructure (dev/staging only)
│   └── infra-outputs.sh      # View infrastructure outputs
└── docs/                     # Infrastructure documentation

## Quick Start

### Prerequisites

1. Install Terraform (>= 1.0)
   ```bash
   brew install terraform  # macOS
   ```

2. Configure AWS credentials
   ```bash
   aws configure
   ```

3. Create S3 bucket for Terraform state (one-time setup)
   ```bash
   aws s3 mb s3://vertical-vibing-terraform-state --region us-east-1
   aws s3api put-bucket-versioning \
     --bucket vertical-vibing-terraform-state \
     --versioning-configuration Status=Enabled
   ```

### Deploy Infrastructure

```bash
# Plan changes for dev environment
./infrastructure/scripts/infra-plan.sh dev

# Deploy to dev environment
./infrastructure/scripts/infra-deploy.sh dev

# View outputs
./infrastructure/scripts/infra-outputs.sh dev
```

## Creating Infrastructure for a Feature

### Step 1: Create Feature Infrastructure Directory

```bash
mkdir -p infrastructure/terraform/features/my-feature
```

### Step 2: Create Terraform Files

**main.tf:**
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

# Use existing modules
module "feature_bucket" {
  source = "../../modules/s3-bucket"

  bucket_name       = var.bucket_name
  enable_versioning = var.enable_versioning
  enable_cors       = var.enable_cors

  tags = {
    Environment = var.environment
    Feature     = "my-feature"
  }
}
```

**variables.tf:**
```hcl
variable "environment" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "enable_versioning" {
  type    = bool
  default = false
}

variable "enable_cors" {
  type    = bool
  default = false
}
```

**outputs.tf:**
```hcl
output "bucket_name" {
  value       = module.feature_bucket.bucket_id
  description = "S3 bucket name (use in backend MY_FEATURE_BUCKET_NAME)"
}

output "bucket_arn" {
  value       = module.feature_bucket.bucket_arn
  description = "S3 bucket ARN"
}
```

**README.md:**
```markdown
# My Feature Infrastructure

Description of what this infrastructure does.

## Resources

- S3 Bucket: Stores feature data

## Backend Environment Variables

```bash
MY_FEATURE_BUCKET_NAME=<bucket_name>
AWS_REGION=us-east-1
```

## Deployment

```bash
./infrastructure/scripts/infra-deploy.sh dev
```
```

### Step 3: Add Feature to Environment

**infrastructure/terraform/environments/dev/main.tf:**
```hcl
module "my_feature" {
  source = "../../features/my-feature"

  environment       = "dev"
  bucket_name       = "vertical-vibing-my-feature-dev"
  enable_versioning = false
  enable_cors       = true
}

output "my_feature_bucket" {
  value = module.my_feature.bucket_name
}
```

### Step 4: Deploy

```bash
./infrastructure/scripts/infra-deploy.sh dev
```

### Step 5: Update Backend

Copy outputs to `repos/backend/.env`:

```bash
MY_FEATURE_BUCKET_NAME=vertical-vibing-my-feature-dev
AWS_REGION=us-east-1
```

## Available Modules

### s3-bucket

Creates S3 bucket with encryption, versioning, CORS, and lifecycle rules.

**Usage:**
```hcl
module "bucket" {
  source = "../../modules/s3-bucket"

  bucket_name       = "my-bucket"
  enable_versioning = true
  enable_cors       = true

  tags = {
    Environment = "dev"
    Feature     = "my-feature"
  }
}
```

See [modules/s3-bucket/README.md](terraform/modules/s3-bucket/README.md) for details.

## Scripts

### infra-plan.sh

Plans infrastructure changes without applying them.

```bash
./infrastructure/scripts/infra-plan.sh <environment>
```

### infra-deploy.sh

Deploys infrastructure changes.

```bash
./infrastructure/scripts/infra-deploy.sh <environment>
```

**Production Safety:** Requires explicit confirmation for production deployments.

### infra-destroy.sh

Destroys infrastructure (dev/staging only).

```bash
./infrastructure/scripts/infra-destroy.sh <environment>
```

**Production Safety:** Script blocks production destruction. Must be done manually.

### infra-outputs.sh

Views current infrastructure outputs.

```bash
./infrastructure/scripts/infra-outputs.sh <environment>
```

## Environments

### Development (dev)

- Bucket names: `vertical-vibing-*-dev`
- Versioning: Disabled
- Cost optimization: Enabled

### Staging (staging)

- Bucket names: `vertical-vibing-*-staging`
- Versioning: Enabled
- Mirrors production configuration

### Production (production)

- Bucket names: `vertical-vibing-*-prod`
- Versioning: Enabled
- Deletion protection: Enabled
- Extra safety checks

## Best Practices

1. **Always plan before deploying**
   ```bash
   ./infrastructure/scripts/infra-plan.sh dev
   ```

2. **Use modules for reusability**
   - Don't repeat resource definitions
   - Use existing modules from `modules/`

3. **Tag everything**
   ```hcl
   tags = {
     Environment = var.environment
     Feature     = "my-feature"
     ManagedBy   = "terraform"
   }
   ```

4. **Document outputs**
   - Every output needs a description
   - Mention backend env var name

5. **Environment-specific variables**
   - Use tfvars files for differences
   - Keep code DRY

## Integration with Backend

Infrastructure outputs become backend environment variables:

**Terraform Output:**
```hcl
output "uploads_bucket_name" {
  value       = module.uploads.bucket_id
  description = "S3 bucket for uploads (backend: UPLOADS_BUCKET_NAME)"
}
```

**Backend .env:**
```bash
UPLOADS_BUCKET_NAME=vertical-vibing-uploads-dev
```

**Backend Code:**
```typescript
const config = {
  aws: {
    uploadsBucket: process.env.UPLOADS_BUCKET_NAME!,
    region: process.env.AWS_REGION || 'us-east-1',
  }
};
```

## Troubleshooting

### Terraform State Lock

If deployment fails with state lock error:

```bash
cd infrastructure/terraform/environments/<env>
terraform force-unlock <lock-id>
```

### AWS Credentials

If authentication fails:

```bash
aws sts get-caller-identity  # Verify credentials
aws configure                 # Reconfigure if needed
```

### Outputs Not Showing

If outputs are empty after deployment:

```bash
cd infrastructure/terraform/environments/<env>
terraform refresh
terraform output
```

## Further Reading

- [INFRASTRUCTURE.md](../.ai-context/INFRASTRUCTURE.md) - Complete infrastructure guide
- [INFRASTRUCTURE-DECISION-TREE.md](../.ai-context/INFRASTRUCTURE-DECISION-TREE.md) - When to use infrastructure
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
