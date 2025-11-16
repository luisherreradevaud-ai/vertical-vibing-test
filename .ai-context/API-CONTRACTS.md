# API Contract Standards

**Purpose:** Strict, consistent API response formats and endpoint conventions across all features.

**Rule:** EVERY endpoint MUST follow these standards. No exceptions.

---

## Response Format Standards (STRICT)

### Success Response

```typescript
{
  "status": "success",
  "data": T  // The actual data
}
```

**Example:**
```json
{
  "status": "success",
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "createdAt": "2025-11-16T12:00:00.000Z"
  }
}
```

### Created Response (201)

```typescript
{
  "status": "success",
  "data": T  // The created resource
}
```

**Example:**
```json
{
  "status": "success",
  "data": {
    "id": "uuid",
    "name": "New Product",
    "createdAt": "2025-11-16T12:00:00.000Z"
  }
}
```

### Error Response

```typescript
{
  "status": "error",
  "code": "ERR_CATEGORY_###",  // From ERROR-CATALOG.md
  "message": "Human-readable error message"
}
```

**Example:**
```json
{
  "status": "error",
  "code": "ERR_RESOURCE_001",
  "message": "User not found"
}
```

### Validation Error Response

```typescript
{
  "status": "error",
  "code": "ERR_VALIDATION_003",
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email format",
      "code": "ERR_VALIDATION_001"
    }
  ]
}
```

### Paginated Response

```typescript
{
  "status": "success",
  "data": T[],  // Array of items
  "pagination": {
    "total": number,      // Total items in database
    "limit": number,      // Items per page
    "offset": number,     // Starting position
    "hasNext": boolean,   // More pages available
    "hasPrev": boolean    // Previous pages available
  }
}
```

**Example:**
```json
{
  "status": "success",
  "data": [
    { "id": "1", "name": "Product 1" },
    { "id": "2", "name": "Product 2" }
  ],
  "pagination": {
    "total": 150,
    "limit": 20,
    "offset": 0,
    "hasNext": true,
    "hasPrev": false
  }
}
```

### No Content Response (204)

No body, just HTTP 204 status.

**When to use:** DELETE operations, UPDATE operations where no data needs to be returned.

---

## HTTP Status Codes (STRICT)

### Success Codes

| Code | Name | When to Use | Example |
|------|------|-------------|---------|
| 200 | OK | Successful GET, PUT, PATCH | Get user, update product |
| 201 | Created | Successful POST (resource created) | Create user, create order |
| 204 | No Content | Successful DELETE, or update with no return | Delete product |

### Client Error Codes

| Code | Name | When to Use | Example |
|------|------|-------------|---------|
| 400 | Bad Request | Invalid input format, validation error | Invalid email, missing field |
| 401 | Unauthorized | Missing or invalid authentication | No token, expired token |
| 403 | Forbidden | Authenticated but insufficient permissions | User not admin |
| 404 | Not Found | Resource doesn't exist | User ID doesn't exist |
| 409 | Conflict | Resource already exists, state conflict | Email already registered |
| 422 | Unprocessable Entity | Business logic violation | Insufficient balance |
| 429 | Too Many Requests | Rate limit exceeded | Too many login attempts |

### Server Error Codes

| Code | Name | When to Use | Example |
|------|------|-------------|---------|
| 500 | Internal Server Error | Unexpected server error | Unhandled exception |
| 502 | Bad Gateway | External service error | Payment gateway down |
| 503 | Service Unavailable | Service temporarily down | Database unavailable |
| 504 | Gateway Timeout | External service timeout | API call timed out |

---

## Endpoint Naming Conventions (STRICT)

### RESTful Resource Patterns

```
✅ CORRECT PATTERNS:

GET    /api/users              # List all users
GET    /api/users/:id          # Get specific user
POST   /api/users              # Create new user
PUT    /api/users/:id          # Full update (replace)
PATCH  /api/users/:id          # Partial update
DELETE /api/users/:id          # Delete user

GET    /api/users/:id/orders   # Get user's orders (nested resource)
POST   /api/users/:id/orders   # Create order for user
```

```
❌ INCORRECT PATTERNS:

GET    /api/getUsers           # Don't use verbs in URL (GET is the verb)
POST   /api/createUser         # Don't use verbs in URL
GET    /api/user/:id           # Use plural (users, not user)
POST   /api/users/new          # Don't use /new (POST is create)
DELETE /api/users/:id/delete   # Don't use /delete (DELETE is the verb)
PUT    /api/updateUser/:id     # Don't use verbs
GET    /api/users/getUserById/:id  # Way too verbose
```

### Action Endpoints (Non-RESTful)

When REST doesn't fit (actions that aren't CRUD):

```
✅ CORRECT:

POST   /api/users/:id/verify-email      # Action: verify email
POST   /api/users/:id/reset-password    # Action: reset password
POST   /api/orders/:id/cancel           # Action: cancel order
POST   /api/orders/:id/ship             # Action: ship order
POST   /api/users/:id/deactivate        # Action: deactivate account
```

**Pattern:** `POST /api/:resource/:id/:action`

**Always use POST for actions** (even if read-only) because actions cause state changes.

### Search/Filter Endpoints

```
✅ CORRECT:

GET    /api/products?search=laptop         # Search
GET    /api/products?category=electronics  # Filter
GET    /api/products?minPrice=100          # Range filter
GET    /api/users?role=admin&active=true   # Multiple filters

GET    /api/products?sort=price&order=asc  # Sorting
GET    /api/products?limit=20&offset=40    # Pagination
```

```
❌ INCORRECT:

POST   /api/products/search    # Don't use POST for search
GET    /api/searchProducts     # Use query params instead
```

---

## Query Parameter Standards

### Pagination (REQUIRED for all list endpoints)

```typescript
GET /api/products?limit=20&offset=0

// Query params
limit: number   // Items per page (default: 20, max: 100)
offset: number  // Starting position (default: 0)
```

**Implementation:**
```typescript
const listQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0)
});
```

### Sorting

```typescript
GET /api/products?sort=createdAt&order=desc

// Query params
sort: string    // Field to sort by
order: 'asc' | 'desc'  // Sort direction (default: 'asc')
```

### Filtering

```typescript
GET /api/products?category=electronics&active=true

// Use descriptive field names
category: string
active: boolean
minPrice: number
maxPrice: number
```

### Search

```typescript
GET /api/products?search=laptop&fields=name,description

// Query params
search: string   // Search term
fields: string   // Comma-separated fields to search (optional)
```

---

## Request Body Standards

### POST (Create)

```json
{
  "email": "user@example.com",
  "password": "SecurePassword123",
  "firstName": "John",
  "lastName": "Doe"
}
```

**Rules:**
- Use camelCase for field names
- No `id` field (server generates)
- No `createdAt`/`updatedAt` (server generates)
- Only include fields the user can set

### PUT (Full Update)

```json
{
  "email": "newemail@example.com",
  "firstName": "John",
  "lastName": "Smith"
}
```

**Rules:**
- ALL fields must be provided (full replacement)
- Omitted fields are set to null/default
- Rarely used (prefer PATCH)

### PATCH (Partial Update)

```json
{
  "firstName": "Johnny"
}
```

**Rules:**
- Only changed fields
- Omitted fields are unchanged
- Prefer this over PUT

---

## Header Standards

### Request Headers

```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer <token>  # If authenticated
```

### Response Headers

```http
Content-Type: application/json
X-Request-ID: <uuid>           # For tracing
X-Response-Time: <ms>          # Response time in milliseconds
```

**Optional but recommended:**
```http
X-RateLimit-Limit: 100         # Rate limit
X-RateLimit-Remaining: 95      # Remaining requests
X-RateLimit-Reset: 1700000000  # Reset timestamp
```

---

## Date/Time Format Standards

### ALWAYS use ISO 8601

```json
{
  "createdAt": "2025-11-16T12:00:00.000Z",
  "updatedAt": "2025-11-16T13:30:00.000Z",
  "expiresAt": "2025-11-17T12:00:00.000Z"
}
```

**Rules:**
- UTC timezone (Z suffix)
- Millisecond precision
- Use `Date.toISOString()` in JavaScript

```typescript
// ✅ Good
const user = {
  createdAt: new Date().toISOString()
};

// ❌ Bad
const user = {
  createdAt: new Date().toString()  // Don't use
};
```

---

## Versioning

### URL Versioning (Recommended)

```
GET /api/v1/users
GET /api/v2/users
```

**When to increment version:**
- Breaking changes (field removed, renamed)
- Behavior changes that affect clients
- Response format changes

**Don't increment for:**
- Adding optional fields
- Adding new endpoints
- Bug fixes

### Implementation

```typescript
// v1 routes
app.use('/api/v1/users', createUsersRouterV1(db));

// v2 routes (breaking changes)
app.use('/api/v2/users', createUsersRouterV2(db));
```

---

## Response Helper Implementation

```typescript
// shared/utils/response.ts
import type { Response } from 'express';

export class ApiResponse {
  /**
   * Success response (200)
   */
  static success<T>(res: Response, data: T, statusCode = 200) {
    return res.status(statusCode).json({
      status: 'success',
      data,
    });
  }

  /**
   * Created response (201)
   */
  static created<T>(res: Response, data: T) {
    return res.status(201).json({
      status: 'success',
      data,
    });
  }

  /**
   * No content response (204)
   */
  static noContent(res: Response) {
    return res.status(204).send();
  }

  /**
   * Paginated response
   */
  static paginated<T>(
    res: Response,
    data: T[],
    total: number,
    limit: number,
    offset: number
  ) {
    return res.status(200).json({
      status: 'success',
      data,
      pagination: {
        total,
        limit,
        offset,
        hasNext: offset + limit < total,
        hasPrev: offset > 0,
      },
    });
  }

  /**
   * Error response
   */
  static error(res: Response, message: string, statusCode = 400, code?: string) {
    return res.status(statusCode).json({
      status: 'error',
      ...(code && { code }),
      message,
    });
  }
}
```

---

## Usage Examples

### List with Pagination

```typescript
router.get(
  '/',
  validateQuery(listQuerySchema),
  asyncHandler(async (req, res) => {
    const { limit, offset } = req.query;
    const { data, total } = await service.list(limit, offset);

    return ApiResponse.paginated(res, data, total, limit, offset);
  })
);
```

### Create Resource

```typescript
router.post(
  '/',
  validateBody(createSchema),
  asyncHandler(async (req, res) => {
    const resource = await service.create(req.body);
    return ApiResponse.created(res, resource);
  })
);
```

### Get Single Resource

```typescript
router.get(
  '/:id',
  validateParams(idSchema),
  asyncHandler(async (req, res) => {
    const resource = await service.getById(req.params.id);

    if (!resource) {
      throw new AppError(404, 'Resource not found', 'ERR_RESOURCE_001');
    }

    return ApiResponse.success(res, resource);
  })
);
```

### Update Resource

```typescript
router.patch(
  '/:id',
  validateParams(idSchema),
  validateBody(updateSchema),
  asyncHandler(async (req, res) => {
    const resource = await service.update(req.params.id, req.body);
    return ApiResponse.success(res, resource);
  })
);
```

### Delete Resource

```typescript
router.delete(
  '/:id',
  validateParams(idSchema),
  asyncHandler(async (req, res) => {
    await service.delete(req.params.id);
    return ApiResponse.noContent(res);
  })
);
```

### Action Endpoint

```typescript
router.post(
  '/:id/verify-email',
  validateParams(idSchema),
  validateBody(verifyEmailSchema),
  asyncHandler(async (req, res) => {
    const result = await service.verifyEmail(req.params.id, req.body.token);
    return ApiResponse.success(res, result);
  })
);
```

---

## Field Naming Conventions

### Use camelCase for JSON

```json
{
  "firstName": "John",
  "lastName": "Doe",
  "emailAddress": "john@example.com",
  "phoneNumber": "+1234567890",
  "isActive": true,
  "createdAt": "2025-11-16T12:00:00.000Z"
}
```

```
❌ INCORRECT:

{
  "first_name": "John",      # snake_case (use in database only)
  "FirstName": "John",       # PascalCase
  "EMAIL_ADDRESS": "...",    # UPPER_CASE
}
```

### Boolean Fields

Prefix with `is`, `has`, `can`, etc.

```typescript
// ✅ Good
{
  "isActive": true,
  "hasVerifiedEmail": false,
  "canEdit": true,
  "shouldNotify": false
}

// ❌ Bad
{
  "active": true,         # Not clear it's boolean
  "verified": false,      # Ambiguous
}
```

---

## Common Patterns

### Bulk Operations

```typescript
POST /api/users/bulk

// Request
{
  "users": [
    { "email": "user1@example.com", ... },
    { "email": "user2@example.com", ... }
  ]
}

// Response
{
  "status": "success",
  "data": {
    "created": 10,
    "failed": 2,
    "errors": [
      {
        "email": "invalid@",
        "error": "Invalid email format"
      }
    ]
  }
}
```

### File Upload

```typescript
POST /api/uploads
Content-Type: multipart/form-data

// Response
{
  "status": "success",
  "data": {
    "id": "uuid",
    "url": "https://cdn.example.com/file.jpg",
    "size": 1024000,
    "mimeType": "image/jpeg"
  }
}
```

---

## Testing API Contracts

Every endpoint should have tests verifying the contract:

```typescript
describe('GET /api/users', () => {
  it('should return success response with pagination', async () => {
    const response = await request(app).get('/api/users');

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('status', 'success');
    expect(response.body).toHaveProperty('data');
    expect(response.body).toHaveProperty('pagination');
    expect(response.body.pagination).toMatchObject({
      total: expect.any(Number),
      limit: expect.any(Number),
      offset: expect.any(Number),
      hasNext: expect.any(Boolean),
      hasPrev: expect.any(Boolean),
    });
  });
});
```

---

## Breaking Changes Checklist

Before making a breaking change, consider:

- [ ] Can this be additive instead? (add new field, keep old)
- [ ] Can we support both formats during transition?
- [ ] Do we need to version the API?
- [ ] Have we documented the migration path?
- [ ] Have we notified API consumers?

**Breaking changes include:**
- Removing a field from response
- Renaming a field
- Changing field type (string → number)
- Changing status codes (200 → 201)
- Removing an endpoint

**Non-breaking changes:**
- Adding optional field to request
- Adding field to response
- Adding new endpoint
- Making required field optional
- Fixing bugs

---

## Summary

**Core Principles:**
1. ✅ **Consistency** - All endpoints follow same patterns
2. ✅ **Predictability** - Response structure is always the same
3. ✅ **RESTful** - Use HTTP verbs correctly
4. ✅ **Clear errors** - Error codes from ERROR-CATALOG.md
5. ✅ **Pagination** - All list endpoints must paginate
6. ✅ **Versioning** - Breaking changes require version bump

**Response Format:**
- Success: `{ "status": "success", "data": T }`
- Error: `{ "status": "error", "code": "ERR_XXX", "message": "..." }`
- Paginated: Includes `pagination` object

**Endpoint Pattern:**
- `GET /api/:resources` - List
- `GET /api/:resources/:id` - Get one
- `POST /api/:resources` - Create
- `PATCH /api/:resources/:id` - Update
- `DELETE /api/:resources/:id` - Delete

**Use ApiResponse helper for all responses. No exceptions.**
