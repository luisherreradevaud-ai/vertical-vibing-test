# Vertical Vibing AWS Architecture

## Complete Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│                              USERS / CLIENTS                                │
│                                                                             │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │
                                 │ HTTPS
                                 │
                ┌────────────────┴────────────────┐
                │                                 │
                │                                 │
┌───────────────▼──────────────┐   ┌─────────────▼────────────────┐
│                              │   │                               │
│   AWS AMPLIFY (Frontend)     │   │   AWS COGNITO / CLERK        │
│   - Next.js 14+ App          │   │   - User Authentication      │
│   - Auto SSL                 │   │   - JWT Tokens               │
│   - Global CDN               │   │   - User Management          │
│   - Auto Builds on Git Push  │   │                               │
│                              │   │                               │
└──────────────┬───────────────┘   └──────────────┬────────────────┘
               │                                   │
               │ API Calls                         │ Auth Tokens
               │                                   │
               └──────────────┬────────────────────┘
                              │
                              │ HTTPS
                              │
┌─────────────────────────────▼────────────────────────────────────┐
│                                                                   │
│              APPLICATION LOAD BALANCER (Optional)                │
│              - SSL Termination                                   │
│              - Health Checks                                     │
│              - Auto Scaling                                      │
│                                                                   │
└──────────────────────────────┬───────────────────────────────────┘
                               │
                               │
        ┌──────────────────────┴──────────────────────┐
        │                                             │
        │                                             │
┌───────▼─────────────────────┐          ┌───────────▼──────────────┐
│                             │          │                          │
│  ECS FARGATE CLUSTER        │          │  CLOUDWATCH              │
│                             │          │  - Logs                  │
│  ┌─────────────────────┐   │          │  - Metrics               │
│  │  Backend Service    │   │          │  - Alarms                │
│  │  (Express.js API)   │───┼──────────▶                          │
│  │  - Task Definition  │   │          │                          │
│  │  - Auto Scaling     │   │          └──────────────────────────┘
│  │  - Health Checks    │   │
│  └──────────┬──────────┘   │
│             │               │
│             │ Connects to   │
│             │               │
└─────────────┼───────────────┘
              │
              │
    ┌─────────┴──────────┬──────────────┬────────────────┐
    │                    │              │                │
    │                    │              │                │
┌───▼─────────┐  ┌───────▼──────┐  ┌──▼──────────┐  ┌──▼──────────────┐
│             │  │              │  │             │  │                 │
│  RDS        │  │  S3 BUCKETS  │  │  SQS        │  │  SECRETS        │
│  PostgreSQL │  │              │  │  (Queues)   │  │  MANAGER        │
│             │  │  ┌────────┐  │  │             │  │                 │
│  - Primary  │  │  │Uploads │  │  │  - Jobs     │  │  - DB Password  │
│  - Multi-AZ │  │  └────────┘  │  │  - Events   │  │  - JWT Secret   │
│  - Backups  │  │  ┌────────┐  │  │             │  │  - API Keys     │
│             │  │  │Assets  │  │  │             │  │                 │
│             │  │  └────────┘  │  │             │  │                 │
└─────────────┘  └───────┬──────┘  └─────────────┘  └─────────────────┘
                         │
                         │
                ┌────────▼────────┐
                │                 │
                │  CLOUDFRONT CDN │
                │  - Global Cache │
                │  - Fast Delivery│
                │                 │
                └─────────────────┘
```

## Infrastructure Layers

### Layer 1: User Access & Authentication
```
┌─────────────────────────────────────────┐
│ Users                                   │
├─────────────────────────────────────────┤
│ ↓ HTTPS                                 │
├─────────────────────────────────────────┤
│ AWS Amplify (Frontend)                  │
│ - Serves Next.js app globally           │
│ - Auto SSL certificate                  │
│ - Git-based deployments                 │
├─────────────────────────────────────────┤
│ AWS Cognito / Clerk (Auth)              │
│ - User sign up/sign in                  │
│ - Issues JWT tokens                     │
│ - MFA support                           │
└─────────────────────────────────────────┘
```

### Layer 2: Application Tier
```
┌─────────────────────────────────────────┐
│ ECS Fargate (Backend)                   │
├─────────────────────────────────────────┤
│ Tasks:                                  │
│ ┌─────────────────────────────────────┐ │
│ │ Backend Container                   │ │
│ │ - Express.js API                    │ │
│ │ - JWT validation                    │ │
│ │ - Business logic                    │ │
│ │ - Database queries                  │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ Features:                               │
│ - Auto scaling (CPU/Memory based)       │
│ - Health checks                         │
│ - Rolling updates                       │
│ - Zero downtime deployments             │
└─────────────────────────────────────────┘
```

### Layer 3: Data & Storage
```
┌──────────────────┬──────────────────┬──────────────────┐
│ RDS PostgreSQL   │ S3 Buckets       │ Secrets Manager  │
├──────────────────┼──────────────────┼──────────────────┤
│ - User data      │ - File uploads   │ - DB credentials │
│ - App data       │ - Images         │ - JWT secrets    │
│ - Transactional  │ - Documents      │ - API keys       │
│ - ACID compliant │ - Static assets  │ - Encrypted      │
│ - Automated      │ - Versioning     │ - Rotatable      │
│   backups        │ - Lifecycle      │ - IAM access     │
└──────────────────┴──────────────────┴──────────────────┘
```

### Layer 4: Supporting Services
```
┌──────────────────┬──────────────────┬──────────────────┐
│ CloudWatch       │ SQS (Optional)   │ Lambda (Optional)│
├──────────────────┼──────────────────┼──────────────────┤
│ - Application    │ - Background     │ - Image resize   │
│   logs           │   jobs           │ - File process   │
│ - Metrics        │ - Email queue    │ - Scheduled jobs │
│ - Alarms         │ - Event bus      │ - Webhooks       │
│ - Dashboards     │ - Decoupling     │ - Serverless     │
└──────────────────┴──────────────────┴──────────────────┘
```

## Data Flow Examples

### Example 1: User Sign Up & Login

```
User Browser
    │
    │ 1. Click "Sign Up"
    ▼
AWS Amplify (Frontend)
    │
    │ 2. POST /auth/signup
    ▼
Cognito/Clerk
    │
    │ 3. Create user
    │ 4. Send verification email
    │ 5. Return JWT token
    ▼
Frontend stores token
    │
    │ 6. Use token for API calls
    ▼
Backend validates JWT
    │
    │ 7. Access protected resources
    ▼
RDS PostgreSQL
```

### Example 2: File Upload (with Infrastructure)

```
User selects file
    │
    │ 1. POST /api/uploads/request
    ▼
Backend (ECS)
    │
    │ 2. Generate presigned S3 URL
    │ 3. Return URL to frontend
    ▼
Frontend
    │
    │ 4. PUT file directly to S3 (with presigned URL)
    ▼
S3 Bucket
    │
    │ 5. File uploaded
    │ 6. S3 triggers Lambda (optional)
    ▼
Lambda (optional)
    │
    │ 7. Resize image / process file
    │ 8. Save to another S3 bucket
    ▼
CloudFront CDN
    │
    │ 9. Serve file globally
    ▼
User sees uploaded file
```

### Example 3: API Request Flow

```
Frontend (Amplify)
    │
    │ 1. GET /api/users?page=1
    │    Authorization: Bearer <JWT>
    ▼
Load Balancer (optional)
    │
    │ 2. Route to healthy ECS task
    ▼
Backend (ECS Task)
    │
    │ 3. Verify JWT
    │ 4. Authorize user
    │ 5. Query database
    ▼
RDS PostgreSQL
    │
    │ 6. Return users data
    ▼
Backend
    │
    │ 7. Format response
    │ 8. Log to CloudWatch
    │ 9. Return JSON
    ▼
Frontend
    │
    │ 10. Display users
    ▼
User sees data
```

## Security Layers

```
┌─────────────────────────────────────────────────────┐
│ Layer 1: Network Security                          │
├─────────────────────────────────────────────────────┤
│ - VPC with private/public subnets                  │
│ - Security Groups (firewall rules)                 │
│ - Network ACLs                                     │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Layer 2: Application Security                      │
├─────────────────────────────────────────────────────┤
│ - JWT token validation                             │
│ - CORS configuration                               │
│ - Rate limiting                                    │
│ - Input validation (Zod)                           │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Layer 3: Data Security                             │
├─────────────────────────────────────────────────────┤
│ - Encryption at rest (RDS, S3)                     │
│ - Encryption in transit (TLS)                      │
│ - Secrets Manager for credentials                  │
│ - Database access control                          │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Layer 4: Monitoring & Compliance                   │
├─────────────────────────────────────────────────────┤
│ - CloudWatch logs (all API calls)                  │
│ - CloudTrail (AWS API audit)                       │
│ - VPC Flow Logs (network traffic)                  │
│ - Automated alerts                                  │
└─────────────────────────────────────────────────────┘
```

## Cost Breakdown (Estimated)

### Development Environment
```
Service                  Cost/Month
─────────────────────────────────────
RDS db.t3.micro         FREE (1st year)
ECS Fargate (1 task)    FREE (1st year)
S3 (5GB)                FREE (1st year)
Amplify Hosting         FREE (1st year)
CloudWatch              ~$5
─────────────────────────────────────
TOTAL:                  ~$5/month
```

### Production Environment (< 1000 users)
```
Service                  Cost/Month
─────────────────────────────────────
RDS db.t3.micro         $15
ECS Fargate (2 tasks)   $30
Application LB          $20
S3 (50GB)               $1
CloudFront              $5
Amplify Hosting         $10
CloudWatch              $10
Cognito (free tier)     $0
─────────────────────────────────────
TOTAL:                  ~$91/month
```

### Production Environment (10,000 users)
```
Service                  Cost/Month
─────────────────────────────────────
RDS db.m5.large         $120
ECS Fargate (4 tasks)   $120
Application LB          $20
S3 (500GB)              $12
CloudFront              $50
Amplify Hosting         $20
CloudWatch              $30
Cognito                 $0 (< 50k MAU)
─────────────────────────────────────
TOTAL:                  ~$372/month
```

## Scaling Strategy

```
Stage 1: MVP (0-100 users)
├─ 1 ECS task
├─ db.t3.micro
└─ Manual deployments

Stage 2: Growth (100-1000 users)
├─ 2 ECS tasks
├─ db.t3.small
├─ Basic monitoring
└─ CI/CD pipeline

Stage 3: Scale (1000-10,000 users)
├─ 2-4 ECS tasks (auto-scaling)
├─ db.m5.large
├─ Multi-AZ RDS
├─ CloudFront CDN
├─ Advanced monitoring
└─ Automated deployments

Stage 4: Enterprise (10,000+ users)
├─ 4-10 ECS tasks (auto-scaling)
├─ db.m5.xlarge (Multi-AZ)
├─ Read replicas
├─ Redis cache
├─ WAF for DDoS protection
├─ Route 53 for DNS
└─ Multi-region (optional)
```

## Disaster Recovery

```
Backup Strategy:
├─ RDS: Automated daily backups (7-day retention)
├─ S3: Versioning enabled
├─ ECS: Immutable infrastructure (rebuild from Docker image)
├─ Secrets: Stored in Secrets Manager (encrypted)
└─ Terraform: State in S3 (versioned)

Recovery Time Objective (RTO): < 1 hour
Recovery Point Objective (RPO): < 24 hours

Recovery Steps:
1. Restore RDS from latest snapshot
2. Deploy ECS tasks from ECR image
3. Update DNS to point to new resources
4. Verify functionality
```

## Monitoring Dashboard

```
CloudWatch Dashboard:
├─ ECS Metrics
│  ├─ CPU Utilization
│  ├─ Memory Utilization
│  ├─ Task Count
│  └─ Request Count
├─ RDS Metrics
│  ├─ Database Connections
│  ├─ Read/Write IOPS
│  ├─ Storage Space
│  └─ Query Performance
├─ Application Metrics
│  ├─ API Response Times
│  ├─ Error Rates
│  ├─ Request Rates
│  └─ Auth Success/Failure
└─ Alarms
   ├─ High CPU (> 80%)
   ├─ High Memory (> 80%)
   ├─ Error Rate (> 5%)
   └─ Database Connections (> 80%)
```

## Summary

**Architecture Highlights:**
- Fully serverless/managed services (minimal ops)
- Auto-scaling at every layer
- High availability with Multi-AZ
- Secure by default
- Cost-optimized for startups
- Production-ready from day one

**Deployment Time:**
- Initial setup: 2-3 hours
- Feature deployment: 5-10 minutes
- Zero-downtime updates

**Maintenance:**
- Automated backups
- Auto-scaling
- Managed updates (RDS, Amplify)
- Minimal operational overhead
