# Infrastructure Documentation

Complete AWS cloud infrastructure setup and management for Vertical Vibing.

---

## 📚 Documentation Index

### 🚀 Getting Started (Read This First!)

**[AWS-SETUP-GUIDE.md](./AWS-SETUP-GUIDE.md)** (31KB - Comprehensive)
- Complete step-by-step AWS setup for beginners
- AWS account creation
- IAM user setup
- Authentication (Cognito + Clerk)
- Database (RDS PostgreSQL)
- Backend deployment (ECS Fargate)
- Frontend deployment (AWS Amplify)
- Cost estimates and troubleshooting

**Estimated time:** 2-3 hours for first-time setup

**Start here if:**
- You have little to no AWS experience
- This is your first time deploying to AWS
- You want detailed explanations for every step

---

### ⚡ Quick Setup (For Experienced Users)

**Run the automated setup script:**

```bash
# One command to create all basic infrastructure
./infrastructure/scripts/aws-quick-setup.sh
```

This script creates:
- S3 bucket for Terraform state
- DynamoDB table for state locking
- ECR repository for Docker images
- Security groups for RDS and ECS
- CloudWatch log groups
- ECS cluster

**Then follow:** Steps in AWS-SETUP-GUIDE.md for RDS, authentication, and deployments.

---

### 📊 Architecture Reference

**[ARCHITECTURE-DIAGRAM.md](./ARCHITECTURE-DIAGRAM.md)** (20KB)
- Visual architecture diagrams
- Data flow examples
- Security layers
- Scaling strategy
- Cost breakdown by stage
- Disaster recovery plan

**Read this to understand:**
- How all AWS services connect
- User request flows
- Where your data lives
- How the system scales
- What each service costs

---

### 🔧 Daily Operations

**[AWS-QUICK-REFERENCE.md](./AWS-QUICK-REFERENCE.md)** (12KB)
- Quick command reference
- Daily deployment commands
- Monitoring and logging
- Troubleshooting procedures
- Emergency rollback procedures
- Cost optimization tips

**Bookmark this for:**
- Deploying backend updates
- Checking logs
- Managing secrets
- Database operations
- Quick troubleshooting

---

### 📝 Complete Example

**[EXAMPLE-FILE-UPLOADS.md](./EXAMPLE-FILE-UPLOADS.md)** (15KB)
- End-to-end file upload feature
- Infrastructure (S3 + CloudFront)
- Backend (presigned URLs)
- Frontend (upload component)
- Complete working code

**Study this for:**
- Understanding infrastructure → code integration
- Learning the feature development workflow
- Seeing a complete implementation
- Copy-paste starting point

---

### 🔐 Compliance & Security

**[COMPLIANCE-GUIDE.md](./COMPLIANCE-GUIDE.md)** (30KB - Comprehensive)
- SOC 2, GDPR, HIPAA readiness assessment
- Current compliance status (60% SOC 2, 70% GDPR ready)
- Step-by-step compliance roadmaps
- Cost estimates for each certification
- Technical implementation guides
- Policy templates and checklists

**Read this if:**
- Selling to enterprise customers (need SOC 2)
- Have EU users (need GDPR)
- Handle health data (need HIPAA)
- Want to understand compliance costs and timelines

---

## 🎯 Quick Start Path

### Path 1: First-Time AWS User (Recommended)

```
1. Read: AWS-SETUP-GUIDE.md (Section 1-2: Account & IAM)
   ├─ Create AWS account
   ├─ Set up IAM user
   └─ Configure AWS CLI

2. Run: ./infrastructure/scripts/aws-quick-setup.sh
   └─ Creates basic infrastructure

3. Read: AWS-SETUP-GUIDE.md (Section 4-5: Auth & Database)
   ├─ Choose: Cognito or Clerk
   └─ Set up RDS PostgreSQL

4. Read: AWS-SETUP-GUIDE.md (Section 6-7: Deploy Backend & Frontend)
   ├─ Build Docker image
   ├─ Deploy to ECS
   └─ Deploy to Amplify

5. Bookmark: AWS-QUICK-REFERENCE.md
   └─ For daily operations

Total time: 2-3 hours
```

### Path 2: Experienced AWS User

```
1. Run: ./infrastructure/scripts/aws-quick-setup.sh
   └─ 5 minutes

2. Skim: AWS-SETUP-GUIDE.md (note sections 5-7)
   └─ RDS, ECS, Amplify setup
   └─ 30 minutes

3. Deploy:
   ├─ Create RDS instance
   ├─ Build & push Docker image
   ├─ Deploy ECS service
   └─ Connect Amplify to GitHub
   └─ 1 hour

4. Reference: AWS-QUICK-REFERENCE.md as needed
   └─ Daily operations

Total time: 1.5 hours
```

### Path 3: Just Exploring

```
1. Read: ARCHITECTURE-DIAGRAM.md
   └─ Understand the architecture (15 min)

2. Skim: AWS-SETUP-GUIDE.md
   └─ See what's involved (20 min)

3. Review: EXAMPLE-FILE-UPLOADS.md
   └─ See complete implementation (15 min)

Total time: 50 minutes
```

---

## 📂 File Structure Reference

```
infrastructure/
├── docs/
│   ├── README.md                    # This file - start here
│   ├── AWS-SETUP-GUIDE.md           # Complete beginner-friendly setup
│   ├── ARCHITECTURE-DIAGRAM.md      # Visual architecture reference
│   ├── AWS-QUICK-REFERENCE.md       # Daily command reference
│   └── EXAMPLE-FILE-UPLOADS.md      # Complete feature example
├── scripts/
│   ├── aws-quick-setup.sh           # Automated AWS setup (run first!)
│   ├── infra-plan.sh                # Plan Terraform changes
│   ├── infra-deploy.sh              # Deploy infrastructure
│   ├── infra-destroy.sh             # Destroy infrastructure
│   └── infra-outputs.sh             # View infrastructure outputs
├── terraform/
│   ├── modules/                     # Reusable Terraform modules
│   │   └── s3-bucket/               # S3 bucket module
│   ├── features/                    # Feature-specific infrastructure
│   └── environments/                # Dev, staging, production
│       ├── dev/
│       ├── staging/
│       └── production/
└── README.md                        # Overview of infrastructure/
```

---

## 🎓 Learning Path

### Week 1: Setup & Deployment
- Day 1-2: Follow AWS-SETUP-GUIDE.md completely
- Day 3: Deploy a simple change to backend
- Day 4: Deploy a simple change to frontend
- Day 5: Review AWS-QUICK-REFERENCE.md, try commands

**Goal:** Have everything running in production

### Week 2: Understanding & Optimization
- Day 1: Study ARCHITECTURE-DIAGRAM.md
- Day 2: Review CloudWatch logs and metrics
- Day 3: Set up billing alarms
- Day 4: Implement EXAMPLE-FILE-UPLOADS.md
- Day 5: Practice emergency procedures

**Goal:** Understand how everything works

### Week 3: Infrastructure as Code
- Day 1-2: Learn Terraform basics
- Day 3: Deploy feature infrastructure with Terraform
- Day 4: Modify existing infrastructure
- Day 5: Create custom Terraform module

**Goal:** Manage infrastructure as code

---

## 💰 Cost Expectations

### Free Tier (First 12 Months)
```
Development Environment: $0-5/month
- Most services covered by free tier
- Only pay for data transfer
```

### After Free Tier
```
Development: $30-40/month
Production (< 1000 users): $50-80/month
Production (1000-10,000 users): $100-200/month
```

**See ARCHITECTURE-DIAGRAM.md for detailed breakdown**

---

## 🆘 Getting Help

### Documentation Order for Issues

1. **Quick Reference First**
   - Check AWS-QUICK-REFERENCE.md troubleshooting section
   - Run suggested diagnostic commands

2. **Setup Guide for Configuration Issues**
   - Review AWS-SETUP-GUIDE.md section 10 (troubleshooting)
   - Verify each setup step was completed

3. **Architecture for System Design Questions**
   - Review ARCHITECTURE-DIAGRAM.md
   - Understand component interactions

### Common Issues & Solutions

**"Cannot connect to database"**
→ See: AWS-QUICK-REFERENCE.md → Troubleshooting → Database Connection Issues

**"ECS task keeps failing"**
→ See: AWS-QUICK-REFERENCE.md → Troubleshooting → Backend Not Starting

**"Amplify build fails"**
→ See: AWS-QUICK-REFERENCE.md → Troubleshooting → Amplify Build Failures

**"Costs are too high"**
→ See: AWS-QUICK-REFERENCE.md → Cost Optimization Tips

---

## 🔐 Security Checklist

Before going to production:

- [ ] Enable MFA on root account (AWS-SETUP-GUIDE.md §1.2)
- [ ] Create IAM user for daily use (AWS-SETUP-GUIDE.md §2)
- [ ] Store secrets in Secrets Manager (AWS-SETUP-GUIDE.md §6.7)
- [ ] Restrict RDS security group to backend only (AWS-SETUP-GUIDE.md §5.2)
- [ ] Enable RDS encryption (AWS-SETUP-GUIDE.md §5.3)
- [ ] Set up billing alarms (AWS-SETUP-GUIDE.md - Pro tip at end)
- [ ] Configure CORS properly (AWS-QUICK-REFERENCE.md)
- [ ] Enable CloudWatch alarms (ARCHITECTURE-DIAGRAM.md)
- [ ] Review security groups (all allow 0.0.0.0/0 should be removed)

---

## 📈 Next Steps After Setup

1. **Set up CI/CD**
   - GitHub Actions for automated deployments
   - Run tests before deploying
   - Automated rollback on failure

2. **Add Monitoring**
   - CloudWatch dashboards
   - Application metrics
   - Error rate alerts

3. **Implement Backup Strategy**
   - Automated RDS snapshots
   - S3 versioning for critical data
   - Disaster recovery plan

4. **Scale for Production**
   - Add Application Load Balancer
   - Configure auto-scaling
   - Set up multi-AZ RDS
   - Add CloudFront for static assets

5. **Optimize Costs**
   - Review unused resources
   - Set up CloudWatch billing alarms
   - Use Reserved Instances for predictable loads
   - Implement S3 lifecycle policies

---

## 🤝 Contributing to Infrastructure

When adding new infrastructure:

1. Read: `.ai-context/INFRASTRUCTURE-DECISION-TREE.md`
   - Determine if feature needs infrastructure

2. Create Terraform module in: `infrastructure/terraform/features/`
   - Follow S3 module pattern
   - Document inputs/outputs
   - Add README

3. Test in dev environment:
   ```bash
   ./infrastructure/scripts/infra-plan.sh dev
   ./infrastructure/scripts/infra-deploy.sh dev
   ```

4. Document in: `infrastructure/docs/EXAMPLE-FEATURE-NAME.md`
   - Infrastructure code
   - Backend integration
   - Frontend integration
   - Complete working example

---

## 📞 Support Resources

**AWS Support:**
- AWS Console: https://console.aws.amazon.com
- AWS Documentation: https://docs.aws.amazon.com
- AWS Support Center: https://console.aws.amazon.com/support/

**Community:**
- AWS Forums: https://forums.aws.amazon.com
- Stack Overflow: Tag `amazon-web-services`
- Reddit: r/aws

**Tools:**
- AWS Calculator: https://calculator.aws
- AWS Status: https://status.aws.amazon.com

---

## 🎯 Success Metrics

You've successfully set up AWS when you can:

- [ ] Access AWS Console with IAM user (not root)
- [ ] Run `aws sts get-caller-identity` successfully
- [ ] Backend is running on ECS and accessible via public IP
- [ ] Frontend is deployed on Amplify with SSL
- [ ] Can connect to RDS database from backend
- [ ] Can view logs in CloudWatch
- [ ] Can deploy updates with one command
- [ ] Set up billing alarms to avoid surprise costs

---

**Ready to start?** → Open [AWS-SETUP-GUIDE.md](./AWS-SETUP-GUIDE.md)

**Already set up?** → Bookmark [AWS-QUICK-REFERENCE.md](./AWS-QUICK-REFERENCE.md)

**Want to understand the architecture?** → Read [ARCHITECTURE-DIAGRAM.md](./ARCHITECTURE-DIAGRAM.md)

**Need a complete example?** → Study [EXAMPLE-FILE-UPLOADS.md](./EXAMPLE-FILE-UPLOADS.md)
