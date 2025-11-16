# SaaS Features Roadmap

## Phase 1: User Authentication & Authorization

### 1.1 User Registration
- **Endpoint**: `POST /api/auth/register`
- **Features**:
  - Email + password registration
  - Email validation (Zod)
  - Password hashing (bcrypt)
  - Automatic email verification token generation
  - Return JWT token on successful registration

### 1.2 User Login
- **Endpoint**: `POST /api/auth/login`
- **Features**:
  - Email + password authentication
  - JWT token generation
  - Refresh token support
  - Login rate limiting

### 1.3 User Profile
- **Endpoint**: `GET /api/users/me` (authenticated)
- **Endpoint**: `PATCH /api/users/me` (authenticated)
- **Features**:
  - View user profile
  - Update profile (name, email)
  - Change password

### 1.4 Frontend Pages
- `/login` - Login page
- `/register` - Registration page
- `/dashboard` - User dashboard (protected route)
- `/profile` - User profile page (protected route)

---

## Phase 2: Subscription & Billing

### 2.1 Subscription Plans
- **Endpoint**: `GET /api/plans`
- **Features**:
  - List available plans (Free, Pro, Enterprise)
  - Plan details (price, features, limits)

### 2.2 User Subscriptions
- **Endpoint**: `GET /api/subscriptions/me` (authenticated)
- **Endpoint**: `POST /api/subscriptions` (authenticated)
- **Endpoint**: `PATCH /api/subscriptions/:id/cancel` (authenticated)
- **Features**:
  - View current subscription
  - Subscribe to a plan
  - Cancel subscription
  - Upgrade/downgrade plans

### 2.3 Frontend Pages
- `/pricing` - Pricing page with plans
- `/dashboard/subscription` - Manage subscription

---

## Phase 3: Team Management

### 3.1 Organizations/Teams
- **Endpoint**: `POST /api/organizations` (authenticated)
- **Endpoint**: `GET /api/organizations` (authenticated)
- **Endpoint**: `GET /api/organizations/:id` (authenticated)
- **Endpoint**: `PATCH /api/organizations/:id` (authenticated)
- **Endpoint**: `DELETE /api/organizations/:id` (authenticated)
- **Features**:
  - Create organization
  - List user's organizations
  - Update organization details
  - Delete organization

### 3.2 Team Members
- **Endpoint**: `POST /api/organizations/:id/members` (authenticated)
- **Endpoint**: `GET /api/organizations/:id/members` (authenticated)
- **Endpoint**: `DELETE /api/organizations/:id/members/:userId` (authenticated)
- **Features**:
  - Invite team members by email
  - List team members
  - Remove team members
  - Role-based permissions (Owner, Admin, Member)

### 3.3 Frontend Pages
- `/dashboard/team` - Team management page
- `/dashboard/team/invite` - Invite members page

---

## Phase 4: Usage Tracking & Analytics

### 4.1 Usage Metrics
- **Endpoint**: `GET /api/usage/me` (authenticated)
- **Features**:
  - Track API calls per user/organization
  - Track feature usage
  - Usage limits based on plan

### 4.2 Analytics Dashboard
- **Endpoint**: `GET /api/analytics/summary` (authenticated)
- **Features**:
  - Daily/weekly/monthly usage stats
  - Growth metrics
  - User engagement metrics

### 4.3 Frontend Pages
- `/dashboard/analytics` - Analytics dashboard
- `/dashboard/usage` - Usage metrics page

---

## Phase 5: API Keys & Webhooks

### 5.1 API Keys
- **Endpoint**: `POST /api/api-keys` (authenticated)
- **Endpoint**: `GET /api/api-keys` (authenticated)
- **Endpoint**: `DELETE /api/api-keys/:id` (authenticated)
- **Features**:
  - Generate API keys
  - List API keys
  - Revoke API keys
  - API key scopes/permissions

### 5.2 Webhooks
- **Endpoint**: `POST /api/webhooks` (authenticated)
- **Endpoint**: `GET /api/webhooks` (authenticated)
- **Endpoint**: `DELETE /api/webhooks/:id` (authenticated)
- **Features**:
  - Register webhook URLs
  - List webhooks
  - Delete webhooks
  - Webhook event types

### 5.3 Frontend Pages
- `/dashboard/api-keys` - API key management
- `/dashboard/webhooks` - Webhook management

---

## Implementation Priority

**Immediate (MVP)**:
1. User Registration & Login (Phase 1.1, 1.2)
2. User Profile (Phase 1.3)
3. Basic Dashboard

**Short-term (Launch)**:
4. Subscription Plans (Phase 2.1, 2.2)
5. Organization Management (Phase 3.1)
6. Team Members (Phase 3.2)

**Medium-term (Growth)**:
7. Usage Tracking (Phase 4.1)
8. Analytics Dashboard (Phase 4.2)

**Long-term (Scale)**:
9. API Keys (Phase 5.1)
10. Webhooks (Phase 5.2)

---

## Technical Stack

### Backend
- **Framework**: Express.js
- **Database**: PostgreSQL (Drizzle ORM)
- **Authentication**: JWT (jsonwebtoken)
- **Password Hashing**: bcrypt
- **Validation**: Zod
- **Email**: (TBD - SendGrid, Resend, or similar)

### Frontend
- **Framework**: Next.js 14+ (App Router)
- **Styling**: Tailwind CSS
- **State Management**: Zustand
- **Forms**: React Hook Form + Zod
- **API Client**: Fetch API

### Shared
- **Types**: @vertical-vibing/shared-types
- **Validation Schemas**: Zod (shared between FE/BE)

---

## Database Schema Overview

### Users
- id (UUID, PK)
- email (unique)
- password_hash
- name
- avatar_url
- email_verified (boolean)
- created_at
- updated_at

### Organizations
- id (UUID, PK)
- name
- slug (unique)
- owner_id (FK -> users)
- created_at
- updated_at

### Organization Members
- id (UUID, PK)
- organization_id (FK)
- user_id (FK)
- role (enum: owner, admin, member)
- created_at

### Subscriptions
- id (UUID, PK)
- user_id (FK) or organization_id (FK)
- plan_id (FK)
- status (enum: active, canceled, past_due)
- current_period_start
- current_period_end
- created_at
- updated_at

### Plans
- id (UUID, PK)
- name
- slug
- price (decimal)
- interval (enum: month, year)
- features (JSON)
- limits (JSON)

### API Keys
- id (UUID, PK)
- user_id or organization_id (FK)
- key_hash
- name
- scopes (JSON)
- last_used_at
- created_at
- expires_at

---

## Next Steps

Start with **Phase 1: User Authentication & Authorization** to build the foundation for all other features.
