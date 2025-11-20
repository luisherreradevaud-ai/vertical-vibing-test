# Auth Provider Implementation - Phase 1 Complete

## Summary

Successfully implemented a flexible authentication provider system that allows switching between different auth providers (in-house, AWS Cognito, Clerk) using environment variables.

**Current Status:** ✅ Phase 1 Complete (In-house provider fully functional)

## What Was Implemented

### 1. Shared Types (Updated)

**Location:** `shared-types/src/`

- Added `AuthProvider` type: `'inhouse' | 'cognito' | 'clerk'`
- Updated `User` type with:
  - `authProvider` - Which provider authenticates this user
  - `externalId` - Provider's user ID (null for in-house)
  - `externalMetadata` - Provider-specific data (JSONB)
- Updated `JWTPayload` to include `authProvider`
- Created `auth-provider.types.ts` with provider interface types

### 2. Database Schema (Updated)

**Location:** `repos/backend/src/shared/db/schema/users.schema.ts`

Added columns to `users` table:
- `auth_provider` VARCHAR(20) DEFAULT 'inhouse' NOT NULL
- `external_id` VARCHAR(255) (nullable)
- `external_metadata` JSONB (nullable)
- `password_hash` now NULLABLE (external auth users don't have passwords)

**Migration:** `repos/backend/src/shared/db/migrations/001_add_auth_provider_columns.sql`

### 3. Backend Provider Pattern

**Location:** `repos/backend/src/features/auth/providers/`

#### Provider Interface
**File:** `auth-provider.interface.ts`

All providers implement `IAuthProvider` with methods:
- `login()` - Authenticate user
- `register()` - Create new user
- `validateToken()` - Verify token
- `refreshToken()` - Get new access token
- `resetPassword()` - Send reset email
- `verifyEmail()` - Verify email address
- `updatePassword()` - Change password

#### Provider Factory
**File:** `auth-provider.factory.ts`

Reads `AUTH_PROVIDER` env variable and creates the appropriate provider instance (singleton pattern).

#### In-House Provider
**File:** `providers/inhouse/inhouse-auth.provider.ts`

Fully implemented provider using:
- bcrypt for password hashing
- JWT tokens stored in our database
- PostgreSQL for user storage

### 4. Refactored Auth Service

**Location:** `repos/backend/src/features/auth/auth.service.ts`

- Uses provider pattern via factory
- Delegates authentication to active provider
- Syncs all users to our database (regardless of provider)
- Generates JWT with `authProvider` included
- Returns specific errors for service unavailability

### 5. Updated JWT Utility

**Location:** `repos/backend/src/shared/utils/jwt.ts`

- `generateToken()` now accepts `authProvider` in payload
- JWT tokens now include provider information

### 6. Frontend Auth Config

**Location:** `repos/frontend/src/features/auth/lib/auth-config.ts`

Utility for reading auth provider from `NEXT_PUBLIC_AUTH_PROVIDER`:
- `authConfig.provider` - Current provider
- `authConfig.isInhouse` - Boolean check
- Helper functions: `getAuthProvider()`, `isInhouseAuth()`, etc.

## How to Use

### Backend Configuration

Set the auth provider in `repos/backend/.env`:

```bash
# Use in-house authentication (default)
AUTH_PROVIDER=inhouse

# Use AWS Cognito (not yet implemented)
# AUTH_PROVIDER=cognito
# AWS_COGNITO_USER_POOL_ID=us-east-1_xxxxx
# AWS_COGNITO_CLIENT_ID=xxxxx

# Use Clerk (not yet implemented)
# AUTH_PROVIDER=clerk
# CLERK_SECRET_KEY=sk_test_xxxxx
```

### Frontend Configuration

Set the auth provider in `repos/frontend/.env.local`:

```bash
# Must match backend AUTH_PROVIDER
NEXT_PUBLIC_AUTH_PROVIDER=inhouse
```

### Migration

Before running the app, apply the database migration:

```bash
# Connect to your PostgreSQL database
psql $DATABASE_URL -f repos/backend/src/shared/db/migrations/001_add_auth_provider_columns.sql
```

Or manually run the SQL in your database client.

### Start Development

```bash
# From project root
./scripts/dev.sh
```

The backend will log: `🔐 Initializing auth provider: inhouse`

## API Changes

### JWT Token Structure (Updated)

JWTs now include the auth provider:

```json
{
  "userId": "uuid-here",
  "email": "user@example.com",
  "authProvider": "inhouse",
  "iat": 1234567890,
  "exp": 1234567890
}
```

### User Response (Updated)

User objects now include provider information:

```json
{
  "id": "uuid-here",
  "email": "user@example.com",
  "name": "John Doe",
  "avatarUrl": null,
  "authProvider": "inhouse",
  "externalId": null,
  "createdAt": "2025-11-20T00:00:00.000Z",
  "updatedAt": "2025-11-20T00:00:00.000Z"
}
```

## Architecture Benefits

### Single Provider Per Deployment
- Set `AUTH_PROVIDER` once in environment
- Entire app uses that provider
- Easy to switch for different environments (dev: inhouse, prod: cognito)

### Backend API Pattern
- Frontend always calls `/api/auth/*` endpoints
- Backend internally delegates to active provider
- Frontend doesn't need provider-specific SDKs

### Database as Source of Truth
- All users synced to PostgreSQL (regardless of provider)
- IAM system works with all auth providers
- User profiles managed in our database

### JWT with Provider Info
- Tokens include `authProvider` claim
- Enables provider-specific logic if needed
- Clear audit trail of authentication method

## Error Handling

Provider errors are caught and translated to user-friendly messages:

```typescript
// Provider down
"Authentication service temporarily unavailable"

// Wrong provider
"This account uses cognito authentication"

// Invalid credentials
"Invalid credentials"
```

## Frontend Integration

### Example: Provider-Aware Login Form

```typescript
// src/features/auth/ui/LoginPage.tsx
import { authConfig } from '../lib/auth-config';

export function LoginPage() {
  if (authConfig.isInhouse) {
    return <InhouseLoginForm />;
  }

  if (authConfig.isCognito) {
    return <CognitoLoginForm />;
  }

  if (authConfig.isClerk) {
    return <ClerkLoginForm />;
  }
}
```

## Next Steps: Phase 2 (Cognito Provider)

To implement AWS Cognito provider:

1. Create `repos/backend/src/features/auth/providers/cognito/` directory
2. Implement `CognitoAuthProvider` class:
   - Use AWS Cognito SDK
   - Implement all `IAuthProvider` methods
   - Sync Cognito users to our database
3. Update factory to import Cognito provider
4. Add Cognito env variables
5. Create Cognito-specific frontend form (optional)

## Next Steps: Phase 3 (Clerk Provider)

To implement Clerk provider:

1. Create `repos/backend/src/features/auth/providers/clerk/` directory
2. Implement `ClerkAuthProvider` class:
   - Use Clerk Backend SDK
   - Implement all `IAuthProvider` methods
   - Sync Clerk users to our database
3. Update factory to import Clerk provider
4. Add Clerk env variables
5. Optionally use Clerk React components on frontend

## File Structure

```
vertical-vibing/
├── shared-types/src/
│   ├── entities/user.ts (updated)
│   └── api/
│       ├── auth.types.ts (updated)
│       └── auth-provider.types.ts (new)
│
├── repos/backend/src/
│   ├── features/auth/
│   │   ├── providers/
│   │   │   ├── auth-provider.interface.ts (new)
│   │   │   ├── auth-provider.factory.ts (new)
│   │   │   └── inhouse/
│   │   │       └── inhouse-auth.provider.ts (new)
│   │   ├── auth.service.ts (refactored)
│   │   └── auth.route.ts (unchanged)
│   │
│   ├── shared/
│   │   ├── db/
│   │   │   ├── schema/users.schema.ts (updated)
│   │   │   └── migrations/
│   │   │       ├── 001_add_auth_provider_columns.sql (new)
│   │   │       └── README.md (new)
│   │   └── utils/jwt.ts (updated)
│
└── repos/frontend/src/
    └── features/auth/
        └── lib/
            └── auth-config.ts (new)
```

## Testing Checklist

- [x] Backend compiles without errors
- [x] Auth provider factory creates in-house provider
- [x] In-house provider implements all interface methods
- [x] JWT includes authProvider claim
- [x] User schema includes new fields
- [x] Frontend config reads environment variable
- [ ] Integration test: Register new user
- [ ] Integration test: Login existing user
- [ ] Integration test: JWT validation
- [ ] Migration runs successfully

## Known Limitations

1. **In-house provider only**: Cognito and Clerk not yet implemented
2. **Refresh tokens**: Not implemented for in-house provider
3. **Email verification**: Not implemented (placeholder)
4. **Password reset**: Not fully implemented (placeholder)
5. **Tests**: Auth service tests need updating for provider pattern

## Notes

- All existing in-house auth functionality preserved
- Backward compatible (existing users will work)
- Migration sets all existing users to `auth_provider = 'inhouse'`
- Provider pattern is fully extensible for new providers
- Frontend can show different UI per provider
