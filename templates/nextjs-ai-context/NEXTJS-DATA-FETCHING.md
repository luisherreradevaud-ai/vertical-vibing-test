# Next.js Data Fetching

**Purpose:** Data fetching strategies and patterns for Next.js App Router applications.

**Last Updated:** 2025-11-16

---

## Table of Contents

1. [Data Fetching Philosophy](#data-fetching-philosophy)
2. [Server Components (Default)](#server-components-default)
3. [Caching Strategies](#caching-strategies)
4. [Revalidation Patterns](#revalidation-patterns)
5. [Server Actions](#server-actions)
6. [Client-Side Fetching](#client-side-fetching)
7. [Streaming and Suspense](#streaming-and-suspense)
8. [Parallel Data Fetching](#parallel-data-fetching)
9. [Sequential Data Fetching](#sequential-data-fetching)
10. [Error Handling](#error-handling)
11. [Loading States](#loading-states)
12. [Common Patterns](#common-patterns)
13. [Anti-Patterns](#anti-patterns)

---

## Data Fetching Philosophy

**Next.js App Router Priority:**

```
1. Server Components (default)
   ↓ Fetch on the server, pass to client

2. Server Actions (mutations)
   ↓ Create, update, delete operations

3. Streaming (Suspense)
   ↓ Progressive rendering

4. Client-Side (only when necessary)
   ↓ Interactive, dynamic data
```

**Key Principles:**
- **Server by default** - Most data fetching happens in Server Components
- **Cache when possible** - Use Next.js built-in caching
- **Revalidate strategically** - Balance freshness and performance
- **Stream when slow** - Don't block the page on slow requests

---

## Server Components (Default)

**Server Components can use async/await directly.**

### Basic Data Fetching

```typescript
// app/(dashboard)/products/page.tsx
// Server Component (no 'use client')

import type { Product } from '@yourorg/shared-types';

export default async function ProductsPage() {
  // Fetch data directly in component
  const response = await fetch('http://localhost:3000/api/products');

  if (!response.ok) {
    throw new Error('Failed to fetch products');
  }

  const { data: products } = await response.json();

  return (
    <div>
      <h1>Products</h1>
      <ul>
        {products.map((product: Product) => (
          <li key={product.id}>{product.name}</li>
        ))}
      </ul>
    </div>
  );
}
```

### Fetching with TypeScript

```typescript
import type { Product } from '@yourorg/shared-types';
import type { ApiResponse } from '@/shared/types';

async function getProducts(): Promise<Product[]> {
  const response = await fetch('http://localhost:3000/api/products');

  if (!response.ok) {
    throw new Error('Failed to fetch products');
  }

  const data: ApiResponse<Product[]> = await response.json();
  return data.data;
}

export default async function ProductsPage() {
  const products = await getProducts();

  return (
    <div>
      {products.map(product => (
        <div key={product.id}>{product.name}</div>
      ))}
    </div>
  );
}
```

### Environment Variables

```typescript
// Use environment variables for API URLs
const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

async function getProducts(): Promise<Product[]> {
  const response = await fetch(`${API_URL}/api/products`);

  if (!response.ok) {
    throw new Error('Failed to fetch products');
  }

  const { data } = await response.json();
  return data;
}
```

---

## Caching Strategies

### Cache Options

Next.js provides four caching options:

```typescript
// 1. Force cache (static) - Default
fetch('http://localhost:3000/api/products', {
  cache: 'force-cache', // Cache indefinitely
});

// 2. No cache (dynamic)
fetch('http://localhost:3000/api/products', {
  cache: 'no-store', // Always fetch fresh data
});

// 3. Revalidate after time
fetch('http://localhost:3000/api/products', {
  next: {
    revalidate: 60, // Revalidate every 60 seconds
  },
});

// 4. Revalidate by tag
fetch('http://localhost:3000/api/products', {
  next: {
    tags: ['products'], // Tag for manual revalidation
  },
});
```

### When to Use Each Strategy

```typescript
// Static data (rarely changes)
async function getCategories() {
  const response = await fetch(`${API_URL}/api/categories`, {
    cache: 'force-cache', // Cache forever
  });
  return response.json();
}

// Dynamic data (user-specific, always fresh)
async function getUserProfile(userId: string) {
  const response = await fetch(`${API_URL}/api/users/${userId}`, {
    cache: 'no-store', // Never cache
  });
  return response.json();
}

// Time-based revalidation (product catalog)
async function getProducts() {
  const response = await fetch(`${API_URL}/api/products`, {
    next: { revalidate: 3600 }, // Revalidate every hour
  });
  return response.json();
}

// Tag-based revalidation (blog posts)
async function getPosts() {
  const response = await fetch(`${API_URL}/api/posts`, {
    next: { tags: ['posts'] }, // Manual revalidation
  });
  return response.json();
}
```

### Page-Level Caching

```typescript
// app/(dashboard)/products/page.tsx

export const revalidate = 60; // Revalidate page every 60 seconds

export const dynamic = 'force-static'; // Force static rendering
// OR
export const dynamic = 'force-dynamic'; // Force dynamic rendering

export default async function ProductsPage() {
  const products = await getProducts();
  return <div>...</div>;
}
```

---

## Revalidation Patterns

### Time-Based Revalidation

```typescript
// Revalidate every 60 seconds
async function getProducts() {
  const response = await fetch(`${API_URL}/api/products`, {
    next: { revalidate: 60 },
  });
  return response.json();
}
```

### On-Demand Revalidation (Path)

```typescript
// features/products/actions/createProduct.ts
'use server';

import { revalidatePath } from 'next/cache';

export async function createProduct(formData: FormData) {
  await fetch(`${API_URL}/api/products`, {
    method: 'POST',
    body: formData,
  });

  // Revalidate specific path
  revalidatePath('/products');

  // Revalidate all products pages
  revalidatePath('/products', 'layout');
}
```

### On-Demand Revalidation (Tag)

```typescript
// features/products/actions/updateProduct.ts
'use server';

import { revalidateTag } from 'next/cache';

export async function updateProduct(id: string, data: Partial<Product>) {
  await fetch(`${API_URL}/api/products/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });

  // Revalidate all fetches tagged with 'products'
  revalidateTag('products');
}
```

```typescript
// Fetch with tag
async function getProducts() {
  const response = await fetch(`${API_URL}/api/products`, {
    next: { tags: ['products'] },
  });
  return response.json();
}

async function getProduct(id: string) {
  const response = await fetch(`${API_URL}/api/products/${id}`, {
    next: { tags: ['products', `product-${id}`] },
  });
  return response.json();
}
```

### Revalidation After Mutation

```typescript
// features/products/actions/deleteProduct.ts
'use server';

import { revalidatePath, revalidateTag } from 'next/cache';
import { redirect } from 'next/navigation';

export async function deleteProduct(id: string) {
  await fetch(`${API_URL}/api/products/${id}`, {
    method: 'DELETE',
  });

  // Revalidate both path and tags
  revalidatePath('/products');
  revalidateTag('products');

  // Optionally redirect
  redirect('/products');
}
```

---

## Server Actions

**Use for mutations (create, update, delete).**

### Basic Server Action

```typescript
// features/products/actions/createProduct.ts
'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { createProductSchema, type CreateProductInput } from '@yourorg/shared-types';

export async function createProduct(formData: FormData) {
  // 1. Validate
  const validatedFields = createProductSchema.safeParse({
    name: formData.get('name'),
    price: Number(formData.get('price')),
    description: formData.get('description'),
  });

  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // 2. Mutate
  try {
    const response = await fetch(`${API_URL}/api/products`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(validatedFields.data),
    });

    if (!response.ok) {
      throw new Error('Failed to create product');
    }
  } catch (error) {
    return {
      message: 'Failed to create product',
    };
  }

  // 3. Revalidate and redirect
  revalidatePath('/products');
  redirect('/products');
}
```

### Server Action with JSON Input

```typescript
'use server';

import { createProductSchema, type CreateProductInput } from '@yourorg/shared-types';

export async function createProductJSON(input: CreateProductInput) {
  // Validate
  const validatedFields = createProductSchema.safeParse(input);

  if (!validatedFields.success) {
    return {
      success: false,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // Mutate
  try {
    const response = await fetch(`${API_URL}/api/products`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(validatedFields.data),
    });

    if (!response.ok) {
      return {
        success: false,
        message: 'Failed to create product',
      };
    }

    const { data } = await response.json();

    revalidatePath('/products');

    return {
      success: true,
      data,
    };
  } catch (error) {
    return {
      success: false,
      message: 'Network error',
    };
  }
}
```

### Using Server Actions in Client Components

```typescript
// features/products/ui/CreateProductButton.tsx
'use client';

import { useState, useTransition } from 'react';
import { createProductJSON } from '../actions/createProduct';
import type { CreateProductInput } from '@yourorg/shared-types';

export function CreateProductButton() {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  const handleCreate = () => {
    startTransition(async () => {
      const input: CreateProductInput = {
        name: 'New Product',
        price: 99.99,
        description: 'Product description',
      };

      const result = await createProductJSON(input);

      if (!result.success) {
        setError(result.message || 'Failed to create product');
      }
    });
  };

  return (
    <div>
      <button onClick={handleCreate} disabled={isPending}>
        {isPending ? 'Creating...' : 'Create Product'}
      </button>
      {error && <p className="error">{error}</p>}
    </div>
  );
}
```

---

## Client-Side Fetching

**Use only when necessary (real-time data, user interactions).**

### When to Use Client-Side Fetching

✅ **Use for:**
- Real-time data (chat, notifications)
- User-triggered requests (search, autocomplete)
- Polling/intervals
- Data that changes frequently based on user interaction

❌ **Don't use for:**
- Initial page load data (use Server Components)
- SEO-critical content
- Data that could be fetched on the server

### Client-Side Fetch with useEffect

```typescript
'use client';

import { useState, useEffect } from 'react';
import type { Product } from '@yourorg/shared-types';

export function ProductSearch({ query }: { query: string }) {
  const [products, setProducts] = useState<Product[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    if (!query) {
      setProducts([]);
      return;
    }

    let cancelled = false;

    async function searchProducts() {
      setIsLoading(true);
      setError(null);

      try {
        const response = await fetch(`/api/products/search?q=${query}`);

        if (!response.ok) {
          throw new Error('Search failed');
        }

        const { data } = await response.json();

        if (!cancelled) {
          setProducts(data);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err : new Error('Unknown error'));
        }
      } finally {
        if (!cancelled) {
          setIsLoading(false);
        }
      }
    }

    searchProducts();

    return () => {
      cancelled = true;
    };
  }, [query]);

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div>
      {products.map(product => (
        <div key={product.id}>{product.name}</div>
      ))}
    </div>
  );
}
```

### Client-Side Fetch with SWR

```typescript
'use client';

import useSWR from 'swr';
import type { Product } from '@yourorg/shared-types';

const fetcher = (url: string) => fetch(url).then(res => res.json());

export function ProductList() {
  const { data, error, isLoading, mutate } = useSWR<{ data: Product[] }>(
    '/api/products',
    fetcher,
    {
      revalidateOnFocus: false,
      revalidateOnReconnect: true,
    }
  );

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error loading products</div>;
  if (!data) return null;

  return (
    <div>
      {data.data.map(product => (
        <div key={product.id}>{product.name}</div>
      ))}
      <button onClick={() => mutate()}>Refresh</button>
    </div>
  );
}
```

### Polling Pattern

```typescript
'use client';

import { useState, useEffect } from 'react';

export function LiveProductCount() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    async function fetchCount() {
      const response = await fetch('/api/products/count');
      const { data } = await response.json();
      setCount(data.count);
    }

    // Initial fetch
    fetchCount();

    // Poll every 5 seconds
    const interval = setInterval(fetchCount, 5000);

    return () => clearInterval(interval);
  }, []);

  return <div>Live Product Count: {count}</div>;
}
```

---

## Streaming and Suspense

### Basic Suspense Pattern

```typescript
// app/(dashboard)/products/page.tsx

import { Suspense } from 'react';
import { ProductList } from '@/features/products/server/ProductList';
import { ProductSkeleton } from '@/features/products/ui/ProductSkeleton';

export default function ProductsPage() {
  return (
    <div>
      <h1>Products</h1>
      <Suspense fallback={<ProductSkeleton />}>
        <ProductList />
      </Suspense>
    </div>
  );
}
```

```typescript
// features/products/server/ProductList.tsx
// Server Component

async function getProducts() {
  const response = await fetch(`${API_URL}/api/products`, {
    cache: 'no-store',
  });
  return response.json();
}

export async function ProductList() {
  const { data: products } = await getProducts();

  return (
    <div>
      {products.map(product => (
        <div key={product.id}>{product.name}</div>
      ))}
    </div>
  );
}
```

### Multiple Suspense Boundaries

```typescript
// app/(dashboard)/products/[id]/page.tsx

import { Suspense } from 'react';

export default function ProductPage({ params }: { params: { id: string } }) {
  return (
    <div>
      <Suspense fallback={<div>Loading product...</div>}>
        <ProductDetails id={params.id} />
      </Suspense>

      <Suspense fallback={<div>Loading reviews...</div>}>
        <ProductReviews id={params.id} />
      </Suspense>

      <Suspense fallback={<div>Loading recommendations...</div>}>
        <RelatedProducts id={params.id} />
      </Suspense>
    </div>
  );
}
```

### Streaming with Loading.tsx

```typescript
// app/(dashboard)/products/loading.tsx

export default function Loading() {
  return (
    <div className="loading-skeleton">
      <div className="skeleton-header" />
      <div className="skeleton-grid">
        {Array.from({ length: 12 }).map((_, i) => (
          <div key={i} className="skeleton-card" />
        ))}
      </div>
    </div>
  );
}
```

---

## Parallel Data Fetching

**Fetch multiple requests simultaneously.**

### Basic Parallel Fetching

```typescript
// app/(dashboard)/dashboard/page.tsx

async function getProducts() {
  const response = await fetch(`${API_URL}/api/products`);
  return response.json();
}

async function getOrders() {
  const response = await fetch(`${API_URL}/api/orders`);
  return response.json();
}

async function getUsers() {
  const response = await fetch(`${API_URL}/api/users`);
  return response.json();
}

export default async function DashboardPage() {
  // Fetch in parallel using Promise.all
  const [productsData, ordersData, usersData] = await Promise.all([
    getProducts(),
    getOrders(),
    getUsers(),
  ]);

  return (
    <div>
      <ProductStats data={productsData.data} />
      <OrderStats data={ordersData.data} />
      <UserStats data={usersData.data} />
    </div>
  );
}
```

### Parallel with Suspense

```typescript
// Each component fetches independently in parallel

export default function DashboardPage() {
  return (
    <div>
      <Suspense fallback={<div>Loading products...</div>}>
        <ProductStats />
      </Suspense>

      <Suspense fallback={<div>Loading orders...</div>}>
        <OrderStats />
      </Suspense>

      <Suspense fallback={<div>Loading users...</div>}>
        <UserStats />
      </Suspense>
    </div>
  );
}

// Each component fetches its own data
async function ProductStats() {
  const { data } = await fetch(`${API_URL}/api/products/stats`).then(r => r.json());
  return <div>Total Products: {data.count}</div>;
}

async function OrderStats() {
  const { data } = await fetch(`${API_URL}/api/orders/stats`).then(r => r.json());
  return <div>Total Orders: {data.count}</div>;
}
```

---

## Sequential Data Fetching

**Fetch requests that depend on previous results.**

### Waterfall Pattern

```typescript
// app/(dashboard)/products/[id]/page.tsx

async function getProduct(id: string) {
  const response = await fetch(`${API_URL}/api/products/${id}`);
  return response.json();
}

async function getRelatedProducts(categoryId: string) {
  const response = await fetch(`${API_URL}/api/products?category=${categoryId}`);
  return response.json();
}

export default async function ProductPage({ params }: { params: { id: string } }) {
  // 1. Fetch product first
  const { data: product } = await getProduct(params.id);

  // 2. Then fetch related products (depends on product.categoryId)
  const { data: relatedProducts } = await getRelatedProducts(product.categoryId);

  return (
    <div>
      <ProductDetails product={product} />
      <RelatedProducts products={relatedProducts} />
    </div>
  );
}
```

### Breaking Waterfalls with Suspense

```typescript
// app/(dashboard)/products/[id]/page.tsx

export default async function ProductPage({ params }: { params: { id: string } }) {
  // Fetch product
  const { data: product } = await getProduct(params.id);

  return (
    <div>
      <ProductDetails product={product} />

      {/* Related products fetch starts immediately */}
      <Suspense fallback={<div>Loading related...</div>}>
        <RelatedProducts categoryId={product.categoryId} />
      </Suspense>
    </div>
  );
}

async function RelatedProducts({ categoryId }: { categoryId: string }) {
  const { data } = await getRelatedProducts(categoryId);
  return <div>...</div>;
}
```

---

## Error Handling

### Error Boundary (error.tsx)

```typescript
// app/(dashboard)/products/error.tsx
'use client';

import { useEffect } from 'react';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error('Error fetching products:', error);
  }, [error]);

  return (
    <div className="error-container">
      <h2>Something went wrong!</h2>
      <p>{error.message}</p>
      <button onClick={reset}>Try again</button>
    </div>
  );
}
```

### Try-Catch in Server Components

```typescript
async function getProducts(): Promise<Product[]> {
  try {
    const response = await fetch(`${API_URL}/api/products`);

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const { data } = await response.json();
    return data;
  } catch (error) {
    console.error('Failed to fetch products:', error);
    return []; // Return empty array as fallback
  }
}

export default async function ProductsPage() {
  const products = await getProducts();

  if (products.length === 0) {
    return <div>No products found or error loading products</div>;
  }

  return <div>...</div>;
}
```

### Error Handling in Server Actions

```typescript
'use server';

export async function createProduct(formData: FormData) {
  try {
    const response = await fetch(`${API_URL}/api/products`, {
      method: 'POST',
      body: formData,
    });

    if (!response.ok) {
      const errorData = await response.json();
      return {
        success: false,
        message: errorData.message || 'Failed to create product',
      };
    }

    const { data } = await response.json();

    revalidatePath('/products');

    return {
      success: true,
      data,
    };
  } catch (error) {
    return {
      success: false,
      message: error instanceof Error ? error.message : 'Network error',
    };
  }
}
```

---

## Loading States

### Page-Level Loading (loading.tsx)

```typescript
// app/(dashboard)/products/loading.tsx

export default function Loading() {
  return (
    <div>
      <h1>Products</h1>
      <div className="skeleton-grid">
        {Array.from({ length: 12 }).map((_, i) => (
          <div key={i} className="skeleton-card">
            <div className="skeleton-image" />
            <div className="skeleton-title" />
            <div className="skeleton-price" />
          </div>
        ))}
      </div>
    </div>
  );
}
```

### Component-Level Loading (Suspense)

```typescript
import { Suspense } from 'react';

export default function ProductsPage() {
  return (
    <div>
      <h1>Products</h1>
      <Suspense fallback={<ProductListSkeleton />}>
        <ProductList />
      </Suspense>
    </div>
  );
}

function ProductListSkeleton() {
  return (
    <div className="grid">
      {Array.from({ length: 12 }).map((_, i) => (
        <div key={i} className="skeleton-card" />
      ))}
    </div>
  );
}
```

### Loading State in Client Components

```typescript
'use client';

import { useState, useTransition } from 'react';

export function RefreshButton() {
  const [isPending, startTransition] = useTransition();

  return (
    <button
      onClick={() => {
        startTransition(async () => {
          await fetch('/api/revalidate');
        });
      }}
      disabled={isPending}
    >
      {isPending ? 'Refreshing...' : 'Refresh'}
    </button>
  );
}
```

---

## Common Patterns

### Data Fetching Helper

```typescript
// shared/lib/api.ts

export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
    public code?: string
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

interface FetchOptions extends RequestInit {
  baseUrl?: string;
}

export async function apiClient<T>(
  endpoint: string,
  options: FetchOptions = {}
): Promise<T> {
  const { baseUrl = process.env.NEXT_PUBLIC_API_URL, ...fetchOptions } = options;

  const response = await fetch(`${baseUrl}${endpoint}`, {
    ...fetchOptions,
    headers: {
      'Content-Type': 'application/json',
      ...fetchOptions.headers,
    },
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new ApiError(
      errorData.message || 'Request failed',
      response.status,
      errorData.code
    );
  }

  return response.json();
}

// Usage
const { data: products } = await apiClient<ApiResponse<Product[]>>('/api/products');
```

### Authenticated Requests

```typescript
// shared/lib/api.ts

export async function authenticatedFetch<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  // Get token from cookies or session
  const token = getAuthToken();

  const response = await fetch(`${API_URL}${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
      ...options.headers,
    },
  });

  if (response.status === 401) {
    // Handle unauthorized
    redirect('/login');
  }

  if (!response.ok) {
    throw new Error('Request failed');
  }

  return response.json();
}
```

### Request Deduplication

```typescript
// Next.js automatically deduplicates identical fetch requests

// These two will only make ONE network request:
const response1 = await fetch(`${API_URL}/api/products/1`);
const response2 = await fetch(`${API_URL}/api/products/1`);

// To prevent deduplication:
const response = await fetch(`${API_URL}/api/products/1`, {
  cache: 'no-store',
});
```

---

## Anti-Patterns

### ❌ 1. Client-Side Fetching for Initial Data

```typescript
// ❌ Bad - Fetching in Client Component
'use client';

export function ProductList() {
  const [products, setProducts] = useState<Product[]>([]);

  useEffect(() => {
    fetch('/api/products')
      .then(res => res.json())
      .then(data => setProducts(data.data));
  }, []);

  return <div>...</div>;
}

// ✅ Good - Fetch in Server Component
export async function ProductsPage() {
  const { data: products } = await fetch(`${API_URL}/api/products`).then(r => r.json());
  return <ProductList products={products} />;
}
```

### ❌ 2. Not Using Cache Options

```typescript
// ❌ Bad - No caching strategy specified
async function getProducts() {
  const response = await fetch(`${API_URL}/api/products`);
  return response.json();
}

// ✅ Good - Explicit caching strategy
async function getProducts() {
  const response = await fetch(`${API_URL}/api/products`, {
    next: { revalidate: 60 }, // Revalidate every 60 seconds
  });
  return response.json();
}
```

### ❌ 3. Sequential Fetching When Parallel is Possible

```typescript
// ❌ Bad - Sequential (slow)
const products = await getProducts();
const categories = await getCategories();
const brands = await getBrands();

// ✅ Good - Parallel (fast)
const [products, categories, brands] = await Promise.all([
  getProducts(),
  getCategories(),
  getBrands(),
]);
```

### ❌ 4. Not Handling Errors

```typescript
// ❌ Bad - No error handling
async function getProducts() {
  const response = await fetch(`${API_URL}/api/products`);
  const data = await response.json(); // Will crash if fetch fails
  return data;
}

// ✅ Good - Proper error handling
async function getProducts() {
  try {
    const response = await fetch(`${API_URL}/api/products`);

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    return await response.json();
  } catch (error) {
    console.error('Failed to fetch products:', error);
    return { data: [] }; // Fallback
  }
}
```

### ❌ 5. Not Revalidating After Mutations

```typescript
// ❌ Bad - No revalidation
'use server';

export async function createProduct(formData: FormData) {
  await fetch(`${API_URL}/api/products`, {
    method: 'POST',
    body: formData,
  });

  redirect('/products'); // Old cached data shown!
}

// ✅ Good - Revalidate before redirect
'use server';

export async function createProduct(formData: FormData) {
  await fetch(`${API_URL}/api/products`, {
    method: 'POST',
    body: formData,
  });

  revalidatePath('/products'); // Fresh data
  redirect('/products');
}
```

### ❌ 6. Blocking UI with Sequential Suspense

```typescript
// ❌ Bad - Product blocks reviews
export default async function ProductPage({ params }: { params: { id: string } }) {
  const product = await getProduct(params.id);
  const reviews = await getReviews(params.id); // Waits for product

  return (
    <div>
      <ProductDetails product={product} />
      <ReviewsList reviews={reviews} />
    </div>
  );
}

// ✅ Good - Independent Suspense boundaries
export default async function ProductPage({ params }: { params: { id: string } }) {
  return (
    <div>
      <Suspense fallback={<div>Loading...</div>}>
        <ProductDetails id={params.id} />
      </Suspense>

      <Suspense fallback={<div>Loading reviews...</div>}>
        <ReviewsList id={params.id} />
      </Suspense>
    </div>
  );
}
```

---

## Summary

### Data Fetching Decision Tree

```
Where should I fetch data?

Is this initial page load data?
├─ YES → Server Component
│   └─ Does it change frequently?
│       ├─ YES → cache: 'no-store'
│       ├─ SOMETIMES → next: { revalidate: X }
│       └─ NO → cache: 'force-cache'
│
└─ NO → Is this a mutation?
    ├─ YES → Server Action
    │   └─ Don't forget revalidatePath/revalidateTag
    │
    └─ NO → Is this interactive/real-time?
        ├─ YES → Client-side fetch (useEffect or SWR)
        └─ NO → Reconsider if you really need this
```

### Caching Strategy Cheat Sheet

| Data Type | Cache Strategy | Revalidation |
|-----------|---------------|--------------|
| Static (categories, terms) | `force-cache` | Manual via tag |
| Dynamic (user-specific) | `no-store` | N/A |
| Time-based (products) | `revalidate: 3600` | Every hour |
| Event-based (blog posts) | `tags: ['posts']` | On mutation |

### Performance Checklist

- [ ] Fetch in Server Components by default
- [ ] Use appropriate cache strategy
- [ ] Fetch in parallel when possible
- [ ] Use Suspense for streaming
- [ ] Revalidate after mutations
- [ ] Handle errors gracefully
- [ ] Provide loading states
- [ ] Avoid client-side fetching for initial data

---

**For more patterns, see:**
- `NEXTJS-ARCHITECTURE.md` - Project structure
- `NEXTJS-COMPONENT-STANDARDS.md` - Component patterns
- `NEXTJS-STATE-MANAGEMENT.md` - State management
- `/shared/lib/api.ts` - API client utilities
