#!/bin/bash

# AWS Quick Setup Script for Vertical Vibing
# This script automates the initial AWS setup

set -e

echo "🚀 Vertical Vibing - AWS Quick Setup"
echo "====================================="
echo ""
echo "This script will create:"
echo "  - S3 bucket for Terraform state"
echo "  - DynamoDB table for state locking"
echo "  - ECR repository for Docker images"
echo "  - Security groups for RDS and ECS"
echo "  - CloudWatch log group"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first:"
    echo "   brew install awscli"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run:"
    echo "   aws configure"
    exit 1
fi

# Get AWS account ID and region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-us-east-1}

echo "✓ AWS Account ID: $ACCOUNT_ID"
echo "✓ Region: $AWS_REGION"
echo ""

read -p "Continue with setup? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""
echo "📦 Step 1: Creating S3 bucket for Terraform state..."

# Create S3 bucket
if aws s3 ls "s3://vertical-vibing-terraform-state" 2>&1 | grep -q 'NoSuchBucket'; then
    aws s3 mb s3://vertical-vibing-terraform-state --region $AWS_REGION
    echo "✓ S3 bucket created"

    # Enable versioning
    aws s3api put-bucket-versioning \
      --bucket vertical-vibing-terraform-state \
      --versioning-configuration Status=Enabled
    echo "✓ Versioning enabled"

    # Enable encryption
    aws s3api put-bucket-encryption \
      --bucket vertical-vibing-terraform-state \
      --server-side-encryption-configuration '{
        "Rules": [{
          "ApplyServerSideEncryptionByDefault": {
            "SSEAlgorithm": "AES256"
          }
        }]
      }'
    echo "✓ Encryption enabled"

    # Block public access
    aws s3api put-public-access-block \
      --bucket vertical-vibing-terraform-state \
      --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    echo "✓ Public access blocked"
else
    echo "✓ S3 bucket already exists"
fi

echo ""
echo "🔒 Step 2: Creating DynamoDB table for state locking..."

# Create DynamoDB table
if aws dynamodb describe-table --table-name terraform-lock --region $AWS_REGION 2>&1 | grep -q 'ResourceNotFoundException'; then
    aws dynamodb create-table \
      --table-name terraform-lock \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST \
      --region $AWS_REGION > /dev/null
    echo "✓ DynamoDB table created"
else
    echo "✓ DynamoDB table already exists"
fi

echo ""
echo "🐳 Step 3: Creating ECR repository..."

# Create ECR repository
if aws ecr describe-repositories --repository-names vertical-vibing-backend --region $AWS_REGION 2>&1 | grep -q 'RepositoryNotFoundException'; then
    aws ecr create-repository \
      --repository-name vertical-vibing-backend \
      --region $AWS_REGION > /dev/null
    echo "✓ ECR repository created"
else
    echo "✓ ECR repository already exists"
fi

REPO_URI=$(aws ecr describe-repositories \
  --repository-names vertical-vibing-backend \
  --region $AWS_REGION \
  --query 'repositories[0].repositoryUri' \
  --output text)

echo ""
echo "🔐 Step 4: Setting up VPC and security groups..."

# Get default VPC
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text --region $AWS_REGION)

if [ "$VPC_ID" = "None" ] || [ -z "$VPC_ID" ]; then
    echo "Creating default VPC..."
    aws ec2 create-default-vpc --region $AWS_REGION
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text --region $AWS_REGION)
fi

echo "✓ VPC ID: $VPC_ID"

# Create security group for RDS
if aws ec2 describe-security-groups --filters "Name=group-name,Values=vertical-vibing-rds-sg" --region $AWS_REGION 2>&1 | grep -q 'InvalidGroup.NotFound'; then
    aws ec2 create-security-group \
      --group-name vertical-vibing-rds-sg \
      --description "Security group for Vertical Vibing RDS" \
      --vpc-id $VPC_ID \
      --region $AWS_REGION > /dev/null

    RDS_SG_ID=$(aws ec2 describe-security-groups \
      --filters "Name=group-name,Values=vertical-vibing-rds-sg" \
      --query 'SecurityGroups[0].GroupId' \
      --output text \
      --region $AWS_REGION)

    # Allow PostgreSQL access (WARNING: from anywhere for dev - restrict in production)
    aws ec2 authorize-security-group-ingress \
      --group-id $RDS_SG_ID \
      --protocol tcp \
      --port 5432 \
      --cidr 0.0.0.0/0 \
      --region $AWS_REGION > /dev/null 2>&1 || true

    echo "✓ RDS security group created: $RDS_SG_ID"
else
    RDS_SG_ID=$(aws ec2 describe-security-groups \
      --filters "Name=group-name,Values=vertical-vibing-rds-sg" \
      --query 'SecurityGroups[0].GroupId' \
      --output text \
      --region $AWS_REGION)
    echo "✓ RDS security group already exists: $RDS_SG_ID"
fi

# Create security group for ECS
if aws ec2 describe-security-groups --filters "Name=group-name,Values=vertical-vibing-ecs-tasks-sg" --region $AWS_REGION 2>&1 | grep -q 'InvalidGroup.NotFound'; then
    aws ec2 create-security-group \
      --group-name vertical-vibing-ecs-tasks-sg \
      --description "Security group for Vertical Vibing ECS tasks" \
      --vpc-id $VPC_ID \
      --region $AWS_REGION > /dev/null

    ECS_SG_ID=$(aws ec2 describe-security-groups \
      --filters "Name=group-name,Values=vertical-vibing-ecs-tasks-sg" \
      --query 'SecurityGroups[0].GroupId' \
      --output text \
      --region $AWS_REGION)

    # Allow HTTP traffic
    aws ec2 authorize-security-group-ingress \
      --group-id $ECS_SG_ID \
      --protocol tcp \
      --port 3000 \
      --cidr 0.0.0.0/0 \
      --region $AWS_REGION > /dev/null 2>&1 || true

    echo "✓ ECS security group created: $ECS_SG_ID"
else
    ECS_SG_ID=$(aws ec2 describe-security-groups \
      --filters "Name=group-name,Values=vertical-vibing-ecs-tasks-sg" \
      --query 'SecurityGroups[0].GroupId' \
      --output text \
      --region $AWS_REGION)
    echo "✓ ECS security group already exists: $ECS_SG_ID"
fi

echo ""
echo "📊 Step 5: Creating CloudWatch log group..."

# Create CloudWatch log group
if aws logs describe-log-groups --log-group-name-prefix /ecs/vertical-vibing-backend --region $AWS_REGION | grep -q "/ecs/vertical-vibing-backend"; then
    echo "✓ CloudWatch log group already exists"
else
    aws logs create-log-group \
      --log-group-name /ecs/vertical-vibing-backend \
      --region $AWS_REGION
    echo "✓ CloudWatch log group created"
fi

echo ""
echo "🎯 Step 6: Creating ECS cluster..."

# Create ECS cluster
if aws ecs describe-clusters --clusters vertical-vibing-cluster --region $AWS_REGION --query 'clusters[0].status' --output text 2>&1 | grep -q 'ACTIVE'; then
    echo "✓ ECS cluster already exists"
else
    aws ecs create-cluster \
      --cluster-name vertical-vibing-cluster \
      --region $AWS_REGION > /dev/null
    echo "✓ ECS cluster created"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Summary"
echo "=========="
echo "AWS Account ID: $ACCOUNT_ID"
echo "Region: $AWS_REGION"
echo ""
echo "S3 Terraform State Bucket: vertical-vibing-terraform-state"
echo "DynamoDB Lock Table: terraform-lock"
echo "ECR Repository URI: $REPO_URI"
echo "VPC ID: $VPC_ID"
echo "RDS Security Group: $RDS_SG_ID"
echo "ECS Security Group: $ECS_SG_ID"
echo "ECS Cluster: vertical-vibing-cluster"
echo ""
echo "📝 Next Steps"
echo "============="
echo "1. Create RDS database:"
echo "   See infrastructure/docs/AWS-SETUP-GUIDE.md - Section 5"
echo ""
echo "2. Store secrets in AWS Secrets Manager:"
echo "   aws secretsmanager create-secret --name vertical-vibing/database-url --secret-string 'your-db-url'"
echo "   aws secretsmanager create-secret --name vertical-vibing/jwt-secret --secret-string 'your-jwt-secret'"
echo ""
echo "3. Build and push Docker image:"
echo "   cd repos/backend"
echo "   docker build -t vertical-vibing-backend ."
echo "   aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REPO_URI"
echo "   docker tag vertical-vibing-backend:latest $REPO_URI:latest"
echo "   docker push $REPO_URI:latest"
echo ""
echo "4. Deploy infrastructure with Terraform:"
echo "   cd infrastructure/terraform/environments/dev"
echo "   terraform init"
echo "   terraform plan"
echo "   terraform apply"
echo ""
echo "For complete setup instructions, see:"
echo "infrastructure/docs/AWS-SETUP-GUIDE.md"
