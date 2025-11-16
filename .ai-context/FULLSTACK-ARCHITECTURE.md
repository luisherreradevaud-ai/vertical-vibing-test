# Full-Stack Architecture Guide

**Purpose:** Unified architecture for building full-stack SaaS applications with AI assistance, combining VSA (backend) with FSD (frontend).

**Philosophy:** Feature-oriented development with clear boundaries, shared types, and consistent patterns across the stack.

---

## Architectural Overview

### Backend: Vertical Slice Architecture (VSA)

**Organization:** By feature/business capability

```
backend/src/
├── features/
│   └── user-registration/
│       ├── FEATURE.md
│       ├── register.route.ts
│       ├── register.service.ts
│       ├── register.repository.ts
│       ├── register.validator.ts
│       ├── register.types.ts
│       └── __tests__/
└── shared/
    ├── db/
    ├── middleware/
    └── utils/
```

**Characteristics:**
- Feature contains ALL code for a vertical slice of functionality
- Route → Service → Repository layers
- Features are independent (minimal cross-feature dependencies)
- Shared code extracted only when used by 3+ features

### Frontend: Feature-Sliced Design (FSD)

**Organization:** By layer, then by feature

```
frontend/src/
├── app/              # Application initialization
├── pages/            # Page compositions
├── widgets/          # Composite UI blocks
├── features/         # Business features
│   └── auth/
│       ├── ui/       # React components
│       ├── api/      # Backend communication
│       ├── model/    # State (Zustand)
│       ├── types/    # TypeScript types
│       ├── lib/      # Utilities
│       └── index.ts  # Public API
├── entities/         # Business entities
└── shared/           # Shared code
    ├── ui/           # Atomic Design components
    ├── api/
    ├── lib/
    └── hooks/
```

**Characteristics:**
- Strict layer hierarchy (can only import from lower layers)
- Feature contains UI + API + Model + Types for a business capability
- Public API principle (features export through index.ts)
- Atomic Design for UI components (atoms → molecules → organisms)

---

## Architectural Alignment

### ✅ Common Principles

Both architectures share these core principles:

1. **Feature-Oriented Organization**
   - Backend: Features are top-level directories
   - Frontend: Features are within the features/ layer
   - Both: Business capabilities are the primary organizing unit

2. **Separation of Concerns**
   - Backend: Route → Service → Repository
   - Frontend: UI → Model → API
   - Both: Clear responsibility boundaries

3. **Independence**
   - Backend: Features avoid dependencies on other features
   - Frontend: Features depend only on entities and shared
   - Both: Minimize coupling, maximize cohesion

4. **Shared Code Guidelines**
   - Backend: Extract to shared/ when used by 3+ features
   - Frontend: shared/ layer for cross-cutting concerns
   - Both: Don't prematurely abstract

5. **TypeScript Strict Mode**
   - Both use strict TypeScript with no `any` types
   - Both define clear interfaces and types
   - Both use Zod for runtime validation

6. **Testing Standards**
   - Both: Unit tests for business logic (> 90% coverage)
   - Both: Integration tests for API/UI flows
   - Both: Vitest as test framework

### 🔀 Key Differences

| Aspect | Backend (VSA) | Frontend (FSD) |
|--------|---------------|----------------|
| Top-level organization | By feature | By layer |
| Dependency flow | Horizontal (avoid cross-feature) | Vertical (top can import from bottom) |
| Primary concern | Business operations | User experience |
| State management | Database (PostgreSQL) | Zustand stores |
| API surface | RESTful HTTP endpoints | Component props + hooks |

---

## Full-Stack Feature Structure

A complete feature spans both backend and frontend:

### Example: Product Reviews Feature

**Backend** (`backend/src/features/product-reviews/`)
```
product-reviews/
├── FEATURE.md                 # Backend API docs
├── reviews.route.ts           # POST /api/reviews, GET /api/reviews/:id
├── reviews.service.ts         # Business logic
├── reviews.repository.ts      # Database operations
├── reviews.validator.ts       # Zod schemas
├── reviews.types.ts           # Backend types
└── __tests__/
    └── reviews.service.test.ts
```

**Frontend** (`frontend/src/features/product-reviews/`)
```
product-reviews/
├── README.md                  # Frontend UI docs
├── ui/
│   ├── ReviewForm.tsx         # Submit review
│   ├── ReviewList.tsx         # Display reviews
│   └── ReviewCard.tsx         # Single review
├── api/
│   └── reviewsApi.ts          # API client (calls backend)
├── model/
│   ├── reviewsStore.ts        # Zustand store
│   └── useReviews.ts          # Custom hook
├── types/
│   └── review.types.ts        # Frontend types
├── lib/
│   └── validation.ts          # Client-side validation
└── index.ts                   # Public API
```

**Shared Types** (`packages/shared-types/`)
```typescript
// Both backend and frontend import these
export interface Review {
  id: string;
  productId: string;
  userId: string;
  rating: number;
  comment: string;
  createdAt: string;
}

export interface CreateReviewDTO {
  productId: string;
  rating: number;
  comment: string;
}
```

---

## Monorepo Structure

### Recommended Structure

```
project-root/
├── .ai-context/              # Global AI context (monorepo-wide)
│   ├── FULLSTACK-ARCHITECTURE.md
│   ├── MONOREPO-STRUCTURE.md
│   ├── FULLSTACK-FEATURE-WORKFLOW.md
│   └── shared/               # Context applicable to both
│       ├── ERROR-CATALOG.md
│       ├── PACKAGE-REGISTRY.md
│       └── API-CONTRACTS.md
├── packages/
│   └── shared-types/         # Shared TypeScript types
│       ├── package.json
│       └── src/
│           ├── api/          # API request/response types
│           ├── entities/     # Business entity types
│           └── index.ts
├── apps/
│   ├── backend/
│   │   ├── .ai-context/      # Backend-specific context
│   │   │   ├── ARCHITECTURE.md (VSA)
│   │   │   ├── CONVENTIONS.md
│   │   │   ├── PERFORMANCE.md
│   │   │   └── TESTING.md
│   │   ├── src/
│   │   │   ├── features/
│   │   │   └── shared/
│   │   ├── package.json
│   │   └── tsconfig.json
│   └── frontend/
│       ├── .ai-context/      # Frontend-specific context
│       │   ├── FSD-ARCHITECTURE.md
│       │   ├── COMPONENT-STANDARDS.md
│       │   ├── STATE-MANAGEMENT.md
│       │   └── STYLING-STANDARDS.md
│       ├── src/
│       │   ├── app/
│       │   ├── pages/
│       │   ├── widgets/
│       │   ├── features/
│       │   ├── entities/
│       │   └── shared/
│       ├── package.json
│       └── tsconfig.json
└── package.json              # Root package.json (workspaces)
```

### Workspace Configuration

**Root `package.json`:**
```json
{
  "name": "fullstack-saas",
  "private": true,
  "workspaces": [
    "apps/*",
    "packages/*"
  ],
  "scripts": {
    "dev": "concurrently \"npm:dev:*\"",
    "dev:backend": "npm run dev --workspace=apps/backend",
    "dev:frontend": "npm run dev --workspace=apps/frontend",
    "build": "npm run build --workspaces",
    "test": "npm run test --workspaces"
  }
}
```

---

## Cross-Stack Communication

### API Contract Alignment

**Backend defines the contract:**
```typescript
// backend/src/features/reviews/reviews.types.ts
import { Review, CreateReviewDTO } from '@shared/types';

// Route
router.post('/reviews', async (req, res) => {
  const dto: CreateReviewDTO = req.body;
  const review: Review = await service.createReview(dto);
  return ApiResponse.created(res, review);
});
```

**Frontend consumes the contract:**
```typescript
// frontend/src/features/reviews/api/reviewsApi.ts
import type { Review, CreateReviewDTO } from '@shared/types';
import { apiClient } from '@/shared/api';

export async function createReview(dto: CreateReviewDTO): Promise<Review> {
  const response = await apiClient.post<Review>('/api/reviews', dto);
  return response.data;
}
```

### Type Safety Across the Stack

**Shared type definition:**
```typescript
// packages/shared-types/src/entities/review.ts
import { z } from 'zod';

// Zod schema (runtime validation)
export const reviewSchema = z.object({
  id: z.string().uuid(),
  productId: z.string().uuid(),
  userId: z.string().uuid(),
  rating: z.number().min(1).max(5),
  comment: z.string().min(10).max(500),
  createdAt: z.string().datetime(),
});

// TypeScript type (compile-time)
export type Review = z.infer<typeof reviewSchema>;

// DTO for creation
export const createReviewSchema = reviewSchema.omit({
  id: true,
  userId: true,
  createdAt: true,
});

export type CreateReviewDTO = z.infer<typeof createReviewSchema>;
```

**Backend validation:**
```typescript
// backend/src/features/reviews/reviews.validator.ts
import { createReviewSchema } from '@shared/types';

export const validateCreateReview = validateBody(createReviewSchema);
```

**Frontend validation:**
```typescript
// frontend/src/features/reviews/lib/validation.ts
import { createReviewSchema } from '@shared/types';

export function validateReviewForm(data: unknown) {
  return createReviewSchema.safeParse(data);
}
```

---

## State Management Across Stack

### Backend: Database as Single Source of Truth

```typescript
// Backend stores state in PostgreSQL
export class ReviewsRepository extends BaseRepository<Review> {
  async create(dto: CreateReviewDTO, userId: string): Promise<Review> {
    const [review] = await this.db
      .insert(reviews)
      .values({ ...dto, userId })
      .returning();
    return review;
  }
}
```

### Frontend: Zustand for Client State

```typescript
// Frontend caches state in Zustand
interface ReviewsState {
  reviews: Review[];
  isLoading: boolean;
  error: string | null;
  fetchReviews: (productId: string) => Promise<void>;
  addReview: (dto: CreateReviewDTO) => Promise<void>;
}

export const useReviewsStore = create<ReviewsState>((set) => ({
  reviews: [],
  isLoading: false,
  error: null,

  fetchReviews: async (productId: string) => {
    set({ isLoading: true, error: null });
    try {
      const reviews = await reviewsApi.getByProduct(productId);
      set({ reviews, isLoading: false });
    } catch (error) {
      set({ error: error.message, isLoading: false });
    }
  },

  addReview: async (dto: CreateReviewDTO) => {
    const review = await reviewsApi.create(dto);
    set((state) => ({ reviews: [...state.reviews, review] }));
  },
}));
```

### Synchronization Strategy

1. **Optimistic Updates** (optional):
```typescript
addReview: async (dto: CreateReviewDTO) => {
  // Optimistic update
  const tempReview = { ...dto, id: 'temp', createdAt: new Date().toISOString() };
  set((state) => ({ reviews: [...state.reviews, tempReview] }));

  try {
    // API call
    const review = await reviewsApi.create(dto);
    // Replace temp with real
    set((state) => ({
      reviews: state.reviews.map(r => r.id === 'temp' ? review : r)
    }));
  } catch (error) {
    // Rollback on error
    set((state) => ({
      reviews: state.reviews.filter(r => r.id !== 'temp'),
      error: error.message
    }));
  }
}
```

2. **Cache Invalidation**:
```typescript
// Refetch after mutation
await addReview(dto);
await fetchReviews(productId);  // Refresh from backend
```

---

## Error Handling Across Stack

### Backend Error Response

```typescript
// backend/src/shared/middleware/error-handler.ts
export function errorHandler(err: Error, req: Request, res: Response) {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      status: 'error',
      code: err.code,
      message: err.message,
    });
  }

  logger.error({ error: err.message, stack: err.stack });
  return res.status(500).json({
    status: 'error',
    code: 'ERR_INTERNAL_001',
    message: 'Internal server error',
  });
}
```

### Frontend Error Handling

```typescript
// frontend/src/features/reviews/api/reviewsApi.ts
import { ApiError } from '@/shared/api/errors';

export async function createReview(dto: CreateReviewDTO): Promise<Review> {
  try {
    const response = await apiClient.post<Review>('/api/reviews', dto);
    return response.data;
  } catch (error) {
    if (error.response?.data?.code === 'ERR_VALIDATION_001') {
      throw new ApiError('Invalid review data', error.response.data.code);
    }
    throw new ApiError('Failed to create review');
  }
}
```

### Shared Error Codes

Both backend and frontend reference the same error catalog:

```typescript
// packages/shared-types/src/errors/codes.ts
export const ErrorCodes = {
  // Validation
  VALIDATION_INVALID_FORMAT: 'ERR_VALIDATION_001',
  VALIDATION_MISSING_FIELD: 'ERR_VALIDATION_002',

  // Resource
  RESOURCE_NOT_FOUND: 'ERR_RESOURCE_001',
  RESOURCE_ALREADY_EXISTS: 'ERR_RESOURCE_002',

  // Auth
  AUTH_INVALID_CREDENTIALS: 'ERR_AUTH_001',
  AUTH_TOKEN_EXPIRED: 'ERR_AUTH_002',
} as const;
```

---

## Feature Development Workflow

### 1. Define Shared Types

```typescript
// packages/shared-types/src/entities/product.ts
export interface Product {
  id: string;
  name: string;
  price: number;
  description: string;
}

export interface CreateProductDTO {
  name: string;
  price: number;
  description: string;
}
```

### 2. Build Backend Feature

```bash
# Create feature structure
mkdir -p backend/src/features/products

# Create files
- products.route.ts
- products.service.ts
- products.repository.ts
- products.validator.ts
- products.types.ts (re-exports from @shared/types)
- FEATURE.md
```

### 3. Build Frontend Feature

```bash
# Create feature structure
mkdir -p frontend/src/features/products

# Create folders
- ui/
- api/
- model/
- types/ (re-exports from @shared/types)
- lib/
```

### 4. Connect Frontend to Backend

```typescript
// frontend/src/features/products/api/productsApi.ts
import type { Product, CreateProductDTO } from '@shared/types';

export async function createProduct(dto: CreateProductDTO): Promise<Product> {
  const response = await apiClient.post<Product>('/api/products', dto);
  return response.data;
}
```

### 5. Integrate in UI

```typescript
// frontend/src/features/products/ui/CreateProductForm.tsx
import { useProductsStore } from '../model/productsStore';

export function CreateProductForm() {
  const addProduct = useProductsStore(state => state.addProduct);

  const handleSubmit = async (dto: CreateProductDTO) => {
    await addProduct(dto);
  };

  return <form onSubmit={handleSubmit}>...</form>;
}
```

---

## AI Context Strategy

### Global Context (Monorepo Root)

Files in `.ai-context/` apply to both backend and frontend:
- `FULLSTACK-ARCHITECTURE.md` - This file
- `MONOREPO-STRUCTURE.md` - Project organization
- `API-CONTRACTS.md` - Shared API standards
- `ERROR-CATALOG.md` - Shared error codes
- `PACKAGE-REGISTRY.md` - Approved packages for both

### Backend Context

Files in `apps/backend/.ai-context/`:
- `ARCHITECTURE.md` - VSA patterns
- `CONVENTIONS.md` - Backend conventions
- `PERFORMANCE.md` - Database optimization
- `TESTING.md` - Backend testing
- `LOGGING.md` - Server logging

### Frontend Context

Files in `apps/frontend/.ai-context/`:
- `FSD-ARCHITECTURE.md` - FSD patterns
- `COMPONENT-STANDARDS.md` - React patterns
- `STATE-MANAGEMENT.md` - Zustand patterns
- `STYLING-STANDARDS.md` - CSS conventions
- `TESTING.md` - Frontend testing

### Reading Order for AI

**For full-stack feature development:**
1. Read `.ai-context/FULLSTACK-ARCHITECTURE.md` (this file)
2. Read `.ai-context/API-CONTRACTS.md` (understand contracts)
3. Read `apps/backend/.ai-context/ARCHITECTURE.md` (backend patterns)
4. Read `apps/frontend/.ai-context/FSD-ARCHITECTURE.md` (frontend patterns)
5. Read relevant specialist docs as needed

**For backend-only task:**
1. Read `apps/backend/.ai-context/ARCHITECTURE.md`
2. Read other backend context files as needed

**For frontend-only task:**
1. Read `apps/frontend/.ai-context/FSD-ARCHITECTURE.md`
2. Read other frontend context files as needed

---

## Key Principles

### 1. Single Source of Truth for Types

✅ **DO:**
```typescript
// packages/shared-types/src/entities/user.ts
export interface User { ... }

// Backend re-exports
export { User } from '@shared/types';

// Frontend re-exports
export { User } from '@shared/types';
```

❌ **DON'T:**
```typescript
// Backend defines User
interface User { ... }

// Frontend defines User separately (duplication!)
interface User { ... }
```

### 2. Backend Defines API Contract

The backend is the authority for API contracts. Frontend adapts to backend, not vice versa.

### 3. Features Own Their Domain

A feature contains ALL code for its business capability:
- Backend: Route + Service + Repository + Types
- Frontend: UI + API + Model + Types

### 4. Minimize Cross-Feature Dependencies

- Backend features should not depend on other backend features
- Frontend features should only depend on entities and shared
- Use events for decoupling if needed

### 5. Test Across the Stack

- Backend: Unit tests for services, integration tests for routes
- Frontend: Unit tests for components, integration tests for features
- E2E: Playwright/Cypress for critical user flows

---

## Summary

**Unified Philosophy:**
- Feature-oriented development
- Type safety across the stack
- Clear separation of concerns
- Consistent patterns and conventions

**Architecture Harmony:**
- VSA (backend) and FSD (frontend) both focus on features
- Shared types eliminate duplication
- API contracts ensure alignment
- Monorepo structure keeps it organized

**AI Context Strategy:**
- Global context for cross-stack concerns
- App-specific context for backend/frontend patterns
- Reading order guides AI to proper context

**Result:**
- Build features that span the entire stack
- Type-safe from database to UI
- Consistent conventions everywhere
- Maximum AI determinism (95-97%)

---

**Next Steps:**
1. Set up monorepo structure
2. Create shared-types package
3. Follow FULLSTACK-FEATURE-WORKFLOW.md to build first feature
4. Use AI-PROMPTS.md templates for consistency
