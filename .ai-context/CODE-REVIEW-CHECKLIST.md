# Code Review Checklist

**Purpose:** AI self-review checklist to validate code before submission. Also used by human reviewers.

**When to use:** Before committing code, creating PR, or considering a task "done".

---

## How to Use This Checklist

### For AI Assistants

Before submitting code, go through EVERY section and check EVERY item.

If ANY item fails:
1. Fix the issue
2. Re-check the item
3. Continue through the list

Don't skip items. Don't assume. Verify each one.

### For Human Reviewers

Use this as a code review guide. If code doesn't pass these checks, request changes.

---

## ✅ Phase 1: Structure & Organization

### File Structure

- [ ] Feature has a `FEATURE.md` file
- [ ] All files follow naming conventions from CONVENTIONS.md
  - [ ] Routes: `*.route.ts`
  - [ ] Services: `*.service.ts`
  - [ ] Repositories: `*.repository.ts`
  - [ ] Validators: `*.validator.ts`
  - [ ] Types: `*.types.ts`
- [ ] Code is in the correct directory
  - [ ] Feature code in `src/features/{feature-name}/`
  - [ ] Shared code in `src/shared/`
  - [ ] No code outside these directories
- [ ] Tests are in `__tests__/` subdirectory
- [ ] No circular dependencies (check with imports)

### Feature Independence

- [ ] Feature does NOT import from other features
  - ❌ `import { UserService } from '../users/...'`
  - ✅ `import { db } from '../../shared/db/client'`
- [ ] Feature only depends on `shared/` infrastructure
- [ ] If cross-feature communication needed, documented in DEPENDENCIES.md

---

## ✅ Phase 2: TypeScript & Type Safety

### Type Annotations

- [ ] All functions have explicit return types
  ```typescript
  // ✅ Good
  async function getUser(id: string): Promise<User> { ... }

  // ❌ Bad
  async function getUser(id: string) { ... }
  ```
- [ ] All parameters have explicit types
- [ ] No `any` types used
  - If `unknown` is needed, document why
- [ ] No `@ts-ignore` or `@ts-expect-error` without explanation
- [ ] Interfaces/types are exported from `*.types.ts`

### Zod Validation

- [ ] All inputs validated with Zod schemas
- [ ] Schemas defined in `*.validator.ts`
- [ ] Types inferred from schemas
  ```typescript
  const schema = z.object({ ... });
  type Input = z.infer<typeof schema>;  // ✅
  ```
- [ ] No manual type duplication (use `z.infer`)

### Enums and Literals

- [ ] Use string literals for known values
  ```typescript
  // ✅ Good
  type Status = 'pending' | 'active' | 'inactive';

  // ❌ Bad (unless many values)
  enum Status { Pending, Active, Inactive }
  ```

---

## ✅ Phase 3: Error Handling

### AppError Usage

- [ ] All operational errors use `AppError`
- [ ] Error codes from `ERROR-CATALOG.md`
  ```typescript
  throw new AppError(404, 'User not found', 'ERR_RESOURCE_001');
  ```
- [ ] No generic `Error` or `throw "string"`
- [ ] Error messages are user-friendly

### Async Error Handling

- [ ] All route handlers wrapped in `asyncHandler`
  ```typescript
  router.get('/', asyncHandler(async (req, res) => { ... }));
  ```
- [ ] No naked `try-catch` without re-throwing
- [ ] Database errors are caught and logged

### Validation Errors

- [ ] Zod validation errors handled by middleware
- [ ] Custom validation uses appropriate error codes
- [ ] Field name included in validation errors

---

## ✅ Phase 4: API Contracts

### Response Format

- [ ] All responses use `ApiResponse` helper
  ```typescript
  return ApiResponse.success(res, data);
  return ApiResponse.created(res, resource);
  return ApiResponse.noContent(res);
  ```
- [ ] Response format matches `API-CONTRACTS.md`
- [ ] Status codes are correct (200, 201, 204, 400, 404, etc.)

### Endpoint Naming

- [ ] Follows RESTful conventions
  - ✅ `GET /api/users`
  - ❌ `GET /api/getUsers`
- [ ] Uses plural resource names
- [ ] No verbs in URL (unless action endpoint)
- [ ] Action endpoints follow pattern: `POST /api/:resource/:id/:action`

### Pagination

- [ ] All list endpoints implement pagination
- [ ] Default limit: 20, max limit: 100
- [ ] Returns pagination object:
  ```json
  {
    "total": number,
    "limit": number,
    "offset": number,
    "hasNext": boolean,
    "hasPrev": boolean
  }
  ```

### Request Validation

- [ ] Query parameters validated with `validateQuery`
- [ ] Body validated with `validateBody`
- [ ] Path parameters validated with `validateParams`

---

## ✅ Phase 5: Database & Repositories

### Repository Pattern

- [ ] All database access through repositories
- [ ] No direct `db` usage in services/routes
- [ ] Repositories extend `BaseRepository` when appropriate
- [ ] Feature-specific queries in feature repository

### Queries

- [ ] No N+1 queries
  ```typescript
  // ❌ Bad
  for (const order of orders) {
    const user = await db.query.users.findFirst(...);
  }

  // ✅ Good
  const ordersWithUsers = await db.select()
    .from(orders)
    .leftJoin(users, eq(orders.userId, users.id));
  ```
- [ ] Pagination always applied to list queries
- [ ] Indexes exist for frequently queried fields (check schema)

### Transactions

- [ ] Transactions used for multi-step operations
- [ ] No transactions for single operations
- [ ] Transaction failures are handled

---

## ✅ Phase 6: Security

### Input Validation

- [ ] All inputs validated (Zod)
- [ ] No SQL injection risk (using Drizzle ORM)
- [ ] No XSS risk (API only, but check if HTML rendered)

### Authentication & Authorization

- [ ] Protected endpoints check authentication
- [ ] Authorization checks before operations
- [ ] No sensitive data in error messages

### Data Exposure

- [ ] Passwords never returned in responses
  ```typescript
  const { passwordHash, ...user } = dbUser;  // ✅
  return user;
  ```
- [ ] No API keys/secrets in responses
- [ ] Soft-deleted records not exposed

### Logging

- [ ] No passwords logged
- [ ] No credit card numbers logged
- [ ] No API keys logged
- [ ] Errors logged with context (but sanitized)

---

## ✅ Phase 7: Testing

### Test Coverage

- [ ] Services have unit tests (target: > 90%)
- [ ] Complex logic has tests
- [ ] Edge cases tested:
  - [ ] Null/undefined inputs
  - [ ] Empty arrays/objects
  - [ ] Invalid UUIDs
  - [ ] Boundary values

### Test Structure

- [ ] Tests follow AAA pattern (Arrange-Act-Assert)
- [ ] Test names describe behavior:
  ```typescript
  it('should throw error when email already exists', ...);
  ```
- [ ] Mocks are used appropriately (unit tests)
- [ ] Test database used for integration tests

### Test Files

- [ ] Test files named `*.test.ts`
- [ ] Located in `__tests__/` directory
- [ ] No tests committed with `.skip` or `.only`

---

## ✅ Phase 8: Performance

### Database Performance

- [ ] Meets performance budgets (see PERFORMANCE.md):
  - [ ] Simple SELECT: < 10ms
  - [ ] With JOIN: < 50ms
  - [ ] Complex query: < 100ms
- [ ] Pagination prevents large result sets
- [ ] Appropriate indexes (check schema)

### Endpoint Performance

- [ ] API endpoints meet budgets:
  - [ ] GET (simple): < 50ms
  - [ ] GET (with DB): < 200ms
  - [ ] POST/PUT: < 300ms
- [ ] No unnecessary database queries
- [ ] No redundant computations

### Optimization

- [ ] Optimizations only where needed (see DECISION-TREES.md)
- [ ] No premature optimization
- [ ] Performance issues documented in FEATURE.md

---

## ✅ Phase 9: Documentation

### FEATURE.md

- [ ] FEATURE.md exists and is complete
- [ ] Updated if API changed
- [ ] Updated if dependencies changed
- [ ] Updated if business rules changed
- [ ] Updated if new files added
- [ ] "AI Context Notes" section helpful

### Code Comments

- [ ] JSDoc on public APIs
  ```typescript
  /**
   * Register a new user
   * @param input - User registration data
   * @returns Created user without password
   * @throws AppError if email exists
   */
  async registerUser(input: RegisterInput): Promise<User> { ... }
  ```
- [ ] Complex logic explained with inline comments
- [ ] No redundant comments (code should be self-documenting)

### README Updates

- [ ] README.md updated if setup changed
- [ ] New environment variables documented
- [ ] New scripts documented

---

## ✅ Phase 10: Code Quality

### Naming

- [ ] Variables are camelCase
- [ ] Classes are PascalCase
- [ ] Constants are UPPER_CASE
- [ ] Functions/methods are descriptive
  - ✅ `calculateDiscountedPrice()`
  - ❌ `calc()` or `doStuff()`

### Function Size

- [ ] Functions are < 50 lines
- [ ] Functions do one thing
- [ ] Complex functions are broken down

### Imports

- [ ] Imports are organized (see CONVENTIONS.md):
  1. Node.js built-ins
  2. External packages
  3. Shared utilities
  4. Feature-specific imports
- [ ] No unused imports
- [ ] Type imports use `import type`

### DRY Principle

- [ ] No copy-paste code within same feature
- [ ] Duplicated code across features is OK (see DECISION-TREES.md)
- [ ] Extracted to `shared/` only when used by 3+ features

---

## ✅ Phase 11: Dependencies

### Package Usage

- [ ] All packages from PACKAGE-REGISTRY.md
- [ ] No unapproved packages added
- [ ] Native alternatives used when possible
- [ ] No deprecated packages (moment, request, etc.)

### Dependency Updates

- [ ] DEPENDENCIES.md updated if new dependency
- [ ] `.ai-context/decisions/` updated for significant additions
- [ ] package.json updated correctly

---

## ✅ Phase 12: Git & Commits

### Commit Messages

- [ ] Follow conventional commits format:
  ```
  feat(users): add email verification
  fix(products): correct price validation
  refactor(orders): extract shipping logic
  ```
- [ ] Commits are atomic (one logical change)
- [ ] No "WIP" or "temp" commits

### Branch

- [ ] Feature branch created from main
- [ ] Branch name descriptive: `feature/user-verification`

### Files

- [ ] No `.env` files committed
- [ ] No `node_modules/` committed
- [ ] No IDE config files (`.vscode/`, `.idea/`)
- [ ] No sensitive data committed

---

## ✅ Phase 13: Anti-Patterns Check

Review `ANTI-PATTERNS.md` and ensure code doesn't include:

- [ ] No direct database access in routes
- [ ] No business logic in repositories
- [ ] No circular dependencies between features
- [ ] No silent failures (all errors thrown/logged)
- [ ] No validation in repository (validate in service)
- [ ] No mixing async/sync code incorrectly

---

## ✅ Phase 14: Production Readiness

### Configuration

- [ ] No hardcoded values (use environment variables)
- [ ] Secrets use `process.env` (not committed)
- [ ] Different behavior for dev/prod handled correctly

### Logging

- [ ] Important events logged (see LOGGING.md)
- [ ] Errors logged with context
- [ ] No console.log in production code (use logger)

### Error Messages

- [ ] Production errors don't expose stack traces
- [ ] Error messages are user-friendly
- [ ] Internal errors are logged but not exposed

---

## Quick Pre-Commit Checklist

If short on time, check at least these critical items:

1. [ ] All tests pass (`pnpm test`)
2. [ ] No TypeScript errors (`pnpm build`)
3. [ ] ESLint passes (`pnpm lint`)
4. [ ] FEATURE.md updated
5. [ ] No console.log statements
6. [ ] No commented-out code
7. [ ] All TODO comments have tracking issue
8. [ ] Error codes from ERROR-CATALOG.md
9. [ ] Using ApiResponse helper
10. [ ] No `any` types

---

## Automated Checks (Run Before Committing)

```bash
# Type checking
pnpm build

# Linting
pnpm lint

# Tests
pnpm test

# Audit dependencies
pnpm audit

# All at once
pnpm build && pnpm lint && pnpm test
```

---

## Review Severity Levels

### 🔴 Critical (Must Fix)

- Security vulnerabilities
- Type errors
- Broken functionality
- Missing error handling
- SQL injection risks
- Exposed secrets

### 🟡 Important (Should Fix)

- Missing tests for business logic
- Incorrect status codes
- Performance issues
- Missing documentation
- Anti-patterns

### 🟢 Nice to Have (Consider Fixing)

- Code style inconsistencies
- Verbose variable names
- Redundant comments
- Minor optimizations

---

## For AI: Self-Review Prompt

Before marking task as complete, ask yourself:

1. **Did I read FEATURE.md before modifying?**
2. **Did I update FEATURE.md if I changed APIs?**
3. **Did I use error codes from ERROR-CATALOG.md?**
4. **Did I follow API-CONTRACTS.md for responses?**
5. **Did I check DECISION-TREES.md for patterns?**
6. **Did I use packages from PACKAGE-REGISTRY.md only?**
7. **Did I write tests for business logic?**
8. **Did I validate all inputs with Zod?**
9. **Did I use ApiResponse helper?**
10. **Would another developer understand this code?**

If ANY answer is "no" or "uncertain", review that aspect before submitting.

---

## Summary

**Purpose:** Ensure consistent, high-quality code
**When:** Before every commit
**How:** Check EVERY item in relevant sections
**Result:** Code that follows all standards and patterns

**Remember:** This checklist exists to help, not hinder. If something doesn't make sense, it might need updating—document that in `.ai-context/decisions/`.

**For AI:** Don't just generate code. Verify it meets these standards.
