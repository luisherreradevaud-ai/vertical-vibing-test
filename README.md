# Vertical Vibing - Full-Stack Application

Full-stack application using VSA (Backend) + Next.js + FSD (Frontend) architecture.

## 📁 Structure

```
vertical-vibing/
├── .ai-context/          # Global AI context files
├── shared-types/         # Shared TypeScript types (NPM package)
├── repos/
│   ├── backend/          # Express backend (VSA architecture)
│   └── frontend/         # Next.js frontend (FSD architecture)
├── scripts/              # Development scripts
├── templates/            # AI context templates
└── docs/                 # Documentation
```

## 🚀 Quick Start

### First Time Setup

```bash
# Install all dependencies
./scripts/setup.sh
```

### Development

```bash
# Start all servers (shared-types, backend, frontend)
./scripts/dev.sh
```

Servers will be available at:
- Backend: http://localhost:3000
- Frontend: http://localhost:3001

### Testing

```bash
# Run all tests
./scripts/test.sh
```

## 📦 Shared Types

The `@vertical-vibing/shared-types` package contains all shared TypeScript types and Zod schemas.

**Location:** `shared-types/`

**Usage in backend:**
```typescript
import { type User } from '@vertical-vibing/shared-types';
```

**Usage in frontend:**
```typescript
import { type User } from '@vertical-vibing/shared-types';
```

## 🔧 Backend (VSA Architecture)

**Location:** `repos/backend/`

**Tech Stack:**
- Express.js
- PostgreSQL + Drizzle ORM
- Zod validation
- Pino logging

**Structure:**
```
src/
├── features/          # Feature modules (VSA)
├── shared/            # Shared utilities
└── index.ts           # Server entry point
```

## ⚛️ Frontend (Next.js + FSD)

**Location:** `repos/frontend/`

**Tech Stack:**
- Next.js 14+ (App Router)
- React Server Components
- Zustand (client state)
- Tailwind CSS

**Structure:**
```
src/
├── app/              # Next.js App Router
├── features/         # Feature modules (FSD)
├── entities/         # Business entities
└── shared/           # Shared UI components
```

## 📚 Documentation

- `.ai-context/AI-COORDINATION-GUIDE.md` - How AI works across repos
- `.ai-context/FULLSTACK-ARCHITECTURE.md` - Architecture overview
- `.ai-context/FULLSTACK-FEATURE-WORKFLOW.md` - Feature development guide
- `repos/backend/.ai-context/` - Backend-specific guides
- `repos/frontend/.ai-context/` - Frontend-specific guides

## 🤖 AI-Assisted Development

This project is set up for AI-assisted development. AI can work across both repositories while maintaining type safety.

**Example prompt:**
```
Create a "Product Reviews" feature:
1. Read .ai-context/AI-COORDINATION-GUIDE.md
2. Create shared types
3. Build backend API
4. Build frontend UI
```

## 🔑 Environment Variables

### Backend (.env)
```
PORT=3000
DATABASE_URL=postgresql://...
```

### Frontend (.env.local)
```
NEXT_PUBLIC_API_URL=http://localhost:3000
```

## 📝 Development Workflow

1. **Create shared types** in `shared-types/src/entities/`
2. **Build backend API** in `repos/backend/src/features/`
3. **Build frontend UI** in `repos/frontend/src/features/`
4. **Types are automatically synced** across the stack

## 🧪 Testing

- Backend: `cd repos/backend && npm test`
- Frontend: `cd repos/frontend && npm test`

## 📦 Building for Production

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

## 🤝 Contributing

1. Create a feature branch
2. Follow the architecture patterns in `.ai-context/`
3. Ensure tests pass
4. Submit a pull request

## 📄 License

MIT
