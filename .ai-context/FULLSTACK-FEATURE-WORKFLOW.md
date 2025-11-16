# Full-Stack Feature Development Workflow

**Purpose:** Step-by-step guide for building features that span backend API and frontend UI.

**Philosophy:** Type-safe development from database to UI with consistent patterns and AI assistance.

---

## Overview

Building a full-stack feature involves:

1. **Define Shared Types** - Single source of truth
2. **Build Backend API** - VSA pattern (Route → Service → Repository)
3. **Build Frontend Feature** - FSD pattern (UI → Model → API)
4. **Test End-to-End** - Verify integration

**Example Feature:** Product Reviews
- Users can submit reviews for products
- Users can view all reviews for a product
- Reviews include rating (1-5) and comment

---

## Phase 1: Define Shared Types

**Location:** `packages/shared-types/src/entities/review.ts`

### Step 1.1: Create Entity Schema

```typescript
// packages/shared-types/src/entities/review.ts
import { z } from 'zod';

/**
 * Review entity schema
 *
 * Used by both backend (database) and frontend (API)
 */
export const reviewSchema = z.object({
  id: z.string().uuid(),
  productId: z.string().uuid(),
  userId: z.string().uuid(),
  rating: z.number().int().min(1).max(5),
  comment: z.string().min(10).max(500),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
});

export type Review = z.infer<typeof reviewSchema>;
```

### Step 1.2: Create DTO Schemas

```typescript
// packages/shared-types/src/entities/review.ts (continued)

/**
 * Create review DTO
 *
 * Omits: id, userId (from auth), timestamps (auto-generated)
 */
export const createReviewSchema = reviewSchema.omit({
  id: true,
  userId: true,
  createdAt: true,
  updatedAt: true,
});

export type CreateReviewDTO = z.infer<typeof createReviewSchema>;

/**
 * Update review DTO
 *
 * Only rating and comment can be updated
 */
export const updateReviewSchema = reviewSchema.pick({
  rating: true,
  comment: true,
}).partial();

export type UpdateReviewDTO = z.infer<typeof updateReviewSchema>;
```

### Step 1.3: Create API Response Types

```typescript
// packages/shared-types/src/api/review.types.ts
import type { Review } from '../entities/review';

export interface GetReviewsQuery {
  productId?: string;
  userId?: string;
  limit?: number;
  offset?: number;
}

export interface GetReviewsResponse {
  reviews: Review[];
  total: number;
}
```

### Step 1.4: Export Types

```typescript
// packages/shared-types/src/index.ts
export * from './entities/review';
export * from './api/review.types';
```

---

## Phase 2: Build Backend Feature

**Location:** `apps/backend/src/features/product-reviews/`

### Step 2.1: Create Feature Structure

```bash
mkdir -p apps/backend/src/features/product-reviews/{__tests__,}
touch apps/backend/src/features/product-reviews/{FEATURE.md,reviews.route.ts,reviews.service.ts,reviews.repository.ts,reviews.validator.ts,reviews.types.ts}
```

### Step 2.2: Create Database Schema

```typescript
// apps/backend/src/shared/db/schema/reviews.schema.ts
import { pgTable, uuid, integer, varchar, timestamp } from 'drizzle-orm/pg-core';
import { users } from './users.schema';
import { products } from './products.schema';

export const reviews = pgTable('reviews', {
  id: uuid('id').primaryKey().defaultRandom(),
  productId: uuid('product_id').references(() => products.id).notNull(),
  userId: uuid('user_id').references(() => users.id).notNull(),
  rating: integer('rating').notNull(),  // 1-5
  comment: varchar('comment', { length: 500 }).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export type Review = typeof reviews.$inferSelect;
export type NewReview = typeof reviews.$inferInsert;
```

### Step 2.3: Create Repository

```typescript
// apps/backend/src/features/product-reviews/reviews.repository.ts
import { eq, and, desc } from 'drizzle-orm';
import { BaseRepository } from '@/shared/db/repositories/base.repository';
import { reviews } from '@/shared/db/schema/reviews.schema';
import type { Database } from '@/shared/db/client';
import type { Review, NewReview } from '@/shared/db/schema/reviews.schema';

export class ReviewsRepository extends BaseRepository<Review> {
  constructor(db: Database) {
    super(db, reviews);
  }

  async findByProduct(productId: string, limit = 20, offset = 0): Promise<Review[]> {
    return this.db
      .select()
      .from(reviews)
      .where(eq(reviews.productId, productId))
      .orderBy(desc(reviews.createdAt))
      .limit(limit)
      .offset(offset);
  }

  async findByUser(userId: string): Promise<Review[]> {
    return this.db
      .select()
      .from(reviews)
      .where(eq(reviews.userId, userId))
      .orderBy(desc(reviews.createdAt));
  }

  async findByProductAndUser(productId: string, userId: string): Promise<Review | null> {
    const [review] = await this.db
      .select()
      .from(reviews)
      .where(and(
        eq(reviews.productId, productId),
        eq(reviews.userId, userId)
      ))
      .limit(1);

    return review || null;
  }

  async create(data: NewReview): Promise<Review> {
    const [review] = await this.db
      .insert(reviews)
      .values(data)
      .returning();

    return review;
  }

  async update(id: string, data: Partial<NewReview>): Promise<Review> {
    const [updated] = await this.db
      .update(reviews)
      .set({ ...data, updatedAt: new Date() })
      .where(eq(reviews.id, id))
      .returning();

    return updated;
  }

  async countByProduct(productId: string): Promise<number> {
    const result = await this.db
      .select({ count: sql<number>`count(*)` })
      .from(reviews)
      .where(eq(reviews.productId, productId));

    return result[0]?.count || 0;
  }
}
```

### Step 2.4: Create Service

```typescript
// apps/backend/src/features/product-reviews/reviews.service.ts
import { ReviewsRepository } from './reviews.repository';
import { AppError } from '@/shared/middleware/error-handler';
import type { CreateReviewDTO, UpdateReviewDTO } from '@shared/types';

export class ReviewsService {
  constructor(private repository: ReviewsRepository) {}

  async getReviewsByProduct(productId: string, limit = 20, offset = 0) {
    const reviews = await this.repository.findByProduct(productId, limit, offset);
    const total = await this.repository.countByProduct(productId);

    return { reviews, total };
  }

  async getReviewById(id: string) {
    const review = await this.repository.findById(id);

    if (!review) {
      throw new AppError(404, 'Review not found', 'ERR_RESOURCE_001');
    }

    return review;
  }

  async createReview(dto: CreateReviewDTO, userId: string) {
    // Business rule: User can only review a product once
    const existing = await this.repository.findByProductAndUser(dto.productId, userId);

    if (existing) {
      throw new AppError(
        409,
        'You have already reviewed this product',
        'ERR_BUSINESS_005'
      );
    }

    const review = await this.repository.create({
      ...dto,
      userId,
    });

    return review;
  }

  async updateReview(id: string, dto: UpdateReviewDTO, userId: string) {
    const review = await this.getReviewById(id);

    // Business rule: Users can only update their own reviews
    if (review.userId !== userId) {
      throw new AppError(403, 'You can only update your own reviews', 'ERR_AUTH_003');
    }

    const updated = await this.repository.update(id, dto);
    return updated;
  }

  async deleteReview(id: string, userId: string) {
    const review = await this.getReviewById(id);

    // Business rule: Users can only delete their own reviews
    if (review.userId !== userId) {
      throw new AppError(403, 'You can only delete your own reviews', 'ERR_AUTH_003');
    }

    await this.repository.delete(id);
  }
}
```

### Step 2.5: Create Validators

```typescript
// apps/backend/src/features/product-reviews/reviews.validator.ts
import { createReviewSchema, updateReviewSchema } from '@shared/types';
import { validateBody, validateQuery } from '@/shared/middleware/validation';
import { z } from 'zod';

export const validateCreateReview = validateBody(createReviewSchema);

export const validateUpdateReview = validateBody(updateReviewSchema);

export const validateGetReviews = validateQuery(
  z.object({
    productId: z.string().uuid().optional(),
    userId: z.string().uuid().optional(),
    limit: z.coerce.number().int().min(1).max(100).default(20),
    offset: z.coerce.number().int().min(0).default(0),
  })
);
```

### Step 2.6: Create Routes

```typescript
// apps/backend/src/features/product-reviews/reviews.route.ts
import { Router } from 'express';
import { ReviewsService } from './reviews.service';
import { ReviewsRepository } from './reviews.repository';
import { validateCreateReview, validateUpdateReview, validateGetReviews } from './reviews.validator';
import { asyncHandler } from '@/shared/middleware/async-handler';
import { authenticate } from '@/shared/middleware/auth';
import { ApiResponse } from '@/shared/utils/response';
import type { Database } from '@/shared/db/client';

export function createReviewsRouter(db: Database): Router {
  const router = Router();
  const repository = new ReviewsRepository(db);
  const service = new ReviewsService(repository);

  // GET /api/reviews - Get reviews (with filters)
  router.get(
    '/',
    validateGetReviews,
    asyncHandler(async (req, res) => {
      const { productId, userId, limit, offset } = req.query;

      if (productId) {
        const result = await service.getReviewsByProduct(productId, limit, offset);
        return ApiResponse.paginated(res, result.reviews, result.total, limit, offset);
      }

      // Add other filters as needed...

      return ApiResponse.success(res, []);
    })
  );

  // GET /api/reviews/:id - Get single review
  router.get(
    '/:id',
    asyncHandler(async (req, res) => {
      const review = await service.getReviewById(req.params.id);
      return ApiResponse.success(res, review);
    })
  );

  // POST /api/reviews - Create review (authenticated)
  router.post(
    '/',
    authenticate,
    validateCreateReview,
    asyncHandler(async (req, res) => {
      const review = await service.createReview(req.body, req.user!.id);
      return ApiResponse.created(res, review);
    })
  );

  // PATCH /api/reviews/:id - Update review (authenticated)
  router.patch(
    '/:id',
    authenticate,
    validateUpdateReview,
    asyncHandler(async (req, res) => {
      const review = await service.updateReview(req.params.id, req.body, req.user!.id);
      return ApiResponse.success(res, review);
    })
  );

  // DELETE /api/reviews/:id - Delete review (authenticated)
  router.delete(
    '/:id',
    authenticate,
    asyncHandler(async (req, res) => {
      await service.deleteReview(req.params.id, req.user!.id);
      return ApiResponse.noContent(res);
    })
  );

  return router;
}
```

### Step 2.7: Write Tests

```typescript
// apps/backend/src/features/product-reviews/__tests__/reviews.service.test.ts
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ReviewsService } from '../reviews.service';
import { ReviewsRepository } from '../reviews.repository';

describe('ReviewsService', () => {
  let service: ReviewsService;
  let repository: ReviewsRepository;

  beforeEach(() => {
    repository = {
      findByProduct: vi.fn(),
      findByProductAndUser: vi.fn(),
      create: vi.fn(),
      // ... other methods
    } as any;

    service = new ReviewsService(repository);
  });

  describe('createReview', () => {
    it('should create review if user has not reviewed product', async () => {
      const dto = {
        productId: 'product-123',
        rating: 5,
        comment: 'Great product!',
      };
      const userId = 'user-123';

      repository.findByProductAndUser = vi.fn().mockResolvedValue(null);
      repository.create = vi.fn().mockResolvedValue({
        id: 'review-123',
        ...dto,
        userId,
        createdAt: new Date().toISOString(),
      });

      const result = await service.createReview(dto, userId);

      expect(result.id).toBe('review-123');
      expect(repository.create).toHaveBeenCalledWith({ ...dto, userId });
    });

    it('should throw error if user already reviewed product', async () => {
      const dto = {
        productId: 'product-123',
        rating: 5,
        comment: 'Great product!',
      };
      const userId = 'user-123';

      repository.findByProductAndUser = vi.fn().mockResolvedValue({
        id: 'existing-review',
      });

      await expect(service.createReview(dto, userId)).rejects.toThrow(
        'You have already reviewed this product'
      );
    });
  });
});
```

---

## Phase 3: Build Frontend Feature

**Location:** `apps/frontend/src/features/product-reviews/`

### Step 3.1: Create Feature Structure

```bash
mkdir -p apps/frontend/src/features/product-reviews/{ui,api,model,types,lib}
touch apps/frontend/src/features/product-reviews/{index.ts,README.md}
```

### Step 3.2: Create Types

```typescript
// apps/frontend/src/features/product-reviews/types/review.types.ts
export { Review, CreateReviewDTO, UpdateReviewDTO } from '@shared/types';
```

### Step 3.3: Create API Client

```typescript
// apps/frontend/src/features/product-reviews/api/reviewsApi.ts
import { apiClient } from '@/shared/api/client';
import type { Review, CreateReviewDTO, UpdateReviewDTO } from '@shared/types';

const BASE_URL = '/reviews';

export async function getReviewsByProduct(productId: string): Promise<Review[]> {
  const response = await apiClient.get<Review[]>(`${BASE_URL}?productId=${productId}`);
  return response.data;
}

export async function getReview(id: string): Promise<Review> {
  const response = await apiClient.get<Review>(`${BASE_URL}/${id}`);
  return response.data;
}

export async function createReview(dto: CreateReviewDTO): Promise<Review> {
  const response = await apiClient.post<Review>(BASE_URL, dto);
  return response.data;
}

export async function updateReview(id: string, dto: UpdateReviewDTO): Promise<Review> {
  const response = await apiClient.patch<Review>(`${BASE_URL}/${id}`, dto);
  return response.data;
}

export async function deleteReview(id: string): Promise<void> {
  await apiClient.delete(`${BASE_URL}/${id}`);
}
```

### Step 3.4: Create Zustand Store

```typescript
// apps/frontend/src/features/product-reviews/model/reviewsStore.ts
import { create } from 'zustand';
import * as api from '../api/reviewsApi';
import type { Review, CreateReviewDTO, UpdateReviewDTO } from '@shared/types';

interface ReviewsState {
  reviews: Review[];
  isLoading: boolean;
  error: string | null;

  fetchReviews: (productId: string) => Promise<void>;
  addReview: (dto: CreateReviewDTO) => Promise<void>;
  updateReview: (id: string, dto: UpdateReviewDTO) => Promise<void>;
  deleteReview: (id: string) => Promise<void>;
  clearError: () => void;
}

export const useReviewsStore = create<ReviewsState>((set) => ({
  reviews: [],
  isLoading: false,
  error: null,

  fetchReviews: async (productId: string) => {
    set({ isLoading: true, error: null });

    try {
      const reviews = await api.getReviewsByProduct(productId);
      set({ reviews, isLoading: false });
    } catch (error) {
      set({ error: error.message, isLoading: false });
    }
  },

  addReview: async (dto: CreateReviewDTO) => {
    set({ isLoading: true, error: null });

    try {
      const review = await api.createReview(dto);
      set((state) => ({
        reviews: [review, ...state.reviews],
        isLoading: false,
      }));
    } catch (error) {
      set({ error: error.message, isLoading: false });
      throw error;
    }
  },

  updateReview: async (id: string, dto: UpdateReviewDTO) => {
    try {
      const updated = await api.updateReview(id, dto);
      set((state) => ({
        reviews: state.reviews.map((r) => (r.id === id ? updated : r)),
      }));
    } catch (error) {
      set({ error: error.message });
      throw error;
    }
  },

  deleteReview: async (id: string) => {
    try {
      await api.deleteReview(id);
      set((state) => ({
        reviews: state.reviews.filter((r) => r.id !== id),
      }));
    } catch (error) {
      set({ error: error.message });
      throw error;
    }
  },

  clearError: () => set({ error: null }),
}));
```

### Step 3.5: Create UI Components

```typescript
// apps/frontend/src/features/product-reviews/ui/ReviewForm.tsx
import { useState, FormEvent } from 'react';
import { Button, Input } from '@/shared/ui/atoms';
import { useReviewsStore } from '../model/reviewsStore';
import type { CreateReviewDTO } from '@shared/types';
import styles from './ReviewForm.module.css';

interface Props {
  productId: string;
  onSuccess?: () => void;
}

export function ReviewForm({ productId, onSuccess }: Props) {
  const [rating, setRating] = useState(5);
  const [comment, setComment] = useState('');
  const { addReview, isLoading, error } = useReviewsStore();

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();

    const dto: CreateReviewDTO = {
      productId,
      rating,
      comment,
    };

    try {
      await addReview(dto);
      setComment('');
      setRating(5);
      onSuccess?.();
    } catch (err) {
      // Error handled by store
    }
  };

  return (
    <form onSubmit={handleSubmit} className={styles.form}>
      <h3>Write a Review</h3>

      <div className={styles.rating}>
        <label>Rating:</label>
        <select value={rating} onChange={(e) => setRating(Number(e.target.value))}>
          <option value={5}>5 stars</option>
          <option value={4}>4 stars</option>
          <option value={3}>3 stars</option>
          <option value={2}>2 stars</option>
          <option value={1}>1 star</option>
        </select>
      </div>

      <div className={styles.comment}>
        <label>Comment:</label>
        <textarea
          value={comment}
          onChange={(e) => setComment(e.target.value)}
          placeholder="Tell us what you think..."
          minLength={10}
          maxLength={500}
          required
        />
      </div>

      {error && <div className={styles.error}>{error}</div>}

      <Button type="submit" isLoading={isLoading}>
        Submit Review
      </Button>
    </form>
  );
}
```

```typescript
// apps/frontend/src/features/product-reviews/ui/ReviewList.tsx
import { useEffect } from 'react';
import { useReviewsStore } from '../model/reviewsStore';
import { ReviewCard } from './ReviewCard';
import { Spinner } from '@/shared/ui/atoms';
import styles from './ReviewList.module.css';

interface Props {
  productId: string;
}

export function ReviewList({ productId }: Props) {
  const { reviews, isLoading, error, fetchReviews } = useReviewsStore();

  useEffect(() => {
    fetchReviews(productId);
  }, [productId, fetchReviews]);

  if (isLoading) {
    return <Spinner />;
  }

  if (error) {
    return <div className={styles.error}>Error: {error}</div>;
  }

  if (reviews.length === 0) {
    return <div className={styles.empty}>No reviews yet. Be the first to review!</div>;
  }

  return (
    <div className={styles.list}>
      <h3>{reviews.length} Reviews</h3>
      {reviews.map((review) => (
        <ReviewCard key={review.id} review={review} />
      ))}
    </div>
  );
}
```

### Step 3.6: Define Public API

```typescript
// apps/frontend/src/features/product-reviews/index.ts
export { ReviewForm } from './ui/ReviewForm';
export { ReviewList } from './ui/ReviewList';
export { useReviewsStore } from './model/reviewsStore';
export type { Review, CreateReviewDTO } from './types/review.types';
```

---

## Phase 4: Integration

### Step 4.1: Use in Page

```typescript
// apps/frontend/src/pages/product-detail/ProductDetailPage.tsx
import { useParams } from 'react-router-dom';
import { ProductInfo } from '@/entities/product';
import { ReviewForm, ReviewList } from '@/features/product-reviews';
import { useAuth } from '@/features/auth';

export function ProductDetailPage() {
  const { productId } = useParams();
  const { isAuthenticated } = useAuth();

  return (
    <div>
      <ProductInfo productId={productId!} />

      <section>
        <ReviewList productId={productId!} />

        {isAuthenticated && <ReviewForm productId={productId!} />}
      </section>
    </div>
  );
}
```

---

## Summary

**Full-stack workflow:**

1. **Shared Types** (`packages/shared-types/`)
   - Define entity schemas with Zod
   - Create DTO schemas
   - Export everything

2. **Backend** (`apps/backend/src/features/product-reviews/`)
   - Create database schema
   - Build Repository (data access)
   - Build Service (business logic)
   - Create Validators (Zod)
   - Create Routes (HTTP endpoints)
   - Write tests

3. **Frontend** (`apps/frontend/src/features/product-reviews/`)
   - Create API client (calls backend)
   - Build Zustand store (state management)
   - Create UI components (React)
   - Define public API (index.ts)

4. **Integration**
   - Use feature in pages
   - Test end-to-end

**Type safety:** Enforced from database → backend → API → frontend → UI

**Result:** A complete, type-safe feature that works across the entire stack.
