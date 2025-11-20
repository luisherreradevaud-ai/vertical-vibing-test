# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Vertical Vibing** is a full-stack SaaS application using a multi-repository architecture with shared TypeScript types. The project combines Vertical Slice Architecture (VSA) for the backend and Next.js App Router for the frontend, with production-ready IAM system.

## Repository Structure

This is a multi-repository project organized as follows:

```
vertical-vibing/
├── shared-types/         # Shared TypeScript types & Zod schemas (NPM package)
├── repos/
│   ├── backend/          # Express backend (VSA architecture)
│   └── frontend/         # Next.js 14+ frontend (App Router)
├── scripts/              # Development automation
└── .ai-context/          # Global AI context files
```

## Development Commands

### First Time Setup
```bash
./scripts/setup.sh        # Install all dependencies
```

### Development
```bash
./scripts/dev.sh          # Start all servers (shared-types + backend + frontend)
```

This starts:
- Shared types watcher (rebuilds on change)
- Backend: http://localhost:3000
- Frontend: http://localhost:3001

### Testing
```bash
./scripts/test.sh         # Run all tests

# Backend tests only
cd repos/backend && npm test

# Frontend tests only
cd repos/frontend && npm test

# Backend tests with coverage
cd repos/backend && npm run test:coverage
```

### Database Management
```bash
cd repos/backend
npm run db:generate       # Generate migrations from schema changes
npm run db:migrate        # Apply migrations to database
npm run db:studio         # Open Drizzle Studio GUI
```

## Architecture

### Backend: Vertical Slice Architecture (VSA)

Location: `repos/backend/`

**Key Principle:** Features are self-contained vertical slices with minimal cross-feature dependencies.

**Structure:**
```
src/
├── features/              # Feature modules (business capabilities)
│   ├── auth/              # Authentication
│   ├── users/             # User management
│   ├── companies/         # Company management
│   ├── subscriptions/     # Subscription handling
│   └── iam/               # Identity & Access Management (production-ready)
└── shared/                # Shared infrastructure
    ├── db/                # Database (Drizzle ORM, schemas, migrations)
    ├── middleware/        # Express middleware
    ├── utils/             # Utilities
    ├── config/            # Configuration
    └── services/          # Shared services
```

**Each feature contains:**
- `FEATURE.md` - Feature documentation
- `*.route.ts` - HTTP endpoints
- `*.service.ts` - Business logic
- `*.repository.ts` - Data access
- `*.validator.ts` - Zod validation schemas
- `*.types.ts` - TypeScript types
- `__tests__/` - Tests

**Tech Stack:**
- Express.js
- PostgreSQL + Drizzle ORM
- Zod validation
- Pino logging
- JWT authentication
- Helmet security
- Vitest testing

### Frontend: Next.js App Router

Location: `repos/frontend/`

**Structure:**
```
src/
├── app/              # Next.js App Router (routes, layouts)
├── features/         # Feature modules (business logic)
├── shared/           # Shared UI components, utilities
└── lib/              # Library code
```

**Tech Stack:**
- Next.js 14+ (App Router)
- React 19
- React Server Components
- Zustand (client state)
- Tailwind CSS 4

### Shared Types Package

Location: `shared-types/`

**Purpose:** Single source of truth for types shared between backend and frontend.

**Usage in backend:**
```typescript
import { type User } from '@vertical-vibing/shared-types';
```

**Usage in frontend:**
```typescript
import { type User } from '@vertical-vibing/shared-types';
```

**Important:** When types change, the watcher auto-rebuilds. Restart dev servers if needed.

## Key Architectural Patterns

### Type Safety Across the Stack

Both backend and frontend import from `@vertical-vibing/shared-types` to ensure:
- Compile-time type checking
- Runtime validation with Zod schemas
- API contract alignment
- No type duplication

### Backend Feature Pattern

Features use factory functions for dependency injection:

```typescript
// *.route.ts
export function createProductsRouter(): Router {
  const router = Router();
  const service = new ProductsService();

  router.get('/', async (req, res) => {
    const products = await service.getAll();
    res.json(products);
  });

  return router;
}
```

### Database Schema

**Location:** `repos/backend/src/shared/db/schema/`

**Important:** Centralized Drizzle schemas - single source of truth for database types. Do NOT duplicate schema definitions in features.

### Validation Pattern

All input validation uses Zod schemas from shared-types:

```typescript
// Backend validation
import { createUserSchema } from '@vertical-vibing/shared-types';
const validated = createUserSchema.parse(req.body);

// Frontend validation
import { createUserSchema } from '@vertical-vibing/shared-types';
const result = createUserSchema.safeParse(formData);
```

## IAM System

The project includes a production-ready Identity and Access Management system with:
- 60 backend tests (100% pass rate)
- 14 API endpoints
- 7 frontend components
- Multi-layer security (JWT → Tenant → Permissions)
- Audit logging
- ETag caching

See `.ai-context/` for detailed IAM documentation.

## Multi-Repository Workflow

### Creating a Full-Stack Feature

1. **Define Shared Types** (in `shared-types/`)
   ```bash
   # Create types in shared-types/src/
   cd shared-types
   npm run build
   ```

2. **Build Backend Feature** (in `repos/backend/`)
   ```bash
   cd repos/backend
   # Create feature in src/features/my-feature/
   # Import types from @vertical-vibing/shared-types
   ```

3. **Build Frontend Feature** (in `repos/frontend/`)
   ```bash
   cd repos/frontend
   # Create feature in src/features/my-feature/
   # Import types from @vertical-vibing/shared-types
   ```

4. **Test Integration**
   ```bash
   # From root
   ./scripts/dev.sh
   # Test end-to-end
   ```

### Committing Changes

Each repository (backend, frontend, orchestration) has its own Git history. Commit to each separately:

```bash
# Backend changes
cd repos/backend
git add .
git commit -m "feat: add feature"

# Frontend changes
cd repos/frontend
git add .
git commit -m "feat: add UI for feature"

# Shared types changes
cd shared-types
git add .
git commit -m "feat: add types for feature"
```

## Important Context Files

When working on features, read these files for architectural guidance:

**Global Context** (`.ai-context/`):
- `FULLSTACK-ARCHITECTURE.md` - Overall architecture
- `AI-COORDINATION-GUIDE.md` - Multi-repo workflow
- `FULLSTACK-FEATURE-WORKFLOW.md` - Feature development guide

**Backend Context** (`repos/backend/.ai-context/`):
- `ARCHITECTURE.md` - VSA patterns and conventions

**Frontend Context** (`repos/frontend/.ai-context/`):
- `NEXTJS-ARCHITECTURE.md` - Next.js patterns
- `NEXTJS-COMPONENT-STANDARDS.md` - React component standards
- `NEXTJS-STATE-MANAGEMENT.md` - Zustand patterns
- `NEXTJS-DATA-FETCHING.md` - Data fetching patterns
- `IAM-SYSTEM.md` - IAM integration guide

## Common Patterns

### Adding a New Backend Feature

1. Create directory: `repos/backend/src/features/my-feature/`
2. Create `FEATURE.md` documenting the feature
3. Create files following naming conventions:
   - `my-feature.route.ts` - HTTP routes
   - `my-feature.service.ts` - Business logic
   - `my-feature.repository.ts` - Data access
   - `my-feature.validator.ts` - Zod validation
   - `my-feature.types.ts` - Re-export from shared-types
4. Register route in `repos/backend/src/index.ts`
5. Write tests in `__tests__/`

### Adding a New Frontend Feature

1. Create directory: `repos/frontend/src/features/my-feature/`
2. Create subdirectories as needed:
   - `ui/` - React components
   - `api/` - Backend API calls
   - `model/` - Zustand stores
   - `lib/` - Utilities
3. Export public API from `index.ts`
4. Import types from `@vertical-vibing/shared-types`

### Database Schema Changes

1. Modify schema in `repos/backend/src/shared/db/schema/`
2. Generate migration: `npm run db:generate`
3. Review migration in `migrations/`
4. Apply migration: `npm run db:migrate`

## Environment Variables

### Backend (`.env`)
```
PORT=3000
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
JWT_SECRET=your-secret-key
```

### Frontend (`.env.local`)
```
NEXT_PUBLIC_API_URL=http://localhost:3000
```

## Best Practices

### Type Safety
- Always import types from `@vertical-vibing/shared-types`
- Use Zod for runtime validation
- Enable TypeScript strict mode (already configured)

### Features
- Keep features independent (minimal cross-feature dependencies)
- Document features with `FEATURE.md`
- Use factory functions for routers (dependency injection)
- Extract to shared/ only when used by 3+ features

### Testing
- Write unit tests for business logic (target >90% coverage)
- Write integration tests for API endpoints
- Backend: Vitest
- Frontend: Vitest + Testing Library

### Security
- Use Zod for input validation
- Use parameterized queries (Drizzle handles this)
- Implement rate limiting (already configured)
- Use JWT for authentication
- Use Helmet for security headers (already configured)

### Performance
- Use database connection pooling (configured)
- Paginate large datasets
- Add database indexes for frequently queried columns
- Consider caching (ETag implemented in IAM)

## Troubleshooting

### Types not syncing
If backend/frontend shows type errors after changing shared-types:

```bash
# Rebuild shared types
cd shared-types
npm run build

# Restart dev servers
# Kill current servers (Ctrl+C) and run:
./scripts/dev.sh
```

### Database connection issues
Check `DATABASE_URL` in `repos/backend/.env` and ensure PostgreSQL is running.

### Port conflicts
Backend uses port 3000, frontend uses port 3001. Change in package.json scripts if needed.

## Production Deployment

### Backend
```bash
cd repos/backend
npm run build
npm start
```

### Frontend
```bash
cd repos/frontend
npm run build
npm start
```

Both apps are stateless and can be horizontally scaled. Ensure environment variables are properly configured for production.
