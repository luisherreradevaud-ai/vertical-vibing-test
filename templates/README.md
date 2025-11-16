# AI Context Templates

**Purpose:** Template AI context files to be copied into backend and frontend repositories when they're created.

---

## Folder Structure

```
templates/
├── backend-ai-context/      # Copy to repos/backend/.ai-context/
│   ├── ARCHITECTURE.md      # VSA patterns
│   ├── CONVENTIONS.md       # Backend coding standards
│   ├── PERFORMANCE.md       # Database optimization
│   ├── TESTING.md           # Backend testing patterns
│   ├── LOGGING.md           # Server logging standards
│   ├── ANTI-PATTERNS.md     # Common mistakes to avoid
│   ├── FEATURE-TEMPLATE.md  # Template for FEATURE.md
│   └── DEPENDENCIES.md      # Feature dependency tracking
│
└── nextjs-ai-context/       # Copy to repos/frontend/.ai-context/
    ├── NEXTJS-ARCHITECTURE.md        # Next.js + FSD patterns
    ├── NEXTJS-COMPONENT-STANDARDS.md # Server/Client components
    ├── NEXTJS-STATE-MANAGEMENT.md    # Server state + Zustand
    └── NEXTJS-DATA-FETCHING.md       # Data fetching strategies
```

---

## How to Use

### When Creating Backend Repository

```bash
# 1. Create backend repository
mkdir repos/backend
cd repos/backend
git init

# 2. Copy AI context files
mkdir .ai-context
cp ../../templates/backend-ai-context/* .ai-context/

# 3. Verify files were copied
ls -la .ai-context/
```

**Files copied to `repos/backend/.ai-context/`:**
- ✅ ARCHITECTURE.md (VSA patterns)
- ✅ CONVENTIONS.md (Backend standards)
- ✅ PERFORMANCE.md (Database optimization)
- ✅ TESTING.md (Testing patterns)
- ✅ LOGGING.md (Logging standards)
- ✅ ANTI-PATTERNS.md (Common mistakes)
- ✅ FEATURE-TEMPLATE.md (FEATURE.md template)
- ✅ DEPENDENCIES.md (Dependency tracking)

### When Creating Frontend Repository

```bash
# 1. Create frontend repository
mkdir repos/frontend
cd repos/frontend
git init

# 2. Copy AI context files
mkdir .ai-context
cp ../../templates/nextjs-ai-context/* .ai-context/

# 3. Verify files were copied
ls -la .ai-context/
```

**Files copied to `repos/frontend/.ai-context/`:**
- ✅ NEXTJS-ARCHITECTURE.md (Next.js App Router + FSD patterns)
- ✅ NEXTJS-COMPONENT-STANDARDS.md (Server/Client components)
- ✅ NEXTJS-STATE-MANAGEMENT.md (Server state + Zustand)
- ✅ NEXTJS-DATA-FETCHING.md (Data fetching strategies)

---

## File Descriptions

### Backend Context Files

#### ARCHITECTURE.md
- **Purpose:** Vertical Slice Architecture (VSA) patterns
- **Content:** Feature organization, separation of concerns, repository pattern
- **When to read:** Before creating any backend feature

#### CONVENTIONS.md
- **Purpose:** Backend coding standards
- **Content:** File naming, TypeScript standards, import order, error handling
- **When to read:** Before writing backend code

#### PERFORMANCE.md
- **Purpose:** Database and API optimization
- **Content:** Performance budgets, N+1 query detection, caching strategies
- **When to read:** When optimizing backend performance

#### TESTING.md
- **Purpose:** Backend testing patterns
- **Content:** Unit tests, integration tests, coverage requirements, AAA pattern
- **When to read:** When writing backend tests

#### LOGGING.md
- **Purpose:** Server-side logging standards
- **Content:** Log levels, what to log, structured logging with Pino
- **When to read:** When implementing logging

#### ANTI-PATTERNS.md
- **Purpose:** Common mistakes to avoid
- **Content:** 15+ anti-patterns with examples and fixes
- **When to read:** During code review or when debugging

#### FEATURE-TEMPLATE.md
- **Purpose:** Template for documenting features
- **Content:** Standard structure for FEATURE.md files
- **When to read:** When creating new feature documentation

#### DEPENDENCIES.md
- **Purpose:** Track feature dependencies
- **Content:** Dependency graph, cross-feature relationships
- **When to read:** When modifying features with dependencies

### Frontend Context Files (Next.js)

#### NEXTJS-ARCHITECTURE.md
- **Purpose:** Next.js App Router + Feature-Sliced Design architecture
- **Content:** Server/Client components, FSD layers, routing, file structure
- **When to read:** Before creating any frontend feature

#### NEXTJS-COMPONENT-STANDARDS.md
- **Purpose:** React component patterns for Next.js
- **Content:** Server Components, Client Components, TypeScript, hooks, performance
- **When to read:** Before writing React components

#### NEXTJS-STATE-MANAGEMENT.md
- **Purpose:** State management with Server Components and Zustand
- **Content:** Server state vs client state, Zustand patterns, revalidation
- **When to read:** When implementing state management

#### NEXTJS-DATA-FETCHING.md
- **Purpose:** Data fetching strategies for Next.js
- **Content:** Server Components, caching, revalidation, Server Actions, streaming
- **When to read:** When fetching data or creating mutations

---

## Context Reading Order for AI

### For Backend Development

1. **Global context** (from orchestration/.ai-context/)
   - FULLSTACK-ARCHITECTURE.md
   - API-CONTRACTS.md
   - ERROR-CATALOG.md

2. **Backend context** (from repos/backend/.ai-context/)
   - ARCHITECTURE.md
   - CONVENTIONS.md
   - Other files as needed

### For Frontend Development

1. **Global context** (from orchestration/.ai-context/)
   - FULLSTACK-ARCHITECTURE.md
   - API-CONTRACTS.md
   - ERROR-CATALOG.md

2. **Frontend context** (from repos/frontend/.ai-context/)
   - NEXTJS-ARCHITECTURE.md
   - NEXTJS-COMPONENT-STANDARDS.md
   - NEXTJS-STATE-MANAGEMENT.md
   - NEXTJS-DATA-FETCHING.md

### For Full-Stack Features

1. **Global context**
   - FULLSTACK-ARCHITECTURE.md
   - FULLSTACK-FEATURE-WORKFLOW.md
   - AI-COORDINATION-GUIDE.md
   - API-CONTRACTS.md
   - ERROR-CATALOG.md

2. **Backend context**
   - ARCHITECTURE.md
   - CONVENTIONS.md

3. **Frontend context**
   - NEXTJS-ARCHITECTURE.md
   - NEXTJS-COMPONENT-STANDARDS.md
   - NEXTJS-STATE-MANAGEMENT.md
   - NEXTJS-DATA-FETCHING.md

---

## Updating Templates

If you need to update these templates:

1. Edit files in `templates/backend-ai-context/` or `templates/nextjs-ai-context/`
2. If repositories already exist, sync changes:
   ```bash
   # Backend
   cp templates/backend-ai-context/* repos/backend/.ai-context/

   # Frontend (Next.js)
   cp templates/nextjs-ai-context/* repos/frontend/.ai-context/
   ```

---

## Why Templates?

**Reason 1: Consistency**
- Every backend repo has the same AI context structure
- Every frontend repo follows the same patterns

**Reason 2: Reusability**
- Can create multiple backend/frontend repos from templates
- Easy to start new microservices

**Reason 3: Version Control**
- Templates are versioned in orchestration repo
- Changes propagate to all projects

**Reason 4: Onboarding**
- New developers/repos get complete context
- No missing documentation

---

## Summary

**Templates provide:**
- ✅ Complete AI context for backend repositories
- ✅ Complete AI context for Next.js frontend repositories
- ✅ Consistent patterns across all repositories
- ✅ Ready-to-use when creating new repos

**How to use:**
1. Create backend/frontend repository
2. Copy relevant template files to `.ai-context/`
3. AI can immediately understand the architecture

**Location in orchestration:**
```
/Users/.../fullstack-vsa-fsd/templates/
├── backend-ai-context/    (8 files ready to copy)
└── nextjs-ai-context/     (4 files ready to copy)
```
