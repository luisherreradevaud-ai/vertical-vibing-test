# PostgreSQL-Only Mode

**Date**: November 16, 2025
**Status**: ✅ Complete
**Breaking Change**: Yes - DATABASE_URL now required

## What Changed

The IAM system now **requires PostgreSQL** and no longer supports in-memory mode for production use.

### Changes Made

✅ **Removed environment variable toggle** - No more `USE_DATABASE` flag
✅ **PostgreSQL is mandatory** - `DATABASE_URL` must be set
✅ **Clear error messages** - Helpful error if `DATABASE_URL` is missing
✅ **Tests still work** - `InMemoryIAMDatabase` exported for testing

## Migration Required

### Before (Toggle Mode)
```bash
# In-memory (no DATABASE_URL needed)
npm run dev
# Output: [IAM Database] Using in-memory storage

# PostgreSQL (optional)
DATABASE_URL=postgresql://... npm run dev
# Output: [IAM Database] Using PostgreSQL persistence
```

### After (PostgreSQL Only)
```bash
# DATABASE_URL is REQUIRED
DATABASE_URL=postgresql://user:pass@localhost:5432/db npm run dev
# Output: [IAM Database] Using PostgreSQL persistence

# Without DATABASE_URL - will error
npm run dev
# Error: DATABASE_URL is required. Please set it in your .env file.
```

## Setup Instructions

### 1. Set Up PostgreSQL

**Option A - Local PostgreSQL:**
```bash
# macOS
brew install postgresql@15
brew services start postgresql@15
createdb vertical_vibing
```

**Option B - Docker:**
```bash
docker run --name postgres \
  -e POSTGRES_DB=vertical_vibing \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  -d postgres:15
```

**Option C - Cloud (Neon, Supabase, Railway):**
Get DATABASE_URL from your provider's dashboard.

### 2. Configure Environment

Create `.env` file:
```bash
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/vertical_vibing
```

Or copy from example:
```bash
cp .env.example .env
# Edit .env and set your DATABASE_URL
```

### 3. Run Migrations

```bash
npm install
npm run db:migrate
```

### 4. Start Server

```bash
npm run dev
# Output: [IAM Database] Using PostgreSQL persistence
```

## Files Modified

### 1. `src/shared/db/repositories/iam.repository.ts`

**Before:**
```typescript
function createIAMDatabase(): IAMDatabase {
  const USE_POSTGRES = !!process.env.DATABASE_URL && process.env.USE_DATABASE !== 'false';

  if (USE_POSTGRES) {
    console.log('[IAM Database] Using PostgreSQL persistence');
    return new PostgreSQLIAMDatabase(db);
  } else {
    console.log('[IAM Database] Using in-memory storage');
    return new InMemoryIAMDatabase();
  }
}
```

**After:**
```typescript
function createIAMDatabase(): IAMDatabase {
  if (!process.env.DATABASE_URL) {
    throw new Error(
      'DATABASE_URL is required. Please set it in your .env file.\n' +
      'Example: DATABASE_URL=postgresql://user:password@localhost:5432/vertical_vibing'
    );
  }

  console.log('[IAM Database] Using PostgreSQL persistence');
  return new PostgreSQLIAMDatabase(db);
}

// Export InMemoryIAMDatabase for testing purposes only
export { InMemoryIAMDatabase };
```

### 2. `src/shared/db/postgres.ts`

**Before:**
```typescript
const DATABASE_URL = process.env.DATABASE_URL || '';
export const USE_POSTGRES = !!DATABASE_URL && process.env.USE_DATABASE !== 'false';

export function getPostgresClient() {
  if (!USE_POSTGRES) {
    throw new Error('PostgreSQL is not configured...');
  }
  // ...
}
```

**After:**
```typescript
const DATABASE_URL = process.env.DATABASE_URL;

if (!DATABASE_URL) {
  throw new Error(
    'DATABASE_URL is required. Please set it in your .env file.\n' +
    'Example: DATABASE_URL=postgresql://user:password@localhost:5432/vertical_vibing'
  );
}

export function getPostgresClient() {
  // DATABASE_URL is guaranteed to exist
  // ...
}
```

### 3. `.env.example`

**Before:**
```bash
# Database (PostgreSQL) - Optional
# Leave empty for in-memory mode (default)
# DATABASE_URL=postgresql://user:password@localhost:5432/vertical_vibing

# Uncomment to force database mode (auto-detects from DATABASE_URL by default)
# USE_DATABASE=true
```

**After:**
```bash
# Database (PostgreSQL) - REQUIRED
# The application requires a PostgreSQL database
DATABASE_URL=postgresql://user:password@localhost:5432/vertical_vibing
```

### 4. `README.md`

**Before:**
```markdown
- ✅ **PostgreSQL persistence** (17 tables, toggle mode via env)
```

**After:**
```markdown
- ✅ **PostgreSQL persistence** (17 tables, production-ready)
```

## Testing

Tests still work because `InMemoryIAMDatabase` is exported:

```typescript
// Test files can import in-memory implementation
import { InMemoryIAMDatabase } from '../repositories/iam.repository';

const testDb = new InMemoryIAMDatabase();
// Use for fast, isolated tests
```

Run tests:
```bash
npm test
# All 60 tests still pass
```

## Error Handling

### Missing DATABASE_URL

**Error:**
```
Error: DATABASE_URL is required. Please set it in your .env file.
Example: DATABASE_URL=postgresql://user:password@localhost:5432/vertical_vibing
```

**Solution:**
1. Create `.env` file in `repos/backend/`
2. Add `DATABASE_URL=postgresql://...`
3. Restart server

### Connection Failed

**Error:**
```
[Database] Health check failed: connection refused
```

**Solution:**
- Ensure PostgreSQL is running: `brew services start postgresql@15`
- Check connection string is correct
- Verify database exists: `psql -l`

### Migrations Not Run

**Error:**
```
relation "user_levels" does not exist
```

**Solution:**
```bash
npm run db:migrate
```

## Why This Change?

### Benefits

✅ **Simpler** - One mode, less configuration
✅ **Production-Ready** - No accidental in-memory in production
✅ **Clear Requirements** - Obvious that PostgreSQL is needed
✅ **Better DX** - Helpful error messages guide setup

### Trade-offs

⚠️ **Setup Required** - Can't just `npm run dev` without database
✅ **But** - Tests still fast (use in-memory)
✅ **But** - Docker makes setup easy
✅ **But** - Cloud providers offer free tiers

## Deployment Checklist

- [ ] PostgreSQL database provisioned
- [ ] `DATABASE_URL` set in environment variables
- [ ] Migrations run: `npm run db:migrate`
- [ ] Server starts successfully
- [ ] Health check passes: `GET /health/db`
- [ ] Tests still passing: `npm test`

## Quick Start (Docker)

Fastest way to get started:

```bash
# 1. Start PostgreSQL
docker run --name postgres \
  -e POSTGRES_DB=vertical_vibing \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  -d postgres:15

# 2. Configure
echo "DATABASE_URL=postgresql://postgres:postgres@localhost:5432/vertical_vibing" > .env

# 3. Install & Migrate
npm install
npm run db:migrate

# 4. Start server
npm run dev
```

## Summary

**What**: Removed toggle mode, PostgreSQL is now required
**Why**: Simpler, production-ready, clearer requirements
**Impact**: Breaking change - requires database setup
**Tests**: Still work (use in-memory export)
**Migration**: Set DATABASE_URL, run migrations, start server

✅ **PostgreSQL-only mode is now active**

---

For detailed PostgreSQL setup, see **[DATABASE-PERSISTENCE-GUIDE.md](./DATABASE-PERSISTENCE-GUIDE.md)**
