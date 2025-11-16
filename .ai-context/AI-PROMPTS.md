# AI Prompt Templates

**Purpose:** Reusable, effective prompts for AI coding assistants to maximize consistency and quality.

**How to use:** Copy these prompts and customize with your specific requirements.

---

## Getting Started Prompts

### 1. Understand the Architecture

```
Read .ai-context/ARCHITECTURE.md and summarize:
1. The overall architecture pattern (Vertical Slice Architecture)
2. The directory structure
3. The key principles
4. Where features should be located

Then confirm you understand by explaining where a new "product reviews" feature would be placed.
```

**Expected AI Response:**
- Describes VSA pattern
- Lists directory structure
- Explains features are independent
- Correctly identifies `src/features/product-reviews/` as location

---

### 2. Learn the Conventions

```
Read .ai-context/CONVENTIONS.md and list:
1. File naming conventions
2. Import order rules
3. TypeScript standards (strict mode, no any, etc.)
4. API response format standards

Confirm understanding by showing how you would name files for a new "email-verification" feature.
```

---

### 3. Review Error Catalog

```
Read .ai-context/ERROR-CATALOG.md and explain:
1. The error code format (ERR_CATEGORY_###)
2. When to use validation errors vs resource errors
3. How to use AppError class

Then show me an example of throwing an error when a product is not found.
```

---

## Feature Development Prompts

### 4. Create a New Feature (Complete)

```
Create a new feature called [FEATURE_NAME] following these requirements:

**Context:**
- Read .ai-context/ARCHITECTURE.md for overall structure
- Read .ai-context/CONVENTIONS.md for coding standards
- Read .ai-context/API-CONTRACTS.md for response formats
- Read .ai-context/ERROR-CATALOG.md for error codes
- Read .ai-context/PACKAGE-REGISTRY.md for approved packages
- Use .ai-context/FEATURE-TEMPLATE.md for FEATURE.md documentation

**Requirements:**
[List your specific requirements here, e.g.:]
- Endpoint: POST /api/[resource]
- Functionality: [Description]
- Validation: [Required fields]
- Business rules: [Any constraints]

**Deliverables:**
1. FEATURE.md (using template)
2. [feature].route.ts (HTTP endpoints)
3. [feature].service.ts (business logic)
4. [feature].repository.ts (database operations)
5. [feature].validator.ts (Zod schemas)
6. [feature].types.ts (TypeScript types)
7. __tests__/[feature].service.test.ts (unit tests)

**Self-Review:**
Before finishing, check CODE-REVIEW-CHECKLIST.md and confirm:
- All files follow naming conventions
- Error codes from ERROR-CATALOG.md
- API responses use ApiResponse helper
- Inputs validated with Zod
- FEATURE.md is complete

Create the feature now.
```

---

### 5. Add Endpoint to Existing Feature

```
Add a new endpoint to the [FEATURE_NAME] feature.

**Before you start:**
1. Read src/features/[FEATURE_NAME]/FEATURE.md to understand the feature
2. Check .ai-context/DEPENDENCIES.md for any dependencies
3. Review existing code structure in the feature

**New Endpoint:**
- Method: [GET/POST/PUT/DELETE]
- Path: /api/[resource]/[path]
- Purpose: [Description]
- Request: [Body/Query params]
- Response: [Expected response]

**Steps:**
1. Add method to service
2. Add route to route file
3. Create Zod validator if needed
4. Update FEATURE.md "Public API" section
5. Write tests
6. Self-review with CODE-REVIEW-CHECKLIST.md

Implement this endpoint now.
```

---

### 6. Modify Existing Feature

```
Modify the [FEATURE_NAME] feature to [DESCRIPTION OF CHANGE].

**Before modifying:**
1. Read src/features/[FEATURE_NAME]/FEATURE.md completely
2. Check .ai-context/DEPENDENCIES.md - what depends on this feature?
3. Review .ai-context/ANTI-PATTERNS.md to avoid common mistakes

**After modifying:**
1. Update FEATURE.md if API or behavior changed
2. Run tests to ensure nothing broke
3. Update DEPENDENCIES.md if dependencies changed
4. Self-review with CODE-REVIEW-CHECKLIST.md

Proceed with the modification.
```

---

## Debugging & Investigation Prompts

### 7. Debug an Issue

```
Debug the following issue: [ISSUE DESCRIPTION]

**Investigation steps:**
1. Read .ai-context/LOGGING.md to understand what should be logged
2. Check .ai-context/ERROR-CATALOG.md for error code meanings
3. Review .ai-context/ANTI-PATTERNS.md for common mistakes
4. Read the FEATURE.md for affected feature(s)
5. Check .ai-context/DEPENDENCIES.md for impact analysis

**Report:**
- Root cause
- Affected features/files
- Proposed fix
- How to prevent this in the future
- Test plan

Investigate and report now.
```

---

### 8. Code Review

```
Review the following code for quality and standards compliance:

[PASTE CODE OR FILE PATH]

**Check against:**
1. CODE-REVIEW-CHECKLIST.md - go through each section
2. CONVENTIONS.md - naming, structure, imports
3. API-CONTRACTS.md - if API endpoint
4. ERROR-CATALOG.md - if errors are thrown
5. ANTI-PATTERNS.md - check for common mistakes
6. TESTING.md - are there tests?

**Provide:**
- List of issues found (critical, important, nice-to-have)
- Specific fixes for each issue
- Code examples of correct implementation

Perform code review now.
```

---

### 9. Optimize Performance

```
Optimize the performance of [FEATURE/ENDPOINT].

**Before optimizing:**
1. Read .ai-context/PERFORMANCE.md for budgets and patterns
2. Check DECISION-TREES.md "When to Optimize" section
3. Measure current performance first

**Analysis:**
1. Does it exceed performance budgets?
2. What is the bottleneck? (query, computation, external API?)
3. Is optimization warranted? (see PERFORMANCE.md)

**If optimization needed:**
1. Apply appropriate pattern from PERFORMANCE.md
2. Measure after optimization
3. Document changes in FEATURE.md

Analyze and optimize if needed.
```

---

## Refactoring Prompts

### 10. Extract to Shared Utility

```
I want to extract [FUNCTIONALITY] to a shared utility.

**Before extracting:**
1. Check DECISION-TREES.md "When to Extract to Shared"
2. Verify it's used by 3+ features (or will be)
3. Verify it's stable (not changing frequently)

**If extraction is justified:**
1. Create file in shared/utils/[name].ts
2. Add JSDoc documentation
3. Write tests in shared/utils/__tests__/
4. Update DEPENDENCIES.md
5. Update using features to import from shared

**If extraction is NOT justified:**
- Explain why duplication is better
- Suggest when to revisit this decision

Evaluate and proceed.
```

---

### 11. Refactor for Better Structure

```
Refactor [FEATURE/FILE] to follow best practices.

**Guidelines:**
1. Read ARCHITECTURE.md for patterns
2. Check CONVENTIONS.md for standards
3. Review ANTI-PATTERNS.md to avoid mistakes
4. Ensure tests still pass after refactoring

**Focus on:**
- Separation of concerns (routes/services/repositories)
- Type safety (no `any` types)
- Error handling (using AppError with error codes)
- Naming conventions
- Function size (< 50 lines)

**Deliverables:**
1. Refactored code
2. Explanation of changes
3. Confirmation tests still pass

Refactor now.
```

---

## Testing Prompts

### 12. Write Tests for Feature

```
Write comprehensive tests for [FEATURE_NAME].

**Read first:**
1. .ai-context/TESTING.md for standards
2. src/features/[FEATURE_NAME]/FEATURE.md for business rules

**Test coverage required:**
1. Unit tests for service (> 90% coverage)
   - Happy path
   - Error cases
   - Edge cases (null, empty, invalid)
   - Business rules

2. Integration tests for routes
   - Valid requests
   - Invalid requests (validation)
   - Error responses

**Structure:**
- Use AAA pattern (Arrange-Act-Assert)
- Descriptive test names: "should [behavior] when [condition]"
- Mock external dependencies

Write tests now.
```

---

## Documentation Prompts

### 13. Update Documentation

```
Update documentation for [FEATURE/CHANGE].

**What needs updating:**

If API changed:
- [ ] Update FEATURE.md "Public API" section
- [ ] Update FEATURE.md examples

If dependencies changed:
- [ ] Update FEATURE.md "Dependencies" section
- [ ] Update .ai-context/DEPENDENCIES.md

If business rules changed:
- [ ] Update FEATURE.md "Business Rules" section

If architecture decision made:
- [ ] Create ADR in .ai-context/decisions/
- [ ] Format: 001-decision-title.md

Update all relevant documentation now.
```

---

### 14. Create FEATURE.md

```
Create a comprehensive FEATURE.md for [FEATURE_NAME].

**Template:**
Use .ai-context/FEATURE-TEMPLATE.md

**Analyze the code and document:**
1. Purpose and scope
2. All API endpoints (with request/response examples)
3. Internal and external dependencies
4. Business rules
5. Key files and their roles
6. Security considerations
7. AI context notes (how to modify this feature)

**Make it useful for:**
- AI assistants (quick context)
- New developers (understanding)
- Future you (remembering why decisions were made)

Create FEATURE.md now.
```

---

## Validation Prompts

### 15. Validate Against Standards

```
Validate that [FEATURE/CODE] follows all standards.

**Check each of these:**

1. ARCHITECTURE.md
   - [ ] Code in correct directory
   - [ ] Follows VSA pattern
   - [ ] Feature is independent

2. CONVENTIONS.md
   - [ ] File naming correct
   - [ ] Import order correct
   - [ ] TypeScript strict mode compliant

3. API-CONTRACTS.md
   - [ ] Response format correct
   - [ ] Status codes appropriate
   - [ ] Pagination implemented (if list endpoint)

4. ERROR-CATALOG.md
   - [ ] Error codes used correctly
   - [ ] Error messages consistent

5. TESTING.md
   - [ ] Coverage > 80%
   - [ ] AAA pattern used
   - [ ] Edge cases tested

6. ANTI-PATTERNS.md
   - [ ] No anti-patterns present

**Report:**
- List all violations
- Provide fixes

Validate now.
```

---

## Migration Prompts

### 16. Migrate Existing Code to This Architecture

```
Migrate [EXISTING CODE] to follow the VSA + LCMP Lite architecture.

**Analysis phase:**
1. Read existing code and understand functionality
2. Identify features (vertical slices)
3. Identify shared infrastructure

**Migration plan:**
1. Create feature directories in src/features/
2. Extract route handlers → [feature].route.ts
3. Extract business logic → [feature].service.ts
4. Extract data access → [feature].repository.ts
5. Create validators → [feature].validator.ts
6. Create types → [feature].types.ts
7. Create FEATURE.md for each feature
8. Write tests

**Validation:**
- All tests pass
- No functionality lost
- Follows all standards (check with CODE-REVIEW-CHECKLIST.md)

Proceed with migration.
```

---

## Advanced Prompts

### 17. Add Complex Business Logic

```
Add complex business logic for [FUNCTIONALITY].

**Before implementing:**
1. Read DECISION-TREES.md "When to Add DDD Layers"
2. Count business rules (if > 10, consider DDD layers)

**If many rules (> 10):**
Consider adding DDD structure:
```
features/[feature]/
├── FEATURE.md
├── domain/
│   ├── entities/
│   └── value-objects/
├── application/
│   └── use-cases/
└── infrastructure/
```

**Implementation:**
1. Document all business rules in FEATURE.md
2. Implement with clear validation
3. Write comprehensive tests for each rule
4. Use error codes from ERROR-CATALOG.md

Implement now.
```

---

### 18. Implement Caching

```
Implement caching for [ENDPOINT/QUERY].

**Read first:**
- .ai-context/PERFORMANCE.md "Caching" section
- .ai-context/DECISION-TREES.md "When to Optimize"

**Validate caching is needed:**
1. Does query take > 100ms? [YES/NO]
2. Is it hit frequently (> 100 req/min)? [YES/NO]
3. Does data change infrequently (< once/hour)? [YES/NO]

**If all YES:**
Implement caching with:
- In-memory for development (Map with TTL)
- Redis for production
- Cache invalidation strategy
- Document in FEATURE.md

**If any NO:**
Don't implement caching yet. Document why in FEATURE.md.

Proceed.
```

---

### 19. Add Event-Driven Communication

```
Implement event-driven communication between features to avoid circular dependencies.

**Scenario:**
Feature A needs to notify Feature B when something happens, but we can't import Feature B into Feature A (circular dependency).

**Solution:**
1. Create shared/events/event-bus.ts
2. Feature A emits event
3. Feature B listens for event

**Implementation:**
```typescript
// shared/events/event-bus.ts
import { EventEmitter } from 'events';
export const eventBus = new EventEmitter();

// Feature A (emits)
eventBus.emit('order.created', { orderId, userId });

// Feature B (listens)
eventBus.on('order.created', async (event) => {
  await notifyUser(event.userId, event.orderId);
});
```

**Documentation:**
- Update DEPENDENCIES.md with event relationships
- Document events in both FEATURE.md files

Implement event-driven communication now.
```

---

## Pro Tips for AI Assistants

### Reading Context in Correct Order

```
When starting any task, read context in this order:

1. ARCHITECTURE.md (understand overall structure)
2. CONVENTIONS.md (understand rules)
3. FEATURE.md (if modifying existing feature)
4. DEPENDENCIES.md (understand impact)
5. Relevant specialist docs (ERROR-CATALOG, API-CONTRACTS, etc.)

This order minimizes re-reading and ensures you have proper context.
```

---

### Self-Validation Prompt

```
Before marking any task complete, ask yourself:

1. Did I read the relevant FEATURE.md first?
2. Did I update FEATURE.md if I changed APIs?
3. Did I use error codes from ERROR-CATALOG.md?
4. Did I follow API-CONTRACTS.md for responses?
5. Did I check DECISION-TREES.md for patterns?
6. Did I use packages from PACKAGE-REGISTRY.md only?
7. Did I write tests following TESTING.md?
8. Did I validate all inputs with Zod?
9. Did I use ApiResponse helper?
10. Did I check CODE-REVIEW-CHECKLIST.md?

If any answer is "no" or "uncertain", STOP and address it before proceeding.
```

---

### Quick Reference Prompt

```
Quick reference for [SPECIFIC TOPIC]:

- Error codes → ERROR-CATALOG.md
- API format → API-CONTRACTS.md
- When to optimize → PERFORMANCE.md + DECISION-TREES.md
- Test patterns → TESTING.md
- Logging → LOGGING.md
- Packages → PACKAGE-REGISTRY.md
- Anti-patterns → ANTI-PATTERNS.md
- Architecture → ARCHITECTURE.md
- Conventions → CONVENTIONS.md

Read the relevant file and summarize key points for [MY SPECIFIC TASK].
```

---

## Summary

**For New Features:**
- Use Template #4 (Create New Feature)
- Always start with context files
- Always end with CODE-REVIEW-CHECKLIST.md

**For Modifications:**
- Use Template #6 (Modify Existing Feature)
- Read FEATURE.md first
- Update FEATURE.md after

**For Debugging:**
- Use Template #7 (Debug Issue)
- Check ANTI-PATTERNS.md
- Review LOGGING.md

**For Optimization:**
- Use Template #9 (Optimize Performance)
- Check PERFORMANCE.md budgets
- Measure before and after

**Key Principle:**
Always read context files BEFORE writing code. AI that reads documentation writes better code than AI that guesses.

---

**These prompts are templates. Customize them for your specific needs.**

---

## Full-Stack Prompts

### 20. Create Full-Stack Feature

```
Create a complete full-stack feature called [FEATURE_NAME] that spans backend API and frontend UI.

**Context - Read in order:**
1. .ai-context/FULLSTACK-ARCHITECTURE.md - Understand how backend and frontend work together
2. .ai-context/MONOREPO-STRUCTURE.md - Understand project structure
3. .ai-context/FULLSTACK-FEATURE-WORKFLOW.md - Follow the workflow
4. apps/backend/.ai-context/ARCHITECTURE.md - Backend patterns
5. apps/frontend/.ai-context/FSD-ARCHITECTURE.md - Frontend patterns

**Requirements:**
[Describe the feature, e.g.:]
- Feature: Product Reviews
- Users can submit reviews (rating 1-5, comment)
- Users can view all reviews for a product
- Users can edit/delete their own reviews

**Deliverables:**

**1. Shared Types** (packages/shared-types/src/)
- entities/review.ts - Entity schema with Zod
- api/review.types.ts - API request/response types

**2. Backend** (apps/backend/src/features/product-reviews/)
- Database schema (shared/db/schema/reviews.schema.ts)
- reviews.repository.ts - Data access
- reviews.service.ts - Business logic
- reviews.route.ts - HTTP endpoints
- reviews.validator.ts - Zod validation
- reviews.types.ts - Re-export from @shared/types
- __tests__/reviews.service.test.ts - Unit tests
- FEATURE.md - Backend API documentation

**3. Frontend** (apps/frontend/src/features/product-reviews/)
- api/reviewsApi.ts - API client
- model/reviewsStore.ts - Zustand store
- ui/ReviewForm.tsx - Submit review form
- ui/ReviewList.tsx - Display reviews
- ui/ReviewCard.tsx - Single review component
- types/review.types.ts - Re-export from @shared/types
- index.ts - Public API
- README.md - Frontend feature documentation

**Self-Review:**
- Types are defined in shared-types package (single source of truth)
- Backend validates using Zod schemas from shared-types
- Frontend uses same types from shared-types
- API contracts align (request/response shapes)
- Error codes from ERROR-CATALOG.md used by both
- Backend FEATURE.md documents API
- Frontend README.md documents UI components
- Tests for both backend (service) and frontend (components/store)

Create the complete feature now.
```

---

### 21. Add Frontend Feature to Existing Backend API

```
Add a frontend feature for the existing [FEATURE_NAME] backend API.

**Context:**
1. Read apps/backend/src/features/[FEATURE_NAME]/FEATURE.md - Understand the API
2. Read .ai-context/FULLSTACK-ARCHITECTURE.md - Understand integration
3. Read apps/frontend/.ai-context/FSD-ARCHITECTURE.md - Understand FSD
4. Read apps/frontend/.ai-context/COMPONENT-STANDARDS.md - React patterns
5. Read apps/frontend/.ai-context/STATE-MANAGEMENT.md - Zustand patterns

**Analyze existing backend:**
- What endpoints are available?
- What request/response types are used?
- What error codes can be returned?

**Create frontend feature:**
1. apps/frontend/src/features/[FEATURE_NAME]/
   - api/[feature]Api.ts - API client for backend endpoints
   - model/[feature]Store.ts - Zustand store for state
   - ui/[Component].tsx - React components
   - types/[feature].types.ts - Re-export from @shared/types
   - index.ts - Public API

2. Ensure types match backend exactly (from @shared/types)
3. Handle loading/error states in store
4. Follow FSD layer rules (feature can only import from entities and shared)

**Self-Review:**
- API client uses correct endpoints from backend FEATURE.md
- Request/response types match backend exactly
- Error handling uses error codes from backend
- Components follow COMPONENT-STANDARDS.md
- Store follows STATE-MANAGEMENT.md patterns
- Public API exports through index.ts

Create the frontend feature now.
```

---

### 22. Add Backend API for Existing Frontend Feature

```
Add a backend API for the existing [FEATURE_NAME] frontend feature.

**Context:**
1. Read apps/frontend/src/features/[FEATURE_NAME]/README.md - Understand UI requirements
2. Analyze apps/frontend/src/features/[FEATURE_NAME]/api/[feature]Api.ts - See what API calls are expected
3. Read .ai-context/FULLSTACK-ARCHITECTURE.md - Understand integration
4. Read apps/backend/.ai-context/ARCHITECTURE.md - Backend patterns

**Analyze frontend requirements:**
- What API endpoints does frontend call?
- What data structures does frontend expect?
- What operations does frontend need (CRUD)?

**Create backend feature:**
1. Define types in packages/shared-types/src/ (if not already exists)
2. apps/backend/src/features/[FEATURE_NAME]/
   - Database schema (shared/db/schema/)
   - [feature].repository.ts
   - [feature].service.ts
   - [feature].route.ts
   - [feature].validator.ts
   - __tests__/[feature].service.test.ts
   - FEATURE.md

**Ensure:**
- API responses match what frontend expects
- Error codes are consistent
- Validation rules match frontend validation

Create the backend feature now.
```

---

## Frontend-Specific Prompts

### 23. Create React Component

```
Create a React component called [COMPONENT_NAME].

**Context:**
- Read apps/frontend/.ai-context/COMPONENT-STANDARDS.md for patterns
- Read apps/frontend/.ai-context/FSD-ARCHITECTURE.md for where to place it

**Requirements:**
[Describe the component, e.g.:]
- Type: [Atom/Molecule/Organism]
- Purpose: [What it does]
- Props: [What props it accepts]
- Interactions: [Buttons, forms, etc.]

**Location:**
- Atoms (Button, Input): shared/ui/atoms/
- Molecules (FormField): shared/ui/molecules/
- Feature components: features/[feature]/ui/

**Deliverables:**
1. [Component].tsx - Component implementation
2. [Component].module.css - Styles
3. [Component].test.tsx - Component tests
4. index.ts - Export

**Standards:**
- TypeScript with proper Props interface
- Extend HTML element props if applicable
- CSS Modules for styles
- Tests with React Testing Library

Create the component now.
```

---

### 24. Create Zustand Store

```
Create a Zustand store for [FEATURE_NAME].

**Context:**
- Read apps/frontend/.ai-context/STATE-MANAGEMENT.md for patterns

**Requirements:**
[Describe the state, e.g.:]
- State: [What data to store]
- Actions: [What operations are needed]
- API integration: [If fetching from backend]

**Deliverables:**
1. features/[feature]/model/[feature]Store.ts
   - State interface
   - Initial state
   - Actions (CRUD operations)
   - Loading/error states
   - API integration

**Patterns to follow:**
- TypeScript for state and actions
- Async actions for API calls
- Loading/error state management
- Optimistic updates (if applicable)

Create the store now.
```

---

### 25. Debug Frontend Issue

```
Debug the following frontend issue: [ISSUE DESCRIPTION]

**Investigation:**
1. Check browser console for errors
2. Check React DevTools for component state
3. Check Redux DevTools (if using Zustand devtools middleware)
4. Check Network tab for failed API calls

**Common frontend issues:**
- Component not re-rendering → Check if using selector correctly
- API call failing → Check Network tab, verify endpoint
- State not updating → Check if mutating state directly
- Props not passed correctly → Check React DevTools

**Context files to review:**
- COMPONENT-STANDARDS.md - Component patterns
- STATE-MANAGEMENT.md - Zustand patterns
- FSD-ARCHITECTURE.md - Import rules

**Report:**
- Root cause
- Which component/store is affected
- Proposed fix
- How to prevent in future

Investigate and fix now.
```

---

### 26. Migrate Component to FSD

```
Migrate the [COMPONENT_NAME] component to follow FSD architecture.

**Context:**
1. Read apps/frontend/.ai-context/FSD-ARCHITECTURE.md
2. Analyze current component location and dependencies

**Analysis:**
- Where is component currently located?
- What does it import?
- Who imports it?
- Is it feature-specific or shared?

**Decision tree:**
- Has user interactions (forms, buttons, actions) → features/
- Displays entity data only (no actions) → entities/
- Generic UI component (Button, Modal) → shared/ui/
- Full page composition → pages/
- Composite UI block → widgets/

**Migration steps:**
1. Determine correct FSD layer
2. Move component to correct location
3. Update imports to follow FSD rules
4. Ensure no upward imports (can only import from lower layers)
5. Update component to export through index.ts (Public API)
6. Update all consumers to import from new location

Migrate the component now.
```

---

## Self-Validation Prompts

### Full-Stack Self-Check

```
Before marking the full-stack feature complete, verify:

**Types & Contracts:**
- [ ] Types defined in packages/shared-types
- [ ] Backend uses types from @shared/types
- [ ] Frontend uses types from @shared/types
- [ ] API request/response shapes match

**Backend:**
- [ ] Database schema created
- [ ] Repository implements data access
- [ ] Service implements business logic
- [ ] Routes use validators
- [ ] Error codes from ERROR-CATALOG.md
- [ ] FEATURE.md documents API
- [ ] Tests for service (>90% coverage)

**Frontend:**
- [ ] API client calls backend endpoints
- [ ] Store manages state with loading/error
- [ ] Components follow COMPONENT-STANDARDS.md
- [ ] Styles use CSS Modules
- [ ] Public API exports through index.ts
- [ ] README.md documents feature
- [ ] Tests for components and store

**Integration:**
- [ ] Frontend successfully calls backend
- [ ] Error handling works end-to-end
- [ ] Loading states display correctly
- [ ] Type safety enforced across stack

If any checkbox is unchecked, address it before proceeding.
```

---

### Frontend Self-Check

```
Before marking frontend work complete, verify:

**FSD Architecture:**
- [ ] Component in correct layer
- [ ] Only imports from lower layers
- [ ] No cross-feature imports
- [ ] Exports through index.ts (Public API)

**Component Standards:**
- [ ] TypeScript Props interface
- [ ] Functional component with hooks
- [ ] Event handlers with handle* prefix
- [ ] Proper dependencies in useEffect
- [ ] CSS Modules for styles

**State Management:**
- [ ] Zustand store if needed (not useState for global state)
- [ ] Selector pattern for accessing state
- [ ] Loading/error states handled
- [ ] Async actions for API calls

**Testing:**
- [ ] Component tests with React Testing Library
- [ ] Store tests if using Zustand
- [ ] Edge cases covered

If any checkbox is unchecked, address it before proceeding.
```

---

## Quick Reference

**Full-Stack Feature:**
1. Define types in packages/shared-types
2. Build backend (VSA pattern)
3. Build frontend (FSD pattern)
4. Integrate and test

**Backend Only:**
1. Read apps/backend/.ai-context/ARCHITECTURE.md
2. Follow VSA pattern (Route → Service → Repository)
3. Use types from @shared/types

**Frontend Only:**
1. Read apps/frontend/.ai-context/FSD-ARCHITECTURE.md
2. Follow FSD layers and import rules
3. Use types from @shared/types

**Context Files:**
- Full-stack → FULLSTACK-ARCHITECTURE.md
- Backend → apps/backend/.ai-context/ARCHITECTURE.md
- Frontend → apps/frontend/.ai-context/FSD-ARCHITECTURE.md
- Monorepo → MONOREPO-STRUCTURE.md
- Workflow → FULLSTACK-FEATURE-WORKFLOW.md

---

**These prompts are templates. Customize them for your specific needs.**
