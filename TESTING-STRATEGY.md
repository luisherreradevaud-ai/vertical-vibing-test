# IAM System - Testing Strategy (Phase 7)

## Overview

This document outlines the comprehensive testing strategy for the IAM system across backend and frontend.

## Testing Infrastructure

### Backend: Vitest
- **Framework**: Vitest (already configured)
- **Coverage**: `@vitest/coverage-v8`
- **Commands**:
  - `npm test` - Run all tests
  - `npm run test:coverage` - Run with coverage report

### Frontend: Jest + React Testing Library
- **Framework**: Jest with Next.js
- **Component Testing**: React Testing Library
- **E2E**: Playwright or Cypress (to be configured)

## Phase 7 Testing Coverage

### 1. Unit Tests (Backend)

#### ✅ Tenant Validation Middleware
**File**: `src/shared/middleware/__tests__/tenantValidation.test.ts`
**Status**: Created

**Coverage**:
- `requireTenant()` - 6 test cases
- `validateTenantAccess()` - 4 test cases
- `enforceTenant()` - 4 test cases

**Test Cases**:
- ✅ Attach tenantId from user.companyId
- ✅ Attach tenantId from query.companyId
- ✅ Attach tenantId from body.companyId
- ✅ Prioritize user.companyId over query
- ✅ Return 400 if no companyId found
- ✅ Allow access when user company matches tenant
- ✅ Allow access when no tenant specified
- ✅ Deny access when user company does not match
- ✅ Return 401 if user has no companyId
- ✅ Combine requireTenant and validateTenantAccess
- ✅ Fail at requireTenant if no companyId
- ✅ Fail at validateTenantAccess if company mismatch
- ✅ Handle query companyId when user companyId matches

#### IAM Authorization Middleware
**File**: `src/features/iam/middleware/__tests__/iamAuthorization.test.ts`
**Status**: To be created

**Test Cases Needed**:
- `requireUserLevelManagement()`
  - Should allow when user has permission
  - Should deny when user lacks permission
  - Should return 403 with clear message
  - Should handle permission service errors

- `requirePermissionManagement()`
  - Should allow when user has permission
  - Should deny when user lacks permission
  - Should check Update action on feature_iam_permissions

- `requireUserAssignment()`
  - Should allow when user has permission
  - Should deny when user lacks permission

- `requireIAMRead()`
  - Should allow when user has Read on user_levels
  - Should allow when user has Read on permissions
  - Should deny when user has neither

#### Audit Service
**File**: `src/features/iam/__tests__/audit.service.test.ts`
**Status**: To be created

**Test Cases Needed**:
- Log operations
  - `logUserLevelCreated()` - Creates audit log with correct data
  - `logUserLevelUpdated()` - Logs changes
  - `logUserLevelDeleted()` - Logs deletion
  - `logViewPermissionsUpdated()` - Logs permission changes
  - `logFeaturePermissionsUpdated()` - Logs permission changes
  - `logUserLevelsAssigned()` - Logs assignments with before/after

- Query operations
  - `getLogsForCompany()` - Returns logs for company
  - `getLogsForCompany()` with filters - Filters by entityType, action, date range
  - `getLogsForEntity()` - Returns logs for specific entity
  - `getLogsForUser()` - Returns logs for specific user
  - Pagination and sorting

- Log management
  - Enforces max 10,000 log limit
  - Oldest logs are removed when limit reached
  - Logs are sorted by timestamp descending

#### Permissions Service (Phase 5)
**File**: `src/features/iam/__tests__/permissions.service.test.ts`
**Status**: To be created

**Test Cases Needed**:
- Permission resolution
  - `canAccessView()` - Resolves view permissions correctly
  - `canPerformAction()` - Resolves feature permissions correctly
  - Multi-level permission merging (deny > allow > inherit)
  - Scope hierarchy (any > team > company > own)
  - Module gating

- Caching
  - Cache hit returns cached data
  - Cache miss calculates permissions
  - `invalidateCachedPermissions()` clears cache
  - TTL expiration works

### 2. Integration Tests (Backend)

#### IAM Endpoints
**File**: `src/features/iam/__tests__/iam.route.integration.test.ts`
**Status**: To be created

**Test Suites**:

##### Navigation Endpoint
- `GET /api/iam/navigation`
  - Returns permission-filtered menu
  - Returns correct entrypoint
  - Filters based on view permissions
  - Filters based on feature permissions
  - Returns 401 without auth
  - Returns 400 without companyId
  - Returns 403 for wrong company
  - Returns ETag header
  - Returns 304 when ETag matches
  - Returns fresh data when ETag differs
  - Cache invalidates after TTL

##### Permissions Endpoint
- `GET /api/iam/permissions/current`
  - Returns all view permissions
  - Returns all feature permissions
  - Requires authentication
  - Requires tenant validation

##### User Levels CRUD
- `GET /api/iam/user-levels`
  - Returns all user levels for company
  - Requires IAM Read permission
  - Does not return other companies' levels

- `POST /api/iam/user-levels`
  - Creates user level
  - Returns 409 if name exists
  - Requires UserLevelManagement permission
  - Creates audit log

- `GET /api/iam/user-levels/:id`
  - Returns user level
  - Returns 404 if not found
  - Returns 404 if wrong company

- `PATCH /api/iam/user-levels/:id`
  - Updates user level
  - Returns 409 if name conflict
  - Creates audit log

- `DELETE /api/iam/user-levels/:id`
  - Deletes user level
  - Returns 400 if users assigned
  - Creates audit log

##### Permission Matrix Endpoints
- `GET /api/iam/user-levels/:id/permissions/views`
  - Returns view permissions for level

- `PUT /api/iam/user-levels/:id/permissions/views`
  - Updates view permissions
  - Invalidates navigation cache
  - Creates audit log

- `GET /api/iam/user-levels/:id/permissions/features`
  - Returns feature permissions for level

- `PUT /api/iam/user-levels/:id/permissions/features`
  - Updates feature permissions
  - Invalidates permission cache
  - Creates audit log

##### User Assignment Endpoints
- `GET /api/iam/users/:userId/user-levels`
  - Returns user's levels

- `PUT /api/iam/users/:userId/user-levels`
  - Updates user's levels
  - Invalidates caches
  - Creates audit log with before/after

### 3. Frontend Unit Tests

#### Permission Hooks
**File**: `src/features/iam/hooks/__tests__/usePermissions.test.ts`
**Status**: To be created

**Test Cases**:
- `useViewPermission(viewId)`
  - Returns canView = true when permission exists
  - Returns canView = false when denied
  - Returns isLoading during fetch

- `useFeaturePermission(featureId, action)`
  - Returns canPerform = true with correct scope
  - Returns canPerform = false when denied
  - Returns correct scope value

- `useFeatureActions(featureId)`
  - Returns batch permission check results
  - Optimizes multiple checks

- `usePermissionsActions()`
  - `loadAll()` fetches permissions
  - `refresh()` refetches permissions
  - Handles errors gracefully

#### Gate Components
**File**: `src/features/iam/components/__tests__/Gate.test.tsx`
**Status**: To be created

**Test Cases**:
- `<Gate view="..." >`
  - Renders children when permission granted
  - Renders fallback when permission denied
  - Shows loading state

- `<GateFeature feature="..." action="...">`
  - Renders children when action allowed
  - Checks scope correctly

- `<GateAny>` / `<GateAll>`
  - Handles multiple permission checks
  - OR logic for GateAny
  - AND logic for GateAll

#### GateButton Components
**File**: `src/features/iam/components/__tests__/GateButton.test.tsx`
**Status**: To be created

**Test Cases**:
- `<GateButton>`
  - Renders enabled when permission granted
  - Renders disabled when permission denied
  - Shows tooltip on disabled state

### 4. Frontend Component Tests

#### User Levels Manager
**File**: `src/features/iam/ui/__tests__/UserLevelsManager.test.tsx`
**Status**: To be created

**Test Cases**:
- Lists user levels for company
- Creates new user level
- Edits existing user level (inline)
- Deletes user level with confirmation
- Shows error when API fails
- Navigates to permission matrices

#### Permission Matrices
**Files**:
- `src/features/iam/ui/__tests__/ViewsPermissionMatrix.test.tsx`
- `src/features/iam/ui/__tests__/FeaturesPermissionMatrix.test.tsx`

**Test Cases**:
- Loads permissions for user level
- Updates tri-state permissions (views)
- Updates feature-action permissions with scope
- Detects unsaved changes
- Saves changes via API
- Shows non-modifiable permissions as read-only

#### User Levels Assignment
**File**: `src/features/iam/ui/__tests__/UserLevelsAssignment.test.tsx`
**Status**: To be created

**Test Cases**:
- Lists all available user levels
- Shows currently assigned levels
- Toggles level assignment
- Shows assignment summary
- Saves changes
- Shows warning when no levels assigned

### 5. E2E Tests

#### IAM Admin Flow
**File**: `e2e/iam-admin-flow.spec.ts`
**Status**: To be created

**Test Scenarios**:
1. **Create User Level**
   - Login as Client Admin
   - Navigate to User Levels Manager
   - Create new level "Manager"
   - Verify level appears in list

2. **Configure Permissions**
   - Click "Permissions" on Manager level
   - Set view permissions (allow Users, deny Settings)
   - Set feature permissions (allow User Create with company scope)
   - Save changes
   - Verify success message

3. **Assign to User**
   - Navigate to Users list
   - Click user "John Doe"
   - Click "User Levels"
   - Assign "Manager" level
   - Save changes
   - Verify assignment

4. **Test Permissions**
   - Logout
   - Login as John Doe
   - Verify can access Users page
   - Verify cannot access Settings page
   - Verify can create user with company scope
   - Verify cannot delete users (no permission)

#### Security Flow
**File**: `e2e/iam-security.spec.ts`
**Status**: To be created

**Test Scenarios**:
1. **Cross-Tenant Isolation**
   - Login as Company A admin
   - Try to access Company B's user levels (API call)
   - Verify 403 Forbidden

2. **Permission Enforcement**
   - Login as user without IAM permissions
   - Try to access User Levels Manager
   - Verify "Access Denied" message
   - Try API call to create user level
   - Verify 403 Forbidden

3. **Audit Trail**
   - Login as Client Admin
   - Create user level
   - Update permissions
   - Delete user level
   - Verify all actions logged (check console/API)

## Testing Best Practices

### Backend Tests

```typescript
// Mock dependencies
import { vi } from 'vitest';

describe('Feature', () => {
  beforeEach(() => {
    // Reset mocks
    vi.clearAllMocks();
  });

  it('should do something', async () => {
    // Arrange
    const mockData = {...};
    vi.mocked(dependency).mockResolvedValue(mockData);

    // Act
    const result = await service.method();

    // Assert
    expect(result).toEqual(expected);
    expect(dependency).toHaveBeenCalledWith(...);
  });
});
```

### Frontend Tests

```typescript
// Test with React Testing Library
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

describe('Component', () => {
  it('should render and interact', async () => {
    // Arrange
    const user = userEvent.setup();
    render(<Component />);

    // Act
    await user.click(screen.getByRole('button', { name: 'Click Me' }));

    // Assert
    await waitFor(() => {
      expect(screen.getByText('Success')).toBeInTheDocument();
    });
  });
});
```

### Integration Tests

```typescript
// Test HTTP endpoints
import request from 'supertest';
import { app } from '../index';

describe('POST /api/iam/user-levels', () => {
  it('should create user level', async () => {
    const response = await request(app)
      .post('/api/iam/user-levels')
      .set('Authorization', `Bearer ${validToken}`)
      .send({ name: 'Test Level', description: 'Test' });

    expect(response.status).toBe(201);
    expect(response.body.data.userLevel).toMatchObject({
      name: 'Test Level',
      description: 'Test',
    });
  });
});
```

## Coverage Goals

- **Backend**:
  - Middleware: 100% (critical security)
  - Services: 90%+
  - Routes: 85%+

- **Frontend**:
  - Hooks: 90%+
  - Components: 80%+
  - UI Components: 70%+

- **E2E**:
  - Critical flows: 100%
  - Happy paths: 100%
  - Error paths: 80%+

## Running Tests

### Backend
```bash
cd repos/backend

# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run specific test file
npm test -- tenantValidation.test.ts

# Watch mode
npm test -- --watch
```

### Frontend
```bash
cd repos/frontend

# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run E2E tests
npm run test:e2e
```

## Test Data

### Test Users
```typescript
const testUsers = {
  clientAdmin: {
    userId: 'user-admin',
    companyId: 'company-123',
    email: 'admin@company.com',
    permissions: ['feature_iam_user_levels:Update', 'feature_iam_permissions:Update'],
  },
  regularUser: {
    userId: 'user-regular',
    companyId: 'company-123',
    email: 'user@company.com',
    permissions: ['feature_users:Read'],
  },
  noPermissionsUser: {
    userId: 'user-none',
    companyId: 'company-123',
    email: 'none@company.com',
    permissions: [],
  },
};
```

### Test Companies
```typescript
const testCompanies = {
  companyA: { id: 'company-123', name: 'Company A' },
  companyB: { id: 'company-456', name: 'Company B' },
};
```

## CI/CD Integration

### GitHub Actions Workflow
```yaml
name: Tests

on: [push, pull_request]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      - run: cd repos/backend && npm install
      - run: cd repos/backend && npm test
      - run: cd repos/backend && npm run test:coverage

  frontend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      - run: cd repos/frontend && npm install
      - run: cd repos/frontend && npm test
      - run: cd repos/frontend && npm run test:coverage

  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      - run: npm run test:e2e
```

## Next Steps

1. ✅ Create tenant validation tests (DONE)
2. Create IAM authorization middleware tests
3. Create audit service tests
4. Create permissions service tests
5. Create integration tests for all IAM endpoints
6. Create frontend hook tests
7. Create frontend component tests
8. Create E2E test suite
9. Set up CI/CD pipeline
10. Achieve coverage goals

## Summary

Phase 7 testing provides comprehensive coverage across:
- **Unit Tests**: Individual functions and components
- **Integration Tests**: API endpoints with real database
- **Component Tests**: React components in isolation
- **E2E Tests**: Full user workflows

This multi-layered approach ensures the IAM system is robust, secure, and production-ready.
