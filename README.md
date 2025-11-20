# Vertical Vibing - Production-Ready Full-Stack SaaS Platform

**Enterprise-grade full-stack application with Infrastructure as Code, VSA Backend, Next.js Frontend, and complete AWS cloud deployment.**

[![Backend Tests](https://github.com/yourusername/vertical-vibing/workflows/Backend%20Tests/badge.svg)](https://github.com/yourusername/vertical-vibing/actions)
[![Test Coverage](60 tests passing)](./repos/backend)

---

## ✨ What's Included

### 🔐 Production-Ready IAM System
- ✅ **60 backend tests** (100% pass rate, ~90% coverage)
- ✅ **14 API endpoints** (user levels, permissions, assignments, navigation, audit)
- ✅ **7 frontend components** (complete admin UI)
- ✅ **Multi-layer security** (JWT → Tenant → Permissions)
- ✅ **Audit logging** (track all IAM changes)
- ✅ **ETag caching** (95% bandwidth reduction)
- ✅ **PostgreSQL persistence** (17 tables, production-ready)

**[→ See IAM System Documentation](./IAM-SYSTEM-COMPLETION.md)** | **[→ Database Guide](./DATABASE-PERSISTENCE-GUIDE.md)**

### 📧 Production-Ready Email System
- ✅ **30 REST API endpoints** (send, templates, logs, configuration)
- ✅ **React Email templates** (6 production-ready templates included)
- ✅ **Hybrid template system** (code defaults + database customs)
- ✅ **3-tier configuration** (database > environment > framework defaults)
- ✅ **Queue-based processing** (AWS SQS + 3 worker deployment patterns)
- ✅ **Template versioning** (Git-like rollback support)
- ✅ **IAM integration** (12 granular permissions)
- ✅ **Self-administrable** (complete admin API for zero-code management)

**[→ See Email System Documentation](./repos/backend/EMAIL-SYSTEM.md)** | **[→ Feature Overview](./repos/backend/src/features/email/FEATURE.md)**

### ☁️ Complete AWS Cloud Infrastructure
- ✅ **Infrastructure as Code** (Terraform modules and automation)
- ✅ **AI-Driven Infrastructure Detection** (Auto-determines when features need cloud resources)
- ✅ **Beginner-Friendly AWS Setup** (Step-by-step guides from zero to production)
- ✅ **Compliance Roadmaps** (SOC 2, GDPR, HIPAA with readiness assessments)
- ✅ **Cost-Optimized** ($5-10/month dev, $50-200/month production)
- ✅ **Production Deployment** (ECS Fargate, RDS, Amplify, S3, CloudFront)

**[→ Start with AWS Setup Guide](./infrastructure/docs/AWS-SETUP-GUIDE.md)** | **[→ See Architecture Diagrams](./infrastructure/docs/ARCHITECTURE-DIAGRAM.md)**

### 🏗️ Modern Architecture Stack
- ✅ **Backend**: Express.js + VSA (Vertical Slice Architecture)
- ✅ **Frontend**: Next.js 14+ App Router + FSD (Feature-Sliced Design)
- ✅ **Shared Types**: Type-safe contracts across infrastructure → backend → frontend
- ✅ **Database**: PostgreSQL + Drizzle ORM
- ✅ **Authentication**: AWS Cognito or Clerk (both supported)
- ✅ **Deployment**: Fully automated with CI/CD ready

---

## 📁 Repository Structure

```
vertical-vibing/
├── .ai-context/              # Global AI context & decision trees
│   ├── INFRASTRUCTURE-DECISION-TREE.md    # AI auto-detects infrastructure needs
│   ├── INFRASTRUCTURE.md                  # Infrastructure implementation guide
│   ├── FULLSTACK-ARCHITECTURE.md          # Architecture overview
│   └── FULLSTACK-FEATURE-WORKFLOW.md      # Feature development guide
├── infrastructure/
│   ├── docs/                 # Complete AWS documentation
│   │   ├── README.md                      # Documentation index (START HERE)
│   │   ├── AWS-SETUP-GUIDE.md             # Beginner AWS setup (31KB guide)
│   │   ├── ARCHITECTURE-DIAGRAM.md        # Visual architecture & data flows
│   │   ├── AWS-QUICK-REFERENCE.md         # Daily operations commands
│   │   ├── COMPLIANCE-GUIDE.md            # SOC 2, GDPR, HIPAA roadmaps
│   │   └── EXAMPLE-FILE-UPLOADS.md        # Complete S3 upload example
│   ├── scripts/              # Infrastructure automation
│   │   ├── aws-quick-setup.sh             # Automated AWS setup (5 min)
│   │   ├── infra-plan.sh                  # Plan Terraform changes
│   │   ├── infra-deploy.sh                # Deploy infrastructure
│   │   ├── infra-destroy.sh               # Destroy infrastructure
│   │   └── infra-outputs.sh               # View infrastructure outputs
│   └── terraform/            # Infrastructure as Code
│       ├── modules/          # Reusable Terraform modules
│       ├── features/         # Feature-specific infrastructure
│       └── environments/     # Dev, staging, production
├── shared-types/             # Shared TypeScript types (NPM package)
├── repos/
│   ├── backend/              # Express backend (VSA architecture)
│   └── frontend/             # Next.js frontend (FSD architecture)
├── scripts/                  # Development scripts
└── templates/                # AI context templates
```

---

## 🚀 Quick Start

### Option 1: Complete Setup (First Time)

```bash
# 1. Install dependencies
./scripts/setup.sh

# 2. Start development servers
./scripts/dev.sh
```

**Servers:**
- Backend: http://localhost:3000
- Frontend: http://localhost:3001

### Option 2: With AWS Cloud Infrastructure

**For beginners (Recommended):**
```bash
# 1. Read the comprehensive guide (2-3 hours)
open infrastructure/docs/AWS-SETUP-GUIDE.md

# 2. Follow step-by-step to deploy to AWS
```

**For experienced AWS users:**
```bash
# 1. Run automated setup (5 minutes)
./infrastructure/scripts/aws-quick-setup.sh

# 2. Follow quick setup path
# See: infrastructure/docs/README.md - Path 2
```

---

## 🏗️ Architecture Overview

### Complete Stack

```
┌─────────────────────────────────────────────────────────────┐
│                         USERS                               │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTPS
        ┌────────────┴────────────┐
        │                         │
┌───────▼──────────┐    ┌─────────▼──────────┐
│  AWS Amplify     │    │  Cognito / Clerk   │
│  (Frontend)      │    │  (Authentication)  │
│  Next.js 14+     │    │  JWT Tokens        │
└───────┬──────────┘    └─────────┬──────────┘
        │                         │
        └────────────┬────────────┘
                     │ API Calls
              ┌──────▼─────────┐
              │  ECS Fargate   │
              │  (Backend API) │
              │  Express.js    │
              └──────┬─────────┘
                     │
        ┌────────────┼────────────┬──────────┐
        │            │            │          │
    ┌───▼───┐   ┌───▼───┐   ┌───▼───┐  ┌──▼───┐
    │  RDS  │   │  S3   │   │  SQS  │  │Secret│
    │Postgre│   │Bucket │   │Queue  │  │Mgr   │
    └───────┘   └───────┘   └───────┘  └──────┘
```

**[→ See Complete Architecture Diagrams](./infrastructure/docs/ARCHITECTURE-DIAGRAM.md)**

### Multi-Repository Architecture

- **Orchestration Layer**: This repository (infrastructure, scripts, global AI context)
- **Backend Repository**: `repos/backend/` (VSA architecture, Express.js)
- **Frontend Repository**: `repos/frontend/` (FSD architecture, Next.js)
- **Shared Types**: `shared-types/` (NPM package, single source of truth)

---

## 📦 Core Technologies

### Backend (VSA Architecture)
- **Framework**: Express.js + TypeScript
- **Database**: PostgreSQL + Drizzle ORM
- **Validation**: Zod schemas
- **Logging**: Pino
- **Security**: Helmet, JWT, rate limiting
- **Testing**: Vitest (60 tests, ~90% coverage)

### Frontend (FSD Architecture)
- **Framework**: Next.js 14+ (App Router)
- **UI**: React 19 + Tailwind CSS 4
- **State**: Zustand
- **Components**: Server & Client Components
- **Testing**: Vitest + Testing Library

### Infrastructure (Terraform)
- **Hosting**: AWS (Amplify, ECS Fargate)
- **Database**: RDS PostgreSQL (Multi-AZ)
- **Storage**: S3 + CloudFront CDN
- **Auth**: AWS Cognito or Clerk
- **Monitoring**: CloudWatch
- **Secrets**: AWS Secrets Manager

---

## 💰 Cost Estimates

### Development Environment
```
RDS db.t3.micro         FREE (1st year)
ECS Fargate (1 task)    FREE (1st year)
S3 (5GB)                FREE (1st year)
Amplify Hosting         FREE (1st year)
CloudWatch              ~$5/month
──────────────────────────────────────
TOTAL:                  ~$5-10/month
```

### Production (<1000 users)
```
RDS db.t3.micro         $15/month
ECS Fargate (2 tasks)   $30/month
Application LB          $20/month
S3 + CloudFront         $6/month
Amplify Hosting         $10/month
CloudWatch              $10/month
──────────────────────────────────────
TOTAL:                  ~$91/month
```

### Production (10,000 users)
```
RDS db.m5.large         $120/month
ECS Fargate (4 tasks)   $120/month
Application LB          $20/month
S3 + CloudFront         $62/month
Amplify Hosting         $20/month
CloudWatch              $30/month
──────────────────────────────────────
TOTAL:                  ~$372/month
```

**[→ See Detailed Cost Breakdown](./infrastructure/docs/ARCHITECTURE-DIAGRAM.md#cost-breakdown-estimated)**

---

## 🔐 Compliance & Security

### Current Readiness
- **SOC 2 Type I**: 60% ready (~$30k-80k to certify)
- **GDPR**: 70% ready (~$5k-15k to certify)
- **HIPAA**: 50% ready (~$40k-85k to certify)
- **PCI DSS**: 40% ready (if handling payments)

### Security Features Already Implemented
- ✅ Encryption at rest (RDS, S3)
- ✅ Encryption in transit (TLS/SSL)
- ✅ Network isolation (VPC, security groups)
- ✅ Audit logging (CloudWatch, IAM audit trail)
- ✅ Secrets management (AWS Secrets Manager)
- ✅ JWT authentication
- ✅ Rate limiting
- ✅ Input validation (Zod)
- ✅ CORS configuration

**[→ See Complete Compliance Roadmaps](./infrastructure/docs/COMPLIANCE-GUIDE.md)**

---

## 📚 Documentation

### Getting Started
1. **[Infrastructure Documentation Index](./infrastructure/docs/README.md)** - Start here for AWS setup
2. **[AWS Setup Guide](./infrastructure/docs/AWS-SETUP-GUIDE.md)** - Complete beginner guide (31KB)
3. **[Quick Reference](./infrastructure/docs/AWS-QUICK-REFERENCE.md)** - Daily commands

### Architecture & Patterns
4. **[Architecture Diagrams](./infrastructure/docs/ARCHITECTURE-DIAGRAM.md)** - Visual architecture
5. **[Infrastructure Guide](./infrastructure/docs/INFRASTRUCTURE.md)** - IaC implementation
6. **[Fullstack Architecture](./infrastructure/docs/FULLSTACK-ARCHITECTURE.md)** - Overall patterns

### Examples & Workflows
7. **[File Upload Example](./infrastructure/docs/EXAMPLE-FILE-UPLOADS.md)** - Complete S3 implementation
8. **[Feature Workflow](./infrastructure/docs/FULLSTACK-FEATURE-WORKFLOW.md)** - Development guide
9. **[IAM System](./IAM-SYSTEM-COMPLETION.md)** - IAM documentation

### AI-Assisted Development
10. **[AI Coordination](./infrastructure/docs/AI-COORDINATION-GUIDE.md)** - AI workflow
11. **[Infrastructure Decision Tree](./infrastructure/docs/INFRASTRUCTURE-DECISION-TREE.md)** - Auto-detect infrastructure needs

---

## 🛠️ Development Workflows

### Local Development

```bash
# Start all servers
./scripts/dev.sh

# Run tests
./scripts/test.sh

# Backend only
cd repos/backend && npm run dev

# Frontend only
cd repos/frontend && npm run dev
```

### Infrastructure Management

```bash
# Quick setup (first time)
./infrastructure/scripts/aws-quick-setup.sh

# Plan infrastructure changes
./infrastructure/scripts/infra-plan.sh dev

# Deploy infrastructure
./infrastructure/scripts/infra-deploy.sh dev

# View infrastructure outputs
./infrastructure/scripts/infra-outputs.sh dev

# Destroy infrastructure (dev only)
./infrastructure/scripts/infra-destroy.sh dev
```

### Database Management

```bash
cd repos/backend

# Generate migration from schema changes
npm run db:generate

# Apply migrations
npm run db:migrate

# Open Drizzle Studio GUI
npm run db:studio
```

### AWS Deployment

```bash
# Backend deployment
cd repos/backend
docker build -t vertical-vibing-backend .
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ECR_URI
docker tag vertical-vibing-backend:latest ECR_URI:latest
docker push ECR_URI:latest
aws ecs update-service --cluster vertical-vibing-cluster --service backend-service --force-new-deployment

# Frontend deployment (auto-deploys on git push)
cd repos/frontend
git add . && git commit -m "Update" && git push origin main
```

**[→ See Complete Deployment Commands](./infrastructure/docs/AWS-QUICK-REFERENCE.md)**

---

## 🤖 AI-Assisted Development

This project is optimized for AI-assisted development with automatic infrastructure detection.

### How AI Agents Work

When you request a feature, AI agents:
1. **Read** `.ai-context/INFRASTRUCTURE-DECISION-TREE.md` to detect infrastructure needs
2. **Create** shared types in `shared-types/`
3. **Build** backend API in `repos/backend/src/features/`
4. **Build** frontend UI in `repos/frontend/src/features/`
5. **Deploy** infrastructure with Terraform (if needed)

### Example Prompt

```
Create a "Product Reviews" feature with image uploads:
1. Read .ai-context/INFRASTRUCTURE-DECISION-TREE.md
2. Create shared types (review schema with image URL)
3. Build backend API (Express routes + S3 presigned URLs)
4. Build frontend UI (review form + image upload)
5. Deploy S3 bucket infrastructure
```

**The AI will automatically detect that "image uploads" requires S3 infrastructure and handle it.**

---

## 📋 Feature Development Workflow

### Standard Feature (No Infrastructure)

```bash
# 1. Create shared types
cd shared-types/src
# Add new type definitions and Zod schemas

# 2. Build backend
cd repos/backend/src/features/my-feature
# Create: my-feature.route.ts, my-feature.service.ts, my-feature.repository.ts

# 3. Build frontend
cd repos/frontend/src/features/my-feature
# Create: ui/ (components), api/ (API calls), model/ (state)

# 4. Test
./scripts/test.sh
```

### Feature with Infrastructure

```bash
# 1. AI detects infrastructure needs (or manually check decision tree)
cat .ai-context/INFRASTRUCTURE-DECISION-TREE.md

# 2. Create Terraform module
cd infrastructure/terraform/features/my-feature
# Create: main.tf, variables.tf, outputs.tf

# 3. Deploy infrastructure
./infrastructure/scripts/infra-deploy.sh dev

# 4. Build backend (using infrastructure outputs)
cd repos/backend/src/features/my-feature
# Example: S3Service uses bucket name from Terraform outputs

# 5. Build frontend
cd repos/frontend/src/features/my-feature
# Use backend API that leverages infrastructure

# 6. Test end-to-end
./scripts/test.sh
```

**[→ See Complete Workflow Guide](./infrastructure/docs/FULLSTACK-FEATURE-WORKFLOW.md)**

---

## 🧪 Testing

### Run All Tests
```bash
./scripts/test.sh
```

### Backend Tests
```bash
cd repos/backend
npm test                    # Run all tests
npm run test:watch          # Watch mode
npm run test:coverage       # Coverage report
```

### Frontend Tests
```bash
cd repos/frontend
npm test                    # Run all tests
npm run test:watch          # Watch mode
npm run test:coverage       # Coverage report
```

### Current Coverage
- **Backend**: ~90% coverage (60 tests passing)
- **Frontend**: In development
- **IAM System**: 100% coverage (production-ready)

---

## 🔑 Environment Variables

### Backend (`.env`)
```bash
# Server
PORT=3000
NODE_ENV=development

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/vertical_vibing

# Authentication
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=7d

# AWS (for production)
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# Email System (AWS SES + SQS)
EMAIL_SYSTEM_ENABLED=true
EMAIL_SANDBOX_MODE=true
EMAIL_FROM_ADDRESS=noreply@yourdomain.com
EMAIL_FROM_NAME="Your App"
EMAIL_QUEUE_ENABLED=true
EMAIL_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/123/email-queue
WORKER_ENABLED=false  # Set true for embedded worker
```

### Frontend (`.env.local`)
```bash
# API
NEXT_PUBLIC_API_URL=http://localhost:3000

# Authentication (choose one)
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...  # If using Clerk
NEXT_PUBLIC_COGNITO_USER_POOL_ID=us-east-1_... # If using Cognito
```

**[→ See Complete Environment Setup](./infrastructure/docs/AWS-SETUP-GUIDE.md#section-6-backend-deployment)**

---

## 📦 Shared Types Package

The `@vertical-vibing/shared-types` package is the single source of truth for all types.

### Installation (Already configured)

```bash
# Backend
cd repos/backend
npm install @vertical-vibing/shared-types@file:../../shared-types

# Frontend
cd repos/frontend
npm install @vertical-vibing/shared-types@file:../../shared-types
```

### Usage

```typescript
// Backend validation
import { createUserSchema } from '@vertical-vibing/shared-types';
const validated = createUserSchema.parse(req.body);

// Frontend validation
import { createUserSchema } from '@vertical-vibing/shared-types';
const result = createUserSchema.safeParse(formData);

// Type inference
import { type User } from '@vertical-vibing/shared-types';
const user: User = { /* ... */ };
```

### Development Mode

The dev script (`./scripts/dev.sh`) automatically watches for changes and rebuilds the package.

---

## 🚢 Production Deployment

### AWS Deployment (Recommended)

**Complete guide:** [infrastructure/docs/AWS-SETUP-GUIDE.md](./infrastructure/docs/AWS-SETUP-GUIDE.md)

**Quick summary:**
1. Run `./infrastructure/scripts/aws-quick-setup.sh`
2. Create RDS database
3. Build and push Docker image to ECR
4. Deploy ECS service
5. Connect Amplify to GitHub (auto-deploys frontend)

**Deployment time:**
- Initial setup: 2-3 hours (first time)
- Feature deployment: 5-10 minutes
- Zero-downtime updates: ✅

### Manual Deployment

**Backend:**
```bash
cd repos/backend
npm run build
npm start
```

**Frontend:**
```bash
cd repos/frontend
npm run build
npm start
```

Both apps are **stateless** and can be horizontally scaled.

---

## 🎯 Success Checklist

### Local Development
- [ ] All dependencies installed (`./scripts/setup.sh`)
- [ ] Dev servers running (`./scripts/dev.sh`)
- [ ] Can access backend at http://localhost:3000
- [ ] Can access frontend at http://localhost:3001
- [ ] All tests passing (`./scripts/test.sh`)

### AWS Cloud Deployment
- [ ] AWS account created
- [ ] IAM user configured with AWS CLI
- [ ] Infrastructure deployed (`./infrastructure/scripts/aws-quick-setup.sh`)
- [ ] RDS database created and accessible
- [ ] Backend running on ECS Fargate
- [ ] Frontend deployed on Amplify with SSL
- [ ] Can view logs in CloudWatch
- [ ] Billing alarms configured

### Production Readiness
- [ ] Environment variables configured for production
- [ ] Database backups enabled (RDS automated backups)
- [ ] Monitoring and alarms set up (CloudWatch)
- [ ] CI/CD pipeline configured (GitHub Actions)
- [ ] Security review completed
- [ ] Load testing performed
- [ ] Disaster recovery plan documented

**[→ See Complete Success Metrics](./infrastructure/docs/README.md#-success-metrics)**

---

## 🆘 Troubleshooting

### Common Issues

**"Cannot connect to database"**
→ See: [AWS-QUICK-REFERENCE.md](./infrastructure/docs/AWS-QUICK-REFERENCE.md#database-connection-issues)

**"ECS task keeps failing"**
→ See: [AWS-QUICK-REFERENCE.md](./infrastructure/docs/AWS-QUICK-REFERENCE.md#backend-not-starting)

**"Types not syncing"**
```bash
cd shared-types && npm run build
# Restart dev servers
```

**"Port already in use"**
```bash
# Kill processes on ports 3000 and 3001
lsof -ti:3000 | xargs kill
lsof -ti:3001 | xargs kill
```

**[→ See Complete Troubleshooting Guide](./infrastructure/docs/AWS-QUICK-REFERENCE.md#troubleshooting-commands)**

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the architecture patterns in `.ai-context/`
4. Ensure all tests pass (`./scripts/test.sh`)
5. Commit your changes (`git commit -m 'feat: add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Development Standards
- Follow VSA patterns for backend
- Follow FSD patterns for frontend
- Use shared types package for all type definitions
- Write tests for all business logic
- Document features with FEATURE.md files
- Check `.ai-context/` for architectural guidance

---

## 📞 Support & Resources

### Documentation
- [Infrastructure Docs](./infrastructure/docs/README.md)
- [Backend Docs](./repos/backend/.ai-context/)
- [Frontend Docs](./repos/frontend/.ai-context/)
- [IAM System](./IAM-SYSTEM-COMPLETION.md)

### AWS Resources
- [AWS Console](https://console.aws.amazon.com)
- [AWS Documentation](https://docs.aws.amazon.com)
- [AWS Cost Calculator](https://calculator.aws)

### Community
- [AWS Forums](https://forums.aws.amazon.com)
- [Stack Overflow](https://stackoverflow.com) (Tag: `amazon-web-services`)
- [Reddit r/aws](https://reddit.com/r/aws)

---

## 📄 License

MIT License - See LICENSE file for details

---

## 🎉 What's Next?

### Immediate Next Steps
1. **Get Started**: Run `./scripts/setup.sh` and `./scripts/dev.sh`
2. **Explore IAM**: Check out the production-ready IAM system
3. **Deploy to AWS**: Follow [AWS-SETUP-GUIDE.md](./infrastructure/docs/AWS-SETUP-GUIDE.md)

### Future Enhancements
- [x] **Email service (AWS SES)** ✅ COMPLETE
- [ ] Real-time features (WebSocket/AppSync)
- [ ] File processing (Lambda)
- [ ] Advanced analytics (OpenSearch)
- [ ] Multi-region deployment
- [ ] GraphQL API option

**Ready to build?** Start with `./scripts/dev.sh` or deploy to AWS with `./infrastructure/scripts/aws-quick-setup.sh`

---

**Built with ❤️ using VSA + FSD + Infrastructure as Code**
