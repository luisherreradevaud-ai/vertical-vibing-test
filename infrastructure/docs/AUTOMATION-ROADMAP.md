# SaaS Automation Roadmap

**Complete guide to automating SaaS development with Vertical Vibing**

This document outlines 23+ high-impact automations that transform this starter kit into a comprehensive SaaS factory, capable of generating production-ready applications in minutes instead of months.

---

## 📊 Market Impact Summary

### Current Repository Value
- **Base value**: $2,000-8,000
- **Development time saved**: ~580 hours ($29k-58k equivalent)

### With Tier 1 Automations (Top 5)
- **Value**: $15,000-30,000
- **Development time saved**: 180-260 hours per project
- **Coverage**: 80% of typical SaaS needs

### With All Tier 1 + Tier 2 (15 features)
- **Value**: $40,000-80,000
- **Development time saved**: 350-500 hours per project
- **Coverage**: Complete production-ready platform

### With Interactive CLI Generator
- **Value**: $100,000-200,000+
- **Reason**: Becomes a "SaaS factory"
- **Comparable to**: Ruby on Rails, Laravel (but specifically for SaaS)

---

## 🎯 Implementation Priority

### Phase 1: Foundation (Weeks 1-2)
**Goal**: Add top 5 highest-impact automations

1. Subscription Billing System (Stripe)
2. Transactional Email System (AWS SES)
3. Auto-Generated Admin Dashboard
4. CI/CD Pipeline Generator
5. Feature Flags System

**Expected outcome**: Repository value → $15k-30k

### Phase 2: Production Essentials (Month 2)
**Goal**: Production-ready features

6. Monitoring & Alerting Stack
7. Background Job System
8. API Documentation Auto-Generator
9. Multi-Tenancy System
10. Webhook System

**Expected outcome**: Repository value → $40k-60k

### Phase 3: Advanced Platform (Month 3)
**Goal**: Complete automation platform

11-20. Advanced features (see Tier 3)
21. Interactive SaaS Generator CLI
22. AI Feature Generator
23. Compliance Automation

**Expected outcome**: Repository value → $100k+

---

# Tier 1: Highest Impact Automations

## 1. Subscription Billing System (Stripe Integration)

### Why This Matters
- Every SaaS needs payments
- Saves 40-80 hours of development per project
- Recurring revenue management is complex
- Worth $5,000-8,000 in development time

### What to Build

#### Infrastructure
```
infrastructure/terraform/features/stripe/
├── main.tf                    # Stripe webhook endpoints
├── secrets.tf                 # Store Stripe keys in Secrets Manager
├── api-gateway.tf             # Webhook receiver
└── outputs.tf                 # Webhook URLs
```

#### Backend Implementation
```
repos/backend/src/features/billing/
├── billing.route.ts           # Checkout, portal, webhooks
├── billing.service.ts         # Subscription lifecycle
├── stripe.service.ts          # Stripe API wrapper
├── stripe-webhook.handler.ts  # Event processing
├── plans.config.ts            # Pricing tiers configuration
├── billing.repository.ts      # Database operations
└── __tests__/
    ├── billing.service.test.ts
    └── stripe-webhook.test.ts
```

#### Database Schema
```sql
-- Subscriptions
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  tenant_id UUID REFERENCES tenants(id),
  stripe_customer_id VARCHAR(255) NOT NULL,
  stripe_subscription_id VARCHAR(255) NOT NULL,
  plan_id VARCHAR(50) NOT NULL,
  status VARCHAR(50) NOT NULL, -- active, canceled, past_due, trialing
  current_period_start TIMESTAMP NOT NULL,
  current_period_end TIMESTAMP NOT NULL,
  cancel_at_period_end BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Invoices
CREATE TABLE invoices (
  id UUID PRIMARY KEY,
  subscription_id UUID REFERENCES subscriptions(id),
  stripe_invoice_id VARCHAR(255) NOT NULL,
  amount_paid INTEGER NOT NULL,
  currency VARCHAR(3) DEFAULT 'usd',
  status VARCHAR(50) NOT NULL,
  invoice_pdf VARCHAR(500),
  paid_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Usage tracking (for metered billing)
CREATE TABLE usage_records (
  id UUID PRIMARY KEY,
  subscription_id UUID REFERENCES subscriptions(id),
  metric VARCHAR(100) NOT NULL, -- api_calls, storage_gb, users
  quantity INTEGER NOT NULL,
  timestamp TIMESTAMP DEFAULT NOW()
);
```

#### Pricing Configuration
```typescript
// repos/backend/src/features/billing/plans.config.ts
export const PLANS = {
  starter: {
    id: 'starter',
    name: 'Starter',
    stripePriceId: process.env.STRIPE_PRICE_STARTER,
    price: 29,
    currency: 'usd',
    interval: 'month',
    features: {
      users: 5,
      apiCalls: 10000,
      storage: 10, // GB
      support: 'email',
    },
  },
  pro: {
    id: 'pro',
    name: 'Pro',
    stripePriceId: process.env.STRIPE_PRICE_PRO,
    price: 99,
    currency: 'usd',
    interval: 'month',
    features: {
      users: 25,
      apiCalls: 100000,
      storage: 100,
      support: 'priority',
    },
  },
  enterprise: {
    id: 'enterprise',
    name: 'Enterprise',
    stripePriceId: process.env.STRIPE_PRICE_ENTERPRISE,
    price: 299,
    currency: 'usd',
    interval: 'month',
    features: {
      users: -1, // unlimited
      apiCalls: -1,
      storage: 1000,
      support: 'dedicated',
    },
  },
} as const;
```

#### API Endpoints
```typescript
// POST /api/billing/checkout
// Create Stripe Checkout session
router.post('/checkout', authenticate, validateBody(checkoutSchema), async (req, res) => {
  const { planId } = req.body;
  const session = await billingService.createCheckoutSession(req.user.id, planId);
  res.json({ url: session.url });
});

// POST /api/billing/portal
// Create Stripe Customer Portal session
router.post('/portal', authenticate, async (req, res) => {
  const session = await billingService.createPortalSession(req.user.id);
  res.json({ url: session.url });
});

// POST /api/billing/webhook
// Handle Stripe webhooks
router.post('/webhook',
  express.raw({ type: 'application/json' }),
  async (req, res) => {
    const sig = req.headers['stripe-signature'];
    await stripeWebhookHandler.handle(req.body, sig);
    res.json({ received: true });
  }
);

// GET /api/billing/subscription
// Get current subscription
router.get('/subscription', authenticate, async (req, res) => {
  const subscription = await billingService.getSubscription(req.user.id);
  res.json(subscription);
});
```

#### Frontend Components
```typescript
// repos/frontend/src/features/billing/ui/PricingPage.tsx
export function PricingPage() {
  return (
    <div className="pricing-grid">
      {Object.values(PLANS).map((plan) => (
        <PricingCard
          key={plan.id}
          plan={plan}
          onSelect={() => handleCheckout(plan.id)}
        />
      ))}
    </div>
  );
}

// repos/frontend/src/features/billing/ui/CheckoutButton.tsx
export function CheckoutButton({ planId }: { planId: string }) {
  const checkout = useCheckout();

  return (
    <Button onClick={() => checkout.mutate({ planId })}>
      Subscribe to {planId}
    </Button>
  );
}

// repos/frontend/src/features/billing/ui/BillingPortal.tsx
export function BillingPortal() {
  const { data: subscription } = useSubscription();
  const portal = useCustomerPortal();

  return (
    <Card>
      <h2>Subscription: {subscription?.plan}</h2>
      <p>Status: {subscription?.status}</p>
      <Button onClick={() => portal.mutate()}>
        Manage Subscription
      </Button>
    </Card>
  );
}
```

#### Webhook Event Handling
```typescript
// repos/backend/src/features/billing/stripe-webhook.handler.ts
export class StripeWebhookHandler {
  async handle(payload: Buffer, signature: string): Promise<void> {
    const event = stripe.webhooks.constructEvent(
      payload,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET
    );

    switch (event.type) {
      case 'customer.subscription.created':
        await this.handleSubscriptionCreated(event.data.object);
        break;
      case 'customer.subscription.updated':
        await this.handleSubscriptionUpdated(event.data.object);
        break;
      case 'customer.subscription.deleted':
        await this.handleSubscriptionDeleted(event.data.object);
        break;
      case 'invoice.paid':
        await this.handleInvoicePaid(event.data.object);
        break;
      case 'invoice.payment_failed':
        await this.handlePaymentFailed(event.data.object);
        break;
    }
  }

  private async handleSubscriptionCreated(subscription: Stripe.Subscription) {
    await this.billingRepo.createSubscription({
      stripeSubscriptionId: subscription.id,
      customerId: subscription.customer as string,
      status: subscription.status,
      planId: this.getPlanFromPriceId(subscription.items.data[0].price.id),
      currentPeriodStart: new Date(subscription.current_period_start * 1000),
      currentPeriodEnd: new Date(subscription.current_period_end * 1000),
    });

    // Send welcome email
    await this.emailService.sendSubscriptionWelcome(subscription);
  }

  // ... other handlers
}
```

### AI Decision Tree Integration
```markdown
# Add to: .ai-context/INFRASTRUCTURE-DECISION-TREE.md

## Billing & Subscriptions

IF description contains:
  - "subscription", "payment", "billing", "checkout", "pricing"
  - "monthly fee", "annual plan", "upgrade", "downgrade"
  - "trial", "free tier", "paid plan"

THEN:
  Infrastructure Needed:
    - Stripe integration (webhook endpoints, secrets)
    - Database tables (subscriptions, invoices, usage_records)

  Backend Components:
    - Billing feature module
    - Stripe webhook handler
    - Subscription lifecycle service

  Frontend Components:
    - Pricing page
    - Checkout flow
    - Billing portal
    - Subscription status indicator

  Additional:
    - Email templates (welcome, payment failed, subscription ending)
    - Usage tracking (if metered billing)
    - Admin dashboard for subscriptions
```

### Value Delivered
- **Time saved**: 40-80 hours per project
- **Revenue enabled**: Immediate monetization
- **Features included**:
  - Multiple pricing tiers
  - Free trials
  - Metered billing (optional)
  - Upgrade/downgrade
  - Customer portal
  - Invoice management
  - Usage tracking
  - Webhook automation

---

## 2. Transactional Email System (AWS SES + Templates)

### Why This Matters
- Every SaaS sends emails (welcome, reset password, notifications, invoices)
- Email template management is tedious and repetitive
- Saves 20-30 hours per project
- Professional email templates improve user experience

### What to Build

#### Infrastructure
```
infrastructure/terraform/features/email/
├── ses.tf                     # SES domain verification, DKIM, SPF
├── ses-templates.tf           # Email templates as infrastructure
├── sqs-email-queue.tf         # Queue for async email sending
├── lambda-email-worker.tf     # Process email queue (optional)
└── outputs.tf                 # SES configuration ARNs
```

**SES Domain Setup:**
```hcl
# infrastructure/terraform/features/email/ses.tf
resource "aws_ses_domain_identity" "main" {
  domain = var.domain_name
}

resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

resource "aws_ses_domain_mail_from" "main" {
  domain           = aws_ses_domain_identity.main.domain
  mail_from_domain = "mail.${var.domain_name}"
}

# Verify domain
resource "aws_ses_domain_identity_verification" "main" {
  domain = aws_ses_domain_identity.main.id
}
```

#### Backend Implementation
```
repos/backend/src/features/email/
├── email.service.ts           # Email sending abstraction
├── email.queue.ts             # SQS queue integration
├── templates/                 # React Email templates
│   ├── WelcomeEmail.tsx
│   ├── ResetPasswordEmail.tsx
│   ├── InvoiceEmail.tsx
│   ├── TeamInviteEmail.tsx
│   ├── SubscriptionEndingEmail.tsx
│   ├── PaymentFailedEmail.tsx
│   └── WeeklyDigestEmail.tsx
├── email.config.ts            # Email configuration
├── email.types.ts             # Email type definitions
└── __tests__/
    └── email.service.test.ts
```

#### React Email Templates
```typescript
// repos/backend/src/features/email/templates/WelcomeEmail.tsx
import {
  Html,
  Head,
  Body,
  Container,
  Section,
  Text,
  Button,
  Img,
} from '@react-email/components';

interface WelcomeEmailProps {
  userName: string;
  loginUrl: string;
}

export function WelcomeEmail({ userName, loginUrl }: WelcomeEmailProps) {
  return (
    <Html>
      <Head />
      <Body style={main}>
        <Container style={container}>
          <Section style={box}>
            <Img
              src="https://your-app.com/logo.png"
              width="49"
              height="49"
              alt="Logo"
            />
            <Text style={heading}>Welcome to Our App!</Text>
            <Text style={paragraph}>
              Hi {userName},
            </Text>
            <Text style={paragraph}>
              Thanks for signing up! We're excited to have you on board.
            </Text>
            <Button style={button} href={loginUrl}>
              Get Started
            </Button>
            <Text style={paragraph}>
              If you have any questions, just reply to this email.
            </Text>
          </Section>
        </Container>
      </Body>
    </Html>
  );
}

// Styles
const main = { backgroundColor: '#f6f9fc', fontFamily: 'Arial, sans-serif' };
const container = { margin: '0 auto', padding: '20px 0 48px' };
const box = { padding: '24px', backgroundColor: '#fff', borderRadius: '8px' };
const heading = { fontSize: '24px', fontWeight: 'bold', marginBottom: '20px' };
const paragraph = { fontSize: '16px', lineHeight: '24px', marginBottom: '16px' };
const button = {
  backgroundColor: '#5469d4',
  borderRadius: '4px',
  color: '#fff',
  fontSize: '16px',
  textDecoration: 'none',
  textAlign: 'center',
  display: 'block',
  padding: '12px',
};
```

#### Email Service
```typescript
// repos/backend/src/features/email/email.service.ts
import { SESClient, SendEmailCommand } from '@aws-sdk/client-ses';
import { render } from '@react-email/render';
import { WelcomeEmail } from './templates/WelcomeEmail';

export class EmailService {
  private ses: SESClient;

  constructor() {
    this.ses = new SESClient({ region: process.env.AWS_REGION });
  }

  async sendWelcome(user: User): Promise<void> {
    const html = render(
      WelcomeEmail({
        userName: user.name,
        loginUrl: `${process.env.APP_URL}/login`,
      })
    );

    await this.send({
      to: user.email,
      subject: 'Welcome to Our App!',
      html,
    });
  }

  async sendResetPassword(user: User, token: string): Promise<void> {
    const html = render(
      ResetPasswordEmail({
        userName: user.name,
        resetUrl: `${process.env.APP_URL}/reset-password?token=${token}`,
        expiresIn: '1 hour',
      })
    );

    await this.send({
      to: user.email,
      subject: 'Reset Your Password',
      html,
    });
  }

  async sendInvoice(invoice: Invoice): Promise<void> {
    const html = render(
      InvoiceEmail({
        invoiceNumber: invoice.number,
        amount: invoice.amount,
        paidAt: invoice.paidAt,
        downloadUrl: invoice.pdfUrl,
      })
    );

    await this.send({
      to: invoice.customerEmail,
      subject: `Invoice ${invoice.number}`,
      html,
      attachments: [
        {
          filename: `invoice-${invoice.number}.pdf`,
          path: invoice.pdfUrl,
        },
      ],
    });
  }

  private async send({
    to,
    subject,
    html,
    attachments = [],
  }: {
    to: string;
    subject: string;
    html: string;
    attachments?: Array<{ filename: string; path: string }>;
  }): Promise<void> {
    // For high volume, queue it
    if (process.env.EMAIL_QUEUE_ENABLED === 'true') {
      await this.emailQueue.enqueue({ to, subject, html, attachments });
      return;
    }

    // Send immediately
    const command = new SendEmailCommand({
      Source: process.env.EMAIL_FROM,
      Destination: { ToAddresses: [to] },
      Message: {
        Subject: { Data: subject },
        Body: { Html: { Data: html } },
      },
    });

    await this.ses.send(command);

    // Log for analytics
    await this.logEmail({ to, subject, sentAt: new Date() });
  }
}
```

#### Email Queue (for async sending)
```typescript
// repos/backend/src/features/email/email.queue.ts
import { SQSClient, SendMessageCommand } from '@aws-sdk/client-sqs';

export class EmailQueue {
  private sqs: SQSClient;
  private queueUrl: string;

  constructor() {
    this.sqs = new SQSClient({ region: process.env.AWS_REGION });
    this.queueUrl = process.env.EMAIL_QUEUE_URL!;
  }

  async enqueue(email: EmailPayload): Promise<void> {
    await this.sqs.send(
      new SendMessageCommand({
        QueueUrl: this.queueUrl,
        MessageBody: JSON.stringify(email),
      })
    );
  }

  // Worker process (separate process or Lambda)
  async processQueue(): Promise<void> {
    // Poll SQS and send emails
    // Implement retry logic
    // Handle failures to DLQ
  }
}
```

#### Email Templates Configuration
```typescript
// repos/backend/src/features/email/email.config.ts
export const EMAIL_CONFIG = {
  from: {
    name: 'Your App',
    email: 'noreply@yourapp.com',
  },
  replyTo: 'support@yourapp.com',

  templates: {
    welcome: {
      subject: 'Welcome to {{appName}}!',
      template: 'WelcomeEmail',
    },
    resetPassword: {
      subject: 'Reset Your Password',
      template: 'ResetPasswordEmail',
    },
    invoice: {
      subject: 'Your Invoice #{{invoiceNumber}}',
      template: 'InvoiceEmail',
    },
    teamInvite: {
      subject: '{{inviterName}} invited you to {{teamName}}',
      template: 'TeamInviteEmail',
    },
    subscriptionEnding: {
      subject: 'Your subscription is ending soon',
      template: 'SubscriptionEndingEmail',
    },
    paymentFailed: {
      subject: 'Payment Failed - Action Required',
      template: 'PaymentFailedEmail',
    },
  },

  // Email sending limits (SES sandbox limits)
  limits: {
    perSecond: 1,
    perDay: 200, // Increase after moving out of sandbox
  },
};
```

### Documentation
```markdown
# Add to: infrastructure/docs/EMAIL-SYSTEM-GUIDE.md

## Email System

### Overview
Complete transactional email system using AWS SES and React Email.

### Features
- React-based email templates (type-safe, component-based)
- Async email queue (SQS) for high volume
- Template preview in development
- Email analytics and tracking
- Bounce/complaint handling

### Usage

#### Send Welcome Email
```typescript
import { EmailService } from '@/features/email';

const emailService = new EmailService();
await emailService.sendWelcome(user);
```

#### Create New Email Template
1. Create React component in `templates/`
2. Add template config to `email.config.ts`
3. Add method to `EmailService`

#### Preview Templates
```bash
npm run email:preview
# Opens http://localhost:3001/email-preview
```

### SES Setup
1. Verify domain in AWS SES
2. Add DNS records (DKIM, SPF, DMARC)
3. Request production access (remove sandbox limits)

### Monitoring
- Email send rate: CloudWatch metrics
- Bounces/complaints: SNS notifications
- Queue depth: SQS metrics
```

### AI Decision Tree Integration
```markdown
## Email/Notifications

IF description contains:
  - "email", "notification", "send message"
  - "welcome email", "reset password"
  - "invoice", "receipt"
  - "reminder", "digest"

THEN:
  Infrastructure Needed:
    - AWS SES (domain verification)
    - SQS queue (for async sending)

  Backend Components:
    - Email service
    - React Email templates
    - Queue worker

  Frontend Components:
    - Email preferences page

  Templates to Generate:
    - Determine email type from context
    - Generate React Email template
    - Add to email service
```

### Value Delivered
- **Time saved**: 20-30 hours per project
- **Features included**:
  - 7+ pre-built email templates
  - React-based templates (easy to customize)
  - Async sending (queue-based)
  - Email analytics
  - Bounce/complaint handling
  - Template preview in development

---

## 3. Auto-Generated Admin Dashboard (CRUD Operations)

### Why This Matters
- Every entity needs admin CRUD operations
- Highly repetitive work (tables, forms, validation)
- Saves 8-12 hours per entity
- Average project has 10-20 entities = 80-240 hours saved
- Enables rapid prototyping and iteration

### What to Build

#### CLI Generator Tool
```
scripts/
├── generate-admin.ts          # Main generator
├── templates/
│   ├── admin-table.tsx.hbs    # Table component template
│   ├── admin-form.tsx.hbs     # Form component template
│   ├── admin-detail.tsx.hbs   # Detail view template
│   ├── admin-route.ts.hbs     # Backend route template
│   └── admin-api.ts.hbs       # Frontend API template
└── README-GENERATORS.md       # Documentation
```

#### Usage
```bash
# Generate complete admin CRUD for an entity
npm run generate:admin User

# With options
npm run generate:admin Product --relations=categories,tags --searchable=name,description
```

#### Generator Implementation
```typescript
// scripts/generate-admin.ts
import Handlebars from 'handlebars';
import { readFileSync, writeFileSync } from 'fs';
import { parse } from '@typescript-eslint/parser';

interface GenerateOptions {
  entityName: string;
  fields?: string[];
  relations?: string[];
  searchableFields?: string[];
  sortableFields?: string[];
}

export class AdminGenerator {
  async generate(options: GenerateOptions): Promise<void> {
    const { entityName } = options;

    // 1. Analyze existing schema
    const schema = await this.analyzeSchema(entityName);

    // 2. Generate backend routes
    await this.generateBackendRoute(entityName, schema);

    // 3. Generate frontend components
    await this.generateTable(entityName, schema);
    await this.generateForm(entityName, schema);
    await this.generateDetail(entityName, schema);

    // 4. Generate API client
    await this.generateApiClient(entityName);

    // 5. Register routes
    await this.registerRoutes(entityName);

    console.log(`✅ Generated admin CRUD for ${entityName}`);
  }

  private async analyzeSchema(entityName: string): Promise<EntitySchema> {
    // Read from Drizzle schema
    const schemaPath = `repos/backend/src/shared/db/schema/${entityName.toLowerCase()}.ts`;
    const content = readFileSync(schemaPath, 'utf-8');

    // Parse TypeScript AST to extract fields, types, validations
    const ast = parse(content, { sourceType: 'module' });

    return {
      name: entityName,
      fields: this.extractFields(ast),
      relations: this.extractRelations(ast),
      validations: this.extractValidations(ast),
    };
  }

  private async generateBackendRoute(
    entityName: string,
    schema: EntitySchema
  ): Promise<void> {
    const template = Handlebars.compile(
      readFileSync('scripts/templates/admin-route.ts.hbs', 'utf-8')
    );

    const code = template({
      entityName,
      entityNameLower: entityName.toLowerCase(),
      fields: schema.fields,
      relations: schema.relations,
    });

    writeFileSync(
      `repos/backend/src/features/admin/admin-${entityName.toLowerCase()}.route.ts`,
      code
    );
  }

  private async generateTable(
    entityName: string,
    schema: EntitySchema
  ): Promise<void> {
    const template = Handlebars.compile(
      readFileSync('scripts/templates/admin-table.tsx.hbs', 'utf-8')
    );

    const code = template({
      entityName,
      fields: schema.fields,
      searchableFields: schema.fields.filter(f => f.searchable),
      sortableFields: schema.fields.filter(f => f.sortable),
    });

    writeFileSync(
      `repos/frontend/src/features/admin/${entityName.toLowerCase()}/${entityName}Table.tsx`,
      code
    );
  }

  // ... similar methods for form, detail, api client
}
```

#### Generated Backend Route
```typescript
// Example output: admin-users.route.ts
import { Router } from 'express';
import { authenticate, requirePermission } from '@/shared/middleware';
import { validateBody, validateQuery } from '@/shared/validation';
import { listUsersSchema, createUserSchema, updateUserSchema } from './schemas';
import { AdminUsersService } from './admin-users.service';

export function createAdminUsersRouter(): Router {
  const router = Router();
  const service = new AdminUsersService();

  // List users (with pagination, search, filter, sort)
  router.get('/',
    authenticate,
    requirePermission('users.read'),
    validateQuery(listUsersSchema),
    async (req, res) => {
      const { page = 1, limit = 20, search, sortBy, sortOrder } = req.query;

      const result = await service.list({
        page: Number(page),
        limit: Number(limit),
        search: search as string,
        sortBy: sortBy as string,
        sortOrder: sortOrder as 'asc' | 'desc',
      });

      res.json(result);
    }
  );

  // Get single user
  router.get('/:id',
    authenticate,
    requirePermission('users.read'),
    async (req, res) => {
      const user = await service.findById(req.params.id);
      res.json(user);
    }
  );

  // Create user
  router.post('/',
    authenticate,
    requirePermission('users.create'),
    validateBody(createUserSchema),
    async (req, res) => {
      const user = await service.create(req.body);
      res.status(201).json(user);
    }
  );

  // Update user
  router.patch('/:id',
    authenticate,
    requirePermission('users.update'),
    validateBody(updateUserSchema),
    async (req, res) => {
      const user = await service.update(req.params.id, req.body);
      res.json(user);
    }
  );

  // Delete user
  router.delete('/:id',
    authenticate,
    requirePermission('users.delete'),
    async (req, res) => {
      await service.delete(req.params.id);
      res.status(204).send();
    }
  );

  // Bulk operations
  router.post('/bulk-delete',
    authenticate,
    requirePermission('users.delete'),
    validateBody(bulkDeleteSchema),
    async (req, res) => {
      await service.bulkDelete(req.body.ids);
      res.json({ deleted: req.body.ids.length });
    }
  );

  // Export to CSV
  router.get('/export',
    authenticate,
    requirePermission('users.export'),
    async (req, res) => {
      const csv = await service.exportToCsv(req.query);
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename=users.csv');
      res.send(csv);
    }
  );

  return router;
}
```

#### Generated Frontend Table
```typescript
// Example output: UsersTable.tsx
import { DataTable } from '@/shared/ui/DataTable';
import { useUsers, useDeleteUser, useBulkDeleteUsers } from '../api/users-api';

export function UsersTable() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [sortBy, setSortBy] = useState('createdAt');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');
  const [selectedIds, setSelectedIds] = useState<string[]>([]);

  const { data, isLoading } = useUsers({ page, search, sortBy, sortOrder });
  const deleteUser = useDeleteUser();
  const bulkDelete = useBulkDeleteUsers();

  const columns = [
    {
      key: 'id',
      header: 'ID',
      sortable: false,
      render: (user: User) => user.id.slice(0, 8),
    },
    {
      key: 'name',
      header: 'Name',
      sortable: true,
      searchable: true,
    },
    {
      key: 'email',
      header: 'Email',
      sortable: true,
      searchable: true,
    },
    {
      key: 'role',
      header: 'Role',
      sortable: true,
      render: (user: User) => <Badge>{user.role}</Badge>,
    },
    {
      key: 'createdAt',
      header: 'Created',
      sortable: true,
      render: (user: User) => formatDate(user.createdAt),
    },
    {
      key: 'actions',
      header: 'Actions',
      render: (user: User) => (
        <div className="flex gap-2">
          <Button size="sm" onClick={() => handleEdit(user)}>Edit</Button>
          <Button
            size="sm"
            variant="destructive"
            onClick={() => deleteUser.mutate(user.id)}
          >
            Delete
          </Button>
        </div>
      ),
    },
  ];

  return (
    <div>
      <div className="flex justify-between mb-4">
        <SearchInput value={search} onChange={setSearch} />
        <div className="flex gap-2">
          {selectedIds.length > 0 && (
            <Button
              variant="destructive"
              onClick={() => bulkDelete.mutate(selectedIds)}
            >
              Delete {selectedIds.length} selected
            </Button>
          )}
          <Button onClick={() => handleExport()}>Export CSV</Button>
          <Button onClick={() => handleCreate()}>Create User</Button>
        </div>
      </div>

      <DataTable
        data={data?.items || []}
        columns={columns}
        loading={isLoading}
        selectable
        selectedIds={selectedIds}
        onSelect={setSelectedIds}
        sortBy={sortBy}
        sortOrder={sortOrder}
        onSort={(key, order) => {
          setSortBy(key);
          setSortOrder(order);
        }}
      />

      <Pagination
        page={page}
        totalPages={data?.totalPages || 1}
        onPageChange={setPage}
      />
    </div>
  );
}
```

#### Generated Form
```typescript
// Example output: UserForm.tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { createUserSchema } from '@vertical-vibing/shared-types';

export function UserForm({ user, onSuccess }: UserFormProps) {
  const form = useForm({
    resolver: zodResolver(createUserSchema),
    defaultValues: user || {
      name: '',
      email: '',
      role: 'user',
    },
  });

  const createUser = useCreateUser();
  const updateUser = useUpdateUser();

  const onSubmit = async (data: UserInput) => {
    if (user) {
      await updateUser.mutateAsync({ id: user.id, data });
    } else {
      await createUser.mutateAsync(data);
    }
    onSuccess?.();
  };

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)}>
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Name</FormLabel>
              <FormControl>
                <Input {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email</FormLabel>
              <FormControl>
                <Input type="email" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="role"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Role</FormLabel>
              <FormControl>
                <Select onValueChange={field.onChange} defaultValue={field.value}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="user">User</SelectItem>
                    <SelectItem value="admin">Admin</SelectItem>
                  </SelectContent>
                </Select>
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <div className="flex justify-end gap-2 mt-4">
          <Button type="button" variant="outline" onClick={onCancel}>
            Cancel
          </Button>
          <Button type="submit" loading={form.formState.isSubmitting}>
            {user ? 'Update' : 'Create'}
          </Button>
        </div>
      </form>
    </Form>
  );
}
```

### Features Generated
- ✅ **Table Component**:
  - Pagination
  - Search (across searchable fields)
  - Sorting (on sortable columns)
  - Filtering
  - Row selection
  - Bulk operations (delete, export)
  - Loading states
  - Empty states

- ✅ **Form Component**:
  - Type-safe validation (Zod)
  - Error handling
  - Loading states
  - Create/Edit modes
  - Relationship dropdowns (foreign keys)

- ✅ **Detail View**:
  - Read-only display
  - Related entities
  - Audit log

- ✅ **Backend Routes**:
  - List (with pagination, search, sort, filter)
  - Get by ID
  - Create
  - Update
  - Delete
  - Bulk delete
  - Export to CSV
  - Permission checks
  - Validation

### AI Integration
```markdown
## Admin Dashboard Generation

When a new entity is created, AI should:
1. Detect the entity definition (from Drizzle schema)
2. Ask: "Generate admin CRUD for this entity?"
3. If yes:
   - Run `npm run generate:admin EntityName`
   - Show generated files
   - Suggest which fields should be searchable/sortable
   - Auto-register routes

Example:
User: "I need a Product entity with name, description, price, categoryId"
AI:
  1. Creates Drizzle schema
  2. Creates shared types
  3. Asks: "Generate admin dashboard?"
  4. If yes, runs generator
  5. Shows: "Created 7 files for Product admin CRUD"
```

### Value Delivered
- **Time saved**: 8-12 hours per entity
- **Typical project**: 10-20 entities = 80-240 hours
- **Features**: Complete admin panel in minutes
- **Consistency**: All admin interfaces follow same patterns
- **Maintainability**: Update generator, regenerate all admin UIs

---

## 4. CI/CD Pipeline Generator (GitHub Actions)

### Why This Matters
- Production deployments need automation
- Manual deploys are error-prone
- Saves 16-24 hours of DevOps setup
- Reduces deployment errors by 90%
- Enables rapid iteration

### What to Build

#### Interactive Setup Script
```bash
./infrastructure/scripts/generate-cicd.sh
```

#### Generated Pipelines
```
.github/workflows/
├── backend-test.yml              # Run tests on every PR
├── backend-deploy-dev.yml        # Auto-deploy dev on push
├── backend-deploy-staging.yml    # Manual approval for staging
├── backend-deploy-prod.yml       # Manual approval for production
├── frontend-test.yml             # Frontend tests
├── frontend-deploy-dev.yml       # Auto-deploy to Amplify dev
├── frontend-deploy-prod.yml      # Deploy to Amplify prod
├── infrastructure-plan.yml       # Terraform plan on PR
├── infrastructure-apply-dev.yml  # Auto-apply dev
└── infrastructure-apply-prod.yml # Manual approval for prod
```

#### Example: Backend Test Pipeline
```yaml
# .github/workflows/backend-test.yml
name: Backend Tests

on:
  pull_request:
    paths:
      - 'repos/backend/**'
      - 'shared-types/**'
  push:
    branches:
      - dev
      - staging
      - main

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: repos/backend/package-lock.json

      - name: Install dependencies
        working-directory: repos/backend
        run: npm ci

      - name: Run linter
        working-directory: repos/backend
        run: npm run lint

      - name: Run type check
        working-directory: repos/backend
        run: npm run type-check

      - name: Run tests
        working-directory: repos/backend
        run: npm test
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test
          JWT_SECRET: test-secret

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: repos/backend/coverage/lcov.info
          flags: backend

      - name: Comment PR with coverage
        if: github.event_name == 'pull_request'
        uses: romeovs/lcov-reporter-action@v0.3.1
        with:
          lcov-file: repos/backend/coverage/lcov.info
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

#### Example: Backend Deploy Pipeline
```yaml
# .github/workflows/backend-deploy-prod.yml
name: Deploy Backend to Production

on:
  workflow_dispatch:  # Manual trigger only
  push:
    branches:
      - main
    paths:
      - 'repos/backend/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production  # Requires manual approval

    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Login to ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build and push Docker image
        working-directory: repos/backend
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: vertical-vibing-backend
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest

      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster vertical-vibing-cluster \
            --service backend-service \
            --force-new-deployment

      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster vertical-vibing-cluster \
            --services backend-service

      - name: Check deployment health
        run: |
          TASK_ARN=$(aws ecs list-tasks \
            --cluster vertical-vibing-cluster \
            --service-name backend-service \
            --query 'taskArns[0]' \
            --output text)

          HEALTH=$(aws ecs describe-tasks \
            --cluster vertical-vibing-cluster \
            --tasks $TASK_ARN \
            --query 'tasks[0].healthStatus' \
            --output text)

          if [ "$HEALTH" != "HEALTHY" ]; then
            echo "Deployment unhealthy!"
            exit 1
          fi

      - name: Notify Slack
        if: always()
        uses: slackapi/slack-github-action@v1
        with:
          channel-id: 'deployments'
          slack-message: |
            Backend deployment to production: ${{ job.status }}
            Commit: ${{ github.sha }}
            Author: ${{ github.actor }}
        env:
          SLACK_BOT_TOKEN: ${{ secrets.SLACK_BOT_TOKEN }}

      - name: Rollback on failure
        if: failure()
        run: |
          # Get previous task definition
          PREV_TASK_DEF=$(aws ecs describe-services \
            --cluster vertical-vibing-cluster \
            --services backend-service \
            --query 'services[0].deployments[1].taskDefinition' \
            --output text)

          # Rollback
          aws ecs update-service \
            --cluster vertical-vibing-cluster \
            --service backend-service \
            --task-definition $PREV_TASK_DEF

          echo "Rolled back to previous version"
```

#### Example: Terraform Plan on PR
```yaml
# .github/workflows/infrastructure-plan.yml
name: Terraform Plan

on:
  pull_request:
    paths:
      - 'infrastructure/terraform/**'

jobs:
  plan:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Terraform Init
        working-directory: infrastructure/terraform/environments/dev
        run: terraform init

      - name: Terraform Plan
        working-directory: infrastructure/terraform/environments/dev
        id: plan
        run: terraform plan -no-color -out=tfplan
        continue-on-error: true

      - name: Comment PR with plan
        uses: actions/github-script@v7
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            const output = `#### Terraform Plan 📖\`${{ steps.plan.outcome }}\`

            <details><summary>Show Plan</summary>

            \`\`\`terraform
            ${{ steps.plan.outputs.stdout }}
            \`\`\`

            </details>

            *Pushed by: @${{ github.actor }}, Action: \`${{ github.event_name }}\`*`;

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })

      - name: Fail if plan failed
        if: steps.plan.outcome == 'failure'
        run: exit 1
```

#### Interactive Setup Script
```bash
#!/bin/bash
# infrastructure/scripts/generate-cicd.sh

echo "🚀 CI/CD Pipeline Generator"
echo ""

# Ask questions
read -p "Deploy backend to AWS ECS? (y/n): " DEPLOY_BACKEND
read -p "Deploy frontend to AWS Amplify? (y/n): " DEPLOY_FRONTEND
read -p "Use Terraform for infrastructure? (y/n): " USE_TERRAFORM
read -p "Enable automatic deployments to dev? (y/n): " AUTO_DEPLOY_DEV
read -p "Require manual approval for production? (y/n): " MANUAL_PROD
read -p "Send Slack notifications? (y/n): " USE_SLACK
read -p "Enable automatic rollback on failure? (y/n): " AUTO_ROLLBACK

# Generate workflows based on answers
if [ "$DEPLOY_BACKEND" = "y" ]; then
  echo "Generating backend CI/CD workflows..."
  generate_backend_workflows
fi

if [ "$DEPLOY_FRONTEND" = "y" ]; then
  echo "Generating frontend CI/CD workflows..."
  generate_frontend_workflows
fi

if [ "$USE_TERRAFORM" = "y" ]; then
  echo "Generating Terraform workflows..."
  generate_terraform_workflows
fi

# Configure GitHub secrets
echo ""
echo "📝 GitHub Secrets Required:"
echo "- AWS_ACCESS_KEY_ID"
echo "- AWS_SECRET_ACCESS_KEY"

if [ "$USE_SLACK" = "y" ]; then
  echo "- SLACK_BOT_TOKEN"
  echo "- SLACK_CHANNEL_ID"
fi

echo ""
echo "✅ CI/CD pipelines generated!"
echo ""
echo "Next steps:"
echo "1. Add required secrets to GitHub"
echo "2. Create 'production' environment in GitHub with protection rules"
echo "3. Push to trigger first workflow"
```

### Features Included
- ✅ **Automated Testing**: Run on every PR
- ✅ **Multi-Environment**: Dev, Staging, Production
- ✅ **Manual Approvals**: For production deploys
- ✅ **Health Checks**: Verify deployment success
- ✅ **Automatic Rollback**: On failure
- ✅ **Notifications**: Slack/Discord/Email
- ✅ **Terraform Integration**: Infrastructure as Code
- ✅ **Coverage Reports**: In PR comments
- ✅ **Security Scanning**: Dependency checks
- ✅ **Performance Monitoring**: Deployment metrics

### Value Delivered
- **Time saved**: 16-24 hours initial setup
- **Ongoing value**: Reduces deployment errors by 90%
- **Enables**: Rapid iteration, confident deployments
- **Compliance**: Audit trail for all deployments

---

## 5. Feature Flags System (LaunchDarkly-style)

### Why This Matters
- Enable/disable features without deploying
- Gradual rollouts (10% → 50% → 100%)
- A/B testing capability
- Kill switches for emergencies
- Saves 30-40 hours of implementation
- Enables safer deployments

### What to Build

#### Database Schema
```sql
CREATE TABLE feature_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  enabled BOOLEAN DEFAULT false,
  rollout_percentage INTEGER DEFAULT 0, -- 0-100
  user_segments JSONB DEFAULT '[]',     -- ["beta_users", "enterprise"]
  environments JSONB DEFAULT '{}',       -- {"dev": true, "prod": false}
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE flag_evaluations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flag_id UUID REFERENCES feature_flags(id),
  user_id UUID REFERENCES users(id),
  variant VARCHAR(50),                   -- For A/B testing
  evaluated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_flag_evaluations_user ON flag_evaluations(user_id, flag_id);
CREATE INDEX idx_flag_evaluations_flag ON flag_evaluations(flag_id);
```

#### Backend Implementation
```
repos/backend/src/features/feature-flags/
├── feature-flags.service.ts      # Evaluation engine
├── feature-flags.repository.ts   # Database operations
├── feature-flags.route.ts        # Admin API
├── feature-flags.types.ts        # Type definitions
├── middleware/
│   └── feature-gate.middleware.ts # Protect routes by flag
└── __tests__/
    └── feature-flags.test.ts
```

#### Feature Flag Service
```typescript
// repos/backend/src/features/feature-flags/feature-flags.service.ts
export class FeatureFlagsService {
  async isEnabled(
    flagKey: string,
    context: FlagContext
  ): Promise<boolean> {
    const flag = await this.repo.findByKey(flagKey);

    if (!flag) {
      return false; // Flag doesn't exist, default to disabled
    }

    // Check environment
    const environment = process.env.NODE_ENV || 'development';
    if (flag.environments[environment] === false) {
      return false;
    }

    // Check if fully enabled
    if (flag.enabled && flag.rolloutPercentage === 100) {
      return true;
    }

    // Check user segments
    if (context.user && flag.userSegments.length > 0) {
      const userSegments = await this.getUserSegments(context.user.id);
      const hasSegment = flag.userSegments.some(seg =>
        userSegments.includes(seg)
      );
      if (hasSegment) {
        return true;
      }
    }

    // Check rollout percentage (deterministic based on user ID)
    if (context.user && flag.rolloutPercentage > 0) {
      const hash = this.hashUserId(context.user.id);
      const bucket = hash % 100;
      if (bucket < flag.rolloutPercentage) {
        // Log evaluation for analytics
        await this.logEvaluation(flag.id, context.user.id, 'enabled');
        return true;
      }
    }

    await this.logEvaluation(flag.id, context.user?.id, 'disabled');
    return false;
  }

  async getVariant(
    flagKey: string,
    context: FlagContext
  ): Promise<string> {
    const flag = await this.repo.findByKey(flagKey);

    if (!flag || !flag.enabled) {
      return 'control'; // Default variant
    }

    // A/B test: assign user to variant
    if (context.user) {
      // Check if user already has a variant
      const existing = await this.repo.getUserVariant(flag.id, context.user.id);
      if (existing) {
        return existing.variant;
      }

      // Assign new variant (sticky - user always gets same variant)
      const variant = this.assignVariant(context.user.id, flag.variants);
      await this.logEvaluation(flag.id, context.user.id, variant);
      return variant;
    }

    return 'control';
  }

  private hashUserId(userId: string): number {
    // Deterministic hash for consistent bucketing
    let hash = 0;
    for (let i = 0; i < userId.length; i++) {
      hash = ((hash << 5) - hash) + userId.charCodeAt(i);
      hash = hash & hash; // Convert to 32bit integer
    }
    return Math.abs(hash);
  }

  private assignVariant(userId: string, variants: FlagVariant[]): string {
    const hash = this.hashUserId(userId);
    const bucket = hash % 100;

    let cumulativeWeight = 0;
    for (const variant of variants) {
      cumulativeWeight += variant.weight;
      if (bucket < cumulativeWeight) {
        return variant.name;
      }
    }

    return 'control';
  }
}
```

#### Middleware for Route Protection
```typescript
// repos/backend/src/features/feature-flags/middleware/feature-gate.middleware.ts
export function requireFeature(flagKey: string) {
  return async (req: Request, res: Response, next: NextFunction) => {
    const flagService = new FeatureFlagsService();

    const enabled = await flagService.isEnabled(flagKey, {
      user: req.user,
      request: req,
    });

    if (!enabled) {
      return res.status(403).json({
        error: 'Feature not available',
        code: 'FEATURE_DISABLED',
      });
    }

    next();
  };
}

// Usage:
router.get('/new-feature',
  authenticate,
  requireFeature('new-dashboard-ui'),
  async (req, res) => {
    // This route only accessible if flag is enabled
  }
);
```

#### Frontend Implementation
```
repos/frontend/src/features/feature-flags/
├── hooks/
│   ├── useFeatureFlag.ts         # React hook
│   └── useABTest.ts              # A/B testing hook
├── ui/
│   ├── FeatureFlagAdmin.tsx      # Admin panel
│   └── FeatureGate.tsx           # Wrapper component
├── api/
│   └── feature-flags-api.ts      # API client
└── context/
    └── FeatureFlagsProvider.tsx  # Context provider
```

#### React Hooks
```typescript
// repos/frontend/src/features/feature-flags/hooks/useFeatureFlag.ts
export function useFeatureFlag(flagKey: string): boolean {
  const { flags } = useFeatureFlags();
  return flags[flagKey] ?? false;
}

// Usage in components:
export function Dashboard() {
  const showNewUI = useFeatureFlag('new-dashboard-ui');

  if (showNewUI) {
    return <NewDashboard />;
  }

  return <OldDashboard />;
}

// A/B testing hook
export function useABTest(
  flagKey: string,
  variants: string[] = ['a', 'b']
): string {
  const { getVariant } = useFeatureFlags();
  return getVariant(flagKey) || 'control';
}

// Usage:
export function CheckoutFlow() {
  const variant = useABTest('checkout-flow', ['a', 'b']);

  if (variant === 'a') {
    return <OnePageCheckout />;
  }

  if (variant === 'b') {
    return <MultiStepCheckout />;
  }

  return <OriginalCheckout />;
}
```

#### Feature Gate Component
```typescript
// repos/frontend/src/features/feature-flags/ui/FeatureGate.tsx
interface FeatureGateProps {
  flag: string;
  fallback?: React.ReactNode;
  children: React.ReactNode;
}

export function FeatureGate({ flag, fallback = null, children }: FeatureGateProps) {
  const enabled = useFeatureFlag(flag);

  if (!enabled) {
    return <>{fallback}</>;
  }

  return <>{children}</>;
}

// Usage:
<FeatureGate
  flag="beta-features"
  fallback={<ComingSoonBanner />}
>
  <BetaFeatures />
</FeatureGate>
```

#### Admin Panel
```typescript
// repos/frontend/src/features/feature-flags/ui/FeatureFlagAdmin.tsx
export function FeatureFlagAdmin() {
  const { data: flags } = useFeatureFlags();
  const updateFlag = useUpdateFeatureFlag();

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Flag</TableHead>
          <TableHead>Enabled</TableHead>
          <TableHead>Rollout %</TableHead>
          <TableHead>Segments</TableHead>
          <TableHead>Actions</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {flags?.map((flag) => (
          <TableRow key={flag.id}>
            <TableCell>
              <div>
                <div className="font-medium">{flag.name}</div>
                <div className="text-sm text-muted">{flag.key}</div>
              </div>
            </TableCell>
            <TableCell>
              <Switch
                checked={flag.enabled}
                onCheckedChange={(enabled) =>
                  updateFlag.mutate({ id: flag.id, enabled })
                }
              />
            </TableCell>
            <TableCell>
              <Slider
                value={[flag.rolloutPercentage]}
                onValueChange={([percentage]) =>
                  updateFlag.mutate({ id: flag.id, rolloutPercentage: percentage })
                }
                max={100}
                step={10}
              />
              <span className="text-sm">{flag.rolloutPercentage}%</span>
            </TableCell>
            <TableCell>
              <MultiSelect
                value={flag.userSegments}
                onChange={(segments) =>
                  updateFlag.mutate({ id: flag.id, userSegments: segments })
                }
                options={['beta_users', 'enterprise', 'internal']}
              />
            </TableCell>
            <TableCell>
              <Button size="sm" onClick={() => handleEdit(flag)}>
                Edit
              </Button>
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}
```

### Use Cases

#### 1. Gradual Rollout
```typescript
// Start: 10% of users
await flagService.updateFlag('new-search', { rolloutPercentage: 10 });

// After monitoring: increase to 50%
await flagService.updateFlag('new-search', { rolloutPercentage: 50 });

// If metrics good: 100%
await flagService.updateFlag('new-search', { rolloutPercentage: 100 });

// If metrics bad: rollback to 0%
await flagService.updateFlag('new-search', { rolloutPercentage: 0 });
```

#### 2. Beta Testing
```typescript
// Create flag for beta users only
await flagService.createFlag({
  key: 'beta-ai-features',
  name: 'AI Features',
  enabled: true,
  userSegments: ['beta_users'],
});

// Frontend automatically shows for beta users
const showAI = useFeatureFlag('beta-ai-features');
```

#### 3. A/B Testing
```typescript
// Create A/B test
await flagService.createFlag({
  key: 'pricing-page-redesign',
  name: 'Pricing Page Redesign',
  enabled: true,
  variants: [
    { name: 'control', weight: 50 },
    { name: 'variant_a', weight: 50 },
  ],
});

// Frontend
const variant = useABTest('pricing-page-redesign');
if (variant === 'variant_a') {
  return <NewPricingPage />;
}
return <OriginalPricingPage />;
```

#### 4. Kill Switch
```typescript
// Emergency: turn off problematic feature
await flagService.updateFlag('problematic-feature', { enabled: false });

// Instantly disabled for all users
// No deployment needed!
```

### Analytics Integration
```typescript
// Track which users see which features
export class FeatureFlagAnalytics {
  async getFeatureAdoption(flagKey: string): Promise<FeatureStats> {
    const evaluations = await this.repo.getEvaluations(flagKey);

    return {
      totalEvaluations: evaluations.length,
      enabledCount: evaluations.filter(e => e.variant !== 'disabled').length,
      variantDistribution: this.countVariants(evaluations),
      conversionRate: await this.getConversionRate(flagKey),
    };
  }
}
```

### Documentation
```markdown
# Add to: infrastructure/docs/FEATURE-FLAGS-GUIDE.md

## Feature Flags System

### Creating a Feature Flag

#### Backend
```typescript
await flagService.createFlag({
  key: 'my-new-feature',
  name: 'My New Feature',
  description: 'Description of the feature',
  enabled: true,
  rolloutPercentage: 10, // Start with 10%
  userSegments: [], // Or ['beta_users'] for beta only
});
```

#### Frontend
```typescript
const enabled = useFeatureFlag('my-new-feature');

if (enabled) {
  return <NewFeature />;
}
return <OldFeature />;
```

### Best Practices
1. Start with low rollout (10-20%)
2. Monitor metrics closely
3. Increase gradually (10% → 25% → 50% → 100%)
4. Keep flags short-lived (remove after full rollout)
5. Clean up old flags monthly
```

### Value Delivered
- **Time saved**: 30-40 hours implementation
- **Deployment safety**: 90% reduction in rollback deployments
- **Flexibility**: Change features without deploying
- **Testing**: Built-in A/B testing
- **Emergency**: Kill switches for quick response

---

## Summary: Tier 1 Value Proposition

**Total Time Saved per Project:**
- Stripe Billing: 40-80 hours
- Email System: 20-30 hours
- Admin Dashboard: 80-240 hours (for 10-30 entities)
- CI/CD Pipelines: 16-24 hours
- Feature Flags: 30-40 hours

**Total: 186-414 hours saved = $9,300 - $41,400 value**

**With these 5 automations, your repository becomes:**
- A complete SaaS starter kit
- Worth $15,000-30,000 in the market
- Covering 80% of typical SaaS needs
- 2-4 weeks faster to market per project

---

# Tier 2: Production Essentials

[Continue with remaining 15 features in similar detail...]

## 6. Monitoring & Alerting Stack

[Detailed implementation similar to above...]

## 7. Background Job System

[Detailed implementation...]

## 8. API Documentation Auto-Generator

[Detailed implementation...]

## 9. Multi-Tenancy System

[Detailed implementation...]

## 10. Webhook System

[Detailed implementation...]

---

# Tier 3: Advanced Features

## 11-20. [Remaining features]

[Each with similar detail level...]

---

# Meta-Automations

## 21. Interactive SaaS Generator CLI

### The Ultimate Automation

This CLI tool ties everything together, allowing developers to choose which features they need and generate a complete, production-ready SaaS in minutes.

```bash
npx create-vertical-vibing my-saas

? What's your SaaS name? > Acme Inc
? What's your domain? > acmeapp.com
? Select features to include:
  ✓ Authentication (AWS Cognito)
  ✓ Subscription billing (Stripe)
  ✓ Multi-tenancy
  ✓ Email system (AWS SES)
  ✓ Admin dashboard
  ✓ Feature flags
  ✓ Background jobs (SQS)
  ✓ File uploads (S3)
  ○ Search (Elasticsearch)
  ○ Webhooks
  ○ Real-time notifications

? Select deployment target:
  ✓ AWS (ECS + RDS + S3)
  ○ Vercel + Supabase
  ○ Self-hosted (Docker Compose)

? Select compliance requirements:
  ✓ GDPR
  ○ HIPAA
  ○ SOC 2

⏳ Generating your SaaS...

✓ Created project structure
✓ Generated backend (Express + VSA)
✓ Generated frontend (Next.js + FSD)
✓ Created shared types package
✓ Generated IAM system
✓ Created Stripe integration
✓ Set up email templates (7 templates)
✓ Generated admin dashboard (12 entities)
✓ Created Terraform infrastructure
✓ Generated CI/CD pipelines
✓ Set up feature flags system
✓ Created background job system
✓ Generated documentation (42 files)

🎉 Your SaaS is ready!

Project: my-saas
Location: /Users/you/my-saas
Features: 9 selected
Components: 247 files generated
Estimated development time saved: 320 hours

Next steps:
1. cd my-saas
2. ./scripts/setup.sh
3. ./scripts/dev.sh
4. Open http://localhost:3001

To deploy to AWS:
1. ./infrastructure/scripts/aws-quick-setup.sh
2. Follow the deployment guide

Documentation:
- README.md (getting started)
- infrastructure/docs/ (AWS deployment)
- .ai-context/ (architecture)
```

### Implementation

[Detailed CLI implementation...]

---

## 22. AI Feature Generator

### Natural Language to Code

Describe a feature in plain English, AI generates complete implementation.

```bash
npm run ai:generate-feature

? Describe the feature:
> "Users can upload product images. Images should be resized to 3 sizes (thumbnail 100x100, medium 400x400, large 800x800) and stored in S3. Users can tag products with multiple tags. There should be search by product name and tags."

🤖 AI analyzing feature...

✓ Detected entities:
  - Product (name, description, price, userId)
  - ProductImage (url, size, productId)
  - Tag (name)
  - ProductTag (productId, tagId)

✓ Detected infrastructure needs:
  - S3 bucket (product-images)
  - Lambda function (image-resize)
  - CloudFront distribution (CDN)

✓ Detected features:
  - File upload with presigned URLs
  - Image processing pipeline
  - Search functionality
  - Tagging system

⏳ Generating implementation...

✓ Created Terraform infrastructure (5 files)
✓ Created database schema (4 tables)
✓ Created shared types (8 types)
✓ Generated backend API (18 endpoints)
✓ Generated frontend UI (12 components)
✓ Created tests (32 test cases)
✓ Generated documentation (4 files)

📁 Files created:
infrastructure/terraform/features/products/
  ├── s3.tf
  ├── lambda-resize.tf
  ├── cloudfront.tf
  └── outputs.tf

repos/backend/src/features/products/
  ├── products.route.ts (12 endpoints)
  ├── products.service.ts
  ├── products.repository.ts
  ├── products.validator.ts
  ├── s3.service.ts (upload/delete)
  ├── image-processor.service.ts
  └── __tests__/ (24 tests)

repos/frontend/src/features/products/
  ├── ui/ProductsList.tsx
  ├── ui/ProductForm.tsx
  ├── ui/ImageUpload.tsx
  ├── ui/TagSelector.tsx
  ├── api/products-api.ts
  └── hooks/useProducts.ts

🚀 Deploying infrastructure...

✓ Created S3 bucket: products-images-dev
✓ Deployed Lambda function: product-image-resizer
✓ Created CloudFront distribution
✓ Updated database schema

🎉 Feature ready!

To test:
1. ./scripts/dev.sh
2. Go to http://localhost:3001/products
3. Upload a product image

API endpoints created:
- POST /api/products (create product)
- GET /api/products (list with search)
- POST /api/products/:id/images (upload image)
- GET /api/products/:id (get with images and tags)
- POST /api/products/:id/tags (add tags)
- GET /api/tags (search tags)
```

### How It Works

[Detailed AI implementation...]

---

## 23. Compliance Automation

### Automatic Compliance Controls

[Detailed compliance automation...]

---

# Implementation Roadmap

## Phase 1: Foundation (Weeks 1-2)
**Goal:** Add top 5 highest-impact automations

**Tasks:**
- [ ] Implement Stripe billing integration
- [ ] Set up AWS SES email system
- [ ] Build admin dashboard generator
- [ ] Create CI/CD pipeline generator
- [ ] Implement feature flags system

**Expected Outcome:** Repository value → $15k-30k

**Success Metrics:**
- Can generate complete billing system in < 5 minutes
- Can send 7 types of transactional emails
- Can generate admin CRUD for any entity in < 2 minutes
- Can deploy to production with one command
- Can toggle features without deploying

---

## Phase 2: Production Essentials (Month 2)
**Goal:** Add production-ready features

**Tasks:**
- [ ] Set up monitoring & alerting
- [ ] Implement background job system
- [ ] Add API documentation generator
- [ ] Build multi-tenancy system
- [ ] Create webhook system

**Expected Outcome:** Repository value → $40k-60k

**Success Metrics:**
- Monitoring dashboards auto-generated
- Background jobs process reliably
- API docs always up-to-date
- Can support 1000+ tenants
- 3rd-party integrations via webhooks

---

## Phase 3: Advanced Platform (Month 3)
**Goal:** Complete automation platform

**Tasks:**
- [ ] Implement remaining Tier 3 features
- [ ] Build interactive CLI generator
- [ ] Create AI feature generator
- [ ] Add compliance automation

**Expected Outcome:** Repository value → $100k+

**Success Metrics:**
- Can generate complete SaaS from CLI
- AI can build features from descriptions
- Compliance reports auto-generated
- Fastest SaaS starter kit on market

---

# Competitive Analysis

## Current Market

| Product | Price | Features | Dev Time Saved | Your Advantage |
|---------|-------|----------|----------------|----------------|
| ShipFast | $199 | Basic auth, payments | 20-40 hrs | You: 186-414 hrs |
| Gravity | $699 | Auth, admin, payments | 60-80 hrs | You: Better IAM, Infrastructure |
| SaaSitive | $1,997 | Complete stack | 100-150 hrs | You: More automation |
| Serverless SaaS | $2,500 | AWS infrastructure | 80-120 hrs | You: Better DX, AI features |

**Your Position:** Premium tier ($997-1,997) with most comprehensive feature set

---

# Marketing Strategy

## Target Audience

### Primary: Solo Developers & Small Teams
- **Pain:** Don't have time to build all SaaS boilerplate
- **Value Prop:** Save 200+ hours, focus on unique features
- **Price Point:** $997

### Secondary: Agencies
- **Pain:** Build same infrastructure for every client
- **Value Prop:** White-label, build client projects 3x faster
- **Price Point:** $5,000-10,000 (agency license)

### Tertiary: Enterprise Dev Teams
- **Pain:** Need compliant, production-ready starter
- **Value Prop:** SOC 2 ready, 40+ hours of compliance work done
- **Price Point:** $15,000-25,000

---

# Revenue Projections

## Conservative (Year 1)

**Individual Licenses:**
- 50 sales × $997 = $49,850

**Agency Licenses:**
- 3 sales × $7,500 = $22,500

**Consulting/Setup:**
- 5 clients × $3,000 = $15,000

**Total: $87,350**

## Optimistic (Year 1)

**Individual Licenses:**
- 150 sales × $997 = $149,550

**Agency Licenses:**
- 10 sales × $7,500 = $75,000

**Consulting/Setup:**
- 20 clients × $3,000 = $60,000

**Enterprise:**
- 2 sales × $15,000 = $30,000

**Total: $314,550**

---

# Next Steps

## Immediate Actions

1. **Choose:** Pick Phase 1 features to implement
2. **Build:** Start with Stripe billing (highest demand)
3. **Document:** Create video showing 5-minute billing setup
4. **Launch:** Product Hunt, Indie Hackers, Twitter

## Long-term

1. **Community:** Build Discord, gather feedback
2. **Content:** Write guides, tutorials, case studies
3. **Partnerships:** Collaborate with agencies
4. **Platform:** Build marketplace for add-ons

---

**Ready to start? Recommend beginning with Stripe billing integration - it's the #1 requested feature and provides immediate value.**
