# Super Admin Implementation - God Mode

## Summary

Implemented a super admin "god mode" feature that provides full access to all features and companies. This is designed for development and staging environments only and includes proper safety guards to prevent use in production.

**Current Status:** ✅ Complete

## What Was Implemented

### 1. Database Schema

**Location:** `repos/backend/src/shared/db/schema/users.schema.ts`

- Added `is_super_admin` BOOLEAN column (default: false)
- Added comment and index for performance
- Non-nullable with default false for security

**Migration:** `repos/backend/src/shared/db/migrations/002_add_super_admin_column.sql`

### 2. Shared Types (Updated)

**Location:** `shared-types/src/`

- Updated `JWTPayload` to include optional `isSuperAdmin` flag
- Updated `User` schema to include `isSuperAdmin` boolean
- Updated `PublicUser` to include `isSuperAdmin` field

### 3. Backend Implementation

#### Bootstrap Service

**File:** `repos/backend/src/shared/services/super-admin-bootstrap.service.ts`

Auto-creates or updates super admin user on application startup:
- Reads credentials from environment variables
- Only runs in development/staging (blocks production)
- Validates email format and password strength
- Creates new user or updates existing user to super admin
- Logs creation/update with clear console output

#### Updated Auth Service

**File:** `repos/backend/src/features/auth/auth.service.ts`

- Includes `isSuperAdmin` flag in JWT token generation
- Returns `isSuperAdmin` in PublicUser response
- Properly syncs super admin status during login/register

#### Authorization Middleware Updates

**File:** `repos/backend/src/shared/middleware/authorize.ts`

Updated all authorization functions to bypass for super admins:
- `authorize()` - Main authorization with super admin bypass
- `authorizeOwn()` - Own resource authorization with bypass
- `requireModule()` - Module access with bypass
- `requireSuperadmin()` - Implemented proper check for super admin flag
- `checkPermission()` - Permission utility with bypass

All bypass operations log to console with 🦸 emoji for audit trail.

### 4. Frontend Components

#### Super Admin Badge

**File:** `repos/frontend/src/components/super-admin-badge.tsx`

Visual indicator showing super admin status:
- Fixed position in top-right corner
- Purple/pink gradient background
- Lightning bolt icon
- Only visible when `user.isSuperAdmin` is true

#### Company Selector

**File:** `repos/frontend/src/components/super-admin-company-selector.tsx`

Allows super admins to switch company context:
- Fixed position in bottom-left corner
- Fetches all companies from API
- Dropdown selector with company list
- Stores selection in localStorage
- Reloads page to apply new company context
- Only visible to super admin users

### 5. Application Startup

**File:** `repos/backend/src/index.ts`

Bootstrap service runs on every server start:
```typescript
SuperAdminBootstrapService.initialize().catch((error) => {
  console.error('Failed to initialize super admin:', error);
});
```

## How to Use

### Backend Configuration

Set these environment variables in `repos/backend/.env`:

```bash
# Super Admin Configuration (DEV/STAGING ONLY)
SUPER_ADMIN_ENABLED=true
SUPER_ADMIN_EMAIL=admin@yourdomain.com
SUPER_ADMIN_PASSWORD=YourSecurePassword123
```

### Environment Requirements

- **SUPER_ADMIN_ENABLED**: Must be set to `"true"` to enable
- **SUPER_ADMIN_EMAIL**: Valid email address for super admin
- **SUPER_ADMIN_PASSWORD**: Minimum 8 characters
- **NODE_ENV**: Must be `"development"` or `"staging"` (blocks production)

### Safety Features

1. **Environment Restriction**: Only runs in development/staging
2. **Explicit Enable**: Must set `SUPER_ADMIN_ENABLED=true`
3. **Validation**: Email format and password strength checks
4. **Audit Logging**: All super admin actions logged with 🦸 indicator
5. **Production Block**: Automatically disabled if `NODE_ENV=production`

### Login Process

1. Start the backend server
2. Check console for super admin initialization:
   ```
   ✅ Super admin created: admin@yourdomain.com
   🦸 Super admin mode: ENABLED
      Environment: development
      Email: admin@yourdomain.com
   ```
3. Login through normal `/api/auth/login` endpoint
4. JWT will include `isSuperAdmin: true`
5. Frontend will show:
   - Purple "SUPER ADMIN" badge (top-right)
   - Company selector button (bottom-left)

### Using Super Admin

**Full Access:**
- Bypass all permission checks automatically
- Access all views regardless of IAM settings
- Perform all actions (Create, Read, Update, Delete)
- Access all modules regardless of subscription
- No company context required (but can be set)

**Company Switching:**
1. Click "Switch Company" button (bottom-left)
2. Select a company from dropdown
3. Page reloads with new company context
4. All API calls will use selected company

**Audit Trail:**
Console logs show all super admin actions:
```
🦸 Super admin bypass: admin@yourdomain.com accessing /api/users
🦸 Super admin bypass: admin@yourdomain.com accessing module module_risks
🦸 Super admin access granted: admin@yourdomain.com
```

## Architecture Benefits

### Security

- **Environment-based**: Can't accidentally enable in production
- **Explicit opt-in**: Requires `SUPER_ADMIN_ENABLED=true`
- **Database-backed**: Super admin status stored in database
- **JWT-based**: Status included in token, can't be spoofed
- **Audit logging**: All actions logged for security review

### Development Efficiency

- **No permission setup needed**: Instantly access all features
- **Fast company switching**: Test multi-tenant scenarios quickly
- **Visual indicators**: Always know when in god mode
- **Auto-creation**: No manual database setup required

### Flexibility

- **Multiple super admins**: Can create multiple accounts if needed
- **Easy toggle**: Enable/disable with environment variable
- **Reversible**: Can revoke super admin status anytime
- **Works with providers**: Compatible with all auth providers (in-house, Cognito, Clerk)

## API Changes

### JWT Token Structure (Updated)

```json
{
  "userId": "uuid-here",
  "email": "admin@yourdomain.com",
  "authProvider": "inhouse",
  "isSuperAdmin": true,
  "iat": 1234567890,
  "exp": 1234567890
}
```

### User Response (Updated)

```json
{
  "id": "uuid-here",
  "email": "admin@yourdomain.com",
  "name": "Super Admin",
  "avatarUrl": null,
  "authProvider": "inhouse",
  "externalId": null,
  "isSuperAdmin": true,
  "createdAt": "2025-11-20T00:00:00.000Z",
  "updatedAt": "2025-11-20T00:00:00.000Z"
}
```

## Frontend Integration

### Adding Components to Layout

```tsx
// repos/frontend/src/app/layout.tsx
import { SuperAdminBadge } from '@/components/super-admin-badge';
import { SuperAdminCompanySelector } from '@/components/super-admin-company-selector';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <SuperAdminBadge />
        <SuperAdminCompanySelector />
        {children}
      </body>
    </html>
  );
}
```

### Checking Super Admin Status

```tsx
import { useAuth } from '@/features/auth/hooks/useAuth';

function MyComponent() {
  const { user } = useAuth();

  if (user?.isSuperAdmin) {
    // Show admin-only features
  }
}
```

## Testing Checklist

- [x] Database migration runs successfully
- [x] Backend compiles without errors
- [x] Super admin bootstrap creates user on startup
- [x] Super admin can login with credentials
- [x] JWT includes isSuperAdmin flag
- [x] Authorization bypass works (all middleware functions)
- [x] Frontend badge displays for super admin
- [x] Company selector displays for super admin
- [x] Audit logs show super admin actions
- [ ] Integration test: Super admin can access restricted views
- [ ] Integration test: Super admin can perform restricted actions
- [ ] Integration test: Company switching works correctly
- [ ] Integration test: Production environment blocks super admin

## Security Considerations

### Disable in Production

**IMPORTANT:** Always ensure production environment has:
```bash
NODE_ENV=production
SUPER_ADMIN_ENABLED=false
# Or simply omit SUPER_ADMIN_* variables
```

The code will automatically block super admin creation in production, but it's best practice to explicitly disable it.

### Rate Limiting

Super admin accounts are subject to the same rate limiting as normal users. This prevents abuse even if credentials are compromised.

### Audit Requirements

All super admin actions are logged to console. For production-like staging environments, consider:
- Storing audit logs to database
- Sending alerts when super admin is used
- Regular review of super admin access logs

### Password Security

Use strong passwords for super admin accounts:
- Minimum 8 characters (enforced)
- Recommended: 16+ characters with mix of types
- Use password manager to generate/store
- Rotate credentials regularly

## Removing Super Admin Access

### Temporary Disable

```bash
# In .env file
SUPER_ADMIN_ENABLED=false
```

Restart server. Existing super admin can still login but won't have bypass privileges.

### Permanent Removal

```typescript
// One-time script or database query
await SuperAdminBootstrapService.disableAllSuperAdmins();
```

Or direct SQL:
```sql
UPDATE users SET is_super_admin = false WHERE is_super_admin = true;
```

## File Structure

```
vertical-vibing/
├── shared-types/src/
│   ├── entities/user.ts (updated with isSuperAdmin)
│   └── api/auth.types.ts (updated with isSuperAdmin)
│
├── repos/backend/
│   ├── src/
│   │   ├── index.ts (calls bootstrap on startup)
│   │   ├── features/auth/auth.service.ts (includes flag in JWT)
│   │   ├── shared/
│   │   │   ├── db/
│   │   │   │   ├── schema/users.schema.ts (added is_super_admin column)
│   │   │   │   └── migrations/
│   │   │   │       └── 002_add_super_admin_column.sql
│   │   │   ├── middleware/authorize.ts (bypass logic added)
│   │   │   └── services/super-admin-bootstrap.service.ts
│
└── repos/frontend/src/
    └── components/
        ├── super-admin-badge.tsx
        └── super-admin-company-selector.tsx
```

## Troubleshooting

### Super admin not created

Check console output:
- `⚠️  Super admin disabled in production environment` - Running in production
- `ℹ️  Super admin disabled (SUPER_ADMIN_ENABLED=false)` - Not enabled
- `⚠️  Super admin enabled but credentials missing` - Missing env vars
- `❌ Invalid super admin email format` - Email validation failed
- `❌ Super admin password must be at least 8 characters` - Password too short

### Permissions still denied

- Check JWT includes `isSuperAdmin: true`
- Verify middleware has super admin bypass logic
- Check console for `🦸 Super admin bypass` messages
- Ensure you're using updated authorization middleware

### Badge not showing

- Verify `useAuth()` hook returns user with `isSuperAdmin: true`
- Check component is imported in layout
- Verify user is logged in
- Check browser console for React errors

### Company selector not working

- Verify `/api/companies` endpoint exists and returns data
- Check localStorage for `superAdminSelectedCompanyId`
- Ensure proper authentication token is sent
- Check network tab for API call errors

## Future Enhancements

Potential improvements for future iterations:

1. **Database Audit Logs**: Store super admin actions in database instead of just console
2. **Email Alerts**: Send notifications when super admin is used
3. **Session Tracking**: Track active super admin sessions
4. **Impersonation Mode**: Allow super admin to "become" another user temporarily
5. **Feature Flags**: Fine-grained control over which features super admin can bypass
6. **Time Limits**: Auto-expire super admin sessions after certain duration
7. **Multi-Factor Auth**: Require additional verification for super admin login

## Notes

- Super admin uses normal login flow (no special endpoint)
- Compatible with all auth providers (in-house, Cognito, Clerk)
- Status persists across login sessions
- Bootstrap runs every time server starts (idempotent)
- Frontend components are optional (can use without UI)
