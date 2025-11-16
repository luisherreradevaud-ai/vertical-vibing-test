# Error Catalog

**Purpose:** Standardized error codes and messages for consistent error handling across all features.

---

## Error Format Standard (STRICT)

All operational errors MUST use this format:

```typescript
{
  "status": "error",
  "code": "ERR_CATEGORY_###",
  "message": "Human-readable message",
  "field": "fieldName",  // Optional - for validation errors
  "timestamp": "2025-11-16T12:00:00.000Z",  // Optional - for debugging
  "requestId": "uuid"  // Optional - for tracing
}
```

### Usage in Code

```typescript
// ✅ Good - Using AppError with code
throw new AppError(400, 'Invalid email format', 'ERR_VALIDATION_001');

// ✅ Good - With field information
throw new AppError(400, 'Invalid email format', 'ERR_VALIDATION_001', {
  field: 'email'
});

// ❌ Bad - No error code
throw new AppError(400, 'Invalid email');

// ❌ Bad - Generic Error
throw new Error('something went wrong');
```

---

## Error Code Registry

### Validation Errors (ERR_VALIDATION_###)

Format and input validation errors.

| Code | HTTP | Message Template | When to Use |
|------|------|------------------|-------------|
| `ERR_VALIDATION_001` | 400 | "Invalid email format" | Email doesn't match email pattern |
| `ERR_VALIDATION_002` | 400 | "Password too short (minimum 8 characters)" | Password < min length |
| `ERR_VALIDATION_003` | 400 | "Required field missing: {field}" | Required field not provided |
| `ERR_VALIDATION_004` | 400 | "Invalid {field} format" | Field format incorrect |
| `ERR_VALIDATION_005` | 400 | "{field} must be between {min} and {max}" | Value out of range |
| `ERR_VALIDATION_006` | 400 | "Invalid UUID format for {field}" | UUID validation failed |
| `ERR_VALIDATION_007` | 400 | "{field} must be a positive number" | Negative value not allowed |
| `ERR_VALIDATION_008` | 400 | "{field} contains invalid characters" | Special chars not allowed |
| `ERR_VALIDATION_009` | 400 | "Invalid date format for {field}" | Date parsing failed |
| `ERR_VALIDATION_010` | 400 | "{field} exceeds maximum length of {max}" | String too long |

**Example:**
```typescript
const createUserSchema = z.object({
  email: z.string().email('Invalid email format'),  // ERR_VALIDATION_001
  password: z.string().min(8, 'Password too short (minimum 8 characters)'),  // ERR_VALIDATION_002
});
```

---

### Authentication Errors (ERR_AUTH_###)

Authentication and authorization errors.

| Code | HTTP | Message | When to Use |
|------|------|---------|-------------|
| `ERR_AUTH_001` | 401 | "Invalid credentials" | Wrong email/password |
| `ERR_AUTH_002` | 401 | "Authentication token expired" | JWT expired |
| `ERR_AUTH_003` | 401 | "Authentication token invalid" | Malformed/invalid JWT |
| `ERR_AUTH_004` | 401 | "Authentication required" | No token provided |
| `ERR_AUTH_005` | 403 | "Insufficient permissions" | User lacks required role/permission |
| `ERR_AUTH_006` | 403 | "Account suspended" | User account is suspended |
| `ERR_AUTH_007` | 403 | "Email not verified" | Action requires verified email |
| `ERR_AUTH_008` | 401 | "Session expired" | Session timeout |
| `ERR_AUTH_009` | 429 | "Too many login attempts" | Rate limit exceeded |
| `ERR_AUTH_010` | 403 | "IP address blocked" | Suspicious activity |

**Example:**
```typescript
if (!token) {
  throw new AppError(401, 'Authentication required', 'ERR_AUTH_004');
}

if (!user.isEmailVerified) {
  throw new AppError(403, 'Email not verified', 'ERR_AUTH_007');
}
```

---

### Resource Errors (ERR_RESOURCE_###)

Resource not found, already exists, or conflict errors.

| Code | HTTP | Message Template | When to Use |
|------|------|------------------|-------------|
| `ERR_RESOURCE_001` | 404 | "{Resource} not found" | Resource doesn't exist |
| `ERR_RESOURCE_002` | 409 | "{Resource} already exists" | Duplicate resource creation |
| `ERR_RESOURCE_003` | 409 | "Cannot delete {resource}: still in use" | FK constraint violation |
| `ERR_RESOURCE_004` | 409 | "{Resource} has been modified" | Optimistic locking conflict |
| `ERR_RESOURCE_005` | 410 | "{Resource} has been deleted" | Soft-deleted resource accessed |
| `ERR_RESOURCE_006` | 404 | "No {resources} found matching criteria" | Empty result set |
| `ERR_RESOURCE_007` | 409 | "{Resource} is locked" | Resource being modified by another process |
| `ERR_RESOURCE_008` | 400 | "Invalid {resource} ID" | Malformed resource identifier |

**Example:**
```typescript
const user = await this.repository.findById(id);
if (!user) {
  throw new AppError(404, 'User not found', 'ERR_RESOURCE_001');
}

const exists = await this.repository.emailExists(email);
if (exists) {
  throw new AppError(409, 'User already exists', 'ERR_RESOURCE_002');
}
```

---

### Business Logic Errors (ERR_BUSINESS_###)

Business rule violations.

| Code | HTTP | Message | When to Use |
|------|------|---------|-------------|
| `ERR_BUSINESS_001` | 422 | "Insufficient balance" | Payment/withdrawal fails due to balance |
| `ERR_BUSINESS_002` | 422 | "Order cannot be modified after shipment" | State transition not allowed |
| `ERR_BUSINESS_003` | 422 | "Product out of stock" | Inventory insufficient |
| `ERR_BUSINESS_004` | 422 | "Discount code expired" | Promotional code no longer valid |
| `ERR_BUSINESS_005` | 422 | "Maximum quantity exceeded" | Quantity > allowed limit |
| `ERR_BUSINESS_006` | 422 | "Minimum order amount not met" | Order total < minimum |
| `ERR_BUSINESS_007` | 422 | "Refund amount exceeds original payment" | Invalid refund amount |
| `ERR_BUSINESS_008` | 422 | "Cannot cancel completed transaction" | Transaction in final state |
| `ERR_BUSINESS_009` | 422 | "Age requirement not met" | User age < required |
| `ERR_BUSINESS_010` | 422 | "Geographic restriction applies" | Service not available in location |

**Example:**
```typescript
if (product.stock < quantity) {
  throw new AppError(422, 'Product out of stock', 'ERR_BUSINESS_003');
}

if (order.status === 'shipped') {
  throw new AppError(422, 'Order cannot be modified after shipment', 'ERR_BUSINESS_002');
}
```

---

### External Service Errors (ERR_EXTERNAL_###)

Third-party service integration errors.

| Code | HTTP | Message | When to Use |
|------|------|---------|-------------|
| `ERR_EXTERNAL_001` | 503 | "Payment service unavailable" | Payment gateway down |
| `ERR_EXTERNAL_002` | 502 | "Email service error" | Email sending failed |
| `ERR_EXTERNAL_003` | 503 | "Storage service unavailable" | File upload service down |
| `ERR_EXTERNAL_004` | 502 | "API rate limit exceeded" | Third-party rate limit hit |
| `ERR_EXTERNAL_005` | 504 | "External service timeout" | Third-party request timed out |
| `ERR_EXTERNAL_006` | 502 | "Invalid response from external service" | Unexpected response format |
| `ERR_EXTERNAL_007` | 503 | "Database unavailable" | Database connection failed |
| `ERR_EXTERNAL_008` | 502 | "SMS service error" | SMS sending failed |

**Example:**
```typescript
try {
  await emailService.send(email);
} catch (error) {
  logger.error('Email service error', { error });
  throw new AppError(502, 'Email service error', 'ERR_EXTERNAL_002');
}
```

---

### Rate Limiting Errors (ERR_RATE_###)

Rate limiting and quota errors.

| Code | HTTP | Message | When to Use |
|------|------|---------|-------------|
| `ERR_RATE_001` | 429 | "Too many requests" | General rate limit exceeded |
| `ERR_RATE_002` | 429 | "Daily quota exceeded" | Daily limit reached |
| `ERR_RATE_003` | 429 | "Concurrent request limit exceeded" | Too many simultaneous requests |
| `ERR_RATE_004` | 429 | "API quota exhausted" | API usage limit reached |

**Example:**
```typescript
if (requestCount > RATE_LIMIT) {
  throw new AppError(429, 'Too many requests', 'ERR_RATE_001', {
    retryAfter: 60  // Retry after 60 seconds
  });
}
```

---

### File/Upload Errors (ERR_FILE_###)

File upload and processing errors.

| Code | HTTP | Message | When to Use |
|------|------|---------|-------------|
| `ERR_FILE_001` | 400 | "File too large (max {size}MB)" | File exceeds size limit |
| `ERR_FILE_002` | 400 | "Invalid file type" | File extension/MIME not allowed |
| `ERR_FILE_003` | 400 | "No file uploaded" | File expected but not provided |
| `ERR_FILE_004` | 422 | "File corrupted" | File cannot be processed |
| `ERR_FILE_005` | 507 | "Storage quota exceeded" | No storage space left |
| `ERR_FILE_006` | 400 | "Filename contains invalid characters" | Filename validation failed |

**Example:**
```typescript
if (!file) {
  throw new AppError(400, 'No file uploaded', 'ERR_FILE_003');
}

if (file.size > MAX_FILE_SIZE) {
  throw new AppError(400, `File too large (max ${MAX_FILE_SIZE}MB)`, 'ERR_FILE_001');
}
```

---

### Internal Errors (ERR_INTERNAL_###)

Unexpected server errors (should be rare).

| Code | HTTP | Message | When to Use |
|------|------|---------|-------------|
| `ERR_INTERNAL_001` | 500 | "Internal server error" | Unexpected exception |
| `ERR_INTERNAL_002` | 500 | "Configuration error" | Missing/invalid config |
| `ERR_INTERNAL_003` | 500 | "Database query error" | Unexpected DB error |
| `ERR_INTERNAL_004` | 500 | "Data integrity violation" | Unexpected constraint violation |

**Example:**
```typescript
try {
  // business logic
} catch (error) {
  logger.error('Unexpected error', { error, stack: error.stack });
  throw new AppError(500, 'Internal server error', 'ERR_INTERNAL_001');
}
```

**Note:** Internal errors should be logged with full details but shown to users generically.

---

## Error Response Format Examples

### Single Field Validation Error

```json
{
  "status": "error",
  "code": "ERR_VALIDATION_001",
  "message": "Invalid email format",
  "field": "email",
  "timestamp": "2025-11-16T12:00:00.000Z"
}
```

### Multiple Validation Errors

```json
{
  "status": "error",
  "code": "ERR_VALIDATION_003",
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email format",
      "code": "ERR_VALIDATION_001"
    },
    {
      "field": "password",
      "message": "Password too short (minimum 8 characters)",
      "code": "ERR_VALIDATION_002"
    }
  ],
  "timestamp": "2025-11-16T12:00:00.000Z"
}
```

### Business Logic Error

```json
{
  "status": "error",
  "code": "ERR_BUSINESS_003",
  "message": "Product out of stock",
  "details": {
    "productId": "uuid",
    "requested": 10,
    "available": 3
  },
  "timestamp": "2025-11-16T12:00:00.000Z"
}
```

### Resource Not Found

```json
{
  "status": "error",
  "code": "ERR_RESOURCE_001",
  "message": "User not found",
  "timestamp": "2025-11-16T12:00:00.000Z"
}
```

---

## Implementation Guide

### In Services

```typescript
export class ProductsService {
  async getProductById(id: string): Promise<Product> {
    const product = await this.repository.findById(id);

    if (!product) {
      throw new AppError(
        404,
        'Product not found',
        'ERR_RESOURCE_001'
      );
    }

    if (!product.isActive) {
      throw new AppError(
        410,
        'Product has been deleted',
        'ERR_RESOURCE_005'
      );
    }

    return product;
  }

  async createProduct(input: CreateProductInput): Promise<Product> {
    if (input.stock < 0) {
      throw new AppError(
        400,
        'Stock must be a positive number',
        'ERR_VALIDATION_007',
        { field: 'stock' }
      );
    }

    return this.repository.create(input);
  }
}
```

### In Error Handler Middleware

```typescript
export function errorHandler(
  err: Error,
  req: Request,
  res: Response,
  next: NextFunction
) {
  // Zod validation errors
  if (err instanceof ZodError) {
    return res.status(400).json({
      status: 'error',
      code: 'ERR_VALIDATION_003',
      message: 'Validation failed',
      errors: err.errors.map((e) => ({
        field: e.path.join('.'),
        message: e.message,
      })),
      timestamp: new Date().toISOString(),
    });
  }

  // Application errors (with error codes)
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      status: 'error',
      code: err.code || 'ERR_INTERNAL_001',
      message: err.message,
      ...(err.metadata && { details: err.metadata }),
      timestamp: new Date().toISOString(),
    });
  }

  // Unexpected errors (no error code)
  logger.error('Unexpected error', {
    error: err.message,
    stack: err.stack
  });

  return res.status(500).json({
    status: 'error',
    code: 'ERR_INTERNAL_001',
    message: process.env.NODE_ENV === 'production'
      ? 'Internal server error'
      : err.message,
    timestamp: new Date().toISOString(),
  });
}
```

### Updated AppError Class

```typescript
export class AppError extends Error {
  constructor(
    public statusCode: number,
    message: string,
    public code?: string,  // Error code from catalog
    public metadata?: Record<string, any>,  // Additional context
    public isOperational = true
  ) {
    super(message);
    Object.setPrototypeOf(this, AppError.prototype);
  }
}
```

---

## Adding New Error Codes

When you need a new error code:

1. **Check if existing code fits** - Don't create duplicates
2. **Choose appropriate category** - Validation, Auth, Resource, Business, etc.
3. **Use next available number** - e.g., ERR_VALIDATION_011
4. **Add to this catalog** - Document it here
5. **Use consistently** - All similar errors should use same code

**Template for New Error:**

| Code | HTTP | Message | When to Use |
|------|------|---------|-------------|
| `ERR_CATEGORY_###` | XXX | "Error message" | Specific scenario |

---

## Best Practices

### ✅ Do:
- Always include error code for operational errors
- Use consistent message format
- Log internal errors with full details
- Return generic messages for security errors
- Include `field` for validation errors
- Add `timestamp` for debugging

### ❌ Don't:
- Expose stack traces to clients (production)
- Use generic error messages ("Error occurred")
- Create error codes for every minor variation
- Include sensitive data in error responses
- Skip logging internal errors

---

## Error Code Quick Reference

| Category | Prefix | HTTP Range | Count |
|----------|--------|------------|-------|
| Validation | ERR_VALIDATION_ | 400 | 10 |
| Authentication | ERR_AUTH_ | 401, 403, 429 | 10 |
| Resource | ERR_RESOURCE_ | 404, 409, 410 | 8 |
| Business Logic | ERR_BUSINESS_ | 422 | 10 |
| External Service | ERR_EXTERNAL_ | 502, 503, 504 | 8 |
| Rate Limiting | ERR_RATE_ | 429 | 4 |
| File/Upload | ERR_FILE_ | 400, 422, 507 | 6 |
| Internal | ERR_INTERNAL_ | 500 | 4 |

**Total Error Codes Defined:** 60

---

**This catalog should be the single source of truth for all error codes in the application.**
