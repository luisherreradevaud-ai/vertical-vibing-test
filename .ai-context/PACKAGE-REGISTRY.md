# Package Registry

**Purpose:** Approved packages and libraries to ensure consistency and prevent AI from choosing different libraries for the same task.

---

## Core Principle

**Before adding ANY package, ask:**
1. Can Node.js/TypeScript built-ins do this?
2. Is there already an approved package for this use case?
3. Is this package actively maintained? (check GitHub, npm)
4. Does this add significant bundle size?

**If YES to #1:** DON'T add the package
**If YES to #2:** USE the approved package
**If NO to #3:** DON'T add the package (security risk)

---

## Approved Packages (STRICT - Use These Only)

### Runtime & Framework

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `node` | 20+ | Runtime | ✅ Required |
| `typescript` | 5.3+ | Type system | ✅ Required |
| `tsx` | 4.7+ | TS execution (dev) | ✅ Required |
| `express` | 4.18+ | Web framework | ✅ Required |

**Alternatives NOT allowed:**
- ❌ Fastify (we chose Express)
- ❌ Koa
- ❌ Hapi

---

### Database & ORM

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `drizzle-orm` | 0.33+ | ORM | ✅ Required |
| `drizzle-kit` | 0.24+ | Migrations | ✅ Required |
| `postgres` | 3.4+ | PostgreSQL client | ✅ Required |

**Alternatives NOT allowed:**
- ❌ Prisma (we chose Drizzle)
- ❌ TypeORM
- ❌ Sequelize
- ❌ pg (use postgres library instead)

**Why Drizzle:**
- Type-safe SQL
- Zero runtime overhead
- Simple migration system
- Better for AI (explicit queries)

---

### Validation

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `zod` | 3.22+ | Schema validation | ✅ Required |

**Alternatives NOT allowed:**
- ❌ joi (prefer Zod for TypeScript)
- ❌ yup (prefer Zod)
- ❌ class-validator (prefer Zod)
- ❌ ajv (prefer Zod for simplicity)

**Why Zod:**
- TypeScript-first
- Type inference
- Composable schemas
- Better error messages

**Example:**
```typescript
// ✅ Good
import { z } from 'zod';

const schema = z.object({
  email: z.string().email()
});
```

---

### Security & Middleware

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `helmet` | 7.1+ | Security headers | ✅ Required |
| `cors` | 2.8+ | CORS handling | ✅ Required |
| `bcrypt` | 5.1+ | Password hashing | ✅ Recommended |
| `jsonwebtoken` | 9.0+ | JWT tokens | ✅ Recommended |

**Alternatives:**
- ⚠️ `argon2` (acceptable alternative to bcrypt)
- ❌ crypto.pbkdf2 (prefer bcrypt/argon2)

**Example:**
```typescript
// ✅ Good - bcrypt
import bcrypt from 'bcrypt';
const hash = await bcrypt.hash(password, 10);

// ❌ Bad - crypto.scrypt
import crypto from 'crypto';
crypto.scrypt(password, salt, 64, ...); // Don't use
```

---

### Logging

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `pino` | 8.15+ | Structured logging | ✅ Recommended |
| `morgan` | 1.10+ | HTTP logging | ✅ Recommended |

**Alternatives:**
- ⚠️ `winston` (acceptable, but prefer pino for performance)
- ❌ console.log (use in dev only, not production)

**Why Pino:**
- Fastest logger
- Structured JSON output
- Low overhead
- Child loggers

**Example:**
```typescript
// ✅ Good - pino
import pino from 'pino';
const logger = pino();
logger.info({ userId: '123' }, 'User logged in');

// ❌ Bad - console.log
console.log('User logged in:', userId);
```

---

### Testing

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `vitest` | 1.1+ | Test framework | ✅ Required |
| `@vitest/coverage-v8` | 1.1+ | Code coverage | ✅ Required |
| `supertest` | 6.3+ | HTTP testing | ✅ Recommended |

**Alternatives NOT allowed:**
- ❌ jest (we chose Vitest)
- ❌ mocha
- ❌ ava

**Why Vitest:**
- Fast (Vite-powered)
- ESM native
- TypeScript support
- Jest-compatible API

**Example:**
```typescript
// ✅ Good
import { describe, it, expect } from 'vitest';

describe('Feature', () => {
  it('should work', () => {
    expect(true).toBe(true);
  });
});
```

---

### HTTP Client (for external APIs)

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `node:fetch` | built-in | HTTP requests | ✅ Required |

**Alternatives NOT allowed:**
- ❌ axios (unnecessary, use native fetch)
- ❌ got
- ❌ node-fetch (use built-in)

**Why Native Fetch:**
- Built into Node.js 20+
- Standard Web API
- Zero dependencies
- Same as browser fetch

**Example:**
```typescript
// ✅ Good - native fetch
const response = await fetch('https://api.example.com/data');
const data = await response.json();

// ❌ Bad - axios
import axios from 'axios';
const { data } = await axios.get('https://api.example.com/data');
```

---

### Date/Time

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `Date` (native) | built-in | Date/time | ✅ Required |
| `Intl` (native) | built-in | Formatting | ✅ Required |
| `date-fns` | 3.0+ | Complex operations | ⚠️ Only if needed |

**Alternatives NOT allowed:**
- ❌ moment.js (deprecated)
- ❌ dayjs (prefer native or date-fns)
- ❌ luxon (prefer native or date-fns)

**Why Native First:**
- Zero dependencies
- Temporal API coming soon
- Good enough for 90% of use cases

**Example:**
```typescript
// ✅ Good - native Date
const now = new Date();
const iso = now.toISOString();

// ✅ Good - Intl formatting
const formatted = new Intl.DateTimeFormat('en-US').format(now);

// ⚠️ OK if complex operations needed
import { addDays, format } from 'date-fns';
const future = addDays(now, 7);

// ❌ Bad - moment
import moment from 'moment';
const formatted = moment().format('YYYY-MM-DD');
```

---

### UUID Generation

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `crypto.randomUUID()` | built-in | UUID v4 | ✅ Required |
| Drizzle `.defaultRandom()` | - | DB UUIDs | ✅ Required |

**Alternatives NOT allowed:**
- ❌ `uuid` package (use built-in)

**Example:**
```typescript
// ✅ Good - native crypto
import { randomUUID } from 'crypto';
const id = randomUUID();

// ✅ Good - Drizzle schema
export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom()
});

// ❌ Bad - uuid package
import { v4 as uuidv4 } from 'uuid';
const id = uuidv4();
```

---

### Environment Variables

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `dotenv` | 16.3+ | Load .env files | ✅ Required |
| `process.env` | built-in | Access env vars | ✅ Required |

**Alternatives NOT allowed:**
- ❌ env-var
- ❌ dotenv-safe
- ❌ cross-env (use scripts instead)

**Example:**
```typescript
// ✅ Good
import * as dotenv from 'dotenv';
dotenv.config();

const port = process.env.PORT || 3000;

// ❌ Bad - env-var
import env from 'env-var';
const port = env.get('PORT').required().asInt();
```

---

### File Upload

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `multer` | 1.4+ | File uploads | ✅ Recommended |

**Alternatives NOT allowed:**
- ❌ formidable
- ❌ busboy (unless specific need)

**Example:**
```typescript
// ✅ Good
import multer from 'multer';
const upload = multer({ dest: 'uploads/' });

router.post('/upload', upload.single('file'), (req, res) => {
  // req.file
});
```

---

### Rate Limiting

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `express-rate-limit` | 7.1+ | Rate limiting | ✅ Recommended |

**Example:**
```typescript
// ✅ Good
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

app.use('/api/', limiter);
```

---

### Compression

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `compression` | 1.7+ | Response compression | ✅ Required |

**Example:**
```typescript
// ✅ Good
import compression from 'compression';
app.use(compression());
```

---

### Email Sending

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `nodemailer` | 6.9+ | Email sending | ✅ Recommended |
| AWS SES SDK | - | Email (production) | ⚠️ For production |
| SendGrid SDK | - | Email (production) | ⚠️ Alternative |

**Choose ONE email solution:**
- Development: nodemailer + SMTP
- Production: AWS SES or SendGrid

**Example:**
```typescript
// ✅ Good - nodemailer (dev)
import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  host: 'smtp.example.com',
  port: 587,
  auth: { user: 'user', pass: 'pass' }
});
```

---

### JSON Web Tokens

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `jsonwebtoken` | 9.0+ | JWT creation/verification | ✅ Recommended |

**Example:**
```typescript
// ✅ Good
import jwt from 'jsonwebtoken';

const token = jwt.sign({ userId: '123' }, process.env.JWT_SECRET, {
  expiresIn: '1h'
});

const decoded = jwt.verify(token, process.env.JWT_SECRET);
```

---

### Code Quality

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `eslint` | 8.56+ | Linting | ✅ Recommended |
| `@typescript-eslint/parser` | 6.15+ | TS parsing | ✅ Recommended |
| `@typescript-eslint/eslint-plugin` | 6.15+ | TS rules | ✅ Recommended |
| `prettier` | 3.1+ | Code formatting | ✅ Recommended |

**Example .eslintrc:**
```json
{
  "parser": "@typescript-eslint/parser",
  "plugins": ["@typescript-eslint"],
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended"
  ]
}
```

---

## Packages to AVOID

### ❌ Deprecated/Unmaintained

- `moment` - Deprecated, use native Date or date-fns
- `request` - Deprecated, use native fetch
- `node-fetch` - Use built-in fetch (Node 20+)

### ❌ Overly Complex

- `lodash` - Most utilities available in ES6+
  - Instead of `_.map()` → use `array.map()`
  - Instead of `_.filter()` → use `array.filter()`
  - Instead of `_.isEmpty()` → use `!obj || Object.keys(obj).length === 0`

### ❌ Framework Conflicts

- `body-parser` - Built into Express 4.16+
- `cookie-parser` - Use Express built-in if possible

---

## Adding New Packages

### Process

1. **Check if native solution exists**
   ```typescript
   // Before: import _ from 'lodash'
   // After: Use native Array.prototype.map
   ```

2. **Search this registry** - Is there an approved package?

3. **Verify package health:**
   - Last update < 6 months ago
   - 1000+ weekly downloads
   - Active GitHub repository
   - Good TypeScript support

4. **Check bundle size:**
   - Use https://bundlephobia.com
   - Prefer < 100KB packages
   - Check tree-shakeable

5. **Document decision:**
   - Add to this registry
   - Update `.ai-context/decisions/` with ADR
   - Add to DEPENDENCIES.md if significant

### Template for New Package

```markdown
| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `package-name` | X.Y+ | What it does | ✅ Recommended |

**Why this package:**
- Reason 1
- Reason 2

**Example:**
\`\`\`typescript
// Code example
\`\`\`
```

---

## Package Installation Commands

```bash
# Production dependencies
pnpm add express drizzle-orm postgres zod dotenv helmet cors compression morgan

# Development dependencies
pnpm add -D typescript tsx @types/node @types/express
pnpm add -D drizzle-kit
pnpm add -D vitest @vitest/coverage-v8 supertest @types/supertest
pnpm add -D eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin
pnpm add -D prettier
pnpm add -D @types/cors @types/compression @types/morgan

# Optional (add when needed)
pnpm add bcrypt jsonwebtoken
pnpm add -D @types/bcrypt @types/jsonwebtoken
```

---

## Common Substitutions

| Need | ❌ Don't Use | ✅ Use Instead |
|------|-------------|----------------|
| Array utilities | lodash | Native array methods |
| HTTP client | axios | native fetch |
| Date manipulation | moment | native Date or date-fns |
| UUID | uuid package | crypto.randomUUID() |
| Body parsing | body-parser | Express built-in |
| Environment vars | env-var | dotenv + process.env |
| Deep clone | lodash.cloneDeep | structuredClone() (native) |
| Debounce | lodash.debounce | Custom or use-debounce (React) |

---

## Native Alternatives Reference

### Array Operations

```typescript
// ❌ Bad - lodash
import _ from 'lodash';
_.map(arr, x => x * 2);
_.filter(arr, x => x > 5);
_.find(arr, x => x.id === '123');

// ✅ Good - native
arr.map(x => x * 2);
arr.filter(x => x > 5);
arr.find(x => x.id === '123');
```

### Object Operations

```typescript
// ❌ Bad - lodash
import _ from 'lodash';
_.isEmpty(obj);
_.keys(obj);
_.values(obj);

// ✅ Good - native
!obj || Object.keys(obj).length === 0;
Object.keys(obj);
Object.values(obj);
```

### Deep Clone

```typescript
// ❌ Bad - lodash
import _ from 'lodash';
const copy = _.cloneDeep(obj);

// ✅ Good - native (Node 17+)
const copy = structuredClone(obj);

// ✅ Good - for simple objects
const copy = JSON.parse(JSON.stringify(obj));
```

---

## Security Note

**NEVER install packages with:**
- Known security vulnerabilities (check `npm audit`)
- Suspicious ownership transfers
- Minimal stars/downloads on npm
- No TypeScript definitions
- Abandoned (last update > 2 years)

**Run before committing:**
```bash
npm audit
pnpm audit
```

---

## Summary

**Approved Core Packages:** 15
**Recommended Packages:** 8
**Total Registered:** 23

**Philosophy:**
1. **Native first** - Use Node.js/TypeScript built-ins when possible
2. **Minimal dependencies** - Each package adds risk and complexity
3. **Active maintenance** - Only use packages that are maintained
4. **TypeScript support** - Must have good TS definitions
5. **Consistency** - One way to do things, not multiple

**When in doubt, ask:**
"Can we do this without a package?" If yes, don't add it.
