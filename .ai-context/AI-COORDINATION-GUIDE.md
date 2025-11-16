# AI Coordination Guide for Multi-Repository Development

**Purpose:** Enable AI assistants to work seamlessly across backend and frontend repositories while maintaining type safety and architectural consistency.

**Critical Requirement:** When developing features, AI must be able to work on BOTH repositories simultaneously.

---

## Multi-Repository Architecture

### Repository Locations

```
Orchestration Folder (Primary Working Directory):
/Users/luisherreradevaud/Documents/Github/imasd/fullstack-vsa-fsd/

├── .ai-context/                    # Global AI context (READ THIS FIRST)
├── repos/                          # Linked repositories
│   ├── backend/                    # Backend repository (Git repo)
│   └── frontend/                   # Frontend repository (Git repo)
├── shared-types/                   # Shared TypeScript types (source)
├── scripts/                        # Development automation
└── docs/                           # Documentation
```

**Backend Repository:** Separate Git repository at `repos/backend/` or absolute path
**Frontend Repository:** Separate Git repository at `repos/frontend/` or absolute path
**Shared Types:** npm package `@yourorg/shared-types`

---

## AI Working Mode: Multi-Repository

### Primary Working Directory

**Always start here:**
```
/Users/luisherreradevaud/Documents/Github/imasd/fullstack-vsa-fsd
```

**Why:**
- Global AI context is here
- Shared types source is here
- Coordination scripts are here
- This is the "source of truth" for the project

###Repository Access

**Backend:**
- Relative path: `repos/backend/`
- Context: `repos/backend/.ai-context/`
- Files: `repos/backend/src/`

**Frontend:**
- Relative path: `repos/frontend/`
- Context: `repos/frontend/.ai-context/`
- Files: `repos/frontend/src/`

---

## Context Reading Strategy

### For Full-Stack Features (touches both backend and frontend)

**Read in this order:**

1. **Global Context (Orchestration Folder)**
   ```
   .ai-context/FULLSTACK-ARCHITECTURE.md       # Overall architecture
   .ai-context/MULTI-REPO-SETUP.md            # Multi-repo specifics
   .ai-context/API-CONTRACTS.md               # API standards
   .ai-context/ERROR-CATALOG.md               # Shared error codes
   ```

2. **Backend Context**
   ```
   repos/backend/.ai-context/ARCHITECTURE.md   # VSA patterns
   repos/backend/.ai-context/CONVENTIONS.md    # Backend standards
   ```

3. **Frontend Context**
   ```
   repos/frontend/.ai-context/FSD-ARCHITECTURE.md    # FSD patterns
   repos/frontend/.ai-context/COMPONENT-STANDARDS.md # React standards
   repos/frontend/.ai-context/STATE-MANAGEMENT.md    # Zustand patterns
   ```

4. **Feature-Specific Context (if modifying existing features)**
   ```
   repos/backend/src/features/[feature]/FEATURE.md   # Backend feature docs
   repos/frontend/src/features/[feature]/README.md   # Frontend feature docs
   ```

### For Backend-Only Tasks

**Read in this order:**

1. **Global Context**
   ```
   .ai-context/API-CONTRACTS.md
   .ai-context/ERROR-CATALOG.md
   ```

2. **Backend Context**
   ```
   repos/backend/.ai-context/ARCHITECTURE.md
   repos/backend/.ai-context/CONVENTIONS.md
   repos/backend/.ai-context/PERFORMANCE.md (if optimization)
   repos/backend/.ai-context/TESTING.md (if writing tests)
   ```

3. **Feature Context**
   ```
   repos/backend/src/features/[feature]/FEATURE.md
   ```

### For Frontend-Only Tasks

**Read in this order:**

1. **Global Context**
   ```
   .ai-context/API-CONTRACTS.md
   .ai-context/ERROR-CATALOG.md
   ```

2. **Frontend Context**
   ```
   repos/frontend/.ai-context/FSD-ARCHITECTURE.md
   repos/frontend/.ai-context/COMPONENT-STANDARDS.md
   repos/frontend/.ai-context/STATE-MANAGEMENT.md
   ```

3. **Feature Context**
   ```
   repos/frontend/src/features/[feature]/README.md
   ```

---

## Development Workflow for AI

### Scenario 1: Create New Full-Stack Feature

**Example:** Add "Product Reviews" feature

#### Phase 1: Define Shared Types (Orchestration Folder)

**Working Directory:** `/Users/luisherreradevaud/Documents/Github/imasd/fullstack-vsa-fsd`

**Tasks:**
1. Create `shared-types/src/entities/review.ts`
2. Create `shared-types/src/api/review.types.ts`
3. Export from `shared-types/src/index.ts`
4. Build types: Run `cd shared-types && npm run build`

**Example:**
```typescript
// shared-types/src/entities/review.ts
import { z } from 'zod';

export const reviewSchema = z.object({
  id: z.string().uuid(),
  productId: z.string().uuid(),
  userId: z.string().uuid(),
  rating: z.number().int().min(1).max(5),
  comment: z.string().min(10).max(500),
  createdAt: z.string().datetime(),
});

export type Review = z.infer<typeof reviewSchema>;

export const createReviewSchema = reviewSchema.omit({
  id: true,
  userId: true,
  createdAt: true,
});

export type CreateReviewDTO = z.infer<typeof createReviewSchema>;
```

#### Phase 2: Build Backend API

**Working Directory:** Navigate to backend

```bash
cd repos/backend
```

**Context to Read:**
- `repos/backend/.ai-context/ARCHITECTURE.md`
- `repos/backend/.ai-context/CONVENTIONS.md`

**Tasks:**
1. Create database schema: `src/shared/db/schema/reviews.schema.ts`
2. Create feature folder: `src/features/product-reviews/`
3. Create files:
   - `reviews.route.ts` - HTTP endpoints
   - `reviews.service.ts` - Business logic
   - `reviews.repository.ts` - Data access
   - `reviews.validator.ts` - Zod validation
   - `reviews.types.ts` - Re-export from `@yourorg/shared-types`
   - `FEATURE.md` - Backend documentation
   - `__tests__/reviews.service.test.ts` - Tests

**Import shared types:**
```typescript
import type { Review, CreateReviewDTO } from '@yourorg/shared-types';
import { createReviewSchema } from '@yourorg/shared-types';
```

**Commit:**
```bash
git add .
git commit -m "feat: add product reviews API"
git push origin main
```

#### Phase 3: Build Frontend UI

**Working Directory:** Navigate to frontend

```bash
cd ../frontend
# Or from orchestration: cd repos/frontend
```

**Context to Read:**
- `repos/frontend/.ai-context/FSD-ARCHITECTURE.md`
- `repos/frontend/.ai-context/COMPONENT-STANDARDS.md`
- `repos/frontend/.ai-context/STATE-MANAGEMENT.md`

**Tasks:**
1. Create feature folder: `src/features/product-reviews/`
2. Create files:
   - `ui/ReviewForm.tsx` - Submit review form
   - `ui/ReviewList.tsx` - Display reviews
   - `ui/ReviewCard.tsx` - Single review
   - `api/reviewsApi.ts` - API client
   - `model/reviewsStore.ts` - Zustand store
   - `types/review.types.ts` - Re-export from `@yourorg/shared-types`
   - `index.ts` - Public API
   - `README.md` - Frontend documentation

**Import shared types:**
```typescript
import type { Review, CreateReviewDTO } from '@yourorg/shared-types';
```

**Commit:**
```bash
git add .
git commit -m "feat: add product reviews UI"
git push origin main
```

#### Phase 4: Update Orchestration

**Working Directory:** Return to orchestration folder

```bash
cd /Users/luisherreradevaud/Documents/Github/imasd/fullstack-vsa-fsd
```

**Tasks:**
1. Version shared types (if types changed):
   ```bash
   cd shared-types
   npm version patch  # or minor for new features
   npm run build
   npm publish  # if using npm registry
   ```

2. Update documentation if needed

3. Commit orchestration changes:
   ```bash
   git add shared-types/
   git commit -m "feat: add review types v0.2.0"
   git push origin main
   ```

---

## File Navigation Patterns

### Creating Files in Backend

**Pattern:**
```
Current Dir: /Users/.../fullstack-vsa-fsd
Target: repos/backend/src/features/product-reviews/reviews.route.ts

Action: Create file at repos/backend/src/features/product-reviews/reviews.route.ts
```

### Creating Files in Frontend

**Pattern:**
```
Current Dir: /Users/.../fullstack-vsa-fsd
Target: repos/frontend/src/features/product-reviews/ui/ReviewForm.tsx

Action: Create file at repos/frontend/src/features/product-reviews/ui/ReviewForm.tsx
```

### Reading Files

**Backend Feature:**
```bash
Read: repos/backend/src/features/user-registration/FEATURE.md
```

**Frontend Feature:**
```bash
Read: repos/frontend/src/features/auth/README.md
```

---

## Type Synchronization

### When Types Change

1. **Update in orchestration folder:**
   ```bash
   cd /Users/.../fullstack-vsa-fsd/shared-types/src/entities
   # Edit review.ts
   cd ../..
   npm run build
   ```

2. **Backend automatically picks up changes** (if using npm link or file: path)
   - Restart backend dev server to see changes

3. **Frontend automatically picks up changes** (if using npm link or file: path)
   - Restart frontend dev server to see changes

4. **For production:** Publish new version
   ```bash
   npm version patch
   npm publish
   ```

### Verifying Type Consistency

**Backend:**
```typescript
// repos/backend/src/features/reviews/reviews.validator.ts
import { createReviewSchema } from '@yourorg/shared-types';

export const validateCreateReview = validateBody(createReviewSchema);
// ✅ Uses same schema as frontend
```

**Frontend:**
```typescript
// repos/frontend/src/features/product-reviews/lib/validation.ts
import { createReviewSchema } from '@yourorg/shared-types';

export function validateReview(data: unknown) {
  return createReviewSchema.safeParse(data);
}
// ✅ Uses same schema as backend
```

---

## Error Handling Across Repositories

### Error Codes (from `.ai-context/ERROR-CATALOG.md`)

**Backend throws:**
```typescript
// repos/backend/src/features/reviews/reviews.service.ts
if (!review) {
  throw new AppError(404, 'Review not found', 'ERR_RESOURCE_001');
}
```

**Frontend catches:**
```typescript
// repos/frontend/src/features/product-reviews/api/reviewsApi.ts
catch (error) {
  if (error.response?.data?.code === 'ERR_RESOURCE_001') {
    throw new ApiError('Review not found', 'ERR_RESOURCE_001');
  }
}
```

**✅ Same error codes used across both repositories**

---

## Commit Strategy

### Separate Commits for Each Repository

**Backend commit:**
```bash
cd repos/backend
git add src/features/product-reviews/
git commit -m "feat(reviews): add product reviews API

- Add reviews endpoints (GET, POST, PATCH, DELETE)
- Add reviews service with business logic
- Add reviews repository for database access
- Add validation with Zod
- Add unit tests for service"
git push origin main
```

**Frontend commit:**
```bash
cd repos/frontend
git add src/features/product-reviews/
git commit -m "feat(reviews): add product reviews UI

- Add ReviewForm component
- Add ReviewList component
- Add ReviewCard component
- Add reviewsApi client
- Add reviewsStore with Zustand
- Add tests for components and store"
git push origin main
```

**Orchestration commit (if types changed):**
```bash
cd /Users/.../fullstack-vsa-fsd
git add shared-types/
git commit -m "feat(types): add review types v0.2.0

- Add Review entity schema
- Add CreateReviewDTO
- Add UpdateReviewDTO"
git push origin main
```

---

## Testing Across Repositories

### Backend Tests

**Location:** `repos/backend/src/features/product-reviews/__tests__/`

**Run:**
```bash
cd repos/backend
npm test
```

### Frontend Tests

**Location:** `repos/frontend/src/features/product-reviews/`

**Run:**
```bash
cd repos/frontend
npm test
```

### Integration Testing

**Start both:**
```bash
cd /Users/.../fullstack-vsa-fsd
./scripts/dev.sh
```

**Test manually:** Open browser and test feature end-to-end

---

## AI Prompt Templates for Multi-Repo

### Template: Create Full-Stack Feature

```
I want to create a full-stack feature called [FEATURE_NAME].

**Working from:** /Users/luisherreradevaud/Documents/Github/imasd/fullstack-vsa-fsd

**Requirements:**
- [Describe feature]

**Instructions:**

1. **Read context first:**
   - .ai-context/FULLSTACK-ARCHITECTURE.md
   - .ai-context/API-CONTRACTS.md
   - repos/backend/.ai-context/ARCHITECTURE.md
   - repos/frontend/.ai-context/FSD-ARCHITECTURE.md

2. **Phase 1: Create shared types**
   - Location: shared-types/src/
   - Create entity schemas with Zod
   - Build types: cd shared-types && npm run build

3. **Phase 2: Build backend**
   - Navigate: cd repos/backend
   - Create: src/features/[feature-name]/
   - Import types from @yourorg/shared-types
   - Commit to backend repo

4. **Phase 3: Build frontend**
   - Navigate: cd repos/frontend
   - Create: src/features/[feature-name]/
   - Import types from @yourorg/shared-types
   - Commit to frontend repo

5. **Phase 4: Update orchestration**
   - Navigate: cd /Users/.../fullstack-vsa-fsd
   - Version shared types if changed
   - Commit to orchestration repo

Please create the complete feature following this workflow.
```

---

## Troubleshooting

### Issue: AI can't find backend files

**Problem:** AI is looking in orchestration folder

**Solution:** Specify full path
```
repos/backend/src/features/user-registration/register.service.ts
```

### Issue: Types not syncing between repos

**Problem:** Backend/frontend using old types

**Solution:** Rebuild and relink
```bash
cd /Users/.../fullstack-vsa-fsd/shared-types
npm run build

cd ../repos/backend
npm link @yourorg/shared-types

cd ../repos/frontend
npm link @yourorg/shared-types

# Restart dev servers
```

### Issue: AI doesn't know which repo to work in

**Problem:** Unclear context

**Solution:** Be explicit in prompt
```
"Create this component in the FRONTEND repository at repos/frontend/src/features/..."
```

---

## Best Practices for AI

### ✅ DO

1. **Always start from orchestration folder**
   ```bash
   cd /Users/luisherreradevaud/Documents/Github/imasd/fullstack-vsa-fsd
   ```

2. **Read global context first**
   ```
   .ai-context/FULLSTACK-ARCHITECTURE.md
   .ai-context/API-CONTRACTS.md
   ```

3. **Use relative paths from orchestration folder**
   ```
   repos/backend/src/features/...
   repos/frontend/src/features/...
   ```

4. **Import shared types consistently**
   ```typescript
   import { User } from '@yourorg/shared-types';
   ```

5. **Commit to each repository separately**

### ❌ DON'T

1. **Don't work in only one repository** for full-stack features

2. **Don't create types in backend or frontend** - use shared-types

3. **Don't forget to rebuild shared types** after changes

4. **Don't commit all repos together** - they're separate

5. **Don't skip reading global context** - it's critical for consistency

---

## Summary

**Key Points:**

1. **Primary Working Directory:** Always `/Users/.../fullstack-vsa-fsd`

2. **Three Repositories:**
   - Orchestration (global context, shared types)
   - Backend (repos/backend/)
   - Frontend (repos/frontend/)

3. **Type Safety:**
   - Define once in shared-types
   - Import in both backend and frontend
   - Single source of truth

4. **AI Workflow:**
   - Read global context first
   - Navigate to specific repos for work
   - Return to orchestration for coordination

5. **Commits:**
   - Separate commit for each repository
   - Backend changes → backend repo
   - Frontend changes → frontend repo
   - Type changes → orchestration repo

**For AI: You can and should work across all repositories. Start from the orchestration folder, navigate to specific repos as needed, and ensure type consistency across the stack.**
