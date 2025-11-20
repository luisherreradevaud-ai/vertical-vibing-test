# Complete AWS Setup Guide for Vertical Vibing

**For Beginners:** This guide assumes you have little AWS experience. We'll walk through everything step-by-step.

**What we'll set up:**
- AWS Account
- IAM User with proper permissions
- Authentication (AWS Cognito + Clerk)
- Frontend hosting (AWS Amplify)
- Backend hosting (AWS ECS with Fargate)
- Database (AWS RDS PostgreSQL)
- Infrastructure as Code (Terraform state storage)

**Time estimate:** 2-3 hours for first-time setup

---

## Table of Contents

1. [AWS Account Setup](#1-aws-account-setup)
2. [IAM User Setup](#2-iam-user-setup)
3. [Terraform State Storage](#3-terraform-state-storage)
4. [Authentication Setup](#4-authentication-setup)
   - [Option A: AWS Cognito](#option-a-aws-cognito)
   - [Option B: Clerk](#option-b-clerk)
5. [Database Setup (RDS PostgreSQL)](#5-database-setup-rds-postgresql)
6. [Backend Deployment (ECS Fargate)](#6-backend-deployment-ecs-fargate)
7. [Frontend Deployment (AWS Amplify)](#7-frontend-deployment-aws-amplify)
8. [Environment Variables](#8-environment-variables)
9. [Cost Estimation](#9-cost-estimation)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. AWS Account Setup

### Step 1.1: Create AWS Account

1. Go to https://aws.amazon.com/
2. Click "Create an AWS Account"
3. Enter:
   - Email address
   - Password
   - AWS account name (e.g., "Vertical Vibing")
4. Choose "Personal" account type
5. Enter payment information (credit card required)
   - **Note:** AWS Free Tier covers most of this setup for first 12 months
6. Verify your phone number
7. Choose "Basic Support" plan (free)

**Result:** You now have an AWS account and are logged into the AWS Console.

### Step 1.2: Enable MFA (Multi-Factor Authentication)

Security best practice - set this up immediately:

1. In AWS Console, click your name (top-right) → "Security credentials"
2. Under "Multi-factor authentication (MFA)", click "Assign MFA device"
3. Choose "Virtual MFA device" (use Google Authenticator or Authy app)
4. Scan QR code with your phone
5. Enter two consecutive MFA codes
6. Click "Assign MFA"

**Result:** Your root account is now secured with MFA.

---

## 2. IAM User Setup

**Why:** Never use root account for daily work. Create an IAM user with specific permissions.

### Step 2.1: Create IAM User

1. In AWS Console, search for "IAM" and open IAM service
2. In left sidebar, click "Users"
3. Click "Create user"
4. Enter username: `vertical-vibing-admin`
5. Check "Provide user access to the AWS Management Console"
6. Choose "I want to create an IAM user"
7. Choose "Custom password", enter a strong password
8. **Uncheck** "Users must create a new password at next sign-in"
9. Click "Next"

### Step 2.2: Attach Permissions

1. Choose "Attach policies directly"
2. Search and select these policies:
   - `AdministratorAccess` (for development/testing)
   - **Note:** In production, use more restrictive policies
3. Click "Next"
4. Review and click "Create user"

### Step 2.3: Create Access Keys

1. Click on the user you just created
2. Go to "Security credentials" tab
3. Scroll to "Access keys"
4. Click "Create access key"
5. Choose "Command Line Interface (CLI)"
6. Check "I understand the above recommendation"
7. Click "Next"
8. Add description tag: "Terraform and CLI access"
9. Click "Create access key"
10. **IMPORTANT:** Download the `.csv` file or copy:
    - Access key ID
    - Secret access key
    - **You can't see the secret key again!**

### Step 2.4: Configure AWS CLI

Open your terminal and run:

```bash
# Install AWS CLI (macOS)
brew install awscli

# Configure AWS CLI
aws configure

# Enter when prompted:
AWS Access Key ID: [paste your access key ID]
AWS Secret Access Key: [paste your secret access key]
Default region name: us-east-1
Default output format: json
```

Test it works:

```bash
aws sts get-caller-identity
```

**Expected output:**
```json
{
    "UserId": "AIDAI...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/vertical-vibing-admin"
}
```

**Result:** You can now use AWS CLI and Terraform with proper credentials.

---

## 3. Terraform State Storage

**Why:** Terraform needs a place to store its state file. We'll use S3 + DynamoDB for state locking.

### Step 3.1: Create S3 Bucket for Terraform State

```bash
# Create bucket
aws s3 mb s3://vertical-vibing-terraform-state --region us-east-1

# Enable versioning (important for state recovery)
aws s3api put-bucket-versioning \
  --bucket vertical-vibing-terraform-state \
  --versioning-configuration Status=Enabled

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

# Block public access
aws s3api put-public-access-block \
  --bucket vertical-vibing-terraform-state \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### Step 3.2: Create DynamoDB Table for State Locking

```bash
aws dynamodb create-table \
  --table-name terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### Step 3.3: Verify Setup

```bash
# Check bucket exists
aws s3 ls | grep terraform-state

# Check DynamoDB table exists
aws dynamodb describe-table --table-name terraform-lock --query 'Table.TableName'
```

**Result:** Terraform can now safely store state in S3 with locking.

---

## 4. Authentication Setup

You have two options for authentication:

- **Option A: AWS Cognito** - AWS-native, no additional cost for < 50k users
- **Option B: Clerk** - Easier to use, better DX, starts free then $25/month

**Recommendation:** Start with Clerk for easier development, migrate to Cognito later if needed.

### Option A: AWS Cognito

#### Step A.1: Create User Pool

1. In AWS Console, search for "Cognito"
2. Click "Create user pool"
3. **Configure sign-in experience:**
   - Sign-in options: Choose "Email"
   - Provider: "Cognito user pool"
   - Click "Next"

4. **Configure security requirements:**
   - Password policy: Choose "Cognito defaults"
   - Multi-factor authentication: Choose "No MFA" (for development)
   - Click "Next"

5. **Configure sign-up experience:**
   - Self-service sign-up: Enable
   - Attribute verification: "Send email message, verify email address"
   - Required attributes: Select "name", "email"
   - Click "Next"

6. **Configure message delivery:**
   - Email provider: "Send email with Cognito" (for development)
   - **Note:** For production, use SES for better deliverability
   - Click "Next"

7. **Integrate your app:**
   - User pool name: `vertical-vibing-users`
   - App client name: `vertical-vibing-web`
   - Client secret: Choose "Don't generate a client secret"
   - Click "Next"

8. **Review and create:**
   - Review settings
   - Click "Create user pool"

#### Step A.2: Get Configuration Values

After creation, you'll see:

1. **User Pool ID**: `us-east-1_XXXXXXXXX` (copy this)
2. Click on the user pool, go to "App integration" tab
3. Scroll down to "App clients", click on your app client
4. **App client ID**: Copy this value

#### Step A.3: Configure Identity Pool (for AWS SDK access)

1. In Cognito console, click "Federated identities" (left sidebar)
2. Click "Create new identity pool"
3. Identity pool name: `vertical_vibing_identity_pool`
4. Enable "Unauthenticated identities" (for guest access if needed)
5. Under "Authentication providers":
   - Expand "Cognito"
   - User Pool ID: [paste your user pool ID]
   - App Client ID: [paste your app client ID]
6. Click "Create Pool"
7. Click "Allow" to create IAM roles
8. **Identity Pool ID**: Copy this value (format: `us-east-1:xxxxx-xxxxx`)

#### Step A.4: Backend Integration

Update `repos/backend/.env`:

```bash
# AWS Cognito
AWS_COGNITO_USER_POOL_ID=us-east-1_XXXXXXXXX
AWS_COGNITO_CLIENT_ID=your-app-client-id
AWS_COGNITO_REGION=us-east-1
```

Install AWS Cognito SDK:

```bash
cd repos/backend
npm install aws-jwt-verify
```

Create Cognito middleware:

```typescript
// repos/backend/src/shared/middleware/cognito-auth.ts
import { CognitoJwtVerifier } from "aws-jwt-verify";

const verifier = CognitoJwtVerifier.create({
  userPoolId: process.env.AWS_COGNITO_USER_POOL_ID!,
  tokenUse: "access",
  clientId: process.env.AWS_COGNITO_CLIENT_ID!,
});

export async function cognitoAuth(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.replace("Bearer ", "");

  if (!token) {
    return res.status(401).json({ error: "No token provided" });
  }

  try {
    const payload = await verifier.verify(token);
    req.user = {
      id: payload.sub,
      email: payload.email,
    };
    next();
  } catch (error) {
    return res.status(401).json({ error: "Invalid token" });
  }
}
```

#### Step A.5: Frontend Integration

Install AWS Amplify:

```bash
cd repos/frontend
npm install aws-amplify @aws-amplify/ui-react
```

Configure Amplify:

```typescript
// repos/frontend/src/lib/amplify.ts
import { Amplify } from 'aws-amplify';

Amplify.configure({
  Auth: {
    Cognito: {
      userPoolId: process.env.NEXT_PUBLIC_COGNITO_USER_POOL_ID!,
      userPoolClientId: process.env.NEXT_PUBLIC_COGNITO_CLIENT_ID!,
      region: process.env.NEXT_PUBLIC_AWS_REGION!,
    }
  }
});
```

Update `repos/frontend/.env.local`:

```bash
NEXT_PUBLIC_COGNITO_USER_POOL_ID=us-east-1_XXXXXXXXX
NEXT_PUBLIC_COGNITO_CLIENT_ID=your-app-client-id
NEXT_PUBLIC_AWS_REGION=us-east-1
```

### Option B: Clerk

#### Step B.1: Create Clerk Account

1. Go to https://clerk.com/
2. Click "Get Started Free"
3. Sign up with GitHub or email
4. Create your first application:
   - Application name: "Vertical Vibing"
   - Choose sign-in options: Email + Google (recommended)
   - Click "Create Application"

#### Step B.2: Get API Keys

In Clerk Dashboard:

1. Go to "API Keys" (left sidebar)
2. Copy these values:
   - **Publishable Key**: `pk_test_...`
   - **Secret Key**: `sk_test_...` (click "Show" to reveal)

#### Step B.3: Backend Integration

Install Clerk SDK:

```bash
cd repos/backend
npm install @clerk/clerk-sdk-node
```

Update `repos/backend/.env`:

```bash
# Clerk
CLERK_SECRET_KEY=sk_test_...
CLERK_PUBLISHABLE_KEY=pk_test_...
```

Create Clerk middleware:

```typescript
// repos/backend/src/shared/middleware/clerk-auth.ts
import { ClerkExpressRequireAuth } from '@clerk/clerk-sdk-node';

export const clerkAuth = ClerkExpressRequireAuth({
  onError: (error) => {
    console.error('Clerk auth error:', error);
  }
});

// Usage in routes:
// router.get('/protected', clerkAuth(), (req, res) => {
//   const userId = req.auth.userId;
//   res.json({ userId });
// });
```

#### Step B.4: Frontend Integration

Install Clerk React:

```bash
cd repos/frontend
npm install @clerk/nextjs
```

Update `repos/frontend/.env.local`:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
```

Wrap your app:

```typescript
// repos/frontend/src/app/layout.tsx
import { ClerkProvider } from '@clerk/nextjs';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body>{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

Add sign-in page:

```typescript
// repos/frontend/src/app/sign-in/[[...sign-in]]/page.tsx
import { SignIn } from '@clerk/nextjs';

export default function SignInPage() {
  return (
    <div style={{ display: 'flex', justifyContent: 'center', padding: '3rem' }}>
      <SignIn />
    </div>
  );
}
```

**Result:** Authentication is now set up. Clerk is easier for development; Cognito is better for cost at scale.

---

## 5. Database Setup (RDS PostgreSQL)

### Step 5.1: Create VPC (Virtual Private Cloud)

**Note:** Skip if you already have a default VPC.

Check for default VPC:

```bash
aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId'
```

If it returns a VPC ID, you're good. Otherwise, create one:

```bash
# Create VPC
aws ec2 create-default-vpc
```

### Step 5.2: Create Security Group for RDS

```bash
# Get your VPC ID
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)

# Create security group
aws ec2 create-security-group \
  --group-name vertical-vibing-rds-sg \
  --description "Security group for Vertical Vibing RDS" \
  --vpc-id $VPC_ID

# Get security group ID
SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=vertical-vibing-rds-sg" \
  --query 'SecurityGroups[0].GroupId' --output text)

# Allow PostgreSQL access from anywhere (for development)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 5432 \
  --cidr 0.0.0.0/0

echo "Security Group ID: $SG_ID"
```

**Important:** For production, restrict `--cidr` to your backend's IP/security group only.

### Step 5.3: Create RDS PostgreSQL Instance

#### Option 1: Using AWS Console (Easier for beginners)

1. In AWS Console, search for "RDS"
2. Click "Create database"
3. **Choose a database creation method:**
   - Select "Standard create"

4. **Engine options:**
   - Engine type: "PostgreSQL"
   - Version: Latest (e.g., PostgreSQL 15.x)

5. **Templates:**
   - Choose "Free tier" (for development)
   - **Note:** Free tier includes db.t3.micro, 20GB storage, single-AZ

6. **Settings:**
   - DB instance identifier: `vertical-vibing-db`
   - Master username: `postgres`
   - Master password: Create a strong password (save it!)
   - Confirm password

7. **Instance configuration:**
   - DB instance class: `db.t3.micro` (Free tier eligible)

8. **Storage:**
   - Storage type: "General Purpose SSD (gp3)"
   - Allocated storage: 20 GB (Free tier)
   - Uncheck "Enable storage autoscaling" (for development)

9. **Connectivity:**
   - Virtual private cloud (VPC): Choose default VPC
   - Public access: **Yes** (for development)
     - **Note:** For production, use **No** and connect via VPN/bastion
   - VPC security group: Choose "vertical-vibing-rds-sg"

10. **Additional configuration:**
    - Initial database name: `vertical_vibing`
    - Uncheck "Enable automated backups" (for development)
    - Uncheck "Enable encryption" (for development)

11. **Monitoring:**
    - Uncheck "Enable Enhanced monitoring" (for development)

12. Click "Create database"

**Wait time:** 5-10 minutes for database to be available.

#### Option 2: Using AWS CLI (Faster)

```bash
# Get subnet groups (required for RDS)
SUBNET_GROUP=$(aws rds describe-db-subnet-groups --query 'DBSubnetGroups[0].DBSubnetGroupName' --output text)

# If no subnet group exists, you'll need to create one (use Console method instead)

# Create RDS instance
aws rds create-db-instance \
  --db-instance-identifier vertical-vibing-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 15.4 \
  --master-username postgres \
  --master-user-password 'YourStrongPassword123!' \
  --allocated-storage 20 \
  --db-name vertical_vibing \
  --vpc-security-group-ids $SG_ID \
  --publicly-accessible \
  --no-multi-az \
  --no-storage-encrypted \
  --backup-retention-period 0
```

### Step 5.4: Get Database Connection String

Wait for database to be available:

```bash
aws rds wait db-instance-available --db-instance-identifier vertical-vibing-db
```

Get endpoint:

```bash
aws rds describe-db-instances \
  --db-instance-identifier vertical-vibing-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text
```

**Result:** Something like `vertical-vibing-db.xxxxxx.us-east-1.rds.amazonaws.com`

### Step 5.5: Update Backend Environment Variables

```bash
# repos/backend/.env
DATABASE_URL=postgresql://postgres:YourStrongPassword123!@vertical-vibing-db.xxxxxx.us-east-1.rds.amazonaws.com:5432/vertical_vibing
```

### Step 5.6: Test Connection

```bash
cd repos/backend

# Run migrations
npm run db:migrate

# Open Drizzle Studio to verify
npm run db:studio
```

**Result:** Database is now set up and connected to your backend.

---

## 6. Backend Deployment (ECS Fargate)

**Why ECS Fargate:** Serverless containers - no server management, auto-scaling, pay per use.

### Step 6.1: Install Docker (if not installed)

```bash
# macOS
brew install docker
```

### Step 6.2: Create Dockerfile for Backend

This should already exist, but here's the production version:

```dockerfile
# repos/backend/Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY src ./src

# Build
RUN npm run build

# Production image
FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --production

# Copy built files from builder
COPY --from=builder /app/dist ./dist

# Expose port
EXPOSE 3000

# Start server
CMD ["node", "dist/index.js"]
```

### Step 6.3: Create ECR Repository (Docker image storage)

```bash
# Create repository
aws ecr create-repository \
  --repository-name vertical-vibing-backend \
  --region us-east-1

# Get repository URI
REPO_URI=$(aws ecr describe-repositories \
  --repository-names vertical-vibing-backend \
  --query 'repositories[0].repositoryUri' \
  --output text)

echo "Repository URI: $REPO_URI"
```

### Step 6.4: Build and Push Docker Image

```bash
cd repos/backend

# Get ECR login token
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $REPO_URI

# Build image
docker build -t vertical-vibing-backend .

# Tag image
docker tag vertical-vibing-backend:latest $REPO_URI:latest

# Push image
docker push $REPO_URI:latest
```

### Step 6.5: Create ECS Cluster

```bash
aws ecs create-cluster \
  --cluster-name vertical-vibing-cluster \
  --region us-east-1
```

### Step 6.6: Create Task Definition

Create file: `infrastructure/ecs/backend-task-definition.json`

```json
{
  "family": "vertical-vibing-backend",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::YOUR_ACCOUNT_ID:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "backend",
      "image": "YOUR_REPO_URI:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        },
        {
          "name": "PORT",
          "value": "3000"
        }
      ],
      "secrets": [
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:YOUR_ACCOUNT_ID:secret:vertical-vibing/database-url"
        },
        {
          "name": "JWT_SECRET",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:YOUR_ACCOUNT_ID:secret:vertical-vibing/jwt-secret"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/vertical-vibing-backend",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

**Note:** We'll store secrets in AWS Secrets Manager next.

### Step 6.7: Store Secrets in AWS Secrets Manager

```bash
# Store DATABASE_URL
aws secretsmanager create-secret \
  --name vertical-vibing/database-url \
  --secret-string "postgresql://postgres:YourPassword@your-rds-endpoint:5432/vertical_vibing"

# Store JWT_SECRET
aws secretsmanager create-secret \
  --name vertical-vibing/jwt-secret \
  --secret-string "your-jwt-secret-key"

# If using Clerk, store that too
aws secretsmanager create-secret \
  --name vertical-vibing/clerk-secret-key \
  --secret-string "sk_test_..."
```

### Step 6.8: Create ECS Task Execution Role

```bash
# Create role
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ecs-tasks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach AWS managed policy
aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# Add Secrets Manager access
aws iam put-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-name SecretsManagerAccess \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:*:secret:vertical-vibing/*"
    }]
  }'
```

### Step 6.9: Get Your AWS Account ID and Update Task Definition

```bash
# Get your account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Your AWS Account ID: $ACCOUNT_ID"
```

Now edit `infrastructure/ecs/backend-task-definition.json`:
- Replace `YOUR_ACCOUNT_ID` with your actual account ID
- Replace `YOUR_REPO_URI` with your ECR repository URI

### Step 6.10: Register Task Definition

```bash
aws ecs register-task-definition \
  --cli-input-json file://infrastructure/ecs/backend-task-definition.json
```

### Step 6.11: Create CloudWatch Log Group

```bash
aws logs create-log-group \
  --log-group-name /ecs/vertical-vibing-backend \
  --region us-east-1
```

### Step 6.12: Create ECS Service with Load Balancer

**Note:** This is complex. For now, let's create a service without load balancer (simpler for development).

Get your default subnets and security group:

```bash
# Get default VPC subnets
SUBNETS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[*].SubnetId' \
  --output text | tr '\t' ',')

# Create security group for ECS tasks
aws ec2 create-security-group \
  --group-name vertical-vibing-ecs-tasks-sg \
  --description "Security group for Vertical Vibing ECS tasks" \
  --vpc-id $VPC_ID

ECS_SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=vertical-vibing-ecs-tasks-sg" \
  --query 'SecurityGroups[0].GroupId' --output text)

# Allow HTTP traffic
aws ec2 authorize-security-group-ingress \
  --group-id $ECS_SG_ID \
  --protocol tcp \
  --port 3000 \
  --cidr 0.0.0.0/0

# Create ECS service
aws ecs create-service \
  --cluster vertical-vibing-cluster \
  --service-name backend-service \
  --task-definition vertical-vibing-backend \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$ECS_SG_ID],assignPublicIp=ENABLED}"
```

### Step 6.13: Get Backend Public IP

```bash
# Wait for service to be stable
aws ecs wait services-stable \
  --cluster vertical-vibing-cluster \
  --services backend-service

# Get task ARN
TASK_ARN=$(aws ecs list-tasks \
  --cluster vertical-vibing-cluster \
  --service-name backend-service \
  --query 'taskArns[0]' --output text)

# Get network interface ID
ENI_ID=$(aws ecs describe-tasks \
  --cluster vertical-vibing-cluster \
  --tasks $TASK_ARN \
  --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
  --output text)

# Get public IP
PUBLIC_IP=$(aws ec2 describe-network-interfaces \
  --network-interface-ids $ENI_ID \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text)

echo "Backend is running at: http://$PUBLIC_IP:3000"
```

**Result:** Your backend is now deployed on AWS ECS Fargate!

---

## 7. Frontend Deployment (AWS Amplify)

**Why Amplify:** Dead simple Next.js deployment with automatic builds, SSL, CDN, preview URLs.

### Step 7.1: Push Code to GitHub

```bash
# Initialize git in frontend (if not already)
cd repos/frontend
git init
git add .
git commit -m "Initial commit"

# Create GitHub repo (via GitHub.com)
# Then push
git remote add origin https://github.com/your-username/vertical-vibing-frontend.git
git push -u origin main
```

### Step 7.2: Create Amplify App

1. In AWS Console, search for "Amplify"
2. Click "Get Started" under "Amplify Hosting"
3. Choose "GitHub" (or your git provider)
4. Click "Continue"
5. Authorize AWS Amplify to access your GitHub
6. Select:
   - Repository: `vertical-vibing-frontend`
   - Branch: `main`
7. Click "Next"

### Step 7.3: Configure Build Settings

Amplify will auto-detect Next.js. Verify the build settings:

```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - npm ci
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: .next
    files:
      - '**/*'
  cache:
    paths:
      - node_modules/**/*
      - .next/cache/**/*
```

Click "Next"

### Step 7.4: Add Environment Variables

Click "Add environment variable" and add:

```
NEXT_PUBLIC_API_URL = http://YOUR_BACKEND_PUBLIC_IP:3000

# If using Clerk:
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY = pk_test_...
CLERK_SECRET_KEY = sk_test_...

# If using Cognito:
NEXT_PUBLIC_COGNITO_USER_POOL_ID = us-east-1_XXXXXXXXX
NEXT_PUBLIC_COGNITO_CLIENT_ID = your-client-id
NEXT_PUBLIC_AWS_REGION = us-east-1
```

Click "Next"

### Step 7.5: Review and Deploy

1. Review settings
2. Click "Save and deploy"

**Wait time:** 3-5 minutes for first deployment

### Step 7.6: Get Frontend URL

After deployment completes, you'll see:
- **Domain:** Something like `https://main.d1234567890.amplifyapp.com`

Copy this URL - your frontend is live!

### Step 7.7: Set Custom Domain (Optional)

If you have a domain:

1. In Amplify console, click "Domain management"
2. Click "Add domain"
3. Enter your domain (e.g., `vertical-vibing.com`)
4. Follow DNS configuration instructions
5. Wait for SSL certificate to be issued (5-30 minutes)

**Result:** Your frontend is now deployed on AWS Amplify with automatic SSL and CDN!

---

## 8. Environment Variables

### Complete Environment Variable Reference

**Backend (`repos/backend/.env`):**
```bash
# Server
NODE_ENV=production
PORT=3000

# Database
DATABASE_URL=postgresql://postgres:password@vertical-vibing-db.xxxxx.us-east-1.rds.amazonaws.com:5432/vertical_vibing

# Authentication (choose one)

# Option A: Clerk
CLERK_SECRET_KEY=sk_test_...
CLERK_PUBLISHABLE_KEY=pk_test_...

# Option B: AWS Cognito
AWS_COGNITO_USER_POOL_ID=us-east-1_XXXXXXXXX
AWS_COGNITO_CLIENT_ID=your-client-id
AWS_COGNITO_REGION=us-east-1

# JWT
JWT_SECRET=your-super-secret-jwt-key-min-32-chars

# AWS (for infrastructure features)
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# Feature-specific (when you add infrastructure)
PROFILE_PICTURES_BUCKET=vertical-vibing-profile-pictures-prod
UPLOADS_BUCKET_NAME=vertical-vibing-uploads-prod
```

**Frontend (`repos/frontend/.env.local`):**
```bash
# API
NEXT_PUBLIC_API_URL=https://your-backend-url.com

# Authentication (choose one)

# Option A: Clerk
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_live_...
CLERK_SECRET_KEY=sk_live_...

# Option B: AWS Cognito
NEXT_PUBLIC_COGNITO_USER_POOL_ID=us-east-1_XXXXXXXXX
NEXT_PUBLIC_COGNITO_CLIENT_ID=your-client-id
NEXT_PUBLIC_AWS_REGION=us-east-1
```

---

## 9. Cost Estimation

### Free Tier (First 12 Months)

- **RDS:** db.t3.micro, 20GB storage = FREE
- **ECS Fargate:** 25GB storage, 20GB bandwidth = FREE
- **Amplify:** 1000 build minutes, 15GB hosting = FREE
- **Cognito:** 50,000 MAU = FREE
- **S3:** 5GB storage, 20,000 GET requests = FREE

**Total Month 1-12:** ~$0-5/month (mostly data transfer)

### After Free Tier

- **RDS db.t3.micro:** $15/month
- **ECS Fargate (1 task):** $15/month
- **Amplify:** $0.01/build minute + $0.15/GB hosting
- **S3:** $0.023/GB storage
- **Data transfer:** $0.09/GB (after 100GB free tier)

**Estimated Monthly Cost:**
- Development: $30-40/month
- Production (< 1000 users): $50-80/month
- Production (1000-10000 users): $100-200/month

**Add if using Clerk:**
- Free: Up to 10,000 MAU
- Pro: $25/month + $0.02/MAU after 10,000

---

## 10. Troubleshooting

### Issue: Cannot connect to RDS

**Symptoms:** Backend throws "Connection refused" or timeout

**Solutions:**
1. Check security group allows inbound on port 5432
2. Verify RDS is "publicly accessible" (for development)
3. Check DATABASE_URL is correct
4. Test connection:
   ```bash
   psql "postgresql://postgres:password@your-rds-endpoint:5432/vertical_vibing"
   ```

### Issue: ECS task keeps failing

**Symptoms:** Task starts then stops immediately

**Solutions:**
1. Check CloudWatch logs:
   ```bash
   aws logs tail /ecs/vertical-vibing-backend --follow
   ```
2. Verify all environment variables are set correctly
3. Verify secrets exist in Secrets Manager
4. Check Docker image builds locally:
   ```bash
   docker run -p 3000:3000 vertical-vibing-backend:latest
   ```

### Issue: Amplify build fails

**Symptoms:** Build fails in Amplify console

**Solutions:**
1. Check build logs in Amplify console
2. Verify `package.json` has `build` script
3. Check all `NEXT_PUBLIC_*` environment variables are set
4. Try building locally:
   ```bash
   cd repos/frontend
   npm run build
   ```

### Issue: CORS errors in frontend

**Symptoms:** "CORS policy: No 'Access-Control-Allow-Origin' header"

**Solution:** Add CORS middleware to backend:

```typescript
// repos/backend/src/index.ts
import cors from 'cors';

app.use(cors({
  origin: [
    'http://localhost:3001',
    'https://your-amplify-domain.amplifyapp.com'
  ],
  credentials: true
}));
```

### Issue: "Invalid credentials" when using AWS CLI

**Solutions:**
1. Verify access keys:
   ```bash
   aws sts get-caller-identity
   ```
2. Reconfigure AWS CLI:
   ```bash
   aws configure
   ```
3. Check `~/.aws/credentials` file exists

---

## Next Steps

You now have:
- ✅ AWS account with proper IAM setup
- ✅ Authentication (Cognito or Clerk)
- ✅ Database (RDS PostgreSQL)
- ✅ Backend deployed (ECS Fargate)
- ✅ Frontend deployed (Amplify)
- ✅ Terraform state storage ready

**What's next:**

1. **Set up CI/CD:**
   - GitHub Actions to auto-deploy on push
   - Automated testing before deployment

2. **Add a Load Balancer:**
   - Application Load Balancer for backend
   - Custom domain with SSL

3. **Add monitoring:**
   - CloudWatch dashboards
   - Alerts for errors/downtime

4. **Deploy infrastructure with Terraform:**
   - Now that you have AWS set up, you can use the Terraform modules we created earlier
   - Deploy features like file uploads (S3), email (SES), etc.

5. **Secure for production:**
   - Move RDS to private subnet
   - Use AWS WAF for DDoS protection
   - Enable RDS backups
   - Use Route 53 for DNS

---

## Quick Reference Commands

```bash
# Check AWS credentials
aws sts get-caller-identity

# View RDS instances
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address]'

# View ECS services
aws ecs list-services --cluster vertical-vibing-cluster

# View Amplify apps
aws amplify list-apps

# Check backend logs
aws logs tail /ecs/vertical-vibing-backend --follow

# Redeploy backend
docker build -t vertical-vibing-backend repos/backend
docker tag vertical-vibing-backend:latest $REPO_URI:latest
docker push $REPO_URI:latest
aws ecs update-service --cluster vertical-vibing-cluster --service backend-service --force-new-deployment

# Redeploy frontend
git push origin main  # Amplify auto-deploys
```

---

**Need help?** Check AWS documentation or reach out to AWS Support (included in Basic plan).

**Pro tip:** Set up billing alerts! Go to AWS Console → Billing → Budgets → Create a budget to get notified if costs exceed $10/month.
