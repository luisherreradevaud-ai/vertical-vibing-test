# S3 Bucket Terraform Module

Reusable module for creating S3 buckets with best practices.

## Features

- Server-side encryption (AES256)
- Public access blocking
- Optional versioning
- Optional CORS configuration
- Optional lifecycle rules
- Comprehensive tagging

## Usage

```hcl
module "uploads" {
  source = "../../modules/s3-bucket"

  bucket_name       = "my-app-uploads-dev"
  enable_versioning = false
  enable_cors       = true

  cors_allowed_origins = [
    "https://myapp.com",
    "https://dev.myapp.com"
  ]

  tags = {
    Environment = "dev"
    Feature     = "file-uploads"
  }
}
```

## With Lifecycle Rules

```hcl
module "backups" {
  source = "../../modules/s3-bucket"

  bucket_name             = "my-app-backups"
  enable_versioning       = true
  enable_lifecycle_rules  = true

  lifecycle_rules = [
    {
      id              = "transition-to-glacier"
      enabled         = true
      transition_days = 90
      storage_class   = "GLACIER"
    },
    {
      id              = "expire-old-backups"
      enabled         = true
      expiration_days = 365
    }
  ]

  tags = {
    Environment = "production"
    Feature     = "backups"
  }
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| bucket_name | string | - | Name of the S3 bucket (required) |
| enable_versioning | bool | false | Enable versioning |
| enable_cors | bool | false | Enable CORS |
| cors_allowed_origins | list(string) | ["*"] | CORS allowed origins |
| enable_lifecycle_rules | bool | false | Enable lifecycle rules |
| lifecycle_rules | list(object) | [] | List of lifecycle rules |
| tags | map(string) | {} | Additional tags |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | ID of the S3 bucket (use in backend env) |
| bucket_arn | ARN of the S3 bucket |
| bucket_domain_name | Domain name of the bucket |
| bucket_regional_domain_name | Regional domain name |

## Backend Integration

After creating the bucket, add to backend `.env`:

```bash
# From module output: bucket_id
UPLOADS_BUCKET_NAME=my-app-uploads-dev
AWS_REGION=us-east-1
```

## Best Practices

1. Always enable versioning for production
2. Configure CORS origins per environment (don't use "*")
3. Use lifecycle rules to reduce costs
4. Tag everything for cost tracking
