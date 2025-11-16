# Next.js Component Standards

**Purpose:** React component patterns and best practices for Next.js App Router applications using Feature-Sliced Design.

**Last Updated:** 2025-11-16

---

## Table of Contents

1. [Component Organization](#component-organization)
2. [Server Components](#server-components)
3. [Client Components](#client-components)
4. [TypeScript Patterns](#typescript-patterns)
5. [Props and Interfaces](#props-and-interfaces)
6. [Event Handlers](#event-handlers)
7. [Hooks Usage](#hooks-usage)
8. [Performance Optimization](#performance-optimization)
9. [Form Patterns](#form-patterns)
10. [Error Handling](#error-handling)
11. [Testing](#testing)
12. [Common Patterns](#common-patterns)
13. [Anti-Patterns](#anti-patterns)

---

## Component Organization

### File Naming

**Use PascalCase for component files:**

```
✅ Good
ProductCard.tsx
UserProfile.tsx
ReviewsList.tsx

❌ Bad
product-card.tsx
userProfile.tsx
reviews_list.tsx
```

### Component Structure

**Each component file should contain:**

```typescript
// 1. Imports (grouped)
import { type ReactNode } from 'react';
import { ProductCard } from '@/entities/products';
import { formatPrice } from '@/shared/lib';
import styles from './ProductList.module.css';

// 2. TypeScript types/interfaces
interface ProductListProps {
  products: Product[];
  onProductClick?: (id: string) => void;
}

// 3. Component implementation
export function ProductList({ products, onProductClick }: ProductListProps) {
  return (
    <div className={styles.list}>
      {products.map(product => (
        <ProductCard
          key={product.id}
          product={product}
          onClick={() => onProductClick?.(product.id)}
        />
      ))}
    </div>
  );
}

// 4. Sub-components (if small and private)
function EmptyState() {
  return <p>No products found</p>;
}
```

### Import Order

**Always follow this order:**

```typescript
// 1. React and Next.js
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Image from 'next/image';
import Link from 'next/link';

// 2. External libraries
import { useProductsStore } from '@/features/products/model';

// 3. Shared types
import type { Product } from '@yourorg/shared-types';

// 4. Internal imports (by FSD layer)
import { Button } from '@/shared/ui/Button';
import { formatPrice } from '@/shared/lib/format';
import { ProductCard } from '@/entities/products';

// 5. Styles (last)
import styles from './ProductList.module.css';
```

---

## Server Components

**Default in Next.js App Router** - No directive needed.

### When to Use Server Components

✅ **Use for:**
- Data fetching from backend API
- Accessing databases directly
- Rendering static content
- SEO-critical content
- Secret API keys usage

❌ **Don't use for:**
- Interactive UI (onClick, onChange)
- React hooks (useState, useEffect)
- Browser APIs (localStorage, window)
- Client-side state management

### Server Component Pattern

```typescript
// features/products/server/ProductsContainer.tsx
// No 'use client' directive - this is a Server Component

import type { Product } from '@yourorg/shared-types';
import { ProductList } from '../ui/ProductList';

interface ProductsContainerProps {
  category?: string;
}

export async function ProductsContainer({ category }: ProductsContainerProps) {
  // Fetch data directly in component
  const response = await fetch(
    `http://localhost:3000/api/products${category ? `?category=${category}` : ''}`,
    {
      cache: 'no-store', // Always fresh data
      // cache: 'force-cache', // Static data
      // next: { revalidate: 60 }, // Revalidate every 60s
    }
  );

  if (!response.ok) {
    throw new Error('Failed to fetch products');
  }

  const { data: products } = await response.json();

  return <ProductList products={products} />;
}
```

### Server Component with Error Handling

```typescript
// features/products/server/ProductsContainer.tsx

import { ProductList } from '../ui/ProductList';
import { EmptyState } from '../ui/EmptyState';
import { ErrorState } from '../ui/ErrorState';

export async function ProductsContainer() {
  try {
    const products = await fetchProducts();

    if (products.length === 0) {
      return <EmptyState />;
    }

    return <ProductList products={products} />;
  } catch (error) {
    console.error('Error fetching products:', error);
    return <ErrorState message="Failed to load products" />;
  }
}

async function fetchProducts() {
  const response = await fetch('http://localhost:3000/api/products', {
    cache: 'no-store',
  });

  if (!response.ok) {
    throw new Error('Failed to fetch products');
  }

  const { data } = await response.json();
  return data;
}
```

### Loading States with Suspense

```typescript
// app/(dashboard)/products/page.tsx

import { Suspense } from 'react';
import { ProductsContainer } from '@/features/products/server/ProductsContainer';
import { ProductsSkeleton } from '@/features/products/ui/ProductsSkeleton';

export default function ProductsPage() {
  return (
    <div>
      <h1>Products</h1>
      <Suspense fallback={<ProductsSkeleton />}>
        <ProductsContainer />
      </Suspense>
    </div>
  );
}
```

---

## Client Components

**Require 'use client' directive** at the top of the file.

### When to Use Client Components

✅ **Use for:**
- Interactive UI (onClick, onChange, onSubmit)
- React hooks (useState, useEffect, useRef)
- Browser APIs (localStorage, window)
- Client-side state management (Zustand)
- Event listeners
- Third-party libraries that use browser APIs

### Client Component Pattern

```typescript
// features/products/ui/ProductList.tsx
'use client';

import { useState, useEffect } from 'react';
import type { Product } from '@yourorg/shared-types';
import { useProductsStore } from '../model/productsStore';
import { ProductCard } from './ProductCard';
import styles from './ProductList.module.css';

interface ProductListProps {
  products: Product[]; // Initial data from Server Component
}

export function ProductList({ products: initialProducts }: ProductListProps) {
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const products = useProductsStore(state => state.products);
  const setProducts = useProductsStore(state => state.setProducts);

  // Initialize store with server data
  useEffect(() => {
    setProducts(initialProducts);
  }, [initialProducts, setProducts]);

  return (
    <div className={styles.list}>
      {products.map(product => (
        <ProductCard
          key={product.id}
          product={product}
          isSelected={product.id === selectedId}
          onClick={() => setSelectedId(product.id)}
        />
      ))}
    </div>
  );
}
```

### Interactive Component Example

```typescript
// features/products/ui/ProductCard.tsx
'use client';

import { useState } from 'react';
import Image from 'next/image';
import type { Product } from '@yourorg/shared-types';
import { formatPrice } from '@/shared/lib/format';
import { Button } from '@/shared/ui/Button';
import styles from './ProductCard.module.css';

interface ProductCardProps {
  product: Product;
  onAddToCart?: (productId: string) => void;
}

export function ProductCard({ product, onAddToCart }: ProductCardProps) {
  const [isHovered, setIsHovered] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const handleAddToCart = async () => {
    setIsLoading(true);
    try {
      await onAddToCart?.(product.id);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div
      className={styles.card}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      <Image
        src={product.imageUrl}
        alt={product.name}
        width={200}
        height={200}
        className={styles.image}
      />

      <h3 className={styles.title}>{product.name}</h3>
      <p className={styles.price}>{formatPrice(product.price)}</p>

      {isHovered && (
        <Button
          onClick={handleAddToCart}
          disabled={isLoading}
          className={styles.addButton}
        >
          {isLoading ? 'Adding...' : 'Add to Cart'}
        </Button>
      )}
    </div>
  );
}
```

### Composing Server and Client Components

```typescript
// Server Component (no directive)
// features/products/server/ProductsContainer.tsx

import { ProductList } from '../ui/ProductList'; // Client Component

export async function ProductsContainer() {
  const products = await fetchProducts();

  // Pass server-fetched data to Client Component
  return <ProductList products={products} />;
}
```

```typescript
// Client Component ('use client')
// features/products/ui/ProductList.tsx
'use client';

import { useState } from 'react';
import type { Product } from '@yourorg/shared-types';

interface ProductListProps {
  products: Product[]; // Receives data from Server Component
}

export function ProductList({ products }: ProductListProps) {
  const [filter, setFilter] = useState('');

  const filteredProducts = products.filter(p =>
    p.name.toLowerCase().includes(filter.toLowerCase())
  );

  return (
    <div>
      <input
        type="text"
        value={filter}
        onChange={e => setFilter(e.target.value)}
        placeholder="Search products..."
      />

      <div>
        {filteredProducts.map(product => (
          <div key={product.id}>{product.name}</div>
        ))}
      </div>
    </div>
  );
}
```

---

## TypeScript Patterns

### Props Interfaces

**Always define explicit props interfaces:**

```typescript
// ✅ Good - Explicit interface
interface ProductCardProps {
  product: Product;
  isSelected?: boolean;
  onSelect?: (id: string) => void;
}

export function ProductCard({ product, isSelected, onSelect }: ProductCardProps) {
  // ...
}

// ❌ Bad - Inline types
export function ProductCard({
  product,
  isSelected,
  onSelect,
}: {
  product: Product;
  isSelected?: boolean;
  onSelect?: (id: string) => void;
}) {
  // ...
}
```

### Children Props

```typescript
// For components that accept children
interface CardProps {
  children: ReactNode;
  title?: string;
}

export function Card({ children, title }: CardProps) {
  return (
    <div>
      {title && <h2>{title}</h2>}
      {children}
    </div>
  );
}
```

### Generic Components

```typescript
// Generic list component
interface ListProps<T> {
  items: T[];
  renderItem: (item: T, index: number) => ReactNode;
  keyExtractor: (item: T) => string;
}

export function List<T>({ items, renderItem, keyExtractor }: ListProps<T>) {
  return (
    <div>
      {items.map((item, index) => (
        <div key={keyExtractor(item)}>
          {renderItem(item, index)}
        </div>
      ))}
    </div>
  );
}

// Usage
<List
  items={products}
  renderItem={product => <ProductCard product={product} />}
  keyExtractor={product => product.id}
/>
```

### Component with Ref

```typescript
import { forwardRef, type InputHTMLAttributes } from 'react';

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, ...props }, ref) => {
    return (
      <div>
        {label && <label>{label}</label>}
        <input ref={ref} {...props} />
        {error && <span>{error}</span>}
      </div>
    );
  }
);

Input.displayName = 'Input';
```

---

## Props and Interfaces

### Required vs Optional Props

```typescript
interface ProductCardProps {
  // Required props
  product: Product;

  // Optional props (use ?)
  className?: string;
  onSelect?: (id: string) => void;
  isSelected?: boolean;

  // Required with default (handle in destructuring)
  variant?: 'default' | 'compact' | 'detailed';
}

export function ProductCard({
  product,
  className,
  onSelect,
  isSelected = false,
  variant = 'default',
}: ProductCardProps) {
  // ...
}
```

### Discriminated Unions for Variants

```typescript
type ButtonProps =
  | {
      variant: 'primary';
      icon?: ReactNode;
      onClick: () => void;
    }
  | {
      variant: 'link';
      href: string;
      icon?: ReactNode;
    };

export function Button(props: ButtonProps) {
  if (props.variant === 'link') {
    return (
      <Link href={props.href}>
        {props.icon}
        Link Button
      </Link>
    );
  }

  return (
    <button onClick={props.onClick}>
      {props.icon}
      Primary Button
    </button>
  );
}
```

### Extending HTML Element Props

```typescript
import { type ButtonHTMLAttributes } from 'react';

interface CustomButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary';
  isLoading?: boolean;
}

export function CustomButton({
  variant = 'primary',
  isLoading,
  children,
  disabled,
  ...props
}: CustomButtonProps) {
  return (
    <button
      disabled={disabled || isLoading}
      className={`btn btn-${variant}`}
      {...props}
    >
      {isLoading ? 'Loading...' : children}
    </button>
  );
}
```

---

## Event Handlers

### Naming Convention

```typescript
// ✅ Good - Use handle* for internal, on* for props
interface ProductCardProps {
  product: Product;
  onClick?: (id: string) => void;  // Prop: on*
  onAddToCart?: (id: string) => void;
}

export function ProductCard({ product, onClick, onAddToCart }: ProductCardProps) {
  // Internal handler: handle*
  const handleClick = () => {
    onClick?.(product.id);
  };

  const handleAddToCart = () => {
    onAddToCart?.(product.id);
  };

  return (
    <div onClick={handleClick}>
      <button onClick={handleAddToCart}>Add to Cart</button>
    </div>
  );
}
```

### Event Types

```typescript
'use client';

import { type ChangeEvent, type FormEvent } from 'react';

export function SearchForm() {
  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    console.log(e.target.value);
  };

  const handleSubmit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    // ...
  };

  return (
    <form onSubmit={handleSubmit}>
      <input onChange={handleChange} />
      <button type="submit">Search</button>
    </form>
  );
}
```

### Async Event Handlers

```typescript
'use client';

import { useState } from 'react';

export function ProductForm() {
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setIsSubmitting(true);

    try {
      const formData = new FormData(e.currentTarget);
      await fetch('/api/products', {
        method: 'POST',
        body: formData,
      });
    } catch (error) {
      console.error('Submission failed:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input name="name" required />
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Submitting...' : 'Submit'}
      </button>
    </form>
  );
}
```

---

## Hooks Usage

**Hooks only work in Client Components ('use client').**

### useState

```typescript
'use client';

import { useState } from 'react';

export function Counter() {
  // Simple state
  const [count, setCount] = useState(0);

  // State with initial function (lazy initialization)
  const [expensiveValue, setExpensiveValue] = useState(() => {
    return computeExpensiveValue();
  });

  // State with type inference
  const [user, setUser] = useState<User | null>(null);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(count + 1)}>Increment</button>
      <button onClick={() => setCount(prev => prev + 1)}>Increment (functional)</button>
    </div>
  );
}
```

### useEffect

```typescript
'use client';

import { useEffect, useState } from 'react';

export function ProductDetails({ productId }: { productId: string }) {
  const [product, setProduct] = useState<Product | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function fetchProduct() {
      try {
        const response = await fetch(`/api/products/${productId}`);
        const data = await response.json();

        if (!cancelled) {
          setProduct(data);
        }
      } catch (error) {
        console.error('Failed to fetch product:', error);
      }
    }

    fetchProduct();

    // Cleanup function
    return () => {
      cancelled = true;
    };
  }, [productId]); // Dependency array

  if (!product) return <div>Loading...</div>;

  return <div>{product.name}</div>;
}
```

### useRef

```typescript
'use client';

import { useRef, useEffect } from 'react';

export function AutoFocusInput() {
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  return <input ref={inputRef} />;
}

// useRef for mutable values (doesn't trigger re-render)
export function Timer() {
  const intervalRef = useRef<NodeJS.Timeout | null>(null);

  const startTimer = () => {
    intervalRef.current = setInterval(() => {
      console.log('Tick');
    }, 1000);
  };

  const stopTimer = () => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
    }
  };

  useEffect(() => {
    return () => stopTimer(); // Cleanup
  }, []);

  return (
    <div>
      <button onClick={startTimer}>Start</button>
      <button onClick={stopTimer}>Stop</button>
    </div>
  );
}
```

### Custom Hooks

```typescript
'use client';

import { useState, useEffect } from 'react';

// Custom hook for data fetching
export function useProduct(productId: string) {
  const [product, setProduct] = useState<Product | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function fetchProduct() {
      setIsLoading(true);
      setError(null);

      try {
        const response = await fetch(`/api/products/${productId}`);

        if (!response.ok) {
          throw new Error('Failed to fetch product');
        }

        const data = await response.json();

        if (!cancelled) {
          setProduct(data);
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

    fetchProduct();

    return () => {
      cancelled = true;
    };
  }, [productId]);

  return { product, isLoading, error };
}

// Usage
export function ProductDetails({ productId }: { productId: string }) {
  const { product, isLoading, error } = useProduct(productId);

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;
  if (!product) return <div>Not found</div>;

  return <div>{product.name}</div>;
}
```

---

## Performance Optimization

### React.memo

```typescript
'use client';

import { memo } from 'react';
import type { Product } from '@yourorg/shared-types';

interface ProductCardProps {
  product: Product;
  onClick: (id: string) => void;
}

// Memoize component to prevent unnecessary re-renders
export const ProductCard = memo(function ProductCard({
  product,
  onClick,
}: ProductCardProps) {
  console.log('ProductCard rendered:', product.id);

  return (
    <div onClick={() => onClick(product.id)}>
      <h3>{product.name}</h3>
      <p>{product.price}</p>
    </div>
  );
});

// Custom comparison function
export const ProductCardWithCustomComparison = memo(
  ProductCard,
  (prevProps, nextProps) => {
    // Return true if props are equal (skip re-render)
    return prevProps.product.id === nextProps.product.id;
  }
);
```

### useCallback

```typescript
'use client';

import { useState, useCallback } from 'react';
import { ProductCard } from './ProductCard';

export function ProductList({ products }: { products: Product[] }) {
  const [selectedId, setSelectedId] = useState<string | null>(null);

  // Memoize callback to prevent ProductCard re-renders
  const handleProductClick = useCallback((id: string) => {
    console.log('Product clicked:', id);
    setSelectedId(id);
  }, []); // Empty deps - function never changes

  return (
    <div>
      {products.map(product => (
        <ProductCard
          key={product.id}
          product={product}
          onClick={handleProductClick} // Same reference every render
        />
      ))}
    </div>
  );
}
```

### useMemo

```typescript
'use client';

import { useMemo } from 'react';

export function ProductList({ products, filter }: Props) {
  // Expensive computation - only recalculate when dependencies change
  const filteredProducts = useMemo(() => {
    console.log('Filtering products...');
    return products.filter(p =>
      p.name.toLowerCase().includes(filter.toLowerCase())
    );
  }, [products, filter]);

  const stats = useMemo(() => {
    console.log('Calculating stats...');
    return {
      total: filteredProducts.length,
      avgPrice: filteredProducts.reduce((sum, p) => sum + p.price, 0) / filteredProducts.length,
    };
  }, [filteredProducts]);

  return (
    <div>
      <p>Total: {stats.total}, Avg: ${stats.avgPrice.toFixed(2)}</p>
      {filteredProducts.map(product => (
        <div key={product.id}>{product.name}</div>
      ))}
    </div>
  );
}
```

### Next.js Image Optimization

```typescript
import Image from 'next/image';

export function ProductCard({ product }: { product: Product }) {
  return (
    <div>
      {/* Optimized images */}
      <Image
        src={product.imageUrl}
        alt={product.name}
        width={300}
        height={300}
        // Priority for above-the-fold images
        priority={product.featured}
        // Lazy load by default
        loading={product.featured ? 'eager' : 'lazy'}
        // Placeholder while loading
        placeholder="blur"
        blurDataURL="data:image/jpeg;base64,..."
      />
    </div>
  );
}
```

### Code Splitting with Dynamic Imports

```typescript
'use client';

import dynamic from 'next/dynamic';
import { Suspense } from 'react';

// Lazy load heavy component
const HeavyChart = dynamic(() => import('./HeavyChart'), {
  loading: () => <div>Loading chart...</div>,
  ssr: false, // Disable server-side rendering
});

export function Dashboard() {
  return (
    <div>
      <h1>Dashboard</h1>
      <Suspense fallback={<div>Loading...</div>}>
        <HeavyChart />
      </Suspense>
    </div>
  );
}
```

---

## Form Patterns

### Forms with Server Actions

```typescript
// features/products/actions/createProduct.ts
'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { createProductSchema } from '@yourorg/shared-types';

export async function createProduct(formData: FormData) {
  // Validate form data
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

  // Create product
  try {
    await fetch('http://localhost:3000/api/products', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(validatedFields.data),
    });

    revalidatePath('/products');
    redirect('/products');
  } catch (error) {
    return {
      message: 'Failed to create product',
    };
  }
}
```

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
          <p className="error">{state.errors.name}</p>
        )}
      </div>

      <div>
        <label htmlFor="price">Price</label>
        <input id="price" name="price" type="number" required />
        {state?.errors?.price && (
          <p className="error">{state.errors.price}</p>
        )}
      </div>

      <div>
        <label htmlFor="description">Description</label>
        <textarea id="description" name="description" />
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

### Controlled Forms

```typescript
'use client';

import { useState, type FormEvent } from 'react';
import { createProductSchema, type CreateProductInput } from '@yourorg/shared-types';

export function ControlledProductForm() {
  const [formData, setFormData] = useState<CreateProductInput>({
    name: '',
    price: 0,
    description: '',
  });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setErrors({});

    // Validate
    const result = createProductSchema.safeParse(formData);

    if (!result.success) {
      const fieldErrors: Record<string, string> = {};
      result.error.issues.forEach(issue => {
        if (issue.path[0]) {
          fieldErrors[issue.path[0].toString()] = issue.message;
        }
      });
      setErrors(fieldErrors);
      return;
    }

    // Submit
    setIsSubmitting(true);
    try {
      await fetch('/api/products', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      });

      // Reset form
      setFormData({ name: '', price: 0, description: '' });
    } catch (error) {
      setErrors({ submit: 'Failed to create product' });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <label htmlFor="name">Name</label>
        <input
          id="name"
          value={formData.name}
          onChange={e => setFormData({ ...formData, name: e.target.value })}
        />
        {errors.name && <p className="error">{errors.name}</p>}
      </div>

      <div>
        <label htmlFor="price">Price</label>
        <input
          id="price"
          type="number"
          value={formData.price}
          onChange={e => setFormData({ ...formData, price: Number(e.target.value) })}
        />
        {errors.price && <p className="error">{errors.price}</p>}
      </div>

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Creating...' : 'Create Product'}
      </button>

      {errors.submit && <p className="error">{errors.submit}</p>}
    </form>
  );
}
```

---

## Error Handling

### Error Boundaries

```typescript
// app/error.tsx (Route error boundary)
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
    // Log error to error reporting service
    console.error('Error:', error);
  }, [error]);

  return (
    <div>
      <h2>Something went wrong!</h2>
      <p>{error.message}</p>
      <button onClick={reset}>Try again</button>
    </div>
  );
}
```

```typescript
// Custom error boundary component
'use client';

import { Component, type ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Error caught by boundary:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback || (
        <div>
          <h2>Something went wrong</h2>
          <p>{this.state.error?.message}</p>
          <button onClick={() => this.setState({ hasError: false })}>
            Try again
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
```

### Handling API Errors

```typescript
'use client';

import { useState } from 'react';
import type { ApiError } from '@/shared/types';

export function ProductDetails({ productId }: { productId: string }) {
  const [error, setError] = useState<ApiError | null>(null);
  const [product, setProduct] = useState<Product | null>(null);

  useEffect(() => {
    async function fetchProduct() {
      try {
        const response = await fetch(`/api/products/${productId}`);

        if (!response.ok) {
          const errorData = await response.json();
          setError(errorData);
          return;
        }

        const { data } = await response.json();
        setProduct(data);
      } catch (err) {
        setError({
          status: 'error',
          code: 'ERR_NETWORK_001',
          message: 'Network error occurred',
        });
      }
    }

    fetchProduct();
  }, [productId]);

  if (error) {
    return (
      <div className="error">
        <h3>Error: {error.code}</h3>
        <p>{error.message}</p>
      </div>
    );
  }

  if (!product) return <div>Loading...</div>;

  return <div>{product.name}</div>;
}
```

---

## Testing

### Component Testing with Vitest + React Testing Library

```typescript
// features/products/ui/__tests__/ProductCard.test.tsx

import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { ProductCard } from '../ProductCard';
import type { Product } from '@yourorg/shared-types';

const mockProduct: Product = {
  id: '1',
  name: 'Test Product',
  price: 99.99,
  description: 'Test description',
  imageUrl: '/test.jpg',
  createdAt: new Date(),
  updatedAt: new Date(),
};

describe('ProductCard', () => {
  it('renders product information', () => {
    render(<ProductCard product={mockProduct} />);

    expect(screen.getByText('Test Product')).toBeInTheDocument();
    expect(screen.getByText('$99.99')).toBeInTheDocument();
  });

  it('calls onClick when clicked', () => {
    const handleClick = vi.fn();
    render(<ProductCard product={mockProduct} onClick={handleClick} />);

    fireEvent.click(screen.getByText('Test Product'));

    expect(handleClick).toHaveBeenCalledWith('1');
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('shows loading state when isLoading is true', () => {
    render(<ProductCard product={mockProduct} isLoading />);

    expect(screen.getByText('Loading...')).toBeInTheDocument();
  });
});
```

### Testing Hooks

```typescript
// features/products/hooks/__tests__/useProduct.test.ts

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { useProduct } from '../useProduct';

global.fetch = vi.fn();

describe('useProduct', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('fetches product successfully', async () => {
    const mockProduct = { id: '1', name: 'Test Product' };

    (global.fetch as any).mockResolvedValueOnce({
      ok: true,
      json: async () => ({ data: mockProduct }),
    });

    const { result } = renderHook(() => useProduct('1'));

    expect(result.current.isLoading).toBe(true);

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.product).toEqual(mockProduct);
    expect(result.current.error).toBeNull();
  });

  it('handles fetch error', async () => {
    (global.fetch as any).mockResolvedValueOnce({
      ok: false,
    });

    const { result } = renderHook(() => useProduct('1'));

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.product).toBeNull();
    expect(result.current.error).toBeTruthy();
  });
});
```

### Testing Server Components

```typescript
// features/products/server/__tests__/ProductsContainer.test.tsx

import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ProductsContainer } from '../ProductsContainer';

vi.mock('next/cache', () => ({
  revalidatePath: vi.fn(),
}));

global.fetch = vi.fn();

describe('ProductsContainer', () => {
  it('renders products from API', async () => {
    const mockProducts = [
      { id: '1', name: 'Product 1' },
      { id: '2', name: 'Product 2' },
    ];

    (global.fetch as any).mockResolvedValueOnce({
      ok: true,
      json: async () => ({ data: mockProducts }),
    });

    const { container } = render(await ProductsContainer());

    expect(screen.getByText('Product 1')).toBeInTheDocument();
    expect(screen.getByText('Product 2')).toBeInTheDocument();
  });

  it('handles fetch error', async () => {
    (global.fetch as any).mockResolvedValueOnce({
      ok: false,
    });

    const { container } = render(await ProductsContainer());

    expect(screen.getByText('Failed to load products')).toBeInTheDocument();
  });
});
```

---

## Common Patterns

### Compound Components

```typescript
'use client';

import { createContext, useContext, useState, type ReactNode } from 'react';

interface TabsContextValue {
  activeTab: string;
  setActiveTab: (tab: string) => void;
}

const TabsContext = createContext<TabsContextValue | null>(null);

function useTabs() {
  const context = useContext(TabsContext);
  if (!context) {
    throw new Error('Tabs components must be used within Tabs');
  }
  return context;
}

interface TabsProps {
  children: ReactNode;
  defaultTab: string;
}

export function Tabs({ children, defaultTab }: TabsProps) {
  const [activeTab, setActiveTab] = useState(defaultTab);

  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      <div className="tabs">{children}</div>
    </TabsContext.Provider>
  );
}

interface TabListProps {
  children: ReactNode;
}

Tabs.List = function TabList({ children }: TabListProps) {
  return <div className="tab-list">{children}</div>;
};

interface TabProps {
  value: string;
  children: ReactNode;
}

Tabs.Tab = function Tab({ value, children }: TabProps) {
  const { activeTab, setActiveTab } = useTabs();

  return (
    <button
      className={activeTab === value ? 'active' : ''}
      onClick={() => setActiveTab(value)}
    >
      {children}
    </button>
  );
};

interface TabPanelProps {
  value: string;
  children: ReactNode;
}

Tabs.Panel = function TabPanel({ value, children }: TabPanelProps) {
  const { activeTab } = useTabs();

  if (activeTab !== value) return null;

  return <div className="tab-panel">{children}</div>;
};

// Usage
<Tabs defaultTab="products">
  <Tabs.List>
    <Tabs.Tab value="products">Products</Tabs.Tab>
    <Tabs.Tab value="reviews">Reviews</Tabs.Tab>
  </Tabs.List>

  <Tabs.Panel value="products">
    <ProductList />
  </Tabs.Panel>

  <Tabs.Panel value="reviews">
    <ReviewList />
  </Tabs.Panel>
</Tabs>
```

### Render Props Pattern

```typescript
'use client';

import { useState, type ReactNode } from 'react';

interface DataLoaderProps<T> {
  url: string;
  children: (data: T | null, isLoading: boolean, error: Error | null) => ReactNode;
}

export function DataLoader<T>({ url, children }: DataLoaderProps<T>) {
  const [data, setData] = useState<T | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    async function fetchData() {
      try {
        const response = await fetch(url);
        const result = await response.json();
        setData(result.data);
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Unknown error'));
      } finally {
        setIsLoading(false);
      }
    }

    fetchData();
  }, [url]);

  return <>{children(data, isLoading, error)}</>;
}

// Usage
<DataLoader<Product[]> url="/api/products">
  {(products, isLoading, error) => {
    if (isLoading) return <div>Loading...</div>;
    if (error) return <div>Error: {error.message}</div>;
    if (!products) return <div>No data</div>;

    return products.map(product => (
      <div key={product.id}>{product.name}</div>
    ));
  }}
</DataLoader>
```

---

## Anti-Patterns

### ❌ 1. Using useState for Server-Fetched Data

```typescript
// ❌ Bad - Don't use useState for initial server data
'use client';

export function ProductList() {
  const [products, setProducts] = useState<Product[]>([]);

  useEffect(() => {
    fetch('/api/products')
      .then(res => res.json())
      .then(data => setProducts(data));
  }, []);

  return <div>...</div>;
}

// ✅ Good - Fetch in Server Component, pass to Client
// Server Component
export async function ProductsContainer() {
  const products = await fetch('/api/products').then(r => r.json());
  return <ProductList products={products} />;
}

// Client Component
'use client';
export function ProductList({ products }: { products: Product[] }) {
  return <div>...</div>;
}
```

### ❌ 2. Not Memoizing Callbacks

```typescript
// ❌ Bad - New function reference every render
export function ProductList({ products }: Props) {
  return products.map(product => (
    <ProductCard
      key={product.id}
      product={product}
      onClick={(id) => console.log(id)} // New function every render
    />
  ));
}

// ✅ Good - Memoized callback
export function ProductList({ products }: Props) {
  const handleClick = useCallback((id: string) => {
    console.log(id);
  }, []);

  return products.map(product => (
    <ProductCard
      key={product.id}
      product={product}
      onClick={handleClick}
    />
  ));
}
```

### ❌ 3. Mutating Props

```typescript
// ❌ Bad - Don't mutate props
export function ProductCard({ product }: { product: Product }) {
  product.price = product.price * 1.1; // NEVER mutate props!
  return <div>{product.price}</div>;
}

// ✅ Good - Create new value
export function ProductCard({ product }: { product: Product }) {
  const discountedPrice = product.price * 1.1;
  return <div>{discountedPrice}</div>;
}
```

### ❌ 4. Using Indexes as Keys

```typescript
// ❌ Bad - Index as key
{products.map((product, index) => (
  <ProductCard key={index} product={product} />
))}

// ✅ Good - Unique ID as key
{products.map(product => (
  <ProductCard key={product.id} product={product} />
))}
```

### ❌ 5. Missing Cleanup in useEffect

```typescript
// ❌ Bad - No cleanup
useEffect(() => {
  const interval = setInterval(() => {
    console.log('Tick');
  }, 1000);
  // Memory leak - interval continues after unmount
}, []);

// ✅ Good - Cleanup function
useEffect(() => {
  const interval = setInterval(() => {
    console.log('Tick');
  }, 1000);

  return () => {
    clearInterval(interval);
  };
}, []);
```

### ❌ 6. Using 'use client' Everywhere

```typescript
// ❌ Bad - Unnecessary 'use client'
'use client';

export function ProductTitle({ title }: { title: string }) {
  return <h1>{title}</h1>; // No interactivity - doesn't need 'use client'
}

// ✅ Good - Server Component (no directive)
export function ProductTitle({ title }: { title: string }) {
  return <h1>{title}</h1>;
}
```

### ❌ 7. Fetching in Client Components When Possible in Server

```typescript
// ❌ Bad - Client-side fetching for initial data
'use client';

export function ProductDetails({ id }: { id: string }) {
  const [product, setProduct] = useState<Product | null>(null);

  useEffect(() => {
    fetch(`/api/products/${id}`)
      .then(res => res.json())
      .then(setProduct);
  }, [id]);

  return <div>{product?.name}</div>;
}

// ✅ Good - Server Component
export async function ProductDetails({ id }: { id: string }) {
  const product = await fetch(`/api/products/${id}`).then(r => r.json());
  return <div>{product.name}</div>;
}
```

---

## Summary

### Server vs Client Decision Tree

```
Do you need interactivity (onClick, state, hooks)?
├─ NO → Server Component (no directive)
│   └─ Benefits: SEO, performance, smaller bundle
│
└─ YES → Client Component ('use client')
    └─ Minimize: Keep Client Components small
```

### Component Checklist

**Before creating a component:**
- [ ] Named in PascalCase
- [ ] TypeScript interface for props
- [ ] Correct directive ('use client' only if needed)
- [ ] Follows FSD layer rules
- [ ] Performance optimized (memo, useCallback if needed)
- [ ] Tested (unit tests for logic-heavy components)

**Common mistakes to avoid:**
- ❌ Using 'use client' when not needed
- ❌ Fetching initial data in Client Components
- ❌ Not memoizing callbacks passed to child components
- ❌ Mutating props
- ❌ Missing cleanup in useEffect
- ❌ Using index as key in lists

**Best practices:**
- ✅ Server Components by default
- ✅ Client Components only for interactivity
- ✅ Memoize expensive computations
- ✅ Use Next.js Image component
- ✅ Validate props with TypeScript
- ✅ Test critical components

---

**For more patterns, see:**
- `NEXTJS-ARCHITECTURE.md` - Project structure and FSD integration
- `NEXTJS-STATE-MANAGEMENT.md` - Zustand patterns
- `NEXTJS-DATA-FETCHING.md` - Data fetching strategies
- `@/shared/ui/` - Shared component library
