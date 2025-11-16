# Decision Trees

**Purpose:** Eliminate AI guessing by providing clear decision paths for common scenarios.

---

## When to Extract Code to Shared

```
Is this logic used by multiple features?
├─ NO → Keep in feature (duplication is ok for 1-2 uses)
└─ YES → How many features use it?
    ├─ 2 features → Keep duplicated (prefer duplication over wrong abstraction)
    └─ 3+ features → Is the logic stable?
        ├─ NO (changes frequently) → Wait, keep duplicated
        └─ YES (stable, mature) → Extract to shared/
            ├─ Pure utility function → shared/utils/
            ├─ Business logic → Consider if it should be shared
            ├─ Database operation → shared/db/repositories/
            └─ Middleware → shared/middleware/
```

**Example:**
```typescript
// Used by 2 features → Keep duplicated
// features/users/utils/format-name.ts
// features/products/utils/format-name.ts

// Used by 5 features → Extract
// shared/utils/format-name.ts
```

---

## When to Use Repository Pattern vs Direct Query

```
What kind of database operation is this?
├─ Simple CRUD (findById, create, update, delete)
│   └─ Use BaseRepository methods
│       repository.findById(id)
│       repository.create(data)
│       repository.update(id, data)
│
├─ Feature-specific query (findByEmail, findActive, etc.)
│   └─ Add method to feature repository
│       class UsersRepository extends BaseRepository {
│         async findByEmail(email: string) { ... }
│       }
│
└─ Complex query used by multiple features
    └─ Consider adding to BaseRepository (rare)
```

**Decision Matrix:**

| Query Type | Location | Example |
|------------|----------|---------|
| Generic CRUD | BaseRepository | `findById`, `create`, `update` |
| Feature-specific | Feature Repository | `findByEmail`, `findActiveProducts` |
| Multi-feature complex | BaseRepository (carefully) | `findWithRelations` |
| One-off complex | Inline in service | Complex joins for specific use case |

---

## When to Add DDD Layers Inside a Feature

```
Analyze the feature complexity:

Does the feature have complex business rules?
├─ NO (simple CRUD) → Keep flat VSA structure
│   src/features/my-feature/
│   ├── FEATURE.md
│   ├── my-feature.route.ts
│   ├── my-feature.service.ts
│   └── my-feature.repository.ts
│
└─ YES → How many business rules?
    ├─ 1-5 rules → Keep flat VSA (add comments explaining rules)
    │
    ├─ 5-10 rules → Add domain/ folder for entities
    │   src/features/my-feature/
    │   ├── FEATURE.md
    │   ├── domain/
    │   │   └── my-feature.entity.ts  (business rules here)
    │   ├── my-feature.route.ts
    │   ├── my-feature.service.ts
    │   └── my-feature.repository.ts
    │
    └─ 10+ rules → Use full DDD layers
        src/features/my-feature/
        ├── FEATURE.md
        ├── domain/
        │   ├── entities/
        │   ├── value-objects/
        │   └── events/
        ├── application/
        │   └── use-cases/
        ├── infrastructure/
        │   └── repositories/
        └── presentation/
            └── routes/
```

**Business Rule Examples:**
- "User cannot register with company email if under 18"
- "Product price cannot be reduced by more than 50% in one update"
- "Order cannot be cancelled after it's shipped"
- "Refund amount cannot exceed original payment"

**Complexity Indicators:**
- Multiple validation steps that depend on each other
- State machines (order: pending → processing → shipped → delivered)
- Complex calculations with business constraints
- Invariants that must be protected (e.g., account balance never negative)

---

## When to Create a New Feature vs Add to Existing

```
Where should this code go?

Is this new functionality?
├─ NO (modifying existing) → Add to existing feature
│   └─ Update FEATURE.md with changes
│
└─ YES (new functionality) → Is it related to an existing feature?
    ├─ YES → How related?
    │   ├─ Tightly coupled (shares most logic) → Add to existing feature
    │   │   Example: "verify email" → part of user-registration
    │   │
    │   └─ Loosely coupled (different use case) → Create new feature
    │       Example: "reset password" → new feature (password-reset)
    │
    └─ NO (completely new domain) → Create new feature
        Example: "product reviews" when you only have "products"
```

**Rule of Thumb:**
- If it shares > 70% of the same data/logic → Same feature
- If it shares < 30% → New feature
- If it's in between → Prefer new feature (better isolation)

---

## When to Write Unit vs Integration vs E2E Test

```
What are you testing?

Service/business logic?
├─ Pure function (no external deps) → Unit test
│   describe('calculateDiscount', () => {
│     it('should return 10% off for premium users', () => { ... });
│   });
│
├─ Uses repository/external service → Unit test with mocks
│   const mockRepo = { findById: vi.fn().mockResolvedValue(user) };
│
└─ Complex workflow → Integration test (real DB)
    Use test database, test actual flow

HTTP endpoint?
└─ Integration test (supertest)
    request(app).get('/api/products').expect(200)

Full user flow (login → create → update → delete)?
└─ E2E test (optional, expensive)
    Only for critical business flows
```

**Testing Strategy:**

| Test Type | Scope | Speed | Cost | Quantity |
|-----------|-------|-------|------|----------|
| Unit | Single function | Fast | Low | Many (70%) |
| Integration | API endpoint + DB | Medium | Medium | Some (20%) |
| E2E | Full user flow | Slow | High | Few (10%) |

---

## When to Optimize Performance

```
Is there a performance issue?
├─ NO → Don't optimize (premature optimization is evil)
│   └─ But: Always use pagination for lists
│
└─ YES → Measure first
    └─ Does query take > 100ms?
        ├─ YES → Is it queried frequently (> 100 req/min)?
        │   ├─ YES → Add database index
        │   │   └─ Still slow? → Optimize query or add caching
        │   └─ NO → Document but don't optimize yet
        │
        └─ NO → Does endpoint take > 200ms?
            ├─ YES → Profile to find bottleneck
            │   ├─ Database? → Optimize queries
            │   ├─ External API? → Add caching or async processing
            │   └─ Business logic? → Optimize algorithm
            └─ NO → Performance is acceptable
```

**Optimization Order:**
1. Add database indexes (cheap, high impact)
2. Optimize queries (remove N+1, reduce joins)
3. Add caching (adds complexity)
4. Async processing (for non-critical operations)
5. Algorithm optimization (rare)

---

## When to Use Transactions

```
Are you doing multiple database operations?
├─ NO (single operation) → No transaction needed
│   await repository.create(user);
│
└─ YES → Must all succeed or all fail?
    ├─ NO (independent operations) → No transaction
    │   await repository.create(user);
    │   await emailService.send(email); // Can fail independently
    │
    └─ YES (atomic operations) → Use transaction
        await db.transaction(async (tx) => {
          await tx.insert(orders).values(order);
          await tx.update(products).set({ stock: stock - 1 });
        });
```

**Examples Requiring Transactions:**
- Creating order + updating product stock
- Transferring money between accounts
- Creating user + creating associated profile
- Deleting parent + deleting children (if not using CASCADE)

**Examples NOT Requiring Transactions:**
- Creating user + sending welcome email (email can fail separately)
- Updating cache after database update
- Logging after business operation

---

## When to Return 404 vs 400 vs 500

```
What went wrong?

Client sent invalid data (bad format, missing field)?
└─ 400 Bad Request
    { "status": "error", "code": "ERR_VALIDATION_001", "message": "Invalid email format" }

Client trying to access resource that doesn't exist?
└─ 404 Not Found
    { "status": "error", "code": "ERR_RESOURCE_001", "message": "User not found" }

Client trying to create resource that already exists?
└─ 409 Conflict
    { "status": "error", "code": "ERR_RESOURCE_002", "message": "Email already exists" }

Client lacks authentication?
└─ 401 Unauthorized
    { "status": "error", "code": "ERR_AUTH_001", "message": "Authentication required" }

Client lacks permission?
└─ 403 Forbidden
    { "status": "error", "code": "ERR_AUTH_003", "message": "Insufficient permissions" }

Business rule violation (valid data but business logic rejects)?
└─ 422 Unprocessable Entity
    { "status": "error", "code": "ERR_BUSINESS_001", "message": "Insufficient balance" }

Unexpected server error (database down, bug in code)?
└─ 500 Internal Server Error
    { "status": "error", "message": "Internal server error" }
    (Log full details, don't expose to client)
```

---

## When to Use Soft Delete vs Hard Delete

```
Are you deleting a record?

Is this data ever referenced by other tables?
├─ YES → Is it currently referenced?
│   ├─ YES → Cannot delete (return 400 or use CASCADE)
│   └─ NO → Might be referenced in future?
│       ├─ YES → Soft delete (set isActive: false)
│       └─ NO → Consider hard delete
│
└─ NO → Is there regulatory/audit requirement to keep data?
    ├─ YES → Soft delete
    └─ NO → Do users expect to recover it?
        ├─ YES ("trash" feature) → Soft delete
        └─ NO → Hard delete is ok
```

**Soft Delete Implementation:**
```typescript
// Add to schema
isActive: boolean('is_active').default(true).notNull()
deletedAt: timestamp('deleted_at')

// Repository
async softDelete(id: string) {
  return this.update(id, {
    isActive: false,
    deletedAt: new Date()
  });
}

// Queries automatically filter
where: and(eq(table.id, id), eq(table.isActive, true))
```

**Hard Delete:**
```typescript
async delete(id: string) {
  await this.db.delete(table).where(eq(table.id, id));
}
```

---

## When to Add Validation in Middleware vs Service

```
Where should validation happen?

Is it input format validation (type, format, length)?
└─ Middleware (Zod schema + validateBody/validateQuery)
    router.post('/users', validateBody(createUserSchema), ...)

Is it business rule validation (email already exists, insufficient balance)?
└─ Service layer
    class UserService {
      async createUser(input: CreateUserInput) {
        if (await this.repository.emailExists(input.email)) {
          throw new AppError(409, 'Email already exists');
        }
        // ...
      }
    }
```

**Validation Layers:**

| Layer | Validates | Example |
|-------|-----------|---------|
| Middleware (Zod) | Format, type, required fields | Email format, password length |
| Service | Business rules, existence | Email uniqueness, balance check |
| Database | Constraints | NOT NULL, UNIQUE, FOREIGN KEY |

**Both are necessary:**
```typescript
// 1. Middleware validates format
const createUserSchema = z.object({
  email: z.string().email(),      // Format validation
  password: z.string().min(8)     // Length validation
});

// 2. Service validates business rules
async createUser(input: CreateUserInput) {
  // Business rule: email must be unique
  if (await this.repository.emailExists(input.email)) {
    throw new AppError(409, 'Email already exists');
  }
  // ...
}
```

---

## When to Update FEATURE.md

```
Did you make a change to the feature?

What did you change?

├─ Added/modified/removed API endpoint?
│   └─ ✅ UPDATE FEATURE.md "Public API" section
│
├─ Added new dependency (internal or external)?
│   └─ ✅ UPDATE FEATURE.md "Dependencies" section
│
├─ Changed business rules?
│   └─ ✅ UPDATE FEATURE.md "Business Rules" section
│
├─ Added new file to feature?
│   └─ ✅ UPDATE FEATURE.md "Key Files" table
│
├─ Changed feature scope (added/removed functionality)?
│   └─ ✅ UPDATE FEATURE.md "Scope" and "Out of Scope" sections
│
├─ Internal refactoring (no API/behavior change)?
│   └─ ⚠️ Consider updating "AI Context Notes" if pattern changed
│
└─ Bug fix (no API change)?
    └─ ❌ No FEATURE.md update needed (but update tests)
```

**Always update FEATURE.md before considering the feature "done".**

---

## When to Create a New Repository vs Use Existing

```
Need to access database?

What table are you accessing?

├─ Table used by this feature only
│   └─ Create feature-specific repository
│       src/features/users/users.repository.ts
│
├─ Table shared across multiple features
│   └─ Where is it primarily managed?
│       ├─ This feature is primary owner → Create in this feature
│       │   Other features import: import { UsersRepository } from '../users/...'
│       │
│       └─ No clear owner → Consider moving to shared/
│           shared/db/repositories/shared-entity.repository.ts
│           (Rare - prefer feature ownership)
│
└─ Need different query methods for same table in different features?
    └─ Create feature-specific repository (duplication is ok)
        features/orders/users.repository.ts    // findActiveUsers()
        features/admin/users.repository.ts     // findSuspendedUsers()
```

**Prefer duplication over coupling between features.**

---

## Summary: Key Decision Principles

1. **Prefer Duplication Over Wrong Abstraction**
   - Extract to shared only when used by 3+ features AND stable

2. **Optimize Based on Data, Not Assumptions**
   - Measure first, optimize if > performance budget

3. **Feature Independence Over Code Reuse**
   - Features should not import from other features

4. **Explicit Over Implicit**
   - Clear error messages over vague ones
   - Explicit validation over assumed inputs

5. **Simple Until Complex**
   - Start with flat VSA, add DDD layers only when needed

6. **Test What Matters**
   - High coverage on business logic, lower on boilerplate

7. **Document When It Matters**
   - Update FEATURE.md when API/behavior changes
   - Don't document every minor refactor

**When in doubt, follow the simplest path. Complexity can always be added later.**
