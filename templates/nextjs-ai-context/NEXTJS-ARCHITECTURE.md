# Next.js Architecture with Feature-Sliced Design

**Purpose:** Frontend architecture for building scalable Next.js applications using Feature-Sliced Design (FSD) adapted for Next.js App Router.

**Philosophy:** Layer-based organization with Server/Client component separation, type safety, and feature isolation.

---

## Overview

This architecture combines:
- **Next.js App Router** - File-based routing, Server Components, Server Actions
- **Feature-Sliced Design (FSD)** - Layer-based organization (adapted for Next.js)
- **TypeScript** - Type safety across the stack
- **Zustand** - Client-side state management (when needed)

---

## Project Structure

```
frontend/
├── app/                          # Next.js App Router
│   ├── (marketing)/             # Route group - marketing pages
│   │   ├── page.tsx             # Home page
│   │   ├── about/
│   │   │   └── page.tsx
│   │   └── layout.tsx           # Marketing layout
│   │
│   ├── (dashboard)/             # Route group - authenticated pages
│   │   ├── layout.tsx           # Dashboard layout
│   │   ├── page.tsx             # Dashboard home
│   │   ├── products/
│   │   │   ├── page.tsx         # Product list
│   │   │   └── [id]/
│   │   │       └── page.tsx     # Product detail
│   │   └── settings/
│   │
│   ├── api/                     # API Routes (optional - proxy to backend)
│   │   └── reviews/
│   │       └── route.ts
│   │
│   ├── layout.tsx               # Root layout
│   └── globals.css              # Global styles
│
├── features/                     # FSD Features (adapted for Next.js)
│   └── product-reviews/
│       ├── ui/                  # Client Components
│       │   ├── ReviewForm.tsx
│       │   ├── ReviewList.tsx
│       │   └── ReviewCard.tsx
│       ├── server/              # Server Components
│       │   └── ReviewsContainer.tsx
│       ├── api/                 # API client (calls Express backend)
│       │   └── reviewsApi.ts
│       ├── model/               # Client state (Zustand)
│       │   └── reviewsStore.ts
│       ├── types/               # TypeScript types
│       │   └── review.types.ts  # Re-export from @yourorg/shared-types
│       ├── lib/                 # Utilities
│       │   └── validation.ts
│       ├── index.ts             # Public API
│       └── README.md
│
├── entities/                     # Business Entities
│   └── user/
│       ├── server/              # Server Components
│       │   └── UserProfile.tsx
│       ├── ui/                  # Client Components
│       │   └── UserAvatar.tsx
│       └── types/
│           └── user.types.ts
│
├── shared/                       # Shared Code
│   ├── ui/                      # Shared UI Components
│   │   ├── atoms/               # Button, Input, etc.
│   │   ├── molecules/           # FormField, Card, etc.
│   │   └── organisms/           # Modal, Header, etc.
│   ├── api/
│   │   ├── client.ts            # API client configuration
│   │   └── errors.ts
│   ├── lib/
│   │   ├── utils.ts
│   │   └── format.ts
│   ├── hooks/                   # Custom hooks (client-side)
│   │   └── useDebounce.ts
│   └── config/
│       └── constants.ts
│
├── public/                       # Static assets
├── package.json
├── next.config.js
├── tsconfig.json
└── .env.local
```

---

## Layer Hierarchy (FSD Adapted)

```
app/          ← Next.js routing (uses all layers below)
  ↓
features/     ← Business features (uses entities, shared)
  ↓
entities/     ← Business entities (uses shared)
  ↓
shared/       ← Shared code (no dependencies)
```

**Rule:** A layer can only import from layers below it, never above.

---

## Next.js App Router Structure

### Route Groups

Use route groups for logical organization:

```
app/
├── (marketing)/          # Public pages
│   ├── layout.tsx       # Marketing layout (header, footer)
│   ├── page.tsx         # Homepage
│   └── about/
│
├── (dashboard)/         # Authenticated pages
│   ├── layout.tsx       # Dashboard layout (sidebar, etc.)
│   ├── page.tsx
│   └── products/
│
└── (auth)/              # Auth pages
    ├── login/
    └── register/
```

**Benefits:**
- Organize routes logically
- Share layouts within groups
- Route groups don't affect URL structure

### Layouts

```typescript
// app/(dashboard)/layout.tsx
export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="dashboard">
      <Sidebar />
      <main>{children}</main>
    </div>
  )
}
```

### Pages

```typescript
// app/(dashboard)/products/page.tsx
import { ProductsContainer } from '@/features/products/server/ProductsContainer';

export default function ProductsPage() {
  return (
    <div>
      <h1>Products</h1>
      <ProductsContainer />
    </div>
  );
}
```

---

## Server Components vs Client Components

### Server Components (Default)

**When to use:**
- Fetching data from backend
- Accessing backend resources directly
- Keeping sensitive info on server (API keys)
- Large dependencies (stay on server)

**Example:**
```typescript
// features/products/server/ProductsContainer.tsx
import { Product } from '@yourorg/shared-types';
import { ProductList } from '../ui/ProductList';

export async function ProductsContainer() {
  // Fetch directly in Server Component
  const res = await fetch('http://localhost:3000/api/products', {
    cache: 'no-store' // or 'force-cache' or { next: { revalidate: 60 } }
  });
  const products: Product[] = await res.json();

  return <ProductList products={products} />;
}
```

**Characteristics:**
- No 'use client' directive
- Can use async/await directly
- Rendered on server
- No access to browser APIs
- No useState, useEffect, onClick, etc.

### Client Components

**When to use:**
- Interactivity (onClick, onChange, etc.)
- Browser APIs (localStorage, window, etc.)
- State management (useState, Zustand)
- Effects (useEffect)
- Event listeners

**Example:**
```typescript
// features/products/ui/ProductList.tsx
'use client';

import { Product } from '@yourorg/shared-types';
import { useProductsStore } from '../model/productsStore';

interface Props {
  products: Product[];
}

export function ProductList({ products: initialProducts }: Props) {
  const products = useProductsStore(state => state.products);

  useEffect(() => {
    // Initialize store with server data
    useProductsStore.setState({ products: initialProducts });
  }, [initialProducts]);

  return (
    <div>
      {products.map(product => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  );
}
```

**Characteristics:**
- Must have 'use client' directive at top
- Can use hooks (useState, useEffect, etc.)
- Can add event handlers
- Rendered on client after hydration

---

## Feature Structure (Next.js Adapted)

### Standard Feature Layout

```
features/product-reviews/
├── server/                    # Server Components
│   └── ReviewsContainer.tsx
├── ui/                        # Client Components
│   ├── ReviewForm.tsx
│   ├── ReviewList.tsx
│   └── ReviewCard.tsx
├── api/                       # API client
│   └── reviewsApi.ts
├── model/                     # Client state (Zustand)
│   └── reviewsStore.ts
├── types/                     # Types
│   └── review.types.ts
├── lib/                       # Utilities
│   └── validation.ts
├── index.ts                   # Public API
└── README.md
```

### Public API (index.ts)

```typescript
// features/product-reviews/index.ts

// Server Components
export { ReviewsContainer } from './server/ReviewsContainer';

// Client Components
export { ReviewForm } from './ui/ReviewForm';
export { ReviewList } from './ui/ReviewList';
export { ReviewCard } from './ui/ReviewCard';

// Hooks/Store
export { useReviewsStore } from './model/reviewsStore';

// Types
export type { Review, CreateReviewDTO } from './types/review.types';
```

### Usage in Pages

```typescript
// app/(dashboard)/products/[id]/page.tsx
import { ReviewsContainer } from '@/features/product-reviews';

export default function ProductDetailPage({ params }: { params: { id: string } }) {
  return (
    <div>
      <h1>Product Details</h1>
      <ReviewsContainer productId={params.id} />
    </div>
  );
}
```

---

## Data Fetching Patterns

### Pattern 1: Server Component Fetch

**Best for:** Initial data loading, SEO

```typescript
// features/products/server/ProductsContainer.tsx
export async function ProductsContainer() {
  const products = await fetch('http://localhost:3000/api/products')
    .then(res => res.json());

  return <ProductList products={products} />;
}
```

### Pattern 2: Server Component with Revalidation

**Best for:** Data that changes periodically

```typescript
export async function ProductsContainer() {
  const products = await fetch('http://localhost:3000/api/products', {
    next: { revalidate: 60 } // Revalidate every 60 seconds
  }).then(res => res.json());

  return <ProductList products={products} />;
}
```

### Pattern 3: Client-Side Fetch (Zustand)

**Best for:** User-specific data, real-time updates

```typescript
// features/cart/model/cartStore.ts
'use client';

import { create } from 'zustand';
import * as api from '../api/cartApi';

export const useCartStore = create((set) => ({
  items: [],
  isLoading: false,

  fetchCart: async () => {
    set({ isLoading: true });
    const items = await api.getCart();
    set({ items, isLoading: false });
  },
}));

// features/cart/ui/CartButton.tsx
'use client';

export function CartButton() {
  const { items, fetchCart } = useCartStore();

  useEffect(() => {
    fetchCart();
  }, []);

  return <button>Cart ({items.length})</button>;
}
```

### Pattern 4: Server Actions (Next.js 14+)

**Best for:** Mutations (create, update, delete)

```typescript
// features/products/actions/createProduct.ts
'use server';

import { revalidatePath } from 'next/cache';
import { CreateProductDTO } from '@yourorg/shared-types';

export async function createProduct(data: CreateProductDTO) {
  const res = await fetch('http://localhost:3000/api/products', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });

  if (!res.ok) {
    throw new Error('Failed to create product');
  }

  revalidatePath('/products'); // Revalidate products page
  return res.json();
}

// features/products/ui/CreateProductForm.tsx
'use client';

import { createProduct } from '../actions/createProduct';

export function CreateProductForm() {
  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    await createProduct({ name, price, description });
  };

  return <form onSubmit={handleSubmit}>...</form>;
}
```

---

## Import Rules (FSD)

### Allowed Imports

```typescript
// app/ (pages) can import from anywhere
import { ReviewsContainer } from '@/features/product-reviews';
import { UserProfile } from '@/entities/user';
import { Button } from '@/shared/ui/atoms';

// features/ can import from entities and shared
import { UserAvatar } from '@/entities/user';
import { Button } from '@/shared/ui/atoms';

// entities/ can import from shared only
import { formatDate } from '@/shared/lib/format';

// shared/ cannot import from any layer above
```

### Forbidden Imports

```typescript
// ❌ features/ CANNOT import from other features
import { CartButton } from '@/features/cart';  // FORBIDDEN in features/products/

// ❌ entities/ CANNOT import from features
import { ReviewForm } from '@/features/reviews';  // FORBIDDEN in entities/

// ❌ shared/ CANNOT import from any business layer
import { User } from '@/entities/user';  // FORBIDDEN in shared/
```

---

## File Naming Conventions

### Components

```
PascalCase.tsx
ProductCard.tsx
ReviewList.tsx
UserProfile.tsx
```

### Server Components

```
PascalCase.tsx (in server/ folder)
ProductsContainer.tsx
ReviewsContainer.tsx
```

### Client Components

```
'use client' at top
PascalCase.tsx (in ui/ folder)
ProductForm.tsx
ReviewCard.tsx
```

### API Routes

```
route.ts (Next.js convention)
app/api/reviews/route.ts
```

### Server Actions

```
camelCase.ts (in actions/ folder)
createProduct.ts
updateUser.ts
```

---

## TypeScript Configuration

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "jsx": "preserve",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "paths": {
      "@/*": ["./src/*"],
      "@/app/*": ["./app/*"],
      "@/features/*": ["./features/*"],
      "@/entities/*": ["./entities/*"],
      "@/shared/*": ["./shared/*"],
      "@shared/types": ["../packages/shared-types/src"]
    },
    "plugins": [{ "name": "next" }]
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

---

## Environment Variables

```bash
# .env.local
NEXT_PUBLIC_API_URL=http://localhost:3000/api
NEXT_PUBLIC_APP_URL=http://localhost:3001

# Server-only (no NEXT_PUBLIC_ prefix)
API_SECRET_KEY=your-secret-key
```

**Usage:**
```typescript
// Client Component
const apiUrl = process.env.NEXT_PUBLIC_API_URL;

// Server Component or API Route
const secretKey = process.env.API_SECRET_KEY;
```

---

## API Integration with Backend

### Option 1: Direct Fetch (Recommended)

```typescript
// features/products/server/ProductsContainer.tsx
export async function ProductsContainer() {
  const products = await fetch(`${process.env.API_URL}/products`)
    .then(res => res.json());

  return <ProductList products={products} />;
}
```

### Option 2: Next.js API Routes as Proxy

```typescript
// app/api/products/route.ts
export async function GET() {
  const res = await fetch('http://localhost:3000/api/products');
  const products = await res.json();
  return Response.json(products);
}

// features/products/server/ProductsContainer.tsx
export async function ProductsContainer() {
  const products = await fetch('/api/products').then(res => res.json());
  return <ProductList products={products} />;
}
```

---

## Common Patterns

### Pattern: Server Component + Client Component

```typescript
// Server Component - fetches data
// features/products/server/ProductDetailContainer.tsx
import { ProductDetail } from '../ui/ProductDetail';

export async function ProductDetailContainer({ id }: { id: string }) {
  const product = await fetch(`http://localhost:3000/api/products/${id}`)
    .then(res => res.json());

  return <ProductDetail product={product} />;
}

// Client Component - handles interactions
// features/products/ui/ProductDetail.tsx
'use client';

import { useState } from 'react';
import { Product } from '@yourorg/shared-types';

export function ProductDetail({ product }: { product: Product }) {
  const [quantity, setQuantity] = useState(1);

  const handleAddToCart = () => {
    // Client-side logic
  };

  return (
    <div>
      <h1>{product.name}</h1>
      <button onClick={handleAddToCart}>Add to Cart</button>
    </div>
  );
}
```

### Pattern: Form with Server Action

```typescript
// features/products/actions/createProduct.ts
'use server';

import { revalidatePath } from 'next/cache';

export async function createProduct(formData: FormData) {
  const name = formData.get('name');
  const price = formData.get('price');

  await fetch('http://localhost:3000/api/products', {
    method: 'POST',
    body: JSON.stringify({ name, price }),
  });

  revalidatePath('/products');
}

// features/products/ui/CreateProductForm.tsx
'use client';

import { createProduct } from '../actions/createProduct';

export function CreateProductForm() {
  return (
    <form action={createProduct}>
      <input name="name" required />
      <input name="price" type="number" required />
      <button type="submit">Create</button>
    </form>
  );
}
```

---

## Decision Trees

### Where Does This Code Go?

**Is it a route/page?**
→ `app/` (Next.js App Router)

**Is it a complete user interaction feature?**
→ `features/`

**Is it a business entity (read-only display)?**
→ `entities/`

**Is it a reusable UI component?**
→ `shared/ui/`

**Is it a utility function?**
→ `shared/lib/`

### Server Component or Client Component?

**Does it need interactivity (onClick, onChange)?**
→ Client Component ('use client')

**Does it need browser APIs (localStorage, window)?**
→ Client Component

**Does it need state or effects (useState, useEffect)?**
→ Client Component

**Does it just fetch and display data?**
→ Server Component (default, no directive)

**Does it need to be SEO-friendly?**
→ Server Component

---

## Best Practices

### ✅ DO

1. **Use Server Components by default**
   ```typescript
   // Default - no 'use client'
   export async function ProductList() {
     const products = await fetch(...);
     return <div>...</div>;
   }
   ```

2. **Only use 'use client' when needed**
   ```typescript
   'use client'; // Only when you need interactivity
   export function ProductForm() {
     const [name, setName] = useState('');
     return <form>...</form>;
   }
   ```

3. **Fetch data in Server Components**
   ```typescript
   export async function ProductsPage() {
     const products = await getProducts(); // Server-side fetch
     return <ProductList products={products} />;
   }
   ```

4. **Use Server Actions for mutations**
   ```typescript
   'use server';
   export async function createProduct(data) {
     await api.create(data);
     revalidatePath('/products');
   }
   ```

5. **Import shared types consistently**
   ```typescript
   import { Product } from '@yourorg/shared-types';
   ```

### ❌ DON'T

1. **Don't use 'use client' everywhere**
   ```typescript
   // ❌ Bad - unnecessary
   'use client';
   export function ProductList({ products }) {
     return <div>...</div>; // No interactivity needed
   }
   ```

2. **Don't fetch in Client Components without reason**
   ```typescript
   // ❌ Bad - use Server Component instead
   'use client';
   export function ProductList() {
     const [products, setProducts] = useState([]);
     useEffect(() => {
       fetch('/api/products').then(...);
     }, []);
   }
   ```

3. **Don't import features from other features**
   ```typescript
   // ❌ Bad - violates FSD
   import { CartButton } from '@/features/cart';
   ```

---

## Summary

**Architecture:**
- Next.js App Router for routing
- FSD for code organization
- Server Components by default
- Client Components for interactivity

**Key Principles:**
- Layers: app → features → entities → shared
- Server Components for data fetching
- Client Components for interactivity
- Shared types from @yourorg/shared-types

**File Organization:**
```
features/[feature-name]/
├── server/      # Server Components
├── ui/          # Client Components
├── api/         # API client
├── model/       # Zustand (client state)
├── actions/     # Server Actions
└── types/       # TypeScript types
```

---

**Next:** See NEXTJS-COMPONENT-STANDARDS.md for React patterns and NEXTJS-STATE-MANAGEMENT.md for state management.
