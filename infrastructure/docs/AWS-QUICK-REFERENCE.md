# AWS Quick Reference for Vertical Vibing

**Quick commands for daily AWS operations**

---

## Initial Setup (One-Time)

```bash
# Run automated setup script
./infrastructure/scripts/aws-quick-setup.sh

# Or follow manual guide
# See: infrastructure/docs/AWS-SETUP-GUIDE.md
```

---

## Daily Commands

### Check AWS Status

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check current region
aws configure get region
```

### Backend Deployment (ECS)

```bash
# 1. Build Docker image
cd repos/backend
docker build -t vertical-vibing-backend .

# 2. Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  $(aws ecr describe-repositories --repository-names vertical-vibing-backend \
    --query 'repositories[0].repositoryUri' --output text)

# 3. Tag image
REPO_URI=$(aws ecr describe-repositories \
  --repository-names vertical-vibing-backend \
  --query 'repositories[0].repositoryUri' --output text)
docker tag vertical-vibing-backend:latest $REPO_URI:latest

# 4. Push to ECR
docker push $REPO_URI:latest

# 5. Force new deployment
aws ecs update-service \
  --cluster vertical-vibing-cluster \
  --service backend-service \
  --force-new-deployment
```

**One-liner for quick redeploy:**
```bash
cd repos/backend && docker build -t vv . && \
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(aws ecr describe-repositories --repository-names vertical-vibing-backend --query 'repositories[0].repositoryUri' --output text) && \
docker tag vv:latest $(aws ecr describe-repositories --repository-names vertical-vibing-backend --query 'repositories[0].repositoryUri' --output text):latest && \
docker push $(aws ecr describe-repositories --repository-names vertical-vibing-backend --query 'repositories[0].repositoryUri' --output text):latest && \
aws ecs update-service --cluster vertical-vibing-cluster --service backend-service --force-new-deployment
```

### Frontend Deployment (Amplify)

```bash
# Just push to GitHub - Amplify auto-deploys
cd repos/frontend
git add .
git commit -m "Update frontend"
git push origin main

# Check deployment status
aws amplify list-apps
```

### View Logs

```bash
# Backend logs (real-time)
aws logs tail /ecs/vertical-vibing-backend --follow

# Backend logs (last 1 hour)
aws logs tail /ecs/vertical-vibing-backend --since 1h

# Backend logs (specific time)
aws logs tail /ecs/vertical-vibing-backend \
  --since 2024-01-20T10:00:00 \
  --until 2024-01-20T11:00:00

# Search logs for errors
aws logs tail /ecs/vertical-vibing-backend --follow --filter-pattern "ERROR"
```

### Database Operations

```bash
# Connect to RDS
psql "postgresql://postgres:PASSWORD@ENDPOINT:5432/vertical_vibing"

# Get RDS endpoint
aws rds describe-db-instances \
  --db-instance-identifier vertical-vibing-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text

# Check RDS status
aws rds describe-db-instances \
  --db-instance-identifier vertical-vibing-db \
  --query 'DBInstances[0].DBInstanceStatus'

# Create database backup (snapshot)
aws rds create-db-snapshot \
  --db-instance-identifier vertical-vibing-db \
  --db-snapshot-identifier vertical-vibing-manual-backup-$(date +%Y%m%d)
```

### Secrets Management

```bash
# Get secret value
aws secretsmanager get-secret-value \
  --secret-id vertical-vibing/database-url \
  --query SecretString --output text

# Update secret
aws secretsmanager update-secret \
  --secret-id vertical-vibing/jwt-secret \
  --secret-string "new-secret-value"

# List all secrets
aws secretsmanager list-secrets \
  --filters Key=name,Values=vertical-vibing/
```

### Monitoring

```bash
# ECS service status
aws ecs describe-services \
  --cluster vertical-vibing-cluster \
  --services backend-service

# Get backend public IP
TASK_ARN=$(aws ecs list-tasks \
  --cluster vertical-vibing-cluster \
  --service-name backend-service \
  --query 'taskArns[0]' --output text)

ENI_ID=$(aws ecs describe-tasks \
  --cluster vertical-vibing-cluster \
  --tasks $TASK_ARN \
  --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
  --output text)

aws ec2 describe-network-interfaces \
  --network-interface-ids $ENI_ID \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text

# Check ECS task health
aws ecs describe-tasks \
  --cluster vertical-vibing-cluster \
  --tasks $TASK_ARN \
  --query 'tasks[0].healthStatus'
```

### Cost Management

```bash
# Get current month costs (requires Cost Explorer API enabled)
aws ce get-cost-and-usage \
  --time-period Start=$(date -u +%Y-%m-01),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost

# Check S3 bucket size
aws s3 ls s3://vertical-vibing-uploads-dev --recursive --summarize

# List running resources (avoid surprise costs)
echo "=== ECS Tasks ==="
aws ecs list-tasks --cluster vertical-vibing-cluster

echo "=== RDS Instances ==="
aws rds describe-db-instances --query 'DBInstances[*].DBInstanceIdentifier'

echo "=== EC2 Instances (should be empty for Fargate) ==="
aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId'
```

---

## Infrastructure as Code (Terraform)

### Deploy Infrastructure

```bash
# Plan changes
./infrastructure/scripts/infra-plan.sh dev

# Deploy
./infrastructure/scripts/infra-deploy.sh dev

# View outputs
./infrastructure/scripts/infra-outputs.sh dev

# Destroy (dev only)
./infrastructure/scripts/infra-destroy.sh dev
```

### Terraform Direct Commands

```bash
# Navigate to environment
cd infrastructure/terraform/environments/dev

# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply

# Show outputs
terraform output

# Destroy specific resource
terraform destroy -target=module.profile_pictures
```

---

## Troubleshooting Commands

### Backend Not Starting

```bash
# Check task status
aws ecs describe-tasks \
  --cluster vertical-vibing-cluster \
  --tasks $(aws ecs list-tasks \
    --cluster vertical-vibing-cluster \
    --service-name backend-service \
    --query 'taskArns[0]' --output text)

# Check container logs
aws logs tail /ecs/vertical-vibing-backend --follow

# Check stopped tasks (for failure reasons)
aws ecs list-tasks \
  --cluster vertical-vibing-cluster \
  --desired-status STOPPED
```

### Database Connection Issues

```bash
# Test database connectivity
nc -zv YOUR_RDS_ENDPOINT 5432

# Check security group rules
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=vertical-vibing-rds-sg" \
  --query 'SecurityGroups[0].IpPermissions'

# Verify RDS is accessible
aws rds describe-db-instances \
  --db-instance-identifier vertical-vibing-db \
  --query 'DBInstances[0].PubliclyAccessible'
```

### High Costs

```bash
# Check CloudWatch logs retention (reduce if high)
aws logs describe-log-groups \
  --log-group-name-prefix /ecs/ \
  --query 'logGroups[*].[logGroupName,retentionInDays]'

# Set log retention to 7 days
aws logs put-retention-policy \
  --log-group-name /ecs/vertical-vibing-backend \
  --retention-in-days 7

# Check ECS service scaling
aws ecs describe-services \
  --cluster vertical-vibing-cluster \
  --services backend-service \
  --query 'services[0].[desiredCount,runningCount]'
```

### Amplify Build Failures

```bash
# Get app ID
APP_ID=$(aws amplify list-apps \
  --query 'apps[?name==`vertical-vibing-frontend`].appId' \
  --output text)

# Get latest build
aws amplify list-jobs \
  --app-id $APP_ID \
  --branch-name main \
  --max-results 1

# Trigger manual build
aws amplify start-job \
  --app-id $APP_ID \
  --branch-name main \
  --job-type RELEASE
```

---

## Useful Aliases

Add these to your `~/.zshrc` or `~/.bashrc`:

```bash
# AWS shortcuts
alias awswho='aws sts get-caller-identity'
alias awsregion='aws configure get region'

# ECS shortcuts
alias vv-backend-logs='aws logs tail /ecs/vertical-vibing-backend --follow'
alias vv-backend-deploy='cd repos/backend && docker build -t vv . && [full deploy command]'
alias vv-backend-ip='[command to get IP]'

# RDS shortcuts
alias vv-db-connect='psql "postgresql://postgres:$DB_PASSWORD@$DB_ENDPOINT:5432/vertical_vibing"'
alias vv-db-endpoint='aws rds describe-db-instances --db-instance-identifier vertical-vibing-db --query "DBInstances[0].Endpoint.Address" --output text'

# Terraform shortcuts
alias tf-dev='cd infrastructure/terraform/environments/dev'
alias tf-plan='./infrastructure/scripts/infra-plan.sh dev'
alias tf-apply='./infrastructure/scripts/infra-deploy.sh dev'
```

---

## Emergency Procedures

### Backend is Down

```bash
# 1. Check logs
aws logs tail /ecs/vertical-vibing-backend --since 30m

# 2. Check service status
aws ecs describe-services \
  --cluster vertical-vibing-cluster \
  --services backend-service

# 3. Force redeploy
aws ecs update-service \
  --cluster vertical-vibing-cluster \
  --service backend-service \
  --force-new-deployment

# 4. If still down, scale down and up
aws ecs update-service \
  --cluster vertical-vibing-cluster \
  --service backend-service \
  --desired-count 0

sleep 30

aws ecs update-service \
  --cluster vertical-vibing-cluster \
  --service backend-service \
  --desired-count 1
```

### Database Emergency Restore

```bash
# 1. List available snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier vertical-vibing-db

# 2. Restore from snapshot (creates new instance)
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier vertical-vibing-db-restored \
  --db-snapshot-identifier snapshot-name

# 3. Wait for restoration
aws rds wait db-instance-available \
  --db-instance-identifier vertical-vibing-db-restored

# 4. Update backend DATABASE_URL to point to new instance
```

### Rollback Deployment

```bash
# Backend: Deploy previous image
PREVIOUS_IMAGE="$REPO_URI:previous-tag"  # or specific digest

# Update task definition with previous image
aws ecs register-task-definition \
  --cli-input-json file://previous-task-definition.json

# Update service
aws ecs update-service \
  --cluster vertical-vibing-cluster \
  --service backend-service \
  --task-definition vertical-vibing-backend:PREVIOUS_VERSION

# Frontend: Revert git commit, push to trigger redeploy
cd repos/frontend
git revert HEAD
git push origin main
```

---

## Cost Optimization Tips

```bash
# 1. Stop dev environment when not in use
aws ecs update-service \
  --cluster vertical-vibing-cluster \
  --service backend-service \
  --desired-count 0

# 2. Stop RDS (saves ~90% of RDS costs)
aws rds stop-db-instance \
  --db-instance-identifier vertical-vibing-db

# 3. Start services when needed
aws rds start-db-instance \
  --db-instance-identifier vertical-vibing-db

aws ecs update-service \
  --cluster vertical-vibing-cluster \
  --service backend-service \
  --desired-count 1

# 4. Delete old Docker images
aws ecr list-images \
  --repository-name vertical-vibing-backend \
  --query 'imageIds[?type(imageDigest)==`string`]' \
  | jq -r '.[] | select(.imageTag == null) | .imageDigest' \
  | while read digest; do
      aws ecr batch-delete-image \
        --repository-name vertical-vibing-backend \
        --image-ids imageDigest=$digest
    done
```

---

## Resources

- **Main Setup Guide:** `infrastructure/docs/AWS-SETUP-GUIDE.md`
- **Architecture Diagram:** `infrastructure/docs/ARCHITECTURE-DIAGRAM.md`
- **Example Implementation:** `infrastructure/docs/EXAMPLE-FILE-UPLOADS.md`
- **AWS Console:** https://console.aws.amazon.com
- **AWS Documentation:** https://docs.aws.amazon.com

---

## Support

**AWS Support:**
- Basic (Free): Account and billing
- Developer ($29/month): Business hours email support
- Business ($100/month): 24/7 phone/email support

**Community:**
- AWS Forums: https://forums.aws.amazon.com
- Stack Overflow: Tag `amazon-web-services`
- Reddit: r/aws

**Emergency:**
- AWS Support (if subscribed)
- Check AWS Status: https://status.aws.amazon.com
