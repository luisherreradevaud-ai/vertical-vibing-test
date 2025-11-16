# Next.js State Management

**Purpose:** State management patterns for Next.js App Router applications using Server Components, Server Actions, and Zustand for client-side state.

**Last Updated:** 2025-11-16

---

## Table of Contents

1. [State Management Philosophy](#state-management-philosophy)
2. [Server State vs Client State](#server-state-vs-client-state)
3. [Server Components (Default)](#server-components-default)
4. [Server Actions](#server-actions)
5. [Zustand for Client State](#zustand-for-client-state)
6. [Store Organization in FSD](#store-organization-in-fsd)
7. [Async Actions](#async-actions)
8. [Middleware](#middleware)
9. [Selectors and Performance](#selectors-and-performance)
10. [Persistence](#persistence)
11. [DevTools](#devtools)
12. [Common Patterns](#common-patterns)
13. [Anti-Patterns](#anti-patterns)

---

## State Management Philosophy

**Next.js App Router Priority:**

```
1. Server Components (default)
   ↓ Most data fetching happens here

2. Server Actions
   ↓ Mutations and form submissions

3. URL State (searchParams)
   ↓ Shareable, bookmarkable state

4. Zustand (client-side only)
   ↓ UI state, temporary client state
```

**Key Principle:** Minimize client-side state. Prefer server state whenever possible.

---

## Server State vs Client State

### Decision Tree

```
What kind of state do you need?

Is this data from the backend (products, users, orders)?
├─ YES → Server State
│   └─ Fetch in Server Component
│       └─ Pass to Client Components as props
│
└─ NO → Is this UI state (modals, filters, selected items)?
    └─ YES → Client State
        └─ Does it need to be shared across components?
            ├─ YES → Zustand store
            └─ NO → Local useState
```

### Examples

**Server State (fetch in Server Components):**
- Product catalog
- User profile
- Order history
- Reviews
- Any data from database

**Client State (Zustand or useState):**
- Modal open/closed
- Selected filters
- Shopping cart (before checkout)
- UI themes
- Form draft state
- Sidebar collapsed/expanded

**URL State (searchParams):**
- Current page number
- Active filters
- Sort order
- Search query
- Selected category

---

## Server Components (Default)

**Most state should come from Server Components.**

### Basic Data Fetching

```typescript
// app/(dashboard)/products/page.tsx
// Server Component (no 'use client')

import { ProductList } from '@/features/products/ui/ProductList';

export default async function ProductsPage() {
  // Fetch data in Server Component
  const response = await fetch('http://localhost:3000/api/products', {
    cache: 'no-store', // Always fresh
  });

  const { data: products } = await response.json();

  // Pass to Client Component
  return (
    <div>
      <h1>Products</h1>
      <ProductList products={products} />
    </div>
  );
}
```

### Using SearchParams for State

```typescript
// app/(dashboard)/products/page.tsx

interface PageProps {
  searchParams: {
    category?: string;
    sort?: string;
    page?: string;
  };
}

export default async function ProductsPage({ searchParams }: PageProps) {
  const category = searchParams.category || 'all';
  const sort = searchParams.sort || 'newest';
  const page = parseInt(searchParams.page || '1');

  // Fetch with filters from URL
  const response = await fetch(
    `http://localhost:3000/api/products?category=${category}&sort=${sort}&page=${page}`,
    { cache: 'no-store' }
  );

  const { data: products, meta } = await response.json();

  return (
    <div>
      <ProductFilters currentCategory={category} currentSort={sort} />
      <ProductList products={products} />
      <Pagination currentPage={page} totalPages={meta.totalPages} />
    </div>
  );
}
```

```typescript
// features/products/ui/ProductFilters.tsx
'use client';

import { useRouter, useSearchParams } from 'next/navigation';

interface ProductFiltersProps {
  currentCategory: string;
  currentSort: string;
}

export function ProductFilters({ currentCategory, currentSort }: ProductFiltersProps) {
  const router = useRouter();
  const searchParams = useSearchParams();

  const updateFilter = (key: string, value: string) => {
    const params = new URLSearchParams(searchParams.toString());
    params.set(key, value);
    params.set('page', '1'); // Reset to first page
    router.push(`/products?${params.toString()}`);
  };

  return (
    <div>
      <select
        value={currentCategory}
        onChange={e => updateFilter('category', e.target.value)}
      >
        <option value="all">All Categories</option>
        <option value="electronics">Electronics</option>
        <option value="clothing">Clothing</option>
      </select>

      <select
        value={currentSort}
        onChange={e => updateFilter('sort', e.target.value)}
      >
        <option value="newest">Newest</option>
        <option value="price-asc">Price: Low to High</option>
        <option value="price-desc">Price: High to Low</option>
      </select>
    </div>
  );
}
```

### Revalidating Server Data

```typescript
// features/products/actions/createProduct.ts
'use server';

import { revalidatePath, revalidateTag } from 'next/cache';

export async function createProduct(formData: FormData) {
  // Create product
  await fetch('http://localhost:3000/api/products', {
    method: 'POST',
    body: formData,
  });

  // Revalidate specific path
  revalidatePath('/products');

  // Or revalidate by tag
  revalidateTag('products');
}
```

```typescript
// Server Component with cache tags
export async function ProductsContainer() {
  const response = await fetch('http://localhost:3000/api/products', {
    next: {
      tags: ['products'], // Tag for revalidation
      revalidate: 60, // Revalidate every 60 seconds
    },
  });

  const { data: products } = await response.json();
  return <ProductList products={products} />;
}
```

---

## Server Actions

**Use for mutations and form submissions.**

### Basic Server Action

```typescript
// features/products/actions/createProduct.ts
'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { createProductSchema } from '@yourorg/shared-types';

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
  const response = await fetch('http://localhost:3000/api/products', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(validatedFields.data),
  });

  if (!response.ok) {
    return {
      message: 'Failed to create product',
    };
  }

  // 3. Revalidate and redirect
  revalidatePath('/products');
  redirect('/products');
}
```

### Server Action with Client Form

```typescript
// features/products/ui/CreateProductForm.tsx
'use client';

import { useFormState, useFormStatus } from 'react-dom';
import { createProduct } from '../actions/createProduct';

export function CreateProductForm() {
  const [state, formAction] = useFormState(createProduct, null);

  return (
    <form action={formAction}>
      <div>
        <label htmlFor="name">Name</label>
        <input id="name" name="name" required />
        {state?.errors?.name && (
          <p className="error">{state.errors.name[0]}</p>
        )}
      </div>

      <div>
        <label htmlFor="price">Price</label>
        <input id="price" name="price" type="number" step="0.01" required />
        {state?.errors?.price && (
          <p className="error">{state.errors.price[0]}</p>
        )}
      </div>

      <SubmitButton />

      {state?.message && <p className="error">{state.message}</p>}
    </form>
  );
}

function SubmitButton() {
  const { pending } = useFormStatus();

  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Creating...' : 'Create Product'}
    </button>
  );
}
```

### Optimistic Updates with Server Actions

```typescript
// features/products/ui/ProductList.tsx
'use client';

import { useOptimistic } from 'react';
import { deleteProduct } from '../actions/deleteProduct';
import type { Product } from '@yourorg/shared-types';

interface ProductListProps {
  products: Product[];
}

export function ProductList({ products }: ProductListProps) {
  const [optimisticProducts, addOptimisticDelete] = useOptimistic(
    products,
    (state, productId: string) => state.filter(p => p.id !== productId)
  );

  const handleDelete = async (productId: string) => {
    // Immediately update UI
    addOptimisticDelete(productId);

    // Perform server action
    await deleteProduct(productId);
  };

  return (
    <div>
      {optimisticProducts.map(product => (
        <div key={product.id}>
          <h3>{product.name}</h3>
          <button onClick={() => handleDelete(product.id)}>Delete</button>
        </div>
      ))}
    </div>
  );
}
```

---

## Zustand for Client State

**Use only for client-side UI state.**

### Store Organization in FSD

```
features/
└── products/
    ├── model/
    │   ├── productsStore.ts       # Main store
    │   ├── types.ts                # Store types
    │   └── index.ts                # Public API
    ├── ui/                         # Components
    └── actions/                    # Server Actions
```

### Basic Zustand Store

```typescript
// features/products/model/productsStore.ts

import { create } from 'zustand';
import type { Product } from '@yourorg/shared-types';

interface ProductsState {
  // State
  products: Product[];
  selectedProductId: string | null;
  isFilterVisible: boolean;

  // Actions
  setProducts: (products: Product[]) => void;
  selectProduct: (id: string | null) => void;
  toggleFilter: () => void;

  // Computed/Selectors
  selectedProduct: () => Product | null;
}

export const useProductsStore = create<ProductsState>((set, get) => ({
  // Initial state
  products: [],
  selectedProductId: null,
  isFilterVisible: false,

  // Actions
  setProducts: (products) => set({ products }),

  selectProduct: (id) => set({ selectedProductId: id }),

  toggleFilter: () => set((state) => ({
    isFilterVisible: !state.isFilterVisible
  })),

  // Computed
  selectedProduct: () => {
    const { products, selectedProductId } = get();
    return products.find(p => p.id === selectedProductId) || null;
  },
}));
```

### Using the Store

```typescript
// features/products/ui/ProductList.tsx
'use client';

import { useEffect } from 'react';
import { useProductsStore } from '../model/productsStore';
import type { Product } from '@yourorg/shared-types';

interface ProductListProps {
  products: Product[]; // From Server Component
}

export function ProductList({ products: initialProducts }: ProductListProps) {
  // Subscribe to store
  const products = useProductsStore(state => state.products);
  const selectedId = useProductsStore(state => state.selectedProductId);
  const selectProduct = useProductsStore(state => state.selectProduct);
  const setProducts = useProductsStore(state => state.setProducts);

  // Initialize store with server data
  useEffect(() => {
    setProducts(initialProducts);
  }, [initialProducts, setProducts]);

  return (
    <div>
      {products.map(product => (
        <div
          key={product.id}
          onClick={() => selectProduct(product.id)}
          style={{
            backgroundColor: product.id === selectedId ? 'lightblue' : 'white'
          }}
        >
          {product.name}
        </div>
      ))}
    </div>
  );
}
```

### Selector Pattern for Performance

```typescript
// ❌ Bad - Subscribes to entire store
export function ProductCount() {
  const store = useProductsStore();
  return <div>Count: {store.products.length}</div>;
}

// ✅ Good - Subscribes only to products array
export function ProductCount() {
  const count = useProductsStore(state => state.products.length);
  return <div>Count: {count}</div>;
}

// ✅ Better - Memoized selector
import { shallow } from 'zustand/shallow';

export function ProductStats() {
  const { count, avgPrice } = useProductsStore(
    state => ({
      count: state.products.length,
      avgPrice: state.products.reduce((sum, p) => sum + p.price, 0) / state.products.length,
    }),
    shallow // Shallow comparison
  );

  return (
    <div>
      <p>Count: {count}</p>
      <p>Avg Price: ${avgPrice.toFixed(2)}</p>
    </div>
  );
}
```

---

## Async Actions

### Client-Side Async Actions

```typescript
// features/products/model/productsStore.ts

import { create } from 'zustand';
import type { Product } from '@yourorg/shared-types';

interface ProductsState {
  products: Product[];
  isLoading: boolean;
  error: string | null;

  fetchProducts: () => Promise<void>;
  addProduct: (product: Omit<Product, 'id'>) => Promise<void>;
}

export const useProductsStore = create<ProductsState>((set, get) => ({
  products: [],
  isLoading: false,
  error: null,

  fetchProducts: async () => {
    set({ isLoading: true, error: null });

    try {
      const response = await fetch('/api/products');
      const { data } = await response.json();
      set({ products: data, isLoading: false });
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Failed to fetch products',
        isLoading: false,
      });
    }
  },

  addProduct: async (product) => {
    set({ isLoading: true, error: null });

    try {
      const response = await fetch('/api/products', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(product),
      });

      const { data } = await response.json();

      set((state) => ({
        products: [...state.products, data],
        isLoading: false,
      }));
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Failed to add product',
        isLoading: false,
      });
    }
  },
}));
```

### Usage with Loading States

```typescript
'use client';

import { useProductsStore } from '../model/productsStore';

export function ProductList() {
  const products = useProductsStore(state => state.products);
  const isLoading = useProductsStore(state => state.isLoading);
  const error = useProductsStore(state => state.error);
  const fetchProducts = useProductsStore(state => state.fetchProducts);

  useEffect(() => {
    fetchProducts();
  }, [fetchProducts]);

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div>
      {products.map(product => (
        <div key={product.id}>{product.name}</div>
      ))}
    </div>
  );
}
```

---

## Middleware

### DevTools Middleware

```typescript
// features/products/model/productsStore.ts

import { create } from 'zustand';
import { devtools } from 'zustand/middleware';

interface ProductsState {
  products: Product[];
  setProducts: (products: Product[]) => void;
}

export const useProductsStore = create<ProductsState>()(
  devtools(
    (set) => ({
      products: [],
      setProducts: (products) => set({ products }, false, 'setProducts'),
    }),
    {
      name: 'ProductsStore', // Name in DevTools
    }
  )
);
```

### Persist Middleware

```typescript
// features/cart/model/cartStore.ts

import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { Product } from '@yourorg/shared-types';

interface CartItem {
  product: Product;
  quantity: number;
}

interface CartState {
  items: CartItem[];
  addItem: (product: Product) => void;
  removeItem: (productId: string) => void;
  clearCart: () => void;
}

export const useCartStore = create<CartState>()(
  persist(
    (set) => ({
      items: [],

      addItem: (product) =>
        set((state) => {
          const existingItem = state.items.find(
            item => item.product.id === product.id
          );

          if (existingItem) {
            return {
              items: state.items.map(item =>
                item.product.id === product.id
                  ? { ...item, quantity: item.quantity + 1 }
                  : item
              ),
            };
          }

          return {
            items: [...state.items, { product, quantity: 1 }],
          };
        }),

      removeItem: (productId) =>
        set((state) => ({
          items: state.items.filter(item => item.product.id !== productId),
        })),

      clearCart: () => set({ items: [] }),
    }),
    {
      name: 'cart-storage', // localStorage key
    }
  )
);
```

### Combining Middleware

```typescript
import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';

export const useCartStore = create<CartState>()(
  devtools(
    persist(
      (set) => ({
        // ... store implementation
      }),
      {
        name: 'cart-storage',
      }
    ),
    {
      name: 'CartStore',
    }
  )
);
```

### Immer Middleware (Immutable Updates)

```typescript
import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';

interface ProductsState {
  products: Product[];
  updateProductPrice: (id: string, price: number) => void;
}

export const useProductsStore = create<ProductsState>()(
  immer((set) => ({
    products: [],

    // With immer, you can "mutate" the draft state
    updateProductPrice: (id, price) =>
      set((draft) => {
        const product = draft.products.find(p => p.id === id);
        if (product) {
          product.price = price; // Looks like mutation, but Immer makes it immutable
        }
      }),
  }))
);
```

---

## Selectors and Performance

### Basic Selectors

```typescript
// features/products/model/selectors.ts

import { useProductsStore } from './productsStore';

// Simple selector
export const useProducts = () => useProductsStore(state => state.products);

// Computed selector
export const useProductCount = () =>
  useProductsStore(state => state.products.length);

// Filtered selector
export const useActiveProducts = () =>
  useProductsStore(state => state.products.filter(p => p.isActive));

// Single product selector
export const useProduct = (id: string) =>
  useProductsStore(state => state.products.find(p => p.id === id));
```

### Memoized Selectors

```typescript
// features/products/model/selectors.ts

import { useProductsStore } from './productsStore';
import { useMemo } from 'react';

export const useExpensiveProducts = (minPrice: number) => {
  const products = useProductsStore(state => state.products);

  return useMemo(
    () => products.filter(p => p.price >= minPrice),
    [products, minPrice]
  );
};

export const useProductStats = () => {
  const products = useProductsStore(state => state.products);

  return useMemo(() => {
    const total = products.length;
    const avgPrice = products.reduce((sum, p) => sum + p.price, 0) / total;
    const maxPrice = Math.max(...products.map(p => p.price));
    const minPrice = Math.min(...products.map(p => p.price));

    return { total, avgPrice, maxPrice, minPrice };
  }, [products]);
};
```

### Shallow Equality

```typescript
import { shallow } from 'zustand/shallow';

// Without shallow - re-renders on any state change
const { products, selectedId } = useProductsStore();

// With shallow - only re-renders if products or selectedId change
const { products, selectedId } = useProductsStore(
  state => ({ products: state.products, selectedId: state.selectedProductId }),
  shallow
);
```

---

## Persistence

### LocalStorage Persistence

```typescript
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';

interface UIState {
  theme: 'light' | 'dark';
  sidebarCollapsed: boolean;
  setTheme: (theme: 'light' | 'dark') => void;
  toggleSidebar: () => void;
}

export const useUIStore = create<UIState>()(
  persist(
    (set) => ({
      theme: 'light',
      sidebarCollapsed: false,

      setTheme: (theme) => set({ theme }),
      toggleSidebar: () => set((state) => ({
        sidebarCollapsed: !state.sidebarCollapsed
      })),
    }),
    {
      name: 'ui-storage',
      storage: createJSONStorage(() => localStorage),
    }
  )
);
```

### SessionStorage Persistence

```typescript
export const useFiltersStore = create<FiltersState>()(
  persist(
    (set) => ({
      // ... store implementation
    }),
    {
      name: 'filters-storage',
      storage: createJSONStorage(() => sessionStorage),
    }
  )
);
```

### Partial Persistence

```typescript
interface UserState {
  user: User | null;
  token: string | null;
  preferences: UserPreferences;

  // Transient state (not persisted)
  isLoading: boolean;
  error: string | null;
}

export const useUserStore = create<UserState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      preferences: {},
      isLoading: false,
      error: null,
      // ...
    }),
    {
      name: 'user-storage',
      partialize: (state) => ({
        // Only persist these fields
        user: state.user,
        token: state.token,
        preferences: state.preferences,
      }),
    }
  )
);
```

### Hydration Handling

```typescript
'use client';

import { useEffect, useState } from 'react';
import { useCartStore } from '../model/cartStore';

export function CartButton() {
  const [hydrated, setHydrated] = useState(false);
  const itemCount = useCartStore(state => state.items.length);

  useEffect(() => {
    setHydrated(true);
  }, []);

  if (!hydrated) {
    return <button>Cart (0)</button>; // Prevent hydration mismatch
  }

  return <button>Cart ({itemCount})</button>;
}
```

---

## DevTools

### Redux DevTools Integration

```typescript
import { create } from 'zustand';
import { devtools } from 'zustand/middleware';

export const useProductsStore = create<ProductsState>()(
  devtools(
    (set) => ({
      products: [],

      // Action name appears in DevTools
      setProducts: (products) => set({ products }, false, 'setProducts'),

      addProduct: (product) => set(
        (state) => ({ products: [...state.products, product] }),
        false,
        'addProduct'
      ),
    }),
    {
      name: 'ProductsStore',
      enabled: process.env.NODE_ENV === 'development',
    }
  )
);
```

### Custom DevTools Actions

```typescript
export const useProductsStore = create<ProductsState>()(
  devtools(
    (set) => ({
      products: [],

      setProducts: (products) =>
        set({ products }, false, {
          type: 'products/set',
          payload: products,
        }),

      updateProduct: (id, updates) =>
        set(
          (state) => ({
            products: state.products.map(p =>
              p.id === id ? { ...p, ...updates } : p
            ),
          }),
          false,
          {
            type: 'products/update',
            payload: { id, updates },
          }
        ),
    }),
    { name: 'ProductsStore' }
  )
);
```

---

## Common Patterns

### Resetting Store State

```typescript
interface ProductsState {
  products: Product[];
  selectedId: string | null;
  filters: Filters;

  setProducts: (products: Product[]) => void;
  reset: () => void;
}

const initialState = {
  products: [],
  selectedId: null,
  filters: {},
};

export const useProductsStore = create<ProductsState>((set) => ({
  ...initialState,

  setProducts: (products) => set({ products }),

  reset: () => set(initialState),
}));
```

### Slices Pattern (Multiple Stores)

```typescript
// features/products/model/slices/productsSlice.ts
export interface ProductsSlice {
  products: Product[];
  setProducts: (products: Product[]) => void;
}

export const createProductsSlice: StateCreator<ProductsSlice> = (set) => ({
  products: [],
  setProducts: (products) => set({ products }),
});

// features/products/model/slices/filtersSlice.ts
export interface FiltersSlice {
  filters: Filters;
  setFilters: (filters: Filters) => void;
}

export const createFiltersSlice: StateCreator<FiltersSlice> = (set) => ({
  filters: {},
  setFilters: (filters) => set({ filters }),
});

// features/products/model/productsStore.ts
import { create } from 'zustand';
import { createProductsSlice, type ProductsSlice } from './slices/productsSlice';
import { createFiltersSlice, type FiltersSlice } from './slices/filtersSlice';

type ProductsStore = ProductsSlice & FiltersSlice;

export const useProductsStore = create<ProductsStore>((...args) => ({
  ...createProductsSlice(...args),
  ...createFiltersSlice(...args),
}));
```

### Computed Values

```typescript
interface ProductsState {
  products: Product[];

  // Computed properties (functions)
  totalCount: () => number;
  averagePrice: () => number;
  mostExpensive: () => Product | null;
}

export const useProductsStore = create<ProductsState>((set, get) => ({
  products: [],

  totalCount: () => get().products.length,

  averagePrice: () => {
    const { products } = get();
    if (products.length === 0) return 0;
    return products.reduce((sum, p) => sum + p.price, 0) / products.length;
  },

  mostExpensive: () => {
    const { products } = get();
    if (products.length === 0) return null;
    return products.reduce((max, p) => p.price > max.price ? p : max);
  },
}));

// Usage
const totalCount = useProductsStore(state => state.totalCount());
const avgPrice = useProductsStore(state => state.averagePrice());
```

---

## Anti-Patterns

### ❌ 1. Using Zustand for Server State

```typescript
// ❌ Bad - Don't use Zustand for server data
export const useProductsStore = create<ProductsState>((set) => ({
  products: [],

  fetchProducts: async () => {
    const response = await fetch('/api/products');
    const { data } = await response.json();
    set({ products: data });
  },
}));

// ✅ Good - Fetch in Server Component
export async function ProductsContainer() {
  const response = await fetch('http://localhost:3000/api/products');
  const { data: products } = await response.json();
  return <ProductList products={products} />;
}
```

### ❌ 2. Not Using Selectors

```typescript
// ❌ Bad - Component re-renders on any store change
export function ProductCount() {
  const store = useProductsStore();
  return <div>{store.products.length}</div>;
}

// ✅ Good - Only re-renders when products array changes
export function ProductCount() {
  const count = useProductsStore(state => state.products.length);
  return <div>{count}</div>;
}
```

### ❌ 3. Mutating State Directly

```typescript
// ❌ Bad - Direct mutation
const updateProduct = (id: string, updates: Partial<Product>) => {
  const product = get().products.find(p => p.id === id);
  if (product) {
    product.name = updates.name; // MUTATION!
  }
};

// ✅ Good - Immutable update
const updateProduct = (id: string, updates: Partial<Product>) => {
  set((state) => ({
    products: state.products.map(p =>
      p.id === id ? { ...p, ...updates } : p
    ),
  }));
};
```

### ❌ 4. Creating Stores Inside Components

```typescript
// ❌ Bad - New store instance every render
export function ProductList() {
  const useProductsStore = create(() => ({ products: [] }));
  // ...
}

// ✅ Good - Store created outside component
const useProductsStore = create(() => ({ products: [] }));

export function ProductList() {
  const products = useProductsStore(state => state.products);
  // ...
}
```

### ❌ 5. Not Handling Hydration

```typescript
// ❌ Bad - Hydration mismatch with persisted state
export function CartButton() {
  const itemCount = useCartStore(state => state.items.length);
  return <button>Cart ({itemCount})</button>;
}

// ✅ Good - Handle hydration
export function CartButton() {
  const [hydrated, setHydrated] = useState(false);
  const itemCount = useCartStore(state => state.items.length);

  useEffect(() => {
    setHydrated(true);
  }, []);

  if (!hydrated) return <button>Cart (0)</button>;
  return <button>Cart ({itemCount})</button>;
}
```

### ❌ 6. Overusing Global State

```typescript
// ❌ Bad - Global state for local UI
const useModalStore = create(() => ({
  isProductModalOpen: false,
  isUserModalOpen: false,
  isSettingsModalOpen: false,
  // ...
}));

// ✅ Good - Local state for local UI
export function ProductCard() {
  const [isModalOpen, setIsModalOpen] = useState(false);

  return (
    <>
      <button onClick={() => setIsModalOpen(true)}>View</button>
      {isModalOpen && <ProductModal onClose={() => setIsModalOpen(false)} />}
    </>
  );
}
```

---

## Summary

### State Management Checklist

**Before creating state, ask:**

1. **Is this server data?**
   - ✅ YES → Fetch in Server Component
   - ❌ NO → Continue

2. **Should it be in the URL?**
   - ✅ YES → Use searchParams
   - ❌ NO → Continue

3. **Is it shared across components?**
   - ✅ YES → Zustand store
   - ❌ NO → Local useState

### State Management Priority

```
1. Server Components (default)
2. Server Actions (mutations)
3. URL State (searchParams)
4. Zustand (client UI state)
5. useState (local UI state)
```

### Key Principles

- **Minimize client state** - Fetch in Server Components when possible
- **Use selectors** - Avoid subscribing to entire store
- **Immutable updates** - Never mutate state directly
- **Handle hydration** - Prevent mismatches with persisted state
- **DevTools in development** - Debug state changes easily

### Common Use Cases

| Use Case | Solution |
|----------|----------|
| Product catalog | Server Component |
| User profile | Server Component |
| Pagination | URL searchParams |
| Sort/Filter | URL searchParams |
| Create product | Server Action |
| Shopping cart | Zustand + persist |
| Modal open/closed | useState |
| Theme | Zustand + persist |
| Selected items | Zustand |
| Form drafts | Zustand + persist |

---

**For more patterns, see:**
- `NEXTJS-ARCHITECTURE.md` - Project structure
- `NEXTJS-COMPONENT-STANDARDS.md` - Component patterns
- `NEXTJS-DATA-FETCHING.md` - Data fetching strategies
- `@/shared/lib/` - Shared utilities
