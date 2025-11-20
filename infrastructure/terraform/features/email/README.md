# Email System Infrastructure

Production-ready Terraform infrastructure for the transactional email system using AWS SES, SQS, and Lambda.

## Architecture

```
┌─────────────┐     ┌──────────┐     ┌─────────┐     ┌─────────┐
│   Backend   │────▶│ SQS Queue│────▶│ Lambda  │────▶│   SES   │
│   (API)     │     │          │     │Processor│     │         │
└─────────────┘     └──────────┘     └─────────┘     └─────────┘
                         │                                 │
                         │                                 │
                         ▼                                 ▼
                    ┌──────────┐                     ┌──────────┐
                    │   DLQ    │                     │Route53   │
                    │(Failed)  │                     │(DNS)     │
                    └──────────┘                     └──────────┘
                         │                                 │
                         │                                 │
                         ▼                                 ▼
                    ┌──────────┐                     ┌──────────┐
                    │CloudWatch│                     │  DKIM    │
                    │ Alarms   │                     │  SPF     │
                    └──────────┘                     └──────────┘
```

## Components

### 1. SES Domain (`ses-domain` module)
- Domain identity verification
- DKIM authentication (3 tokens)
- Custom MAIL FROM domain
- Optional Route53 DNS automation
- Configuration set with event destinations
- Bounce/complaint handling via SNS

### 2. SQS Queue (`sqs-email-queue` module)
- Main email processing queue
- Dead Letter Queue (DLQ) for failures
- Server-side encryption (KMS)
- CloudWatch alarms for monitoring
- Message retention: 14 days
- Visibility timeout: 6 minutes

### 3. Lambda Function (`email-lambda` module)
- Event-driven queue processor
- Batch processing (10 messages/batch)
- Auto-scaling (max 10 concurrent executions)
- VPC support for database access
- CloudWatch Logs (14-day retention)
- Error tracking and throttle alarms

### 4. IAM Roles (`email-iam` module)
- Lambda execution role with SES/SQS permissions
- Optional backend role for direct SQS access
- KMS decryption for encrypted queues
- Secrets Manager access for credentials
- Least-privilege security model

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured with credentials
4. **Domain** registered (for SES)
5. **Lambda Package** built and ready to deploy

## Quick Start

### 1. Build Lambda Package

```bash
cd repos/backend
npm run build
npm run package:lambda
# Creates dist/lambda.zip
```

### 2. Configure Variables

```bash
cd infrastructure/terraform/features/email
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Configure Backend

```bash
cp backend.tf.example backend.tf
# Edit backend.tf for state storage
```

### 4. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Apply infrastructure
terraform apply
```

### 5. Verify SES Domain

If using manual DNS setup (`create_route53_records = false`):

```bash
# Get DNS records from Terraform output
terraform output ses_dns_records

# Add these records to your DNS provider:
# 1. TXT record for domain verification
# 2. 3 CNAME records for DKIM
# 3. MX record for MAIL FROM domain (if configured)
# 4. TXT record for SPF (if configured)
```

Wait for DNS propagation (can take up to 72 hours), then verify:

```bash
aws ses get-identity-verification-attributes \
  --identities example.com \
  --region us-east-1
```

### 6. Request Production Access

New AWS accounts start in **SES Sandbox** mode (limited to verified emails only).

To send to any email address:
1. Go to AWS Console → SES → Account dashboard
2. Click "Request production access"
3. Fill out the form explaining your use case
4. Wait for approval (usually 24-48 hours)

## Configuration Reference

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `project_name` | Project identifier | `"vertical-vibing"` |
| `environment` | Environment name | `"production"` |
| `domain` | SES domain | `"example.com"` |
| `default_from_email` | Default FROM address | `"noreply@example.com"` |
| `lambda_deployment_package_path` | Path to Lambda ZIP | `"../../../repos/backend/dist/lambda.zip"` |
| `database_url` | Database connection URL | `"postgresql://..."` |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `mail_from_domain` | `null` | Custom MAIL FROM domain |
| `create_route53_records` | `false` | Auto-create DNS records |
| `enable_lambda_vpc_access` | `false` | Enable VPC for Lambda |
| `log_level` | `"info"` | Logging level |
| `log_retention_days` | `14` | CloudWatch log retention |

See `variables.tf` for complete list.

## DNS Configuration

### Option 1: Automated (Route53)

Set in `terraform.tfvars`:
```hcl
create_route53_records = true
route53_zone_id        = "Z1234567890ABC"
```

Terraform will automatically create all required DNS records.

### Option 2: Manual DNS Setup

After `terraform apply`, run:
```bash
terraform output ses_dns_records
```

Create these records in your DNS provider:

**Domain Verification (TXT)**
```
Name:  _amazonses.example.com
Type:  TXT
Value: <verification_token>
```

**DKIM (3 CNAME records)**
```
Name:  <dkim_token_1>._domainkey.example.com
Type:  CNAME
Value: <dkim_token_1>.dkim.amazonses.com
```
(Repeat for all 3 tokens)

**MAIL FROM MX** (if using custom mail from):
```
Name:  mail.example.com
Type:  MX
Value: 10 feedback-smtp.us-east-1.amazonses.com
```

**MAIL FROM SPF** (if using custom mail from):
```
Name:  mail.example.com
Type:  TXT
Value: v=spf1 include:amazonses.com -all
```

## Deployment Patterns

### Pattern 1: Lambda Queue Processor (Recommended)

Default configuration. Backend enqueues to SQS, Lambda processes asynchronously.

**Pros:**
- Decoupled architecture
- Auto-scaling and retries
- Better error handling
- Cost-effective

**Cons:**
- ~1-2 second delay
- Requires Lambda deployment

### Pattern 2: Embedded Queue Processor

Backend runs queue processor in-process. Set `create_backend_role = true`.

**Pros:**
- No Lambda needed
- Simpler deployment
- Real-time processing

**Cons:**
- Couples email to API
- Harder to scale
- Blocks API threads

### Pattern 3: Hybrid

Use Lambda in production, embedded in development:
```hcl
# production.tfvars
create_backend_role = false

# dev.tfvars
create_backend_role = true
```

## Monitoring

### CloudWatch Alarms

Automatically created alarms:

1. **DLQ Messages** - Triggers when DLQ has messages (failures)
2. **Message Age** - Triggers when messages sit in queue too long
3. **Lambda Errors** - Triggers on Lambda errors
4. **Lambda Throttles** - Triggers on Lambda throttling
5. **Lambda Duration** - Triggers when execution time is high

### Configure SNS Notifications

```hcl
alarm_sns_topic_arns = [
  "arn:aws:sns:us-east-1:123456789012:alerts"
]
```

### CloudWatch Dashboards

View metrics:
- AWS Console → CloudWatch → Dashboards
- Filter by: `email-system`

## Security

### Encryption

- **At Rest**: SQS queues encrypted with KMS
- **In Transit**: TLS required for SES delivery
- **Credentials**: Stored in environment variables or Secrets Manager

### IAM

All roles follow least-privilege principle:
- Lambda can only read from queue and send via SES
- Backend can only write to queue
- No broad permissions granted

### VPC Configuration

For database in private VPC:

```hcl
enable_lambda_vpc_access = true
lambda_vpc_config = {
  subnet_ids         = ["subnet-abc123", "subnet-def456"]
  security_group_ids = ["sg-abc123"]
}
```

## Cost Estimation

### Monthly Cost (approximate)

**SES:**
- First 62,000 emails: Free (AWS Free Tier)
- Additional emails: $0.10 per 1,000 emails
- Example: 100k emails/month = ~$4

**SQS:**
- First 1M requests: Free (AWS Free Tier)
- Additional requests: $0.40 per 1M requests
- Example: 500k requests/month = Free

**Lambda:**
- First 1M requests: Free (AWS Free Tier)
- First 400,000 GB-seconds: Free
- Example: 100k emails @ 512MB, 2s avg = Free

**CloudWatch Logs:**
- First 5GB: Free
- Additional: $0.50 per GB
- Example: 1GB/month = Free

**Total Estimate:** $0-10/month for small-medium workloads

## Troubleshooting

### Domain Not Verified

**Problem:** SES domain shows "pending verification"

**Solution:**
1. Check DNS records are created: `dig TXT _amazonses.example.com`
2. Wait for DNS propagation (up to 72 hours)
3. Verify in AWS Console: SES → Identities

### Emails Not Sending

**Problem:** Emails enqueued but not delivered

**Check:**
1. Lambda CloudWatch Logs: `/aws/lambda/<env>-email-processor`
2. SQS DLQ for failed messages
3. SES sending statistics in AWS Console

**Common Issues:**
- SES still in sandbox mode (verify destination emails)
- IAM permissions missing
- Database connection failed (check VPC config)
- Template rendering error (check logs)

### High Lambda Costs

**Problem:** Unexpected Lambda charges

**Solutions:**
1. Reduce batch size (fewer invocations but longer duration)
2. Reduce memory (512MB → 256MB if possible)
3. Optimize database queries
4. Enable Lambda reserved concurrency

### DLQ Has Messages

**Problem:** Messages repeatedly failing

**Action:**
1. Check DLQ messages: `aws sqs receive-message --queue-url <dlq_url>`
2. Review Lambda error logs
3. Fix underlying issue (template, permissions, etc.)
4. Manually retry: Re-enqueue to main queue
5. Or delete if invalid: `aws sqs purge-queue --queue-url <dlq_url>`

## Maintenance

### Update Lambda Code

```bash
# Build new package
cd repos/backend
npm run build
npm run package:lambda

# Update Lambda
cd infrastructure/terraform/features/email
terraform apply -var="lambda_source_code_hash=$(base64 < ../../../repos/backend/dist/lambda.zip | shasum -a 256 | cut -d' ' -f1)"
```

### Update Infrastructure

```bash
# Pull latest Terraform code
git pull

# Review changes
terraform plan

# Apply updates
terraform apply
```

### Rotate Secrets

If using Secrets Manager:

```bash
# Update secret value in AWS
aws secretsmanager update-secret \
  --secret-id database-credentials \
  --secret-string '{"username":"...","password":"..."}'

# Lambda will use new secret on next invocation (no redeploy needed)
```

## Disaster Recovery

### Backup

- **State Files:** Backed up in S3 (versioned)
- **SQS Messages:** Retained for 14 days
- **CloudWatch Logs:** Retained for 14 days

### Restore

```bash
# Restore infrastructure from state
terraform init
terraform plan
terraform apply

# Reprocess failed messages from DLQ if needed
```

## Cleanup

To destroy all infrastructure:

```bash
# Review what will be deleted
terraform plan -destroy

# Destroy all resources
terraform destroy

# WARNING: This will delete:
# - SES domain identity
# - SQS queues (and messages)
# - Lambda function
# - IAM roles
# - CloudWatch alarms
```

## Support

For issues or questions:
- Check [Backend FEATURE.md](../../../repos/backend/src/features/email/FEATURE.md)
- Review CloudWatch Logs
- Check AWS Service Health Dashboard
- Contact DevOps team

## License

Internal use only - Vertical Vibing SaaS Framework
