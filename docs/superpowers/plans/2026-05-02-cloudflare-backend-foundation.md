# Cloudflare Backend Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the Cloudflare backend foundation for THE CRIME BOARD: a working monorepo with D1 schema, an `api-worker` that handles Sign in with Apple → session token issuance and `GET / PATCH /me`, deployed to dev + staging environments. Every later backend plan (ingest, clustering, deep-check, push) extends this foundation.

**Architecture:** pnpm monorepo at `backend/` containing a `shared` package (types, auth helpers) and an `api` worker. Cloudflare-only: D1 (SQL), KV (cache), R2 (object storage), Queues (background jobs), Workers AI (embeddings, LLM). Hono as HTTP router. `jose` for Apple JWKS verification, `hono/jwt` for HS256 session tokens. Vitest with `@cloudflare/vitest-pool-workers` for Worker integration tests against real D1 in `--local` mode.

**Tech Stack:** Node 20+, pnpm 9+, TypeScript 5.5+, Wrangler 4+, Hono 4+, jose 5+, Vitest 2+, `@cloudflare/vitest-pool-workers`. macOS / zsh.

**Skill applicability:** This is a backend-only plan — no UI, no copy, no visual decisions. The `impeccable` skill (shape / craft / critique / polish) does not apply here. Invoke `impeccable` for plan #2 (iOS app foundation + DesignSystem) and every iOS feature plan after. Backend-only plans (#3 ingest/clustering, #4 read API, #5 bias data refresh, #9 Deep Check service, #14 push notifications backend) follow the same "no impeccable needed" rule.

---

## Prerequisites

Before starting Task 1, the engineer must have:

- **Node 20+** — `node --version` should print `v20.x` or higher. Install via `brew install node` if missing.
- **pnpm 9+** — `pnpm --version` should print `9.x` or higher. Install with `npm install -g pnpm`.
- **A Cloudflare account** — free tier works. Sign up at https://dash.cloudflare.com if needed.
- **An Apple Bundle ID reserved** for THE CRIME BOARD (e.g. `com.bworthy.crimeboard`). Reserved at https://developer.apple.com/account → Identifiers. Doesn't need a paid Developer account yet — even free ones can reserve a Bundle ID, though Sign in with Apple itself requires the paid program eventually. For local testing, a placeholder string works.
- **Git** — `git --version`. Install via `brew install git` if missing.

---

## Out of scope for this plan (covered in later plans)

- RSS ingestion + clustering pipeline (plan #3)
- Full API endpoints — `/feed`, `/clusters/:id`, `/articles/:id`, `/factchecks/lookup`, etc. (plan #4)
- Deep Check service (plan #9)
- Push notifications (plan #14)
- Bias data ingestion script (plan #5)
- GitHub Actions CI/CD (separate ops plan)
- Email signup as fallback auth (separate auth-extensions plan)
- Anonymous mode endpoints (no public unauthenticated routes exist in this plan; nothing to test against)

---

## File structure produced by this plan

```
/Users/kari/Documents/news app/
├── .gitignore                      [created Task 1]
├── README.md                       [created Task 1]
└── backend/
    ├── package.json                [Task 2]
    ├── pnpm-workspace.yaml         [Task 2]
    ├── tsconfig.base.json          [Task 3]
    ├── .gitignore                  [Task 2]
    ├── README.md                   [Task 21]
    ├── migrations/
    │   └── 0001_initial_schema.sql [Task 6]
    ├── packages/
    │   └── shared/
    │       ├── package.json        [Task 8]
    │       ├── tsconfig.json       [Task 8]
    │       └── src/
    │           ├── env.ts          [Task 8]
    │           ├── session.ts      [Task 9]
    │           ├── session.test.ts [Task 9]
    │           ├── jwks.ts         [Task 10]
    │           ├── jwks.test.ts    [Task 10]
    │           ├── apple.ts        [Task 11]
    │           ├── apple.test.ts   [Task 11]
    │           └── index.ts        [Task 11]
    └── workers/
        └── api/
            ├── package.json        [Task 12]
            ├── tsconfig.json       [Task 12]
            ├── wrangler.toml       [Task 12, 18]
            ├── vitest.config.ts    [Task 13]
            ├── worker-configuration.d.ts  [Task 12, regenerated]
            ├── src/
            │   ├── index.ts        [Task 12, 17]
            │   ├── types.ts        [Task 12]
            │   ├── routes/
            │   │   ├── auth.ts     [Task 15]
            │   │   └── me.ts       [Task 16]
            │   └── middleware/
            │       └── authn.ts    [Task 14]
            └── test/
                ├── env.d.ts        [Task 13]
                ├── smoke.test.ts   [Task 13]
                ├── authn.test.ts   [Task 14]
                ├── auth.test.ts    [Task 15]
                └── me.test.ts      [Task 16]
```

---

## Phase 0 — Project bootstrap

### Task 1: Initialize git repo at project root

**Files:**
- Create: `/Users/kari/Documents/news app/.gitignore`
- Create: `/Users/kari/Documents/news app/README.md`

The project root has many files (PRODUCT.md, DESIGN.md, AGENTS.md, etc.) but no git repo yet. Initialize git and commit the existing canonical docs as the first commit so all future work is tracked.

- [ ] **Step 1: Verify we're in the project root and not already a git repo**

Run:
```bash
cd "/Users/kari/Documents/news app" && pwd && [ -d .git ] && echo "ALREADY A REPO — STOP" || echo "OK to init"
```
Expected: `/Users/kari/Documents/news app` followed by `OK to init`. If you see `ALREADY A REPO — STOP`, do not proceed — investigate why.

- [ ] **Step 2: Initialize git**

Run:
```bash
git init -b main
```
Expected: `Initialized empty Git repository in /Users/kari/Documents/news app/.git/`

- [ ] **Step 3: Write `.gitignore`**

Create `/Users/kari/Documents/news app/.gitignore`:

```gitignore
# macOS
.DS_Store

# Editor
.vscode/
.idea/
*.swp

# Node / pnpm (used in backend/)
node_modules/
.pnpm-store/
*.tsbuildinfo

# Cloudflare Wrangler
.wrangler/
.dev.vars
.env

# Superpowers (visual companion mockups, brainstorm artifacts)
.superpowers/

# Logs
*.log
npm-debug.log*
pnpm-debug.log*

# Test output
coverage/
```

- [ ] **Step 4: Write top-level README**

Create `/Users/kari/Documents/news app/README.md`:

```markdown
# THE CRIME BOARD

News-as-investigation iOS app for news-skeptical adults.

## Canonical docs

- [`AGENTS.md`](./AGENTS.md) — TL;DR for AI agents
- [`PRODUCT.md`](./PRODUCT.md) — strategic / voice / anti-references
- [`DESIGN.md`](./DESIGN.md) — visual design system (in seed mode)
- [`docs/superpowers/specs/`](./docs/superpowers/specs/) — technical specs
- [`docs/superpowers/plans/`](./docs/superpowers/plans/) — implementation plans

## Sub-projects

- [`backend/`](./backend/) — Cloudflare Workers backend (this is the only sub-project so far)
- iOS app — not yet scaffolded
```

- [ ] **Step 5: Commit**

Run:
```bash
git add .gitignore README.md AGENTS.md PRODUCT.md DESIGN.md "design idea.md.rtf" docs/ skills-lock.json
git commit -m "chore: initial commit — canonical docs and project scaffolding"
```

Expected: a single commit on `main` with the existing project docs.

If you see `.agents/` or `.claude/` flagged as untracked when running `git status`, leave them — they're agent runtime files and should stay local. (They won't be committed by the explicit `git add` above.)

---

### Task 2: Create backend monorepo structure

**Files:**
- Create: `/Users/kari/Documents/news app/backend/package.json`
- Create: `/Users/kari/Documents/news app/backend/pnpm-workspace.yaml`
- Create: `/Users/kari/Documents/news app/backend/.gitignore`

- [ ] **Step 1: Create directory structure**

Run:
```bash
cd "/Users/kari/Documents/news app" && mkdir -p backend/migrations backend/packages/shared/src backend/workers/api/src/routes backend/workers/api/src/middleware backend/workers/api/test
```

- [ ] **Step 2: Write root `backend/package.json`**

Create `/Users/kari/Documents/news app/backend/package.json`:

```json
{
  "name": "crimeboard-backend",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "engines": {
    "node": ">=20",
    "pnpm": ">=9"
  },
  "scripts": {
    "test": "pnpm -r run test",
    "typecheck": "pnpm -r run typecheck",
    "deploy:dev": "pnpm --filter @crimeboard/api run deploy:dev",
    "deploy:staging": "pnpm --filter @crimeboard/api run deploy:staging",
    "deploy:prod": "pnpm --filter @crimeboard/api run deploy:prod"
  },
  "devDependencies": {
    "typescript": "^5.5.4",
    "wrangler": "^4.0.0"
  }
}
```

- [ ] **Step 3: Write `pnpm-workspace.yaml`**

Create `/Users/kari/Documents/news app/backend/pnpm-workspace.yaml`:

```yaml
packages:
  - "packages/*"
  - "workers/*"
```

- [ ] **Step 4: Write `backend/.gitignore`**

Create `/Users/kari/Documents/news app/backend/.gitignore`:

```gitignore
node_modules/
.wrangler/
.dev.vars
*.tsbuildinfo
dist/
coverage/
```

- [ ] **Step 5: Install root devDependencies**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm install
```

Expected: pnpm creates `node_modules/`, installs `typescript` and `wrangler` at the root. No errors.

- [ ] **Step 6: Verify wrangler version**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm exec wrangler --version
```

Expected: `4.x.y` (any 4.x version is fine).

- [ ] **Step 7: Commit**

Run:
```bash
cd "/Users/kari/Documents/news app" && git add backend/package.json backend/pnpm-workspace.yaml backend/.gitignore && git commit -m "chore(backend): scaffold pnpm monorepo structure"
```

Note: do NOT commit `backend/node_modules/` or `backend/pnpm-lock.yaml` yet — the lockfile is created on install but should be added in a later step once we have real workspace packages installed (next task adds it intentionally).

Actually, do commit the lockfile — pnpm needs it for reproducible installs across machines. Run:

```bash
cd "/Users/kari/Documents/news app" && git add backend/pnpm-lock.yaml && git commit --amend --no-edit
```

Expected: lockfile is now part of the scaffold commit.

---

### Task 3: Configure shared TypeScript settings

**Files:**
- Create: `/Users/kari/Documents/news app/backend/tsconfig.base.json`

A single base TS config that all packages and workers extend. Strict mode, ES2022, NodeNext module resolution (works for Cloudflare Workers, which runs on V8 with ESM).

- [ ] **Step 1: Write `tsconfig.base.json`**

Create `/Users/kari/Documents/news app/backend/tsconfig.base.json`:

```json
{
  "compilerOptions": {
    "target": "es2022",
    "module": "esnext",
    "moduleResolution": "bundler",
    "lib": ["es2022"],
    "types": [],
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "isolatedModules": true,
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "verbatimModuleSyntax": true,
    "noEmit": true
  }
}
```

- [ ] **Step 2: Commit**

Run:
```bash
cd "/Users/kari/Documents/news app" && git add backend/tsconfig.base.json && git commit -m "chore(backend): add base tsconfig with strict settings"
```

---

## Phase 1 — Cloudflare account + dev resources

### Task 4: Cloudflare login + verify account access

**Files:** none — manual setup.

- [ ] **Step 1: Authenticate wrangler**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm exec wrangler login
```

Expected: a browser window opens prompting you to authorize Wrangler. Click "Allow." Terminal prints `Successfully logged in.`

- [ ] **Step 2: Verify account access**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm exec wrangler whoami
```

Expected: prints your Cloudflare account email and an account ID. **Save the account ID** — you'll paste it into `wrangler.toml` later. Example output:

```
👋 You are logged in with an OAuth Token, associated with the email user@example.com
┌──────────────────────────────────────┬──────────────────────────────────────┐
│ Account Name                         │ Account ID                           │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ user@example.com's Account           │ abc123def456...                      │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

If multiple accounts are listed, decide which one to use for THE CRIME BOARD and note its ID.

---

### Task 5: Provision Cloudflare dev resources

**Files:** none — these are wrangler CLI commands. **Save the IDs** Wrangler returns; you'll paste them into `wrangler.toml` in Task 12.

- [ ] **Step 1: Create the dev D1 database**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm exec wrangler d1 create crimeboard-dev
```

Expected output ends with a `[[d1_databases]]` TOML block. Copy the `database_id` value somewhere — you need it for `wrangler.toml`. Example:

```
✅ Successfully created DB 'crimeboard-dev' in region ...

[[d1_databases]]
binding = "DB"
database_name = "crimeboard-dev"
database_id = "11111111-2222-3333-4444-555555555555"
```

- [ ] **Step 2: Create the dev KV namespace**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm exec wrangler kv namespace create crimeboard-cache-dev
```

Expected output ends with a `[[kv_namespaces]]` TOML block. Save the `id` value.

- [ ] **Step 3: Create the dev R2 bucket**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm exec wrangler r2 bucket create crimeboard-archive-dev
```

Expected: `Created bucket crimeboard-archive-dev`. (R2 buckets are referenced by name, not ID.)

- [ ] **Step 4: Create dev queues**

Two queues — one for ingest fan-out, one for deep-check (used in later plans, but cheap to provision now).

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm exec wrangler queues create crimeboard-ingest-dev && pnpm exec wrangler queues create crimeboard-deepcheck-dev
```

Expected: `Created queue crimeboard-ingest-dev.` then `Created queue crimeboard-deepcheck-dev.`

- [ ] **Step 5: Record the dev resource IDs**

Open a scratch file (or note app) and write down, for use in Task 12:

```
ACCOUNT_ID = ...
D1_DATABASE_ID_DEV = ...
KV_NAMESPACE_ID_DEV = ...
```

(R2 bucket and queue names are stable strings — no IDs to record.)

You will not commit these to git anywhere — they're injected via `wrangler.toml` which is committed (these IDs are not secrets, but resource handles).

---

## Phase 2 — D1 schema

### Task 6: Write the initial schema migration

**Files:**
- Create: `/Users/kari/Documents/news app/backend/migrations/0001_initial_schema.sql`

Six tables per the spec data model. SQLite STRICT tables for type enforcement. Foreign keys enforced when `PRAGMA foreign_keys = ON` (Wrangler enables this for D1).

Table order matters for FK constraints: `clusters` is created before `articles` because `articles.cluster_id` references it.

- [ ] **Step 1: Write the schema**

Create `/Users/kari/Documents/news app/backend/migrations/0001_initial_schema.sql`:

```sql
-- 0001_initial_schema.sql
-- Initial schema for THE CRIME BOARD backend.
-- Six tables: outlets, clusters, articles, fact_checks, users, push_subscriptions.
-- All times stored as Unix epoch seconds (INTEGER).
-- All JSON-shaped fields stored as TEXT (D1/SQLite has no JSON type but supports JSON1 functions).
-- Embeddings stored as BLOB (JSON-encoded float arrays per the spec).

CREATE TABLE outlets (
  id                 TEXT    PRIMARY KEY,
  name               TEXT    NOT NULL,
  homepage_url       TEXT    NOT NULL,
  rss_urls           TEXT    NOT NULL DEFAULT '[]',
  logo_url           TEXT,
  bias_score         REAL    NOT NULL,
  reliability_score  REAL    NOT NULL,
  bias_source        TEXT    NOT NULL CHECK (bias_source IN ('allsides', 'adfontes', 'manual')),
  ownership          TEXT,
  funding_model      TEXT,
  wikipedia_url      TEXT
) STRICT;

CREATE TABLE clusters (
  id                  TEXT    PRIMARY KEY,
  created_at          INTEGER NOT NULL,
  updated_at          INTEGER NOT NULL,
  representative_title TEXT   NOT NULL,
  centroid_embedding  BLOB    NOT NULL,
  topic_tags          TEXT    NOT NULL DEFAULT '[]',
  bias_distribution   TEXT    NOT NULL DEFAULT '{}',
  is_breaking         INTEGER NOT NULL DEFAULT 0 CHECK (is_breaking IN (0, 1)),
  article_count       INTEGER NOT NULL DEFAULT 0
) STRICT;

CREATE INDEX idx_clusters_updated_at ON clusters(updated_at);
CREATE INDEX idx_clusters_breaking   ON clusters(is_breaking) WHERE is_breaking = 1;

CREATE TABLE articles (
  id            TEXT    PRIMARY KEY,
  outlet_id     TEXT    NOT NULL REFERENCES outlets(id),
  url           TEXT    NOT NULL UNIQUE,
  title         TEXT    NOT NULL,
  description   TEXT,
  published_at  INTEGER NOT NULL,
  fetched_at    INTEGER NOT NULL,
  embedding     BLOB,
  cluster_id    TEXT             REFERENCES clusters(id),
  topic_tags    TEXT    NOT NULL DEFAULT '[]'
) STRICT;

CREATE INDEX idx_articles_published_at ON articles(published_at);
CREATE INDEX idx_articles_cluster      ON articles(cluster_id);
CREATE INDEX idx_articles_outlet       ON articles(outlet_id);

CREATE TABLE fact_checks (
  id              TEXT    PRIMARY KEY,
  claim_text      TEXT    NOT NULL,
  verdict         TEXT    NOT NULL CHECK (verdict IN ('true', 'mostly-true', 'mixed', 'mostly-false', 'false', 'unverifiable')),
  source          TEXT    NOT NULL,
  evidence_url    TEXT,
  checked_at      INTEGER NOT NULL,
  claim_embedding BLOB
) STRICT;

CREATE INDEX idx_factchecks_checked_at ON fact_checks(checked_at);

CREATE TABLE users (
  id                  TEXT    PRIMARY KEY,
  apple_sub           TEXT    UNIQUE,
  email               TEXT,
  created_at          INTEGER NOT NULL,
  pro_until           INTEGER,
  feed_mode           TEXT    NOT NULL DEFAULT 'strict' CHECK (feed_mode IN ('strict', 'balanced')),
  selected_topics     TEXT    NOT NULL DEFAULT '[]',
  selected_outlets    TEXT    NOT NULL DEFAULT '[]',
  excluded_outlets    TEXT    NOT NULL DEFAULT '[]',
  notification_prefs  TEXT    NOT NULL DEFAULT '{}'
) STRICT;

CREATE INDEX idx_users_apple_sub ON users(apple_sub);

CREATE TABLE push_subscriptions (
  user_id              TEXT    NOT NULL REFERENCES users(id),
  device_token         TEXT    NOT NULL,
  topic_subscriptions  TEXT    NOT NULL DEFAULT '[]',
  last_seen_at         INTEGER NOT NULL,
  PRIMARY KEY (user_id, device_token)
) STRICT;
```

- [ ] **Step 2: Apply migration locally (no remote D1 yet)**

Wrangler migrations require a `wrangler.toml` to know which D1 to target. We don't have one until Task 12 — skip the apply step here. We'll apply in Task 12.

For now, just verify the SQL parses by running it through `sqlite3` if available:

```bash
cd "/Users/kari/Documents/news app/backend" && command -v sqlite3 >/dev/null && sqlite3 :memory: < migrations/0001_initial_schema.sql && echo "SQL parses cleanly" || echo "SKIP: sqlite3 not installed (install with: brew install sqlite — optional)"
```

Expected: either `SQL parses cleanly` or `SKIP: ...`. If the SQL has errors, sqlite3 will print them; fix and re-run.

- [ ] **Step 3: Commit**

Run:
```bash
cd "/Users/kari/Documents/news app" && git add backend/migrations/0001_initial_schema.sql && git commit -m "feat(backend): add initial D1 schema (outlets, clusters, articles, fact_checks, users, push_subscriptions)"
```

---

## Phase 3 — Shared package (auth helpers, types)

### Task 7: Bootstrap shared package

**Files:**
- Create: `/Users/kari/Documents/news app/backend/packages/shared/package.json`
- Create: `/Users/kari/Documents/news app/backend/packages/shared/tsconfig.json`
- Create: `/Users/kari/Documents/news app/backend/packages/shared/src/env.ts`
- Create: `/Users/kari/Documents/news app/backend/packages/shared/src/index.ts`

The `shared` package holds types and pure utilities used by every worker. Starts with the `Env` binding type and a barrel `index.ts`.

- [ ] **Step 1: Write `packages/shared/package.json`**

Create `/Users/kari/Documents/news app/backend/packages/shared/package.json`:

```json
{
  "name": "@crimeboard/shared",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "main": "./src/index.ts",
  "exports": {
    ".": "./src/index.ts"
  },
  "scripts": {
    "typecheck": "tsc --noEmit",
    "test": "vitest run"
  },
  "dependencies": {
    "jose": "^5.9.6",
    "hono": "^4.6.0"
  },
  "devDependencies": {
    "@cloudflare/workers-types": "^4.20250101.0",
    "typescript": "^5.5.4",
    "vitest": "^2.1.0"
  }
}
```

- [ ] **Step 2: Write `packages/shared/tsconfig.json`**

Create `/Users/kari/Documents/news app/backend/packages/shared/tsconfig.json`:

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "types": ["@cloudflare/workers-types"],
    "rootDir": "./src",
    "outDir": "./dist"
  },
  "include": ["src/**/*"]
}
```

- [ ] **Step 3: Write `packages/shared/src/env.ts`**

Create `/Users/kari/Documents/news app/backend/packages/shared/src/env.ts`:

```typescript
// Cloudflare Worker bindings shared across all workers in the monorepo.
// Each worker's wrangler.toml declares the bindings; this type describes them
// so Hono's `c.env` is fully type-safe.

export interface Env {
  // D1 database
  DB: D1Database;

  // KV namespace for hot-data caching
  CACHE: KVNamespace;

  // R2 bucket for archived articles (used by later plans; bound now for parity)
  ARCHIVE: R2Bucket;

  // Queues — bindings are producer-side; consumers live in dedicated workers
  INGEST_QUEUE: Queue<unknown>;
  DEEPCHECK_QUEUE: Queue<unknown>;

  // Workers AI for embeddings + small LLM inference
  AI: Ai;

  // Vars (non-secret config)
  APPLE_AUDIENCE: string; // The iOS app's bundle ID, e.g. "com.bworthy.crimeboard"

  // Secrets (set via `wrangler secret put`)
  SESSION_SECRET: string; // HMAC key for our session tokens
}
```

- [ ] **Step 4: Write `packages/shared/src/index.ts`**

Create `/Users/kari/Documents/news app/backend/packages/shared/src/index.ts`:

```typescript
export type { Env } from "./env.ts";
```

- [ ] **Step 5: Install workspace dependencies**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm install
```

Expected: pnpm installs `jose`, `hono`, `@cloudflare/workers-types`, `vitest` into the workspace. No errors.

- [ ] **Step 6: Verify typecheck passes**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm --filter @crimeboard/shared run typecheck
```

Expected: no output (success). If you see a missing-types error, double-check `tsconfig.json` extends the right base path.

- [ ] **Step 7: Commit**

Run:
```bash
cd "/Users/kari/Documents/news app" && git add backend/packages/shared/ backend/pnpm-lock.yaml && git commit -m "feat(backend): scaffold @crimeboard/shared package with Env binding types"
```

---

### Task 8: Implement HMAC session token mint/verify (TDD)

**Files:**
- Create: `/Users/kari/Documents/news app/backend/packages/shared/src/session.ts`
- Test: `/Users/kari/Documents/news app/backend/packages/shared/src/session.test.ts`

After we verify a user's Apple identity token, we mint our own short-lived session token (HS256 JWT, 30-day expiry) and the iOS app sends it on subsequent requests as `Authorization: Bearer <token>`.

- [ ] **Step 1: Write the failing test**

Create `/Users/kari/Documents/news app/backend/packages/shared/src/session.test.ts`:

```typescript
import { describe, it, expect } from "vitest";
import { mintSessionToken, verifySessionToken } from "./session.ts";

const SECRET = "test-secret-do-not-use-in-prod";

describe("session token", () => {
  it("round-trips a user id", async () => {
    const token = await mintSessionToken({ userId: "user-123", secret: SECRET });
    const claims = await verifySessionToken({ token, secret: SECRET });
    expect(claims.userId).toBe("user-123");
  });

  it("rejects a token signed with a different secret", async () => {
    const token = await mintSessionToken({ userId: "user-123", secret: SECRET });
    await expect(
      verifySessionToken({ token, secret: "wrong-secret" })
    ).rejects.toThrow();
  });

  it("rejects a tampered token", async () => {
    const token = await mintSessionToken({ userId: "user-123", secret: SECRET });
    const tampered = token.slice(0, -2) + "XX";
    await expect(
      verifySessionToken({ token: tampered, secret: SECRET })
    ).rejects.toThrow();
  });

  it("rejects an expired token", async () => {
    const token = await mintSessionToken({
      userId: "user-123",
      secret: SECRET,
      expiresInSeconds: -10, // already expired
    });
    await expect(
      verifySessionToken({ token, secret: SECRET })
    ).rejects.toThrow();
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm --filter @crimeboard/shared run test
```

Expected: **FAIL** — `Cannot find module './session.ts'` or `mintSessionToken is not defined`. This is the expected red state for TDD.

- [ ] **Step 3: Write minimal implementation**

Create `/Users/kari/Documents/news app/backend/packages/shared/src/session.ts`:

```typescript
import { sign, verify } from "hono/jwt";

export interface SessionClaims {
  userId: string;
  iat: number;
  exp: number;
}

export interface MintParams {
  userId: string;
  secret: string;
  /** Token lifetime in seconds. Default: 30 days. Pass a negative value for an already-expired token (testing only). */
  expiresInSeconds?: number;
}

export interface VerifyParams {
  token: string;
  secret: string;
}

const DEFAULT_EXPIRY_SECONDS = 60 * 60 * 24 * 30; // 30 days

export async function mintSessionToken(params: MintParams): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const expiresIn = params.expiresInSeconds ?? DEFAULT_EXPIRY_SECONDS;
  const payload = {
    userId: params.userId,
    iat: now,
    exp: now + expiresIn,
  };
  return sign(payload, params.secret, "HS256");
}

export async function verifySessionToken(params: VerifyParams): Promise<SessionClaims> {
  // hono/jwt's verify throws on invalid signature, malformed token, or expired exp.
  const decoded = (await verify(params.token, params.secret, "HS256")) as SessionClaims;
  if (typeof decoded.userId !== "string" || decoded.userId.length === 0) {
    throw new Error("Session token missing userId claim");
  }
  return decoded;
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm --filter @crimeboard/shared run test
```

Expected: **PASS** — all four tests green.

- [ ] **Step 5: Add a re-export to the barrel**

Edit `/Users/kari/Documents/news app/backend/packages/shared/src/index.ts` to add:

```typescript
export type { Env } from "./env.ts";
export { mintSessionToken, verifySessionToken } from "./session.ts";
export type { SessionClaims, MintParams, VerifyParams } from "./session.ts";
```

- [ ] **Step 6: Re-run typecheck**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm --filter @crimeboard/shared run typecheck
```

Expected: no output (success).

- [ ] **Step 7: Commit**

Run:
```bash
cd "/Users/kari/Documents/news app" && git add backend/packages/shared/src/session.ts backend/packages/shared/src/session.test.ts backend/packages/shared/src/index.ts && git commit -m "feat(shared): HMAC session token mint/verify with hono/jwt"
```

---

### Task 9: Implement Apple JWKS fetch + cache (TDD)

**Files:**
- Create: `/Users/kari/Documents/news app/backend/packages/shared/src/jwks.ts`
- Test: `/Users/kari/Documents/news app/backend/packages/shared/src/jwks.test.ts`

Apple publishes its JWKS (public keys for verifying identity tokens) at `https://appleid.apple.com/auth/keys`. The keys rotate periodically; we cache them in KV for 1 hour to avoid hitting Apple on every auth request.

- [ ] **Step 1: Write the failing test**

Create `/Users/kari/Documents/news app/backend/packages/shared/src/jwks.test.ts`:

```typescript
import { describe, it, expect, vi, beforeEach } from "vitest";
import { fetchAppleJwks } from "./jwks.ts";

const MOCK_JWKS = {
  keys: [
    {
      kty: "RSA",
      kid: "test-key-id",
      use: "sig",
      alg: "RS256",
      n: "mock-modulus",
      e: "AQAB",
    },
  ],
};

function makeKvStub() {
  const store = new Map<string, string>();
  return {
    store,
    kv: {
      get: vi.fn(async (key: string) => store.get(key) ?? null),
      put: vi.fn(async (key: string, value: string, _opts?: unknown) => {
        store.set(key, value);
      }),
    } as unknown as KVNamespace,
  };
}

describe("fetchAppleJwks", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it("returns parsed JWKS on cache miss and stores it in KV", async () => {
    const fetchMock = vi.fn(async () =>
      new Response(JSON.stringify(MOCK_JWKS), { status: 200 })
    );
    vi.stubGlobal("fetch", fetchMock);

    const { kv, store } = makeKvStub();
    const jwks = await fetchAppleJwks(kv);

    expect(jwks).toEqual(MOCK_JWKS);
    expect(fetchMock).toHaveBeenCalledOnce();
    expect(store.get("apple-jwks")).toBe(JSON.stringify(MOCK_JWKS));
  });

  it("returns cached JWKS without calling fetch on cache hit", async () => {
    const fetchMock = vi.fn();
    vi.stubGlobal("fetch", fetchMock);

    const { kv, store } = makeKvStub();
    store.set("apple-jwks", JSON.stringify(MOCK_JWKS));

    const jwks = await fetchAppleJwks(kv);

    expect(jwks).toEqual(MOCK_JWKS);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("throws if Apple returns non-200", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => new Response("oops", { status: 503 }))
    );

    const { kv } = makeKvStub();
    await expect(fetchAppleJwks(kv)).rejects.toThrow(/Apple JWKS/);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm --filter @crimeboard/shared run test
```

Expected: **FAIL** — module not found / `fetchAppleJwks` not defined.

- [ ] **Step 3: Write minimal implementation**

Create `/Users/kari/Documents/news app/backend/packages/shared/src/jwks.ts`:

```typescript
const APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys";
const KV_KEY = "apple-jwks";
const CACHE_TTL_SECONDS = 60 * 60; // 1 hour

export interface AppleJwks {
  keys: Array<{
    kty: string;
    kid: string;
    use: string;
    alg: string;
    n: string;
    e: string;
  }>;
}

/**
 * Fetch Apple's JWKS, caching it in KV for CACHE_TTL_SECONDS.
 * Subsequent calls within the TTL hit the cache and don't network.
 */
export async function fetchAppleJwks(kv: KVNamespace): Promise<AppleJwks> {
  const cached = await kv.get(KV_KEY);
  if (cached !== null) {
    return JSON.parse(cached) as AppleJwks;
  }

  const response = await fetch(APPLE_JWKS_URL);
  if (!response.ok) {
    throw new Error(`Apple JWKS fetch failed: ${response.status} ${response.statusText}`);
  }
  const body = await response.text();
  // Don't await the put — fire-and-forget keeps auth latency minimal.
  // KV's put returns a Promise; in a Worker we'd usually use ctx.waitUntil(),
  // but the caller doesn't have ctx here. Awaiting is fine for a foundation.
  await kv.put(KV_KEY, body, { expirationTtl: CACHE_TTL_SECONDS });
  return JSON.parse(body) as AppleJwks;
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm --filter @crimeboard/shared run test
```

Expected: **PASS** — all three jwks tests + four session tests = 7 green.

- [ ] **Step 5: Re-export**

Edit `/Users/kari/Documents/news app/backend/packages/shared/src/index.ts` to add:

```typescript
export { fetchAppleJwks } from "./jwks.ts";
export type { AppleJwks } from "./jwks.ts";
```

The full file should now read:

```typescript
export type { Env } from "./env.ts";
export { mintSessionToken, verifySessionToken } from "./session.ts";
export type { SessionClaims, MintParams, VerifyParams } from "./session.ts";
export { fetchAppleJwks } from "./jwks.ts";
export type { AppleJwks } from "./jwks.ts";
```

- [ ] **Step 6: Commit**

Run:
```bash
cd "/Users/kari/Documents/news app" && git add backend/packages/shared/src/jwks.ts backend/packages/shared/src/jwks.test.ts backend/packages/shared/src/index.ts && git commit -m "feat(shared): Apple JWKS fetch with KV caching"
```

---

### Task 10: Implement Apple identity token verifier (TDD)

**Files:**
- Create: `/Users/kari/Documents/news app/backend/packages/shared/src/apple.ts`
- Test: `/Users/kari/Documents/news app/backend/packages/shared/src/apple.test.ts`

Verifies an Apple identity token JWT against Apple's JWKS using `jose.jwtVerify`. Returns the validated claims (`sub`, `email` if present, etc.).

- [ ] **Step 1: Write the failing test**

Create `/Users/kari/Documents/news app/backend/packages/shared/src/apple.test.ts`:

```typescript
import { describe, it, expect, beforeAll } from "vitest";
import { generateKeyPair, exportJWK, SignJWT, type KeyLike } from "jose";
import { verifyAppleIdentityToken } from "./apple.ts";

// We generate a keypair at test-time so we can sign tokens that pass real cryptographic verification.
let privateKey: KeyLike;
let publicJwk: { kty: string; n: string; e: string; kid: string; alg: string; use: string };

const AUDIENCE = "com.bworthy.crimeboard";

beforeAll(async () => {
  const { publicKey, privateKey: priv } = await generateKeyPair("RS256", { extractable: true });
  privateKey = priv;
  const jwk = await exportJWK(publicKey);
  publicJwk = {
    kty: "RSA",
    n: jwk.n!,
    e: jwk.e!,
    kid: "test-key-1",
    alg: "RS256",
    use: "sig",
  };
});

async function makeToken(overrides: Partial<{ sub: string; aud: string; iss: string; email: string; expSeconds: number }> = {}) {
  const now = Math.floor(Date.now() / 1000);
  const builder = new SignJWT({ email: overrides.email })
    .setProtectedHeader({ alg: "RS256", kid: "test-key-1" })
    .setIssuer(overrides.iss ?? "https://appleid.apple.com")
    .setAudience(overrides.aud ?? AUDIENCE)
    .setSubject(overrides.sub ?? "001234.abcdef.5678")
    .setIssuedAt(now)
    .setExpirationTime(now + (overrides.expSeconds ?? 600));
  return builder.sign(privateKey);
}

describe("verifyAppleIdentityToken", () => {
  it("returns claims for a valid token", async () => {
    const token = await makeToken({ email: "user@example.com" });
    const claims = await verifyAppleIdentityToken({
      token,
      audience: AUDIENCE,
      jwks: { keys: [publicJwk] },
    });
    expect(claims.sub).toBe("001234.abcdef.5678");
    expect(claims.email).toBe("user@example.com");
  });

  it("rejects a token with the wrong audience", async () => {
    const token = await makeToken({ aud: "com.someoneelse.app" });
    await expect(
      verifyAppleIdentityToken({ token, audience: AUDIENCE, jwks: { keys: [publicJwk] } })
    ).rejects.toThrow();
  });

  it("rejects a token with the wrong issuer", async () => {
    const token = await makeToken({ iss: "https://evil.example.com" });
    await expect(
      verifyAppleIdentityToken({ token, audience: AUDIENCE, jwks: { keys: [publicJwk] } })
    ).rejects.toThrow();
  });

  it("rejects an expired token", async () => {
    const token = await makeToken({ expSeconds: -10 });
    await expect(
      verifyAppleIdentityToken({ token, audience: AUDIENCE, jwks: { keys: [publicJwk] } })
    ).rejects.toThrow();
  });

  it("returns claims when email is absent (Apple omits it after first sign-in)", async () => {
    const token = await makeToken();
    const claims = await verifyAppleIdentityToken({
      token,
      audience: AUDIENCE,
      jwks: { keys: [publicJwk] },
    });
    expect(claims.sub).toBe("001234.abcdef.5678");
    expect(claims.email).toBeUndefined();
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm --filter @crimeboard/shared run test
```

Expected: **FAIL** — `verifyAppleIdentityToken` not defined.

- [ ] **Step 3: Write minimal implementation**

Create `/Users/kari/Documents/news app/backend/packages/shared/src/apple.ts`:

```typescript
import { jwtVerify, importJWK, type JWK } from "jose";
import type { AppleJwks } from "./jwks.ts";

const APPLE_ISSUER = "https://appleid.apple.com";

export interface AppleClaims {
  sub: string;
  email?: string;
  email_verified?: boolean;
  iat: number;
  exp: number;
}

export interface VerifyAppleParams {
  token: string;
  audience: string;
  jwks: AppleJwks;
}

/**
 * Verify an Apple identity token against the supplied JWKS.
 * Throws if signature, issuer, audience, or expiry is invalid.
 */
export async function verifyAppleIdentityToken(params: VerifyAppleParams): Promise<AppleClaims> {
  // Find the right key by kid from the JWT header.
  const { token, audience, jwks } = params;
  const headerSegment = token.split(".")[0];
  if (!headerSegment) {
    throw new Error("Apple token: malformed (no header segment)");
  }
  const header = JSON.parse(atob(headerSegment.replace(/-/g, "+").replace(/_/g, "/"))) as { kid?: string };
  if (!header.kid) {
    throw new Error("Apple token: missing kid in header");
  }
  const jwk = jwks.keys.find((k) => k.kid === header.kid);
  if (!jwk) {
    throw new Error(`Apple token: no key matches kid ${header.kid}`);
  }
  const key = await importJWK(jwk as JWK, "RS256");

  const { payload } = await jwtVerify(token, key, {
    issuer: APPLE_ISSUER,
    audience,
  });

  if (typeof payload.sub !== "string" || payload.sub.length === 0) {
    throw new Error("Apple token: missing sub");
  }

  return {
    sub: payload.sub,
    email: typeof payload.email === "string" ? payload.email : undefined,
    email_verified: typeof payload.email_verified === "boolean" ? payload.email_verified : undefined,
    iat: payload.iat ?? 0,
    exp: payload.exp ?? 0,
  };
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm --filter @crimeboard/shared run test
```

Expected: **PASS** — all 12 tests green (4 session + 3 jwks + 5 apple).

- [ ] **Step 5: Re-export**

Edit `/Users/kari/Documents/news app/backend/packages/shared/src/index.ts`:

```typescript
export type { Env } from "./env.ts";
export { mintSessionToken, verifySessionToken } from "./session.ts";
export type { SessionClaims, MintParams, VerifyParams } from "./session.ts";
export { fetchAppleJwks } from "./jwks.ts";
export type { AppleJwks } from "./jwks.ts";
export { verifyAppleIdentityToken } from "./apple.ts";
export type { AppleClaims, VerifyAppleParams } from "./apple.ts";
```

- [ ] **Step 6: Commit**

Run:
```bash
cd "/Users/kari/Documents/news app" && git add backend/packages/shared/src/apple.ts backend/packages/shared/src/apple.test.ts backend/packages/shared/src/index.ts && git commit -m "feat(shared): Apple identity token verifier with jose"
```

---

## Phase 4 — api-worker

### Task 11: Bootstrap the api worker with hello-world

**Files:**
- Create: `/Users/kari/Documents/news app/backend/workers/api/package.json`
- Create: `/Users/kari/Documents/news app/backend/workers/api/tsconfig.json`
- Create: `/Users/kari/Documents/news app/backend/workers/api/wrangler.toml`
- Create: `/Users/kari/Documents/news app/backend/workers/api/src/index.ts`
- Create: `/Users/kari/Documents/news app/backend/workers/api/src/types.ts`

The minimal worker — Hono router, one health endpoint, all the bindings declared in `wrangler.toml` so we can apply the D1 migration through it.

- [ ] **Step 1: Write `workers/api/package.json`**

Create `/Users/kari/Documents/news app/backend/workers/api/package.json`:

```json
{
  "name": "@crimeboard/api",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "wrangler dev",
    "deploy:dev": "wrangler deploy",
    "deploy:staging": "wrangler deploy --env staging",
    "deploy:prod": "wrangler deploy --env production",
    "typecheck": "tsc --noEmit",
    "test": "vitest run",
    "cf-typegen": "wrangler types"
  },
  "dependencies": {
    "@crimeboard/shared": "workspace:*",
    "hono": "^4.6.0",
    "jose": "^5.9.6"
  },
  "devDependencies": {
    "@cloudflare/vitest-pool-workers": "^0.5.0",
    "@cloudflare/workers-types": "^4.20250101.0",
    "typescript": "^5.5.4",
    "vitest": "^2.1.0",
    "wrangler": "^4.0.0"
  }
}
```

- [ ] **Step 2: Write `workers/api/tsconfig.json`**

Create `/Users/kari/Documents/news app/backend/workers/api/tsconfig.json`:

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "types": ["@cloudflare/workers-types", "./worker-configuration.d.ts"],
    "rootDir": "./src",
    "outDir": "./dist",
    "paths": {
      "@crimeboard/shared": ["../../packages/shared/src/index.ts"]
    }
  },
  "include": ["src/**/*", "test/**/*"]
}
```

- [ ] **Step 3: Write `workers/api/wrangler.toml` for the dev environment**

**Replace the placeholder IDs below with the values you saved in Task 5.**

Create `/Users/kari/Documents/news app/backend/workers/api/wrangler.toml`:

```toml
name = "crimeboard-api"
main = "src/index.ts"
compatibility_date = "2025-01-01"
compatibility_flags = ["nodejs_compat"]

# === Default (dev) environment ===
# Replace ACCOUNT_ID and *_ID values with the IDs Wrangler returned in Task 5.

account_id = "REPLACE_WITH_YOUR_ACCOUNT_ID"

[[d1_databases]]
binding = "DB"
database_name = "crimeboard-dev"
database_id = "REPLACE_WITH_D1_DATABASE_ID_DEV"
migrations_dir = "../../migrations"

[[kv_namespaces]]
binding = "CACHE"
id = "REPLACE_WITH_KV_NAMESPACE_ID_DEV"

[[r2_buckets]]
binding = "ARCHIVE"
bucket_name = "crimeboard-archive-dev"

[[queues.producers]]
binding = "INGEST_QUEUE"
queue = "crimeboard-ingest-dev"

[[queues.producers]]
binding = "DEEPCHECK_QUEUE"
queue = "crimeboard-deepcheck-dev"

[ai]
binding = "AI"

[vars]
APPLE_AUDIENCE = "com.bworthy.crimeboard"
# SESSION_SECRET is set as a secret via `wrangler secret put SESSION_SECRET`.
```

- [ ] **Step 4: Generate Cloudflare types from wrangler.toml**

Run:
```bash
cd "/Users/kari/Documents/news app/backend/workers/api" && pnpm install && pnpm exec wrangler types
```

Expected: `pnpm install` finishes, then `wrangler types` writes a `worker-configuration.d.ts` file containing typed bindings inferred from `wrangler.toml`. (The file will get re-generated as bindings change.)

- [ ] **Step 5: Write `src/types.ts`**

We use `@crimeboard/shared`'s `Env` type as the canonical binding type rather than the auto-generated one — that keeps all workers aligned to the same shape.

Create `/Users/kari/Documents/news app/backend/workers/api/src/types.ts`:

```typescript
import type { Env } from "@crimeboard/shared";

/** Hono variables stashed by middleware. */
export interface Variables {
  userId: string;
}

export type AppBindings = { Bindings: Env; Variables: Variables };
```

- [ ] **Step 6: Write `src/index.ts` with a hello-world health check**

Create `/Users/kari/Documents/news app/backend/workers/api/src/index.ts`:

```typescript
import { Hono } from "hono";
import type { AppBindings } from "./types.ts";

const app = new Hono<AppBindings>();

app.get("/health", (c) => c.json({ ok: true, service: "crimeboard-api" }));

export default app;
```

- [ ] **Step 7: Verify typecheck passes**

Run:
```bash
cd "/Users/kari/Documents/news app/backend/workers/api" && pnpm run typecheck
```

Expected: no output (success).

- [ ] **Step 8: Smoke-test with `wrangler dev` (manual)**

Run in one terminal:
```bash
cd "/Users/kari/Documents/news app/backend/workers/api" && pnpm run dev
```

Expected: Wrangler boots, prints `Ready on http://localhost:8787`.

In another terminal:
```bash
curl -s http://localhost:8787/health
```

Expected response:
```json
{"ok":true,"service":"crimeboard-api"}
```

Stop the dev server with Ctrl+C.

- [ ] **Step 9: Apply the D1 migration locally**

Run:
```bash
cd "/Users/kari/Documents/news app/backend/workers/api" && pnpm exec wrangler d1 migrations apply crimeboard-dev --local
```

Expected: Wrangler reports `Migrations to be applied: 0001_initial_schema.sql`, then `✅ Successfully applied`. The local D1 lives in `.wrangler/state/v3/d1/`.

Verify the tables exist:

```bash
cd "/Users/kari/Documents/news app/backend/workers/api" && pnpm exec wrangler d1 execute crimeboard-dev --local --command "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;"
```

Expected output lists 6 tables: `articles`, `clusters`, `fact_checks`, `outlets`, `push_subscriptions`, `users` (plus the internal `_cf_KV` / `d1_migrations` housekeeping tables).

- [ ] **Step 10: Apply the migration to remote D1**

Run:
```bash
cd "/Users/kari/Documents/news app/backend/workers/api" && pnpm exec wrangler d1 migrations apply crimeboard-dev --remote
```

Expected: same `✅ Successfully applied` confirmation, this time against the cloud-hosted D1.

- [ ] **Step 11: Set the dev SESSION_SECRET**

Generate a strong secret and store it as a Wrangler secret:

```bash
cd "/Users/kari/Documents/news app/backend/workers/api" && openssl rand -base64 48 | pnpm exec wrangler secret put SESSION_SECRET
```

Expected: prompt to confirm; on success, `✨ Success! Uploaded secret SESSION_SECRET`.

- [ ] **Step 12: Commit**

Run:
```bash
cd "/Users/kari/Documents/news app" && git add backend/workers/api/package.json backend/workers/api/tsconfig.json backend/workers/api/wrangler.toml backend/workers/api/src/index.ts backend/workers/api/src/types.ts backend/workers/api/worker-configuration.d.ts backend/pnpm-lock.yaml && git commit -m "feat(api): bootstrap api-worker with Hono and /health endpoint"
```

---

### Task 12: Set up vitest with vitest-pool-workers

**Files:**
- Create: `/Users/kari/Documents/news app/backend/workers/api/vitest.config.ts`
- Create: `/Users/kari/Documents/news app/backend/workers/api/test/env.d.ts`
- Create: `/Users/kari/Documents/news app/backend/workers/api/test/smoke.test.ts`

`@cloudflare/vitest-pool-workers` runs tests inside a real Workers runtime with bindings (D1, KV, etc.) wired up via `wrangler.toml`. We can hit our Hono app with `SELF.fetch()` and assert on real responses.

- [ ] **Step 1: Write the vitest config**

Create `/Users/kari/Documents/news app/backend/workers/api/vitest.config.ts`:

```typescript
import { defineWorkersConfig } from "@cloudflare/vitest-pool-workers/config";

export default defineWorkersConfig({
  test: {
    poolOptions: {
      workers: {
        wrangler: { configPath: "./wrangler.toml" },
        miniflare: {
          // Each test gets a fresh isolated D1; migrations are applied via the
          // `--local` D1 we set up in Task 11. For tests that require a clean
          // schema, we'll re-apply migrations in beforeAll.
          d1Databases: ["DB"],
          kvNamespaces: ["CACHE"],
          r2Buckets: ["ARCHIVE"],
          queueProducers: { INGEST_QUEUE: "crimeboard-ingest-dev", DEEPCHECK_QUEUE: "crimeboard-deepcheck-dev" },
          bindings: {
            APPLE_AUDIENCE: "com.bworthy.crimeboard.test",
            SESSION_SECRET: "test-session-secret-do-not-use-in-prod",
          },
        },
      },
    },
  },
});
```

- [ ] **Step 2: Write the env.d.ts for test types**

Create `/Users/kari/Documents/news app/backend/workers/api/test/env.d.ts`:

```typescript
declare module "cloudflare:test" {
  // Make ProvidedEnv match our shared Env so tests get full type-safety on env bindings.
  // eslint-disable-next-line @typescript-eslint/no-empty-object-type
  interface ProvidedEnv extends import("@crimeboard/shared").Env {}
}
```

- [ ] **Step 3: Write the smoke test**

Create `/Users/kari/Documents/news app/backend/workers/api/test/smoke.test.ts`:

```typescript
import { describe, it, expect } from "vitest";
import { SELF } from "cloudflare:test";

describe("api worker smoke", () => {
  it("GET /health returns 200 + ok payload", async () => {
    const res = await SELF.fetch("http://test/health");
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toEqual({ ok: true, service: "crimeboard-api" });
  });
});
```

- [ ] **Step 4: Install + run**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm install && pnpm --filter @crimeboard/api run test
```

Expected: vitest boots the workers pool, runs the smoke test, prints `1 passed`. If you see a "miniflare" / D1 setup error, double-check that `wrangler d1 migrations apply crimeboard-dev --local` was run in Task 11.

- [ ] **Step 5: Apply migrations to the test D1 (one-time setup helper)**

Add a `pretest` script so the test D1 always has fresh schema. Edit `/Users/kari/Documents/news app/backend/workers/api/package.json` and replace the `"scripts"` block with:

```json
  "scripts": {
    "dev": "wrangler dev",
    "deploy:dev": "wrangler deploy",
    "deploy:staging": "wrangler deploy --env staging",
    "deploy:prod": "wrangler deploy --env production",
    "typecheck": "tsc --noEmit",
    "pretest": "wrangler d1 migrations apply crimeboard-dev --local",
    "test": "vitest run",
    "cf-typegen": "wrangler types"
  },
```

- [ ] **Step 6: Re-run tests**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm --filter @crimeboard/api run test
```

Expected: pretest applies migrations (no-op if already applied), then `1 passed`.

- [ ] **Step 7: Commit**

Run:
```bash
cd "/Users/kari/Documents/news app" && git add backend/workers/api/vitest.config.ts backend/workers/api/test/env.d.ts backend/workers/api/test/smoke.test.ts backend/workers/api/package.json backend/pnpm-lock.yaml && git commit -m "test(api): vitest-pool-workers smoke test against /health"
```

---

### Task 13: Implement session authn middleware (TDD)

**Files:**
- Create: `/Users/kari/Documents/news app/backend/workers/api/src/middleware/authn.ts`
- Test: `/Users/kari/Documents/news app/backend/workers/api/test/authn.test.ts`

Hono middleware that reads `Authorization: Bearer <token>`, verifies it via `verifySessionToken`, stashes `userId` in the Hono context, or returns 401.

- [ ] **Step 1: Write the failing test**

Create `/Users/kari/Documents/news app/backend/workers/api/test/authn.test.ts`:

```typescript
import { describe, it, expect } from "vitest";
import { SELF, env } from "cloudflare:test";
import { Hono } from "hono";
import { mintSessionToken } from "@crimeboard/shared";
import { sessionAuthn } from "../src/middleware/authn.ts";
import type { AppBindings } from "../src/types.ts";

// Mount a tiny test app inside the test that uses the middleware so we don't
// need to wire it into the production router until the next task.
function makeTestApp() {
  const app = new Hono<AppBindings>();
  app.use("/protected/*", sessionAuthn);
  app.get("/protected/whoami", (c) => c.json({ userId: c.get("userId") }));
  return app;
}

describe("sessionAuthn middleware", () => {
  it("returns 401 when Authorization header is missing", async () => {
    const app = makeTestApp();
    const res = await app.request("/protected/whoami", {}, env);
    expect(res.status).toBe(401);
  });

  it("returns 401 when Authorization header is malformed", async () => {
    const app = makeTestApp();
    const res = await app.request(
      "/protected/whoami",
      { headers: { Authorization: "NotBearer xyz" } },
      env
    );
    expect(res.status).toBe(401);
  });

  it("returns 401 when token is invalid", async () => {
    const app = makeTestApp();
    const res = await app.request(
      "/protected/whoami",
      { headers: { Authorization: "Bearer not.a.real.token" } },
      env
    );
    expect(res.status).toBe(401);
  });

  it("attaches userId from a valid token and proceeds", async () => {
    const token = await mintSessionToken({ userId: "user-abc", secret: env.SESSION_SECRET });
    const app = makeTestApp();
    const res = await app.request(
      "/protected/whoami",
      { headers: { Authorization: `Bearer ${token}` } },
      env
    );
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ userId: "user-abc" });
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm --filter @crimeboard/api run test
```

Expected: **FAIL** — `Cannot find module '../src/middleware/authn.ts'`.

- [ ] **Step 3: Write minimal implementation**

Create `/Users/kari/Documents/news app/backend/workers/api/src/middleware/authn.ts`:

```typescript
import type { MiddlewareHandler } from "hono";
import { verifySessionToken } from "@crimeboard/shared";
import type { AppBindings } from "../types.ts";

export const sessionAuthn: MiddlewareHandler<AppBindings> = async (c, next) => {
  const auth = c.req.header("Authorization");
  if (!auth || !auth.startsWith("Bearer ")) {
    return c.json({ error: "unauthorized" }, 401);
  }
  const token = auth.slice("Bearer ".length).trim();
  if (token.length === 0) {
    return c.json({ error: "unauthorized" }, 401);
  }
  try {
    const claims = await verifySessionToken({ token, secret: c.env.SESSION_SECRET });
    c.set("userId", claims.userId);
  } catch {
    return c.json({ error: "unauthorized" }, 401);
  }
  await next();
  return;
};
```

- [ ] **Step 4: Run the test to verify it passes**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm --filter @crimeboard/api run test
```

Expected: **PASS** — 5 tests now (smoke + 4 authn).

- [ ] **Step 5: Commit**

Run:
```bash
cd "/Users/kari/Documents/news app" && git add backend/workers/api/src/middleware/authn.ts backend/workers/api/test/authn.test.ts && git commit -m "feat(api): sessionAuthn middleware verifies Bearer session tokens"
```

---

### Task 14: Implement POST /auth/apple (TDD)

**Files:**
- Create: `/Users/kari/Documents/news app/backend/workers/api/src/routes/auth.ts`
- Test: `/Users/kari/Documents/news app/backend/workers/api/test/auth.test.ts`

Receives `{ identityToken: string }`, verifies against Apple's JWKS, looks up or creates a user keyed by `apple_sub`, returns `{ sessionToken, user }`.

The test mocks the Apple JWKS fetch by stuffing a controlled JWKS into KV before the request runs (so `fetchAppleJwks` returns it from cache without networking) and signs tokens with a corresponding test private key.

- [ ] **Step 1: Write the failing test**

Create `/Users/kari/Documents/news app/backend/workers/api/test/auth.test.ts`:

```typescript
import { describe, it, expect, beforeAll, beforeEach } from "vitest";
import { SELF, env } from "cloudflare:test";
import { generateKeyPair, exportJWK, SignJWT, type KeyLike } from "jose";

let privateKey: KeyLike;
let publicJwk: { kty: string; n: string; e: string; kid: string; alg: string; use: string };

beforeAll(async () => {
  const { publicKey, privateKey: priv } = await generateKeyPair("RS256", { extractable: true });
  privateKey = priv;
  const jwk = await exportJWK(publicKey);
  publicJwk = {
    kty: "RSA",
    n: jwk.n!,
    e: jwk.e!,
    kid: "test-key-1",
    alg: "RS256",
    use: "sig",
  };
});

beforeEach(async () => {
  // Pre-seed KV with our test JWKS so fetchAppleJwks hits cache and never networks.
  await env.CACHE.put("apple-jwks", JSON.stringify({ keys: [publicJwk] }));
  // Clear users between tests for isolation.
  await env.DB.exec("DELETE FROM users;");
});

async function makeAppleToken(sub: string, email: string | null = null): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const builder = new SignJWT({ ...(email ? { email } : {}) })
    .setProtectedHeader({ alg: "RS256", kid: "test-key-1" })
    .setIssuer("https://appleid.apple.com")
    .setAudience(env.APPLE_AUDIENCE)
    .setSubject(sub)
    .setIssuedAt(now)
    .setExpirationTime(now + 600);
  return builder.sign(privateKey);
}

describe("POST /auth/apple", () => {
  it("creates a new user on first sign-in and returns a session token", async () => {
    const identityToken = await makeAppleToken("001234.abcdef.5678", "user@example.com");
    const res = await SELF.fetch("http://test/auth/apple", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ identityToken }),
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { sessionToken: string; user: { id: string; email: string | null } };
    expect(body.sessionToken).toMatch(/^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/);
    expect(body.user.email).toBe("user@example.com");

    const row = await env.DB.prepare("SELECT id, apple_sub, email FROM users WHERE apple_sub = ?")
      .bind("001234.abcdef.5678")
      .first();
    expect(row).toBeTruthy();
    expect(row!.email).toBe("user@example.com");
  });

  it("reuses the existing user on subsequent sign-ins (no duplicate row)", async () => {
    const t1 = await makeAppleToken("001234.abcdef.5678", "user@example.com");
    await SELF.fetch("http://test/auth/apple", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ identityToken: t1 }),
    });
    // Apple omits email on subsequent sign-ins — verify we don't overwrite it with null.
    const t2 = await makeAppleToken("001234.abcdef.5678", null);
    const res = await SELF.fetch("http://test/auth/apple", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ identityToken: t2 }),
    });
    expect(res.status).toBe(200);

    const rows = await env.DB.prepare("SELECT id, email FROM users WHERE apple_sub = ?")
      .bind("001234.abcdef.5678")
      .all();
    expect(rows.results.length).toBe(1);
    expect(rows.results[0]!.email).toBe("user@example.com");
  });

  it("returns 400 when body is missing identityToken", async () => {
    const res = await SELF.fetch("http://test/auth/apple", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({}),
    });
    expect(res.status).toBe(400);
  });

  it("returns 401 when identityToken is invalid", async () => {
    const res = await SELF.fetch("http://test/auth/apple", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ identityToken: "not.a.real.token" }),
    });
    expect(res.status).toBe(401);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm --filter @crimeboard/api run test
```

Expected: **FAIL** — `/auth/apple` 404s (not yet routed). The new file path also fails to import.

- [ ] **Step 3: Write minimal implementation**

Create `/Users/kari/Documents/news app/backend/workers/api/src/routes/auth.ts`:

```typescript
import { Hono } from "hono";
import {
  fetchAppleJwks,
  verifyAppleIdentityToken,
  mintSessionToken,
} from "@crimeboard/shared";
import type { AppBindings } from "../types.ts";

const auth = new Hono<AppBindings>();

interface AuthAppleBody {
  identityToken?: unknown;
}

interface UserRow {
  id: string;
  apple_sub: string;
  email: string | null;
  created_at: number;
  pro_until: number | null;
  feed_mode: "strict" | "balanced";
}

auth.post("/apple", async (c) => {
  const body = (await c.req.json().catch(() => ({}))) as AuthAppleBody;
  if (typeof body.identityToken !== "string" || body.identityToken.length === 0) {
    return c.json({ error: "missing identityToken" }, 400);
  }

  const jwks = await fetchAppleJwks(c.env.CACHE);
  let claims;
  try {
    claims = await verifyAppleIdentityToken({
      token: body.identityToken,
      audience: c.env.APPLE_AUDIENCE,
      jwks,
    });
  } catch {
    return c.json({ error: "invalid identity token" }, 401);
  }

  // Upsert: keep an existing user's email if Apple omits it on this sign-in.
  const now = Math.floor(Date.now() / 1000);
  const existing = await c.env.DB.prepare(
    "SELECT id, apple_sub, email, created_at, pro_until, feed_mode FROM users WHERE apple_sub = ?"
  )
    .bind(claims.sub)
    .first<UserRow>();

  let user: UserRow;
  if (existing) {
    // Only update email if Apple gave us a new one (i.e. don't overwrite to NULL).
    if (claims.email && claims.email !== existing.email) {
      await c.env.DB.prepare("UPDATE users SET email = ? WHERE id = ?")
        .bind(claims.email, existing.id)
        .run();
      existing.email = claims.email;
    }
    user = existing;
  } else {
    const id = crypto.randomUUID();
    await c.env.DB.prepare(
      "INSERT INTO users (id, apple_sub, email, created_at) VALUES (?, ?, ?, ?)"
    )
      .bind(id, claims.sub, claims.email ?? null, now)
      .run();
    user = {
      id,
      apple_sub: claims.sub,
      email: claims.email ?? null,
      created_at: now,
      pro_until: null,
      feed_mode: "strict",
    };
  }

  const sessionToken = await mintSessionToken({ userId: user.id, secret: c.env.SESSION_SECRET });

  return c.json({
    sessionToken,
    user: {
      id: user.id,
      email: user.email,
      created_at: user.created_at,
      pro_until: user.pro_until,
      feed_mode: user.feed_mode,
    },
  });
});

export default auth;
```

- [ ] **Step 4: Wire `/auth` into the router**

Edit `/Users/kari/Documents/news app/backend/workers/api/src/index.ts`:

```typescript
import { Hono } from "hono";
import auth from "./routes/auth.ts";
import type { AppBindings } from "./types.ts";

const app = new Hono<AppBindings>();

app.get("/health", (c) => c.json({ ok: true, service: "crimeboard-api" }));

app.route("/auth", auth);

export default app;
```

- [ ] **Step 5: Run the test to verify it passes**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm --filter @crimeboard/api run test
```

Expected: **PASS** — 9 tests now (1 smoke + 4 authn + 4 auth/apple).

- [ ] **Step 6: Commit**

Run:
```bash
cd "/Users/kari/Documents/news app" && git add backend/workers/api/src/routes/auth.ts backend/workers/api/src/index.ts backend/workers/api/test/auth.test.ts && git commit -m "feat(api): POST /auth/apple verifies identity token, upserts user, mints session"
```

---

### Task 15: Implement GET /me and PATCH /me (TDD)

**Files:**
- Create: `/Users/kari/Documents/news app/backend/workers/api/src/routes/me.ts`
- Test: `/Users/kari/Documents/news app/backend/workers/api/test/me.test.ts`
- Modify: `/Users/kari/Documents/news app/backend/workers/api/src/index.ts`

`GET /me` returns the current user's prefs. `PATCH /me` lets the iOS app update `feed_mode`, `selected_topics`, `selected_outlets`, `excluded_outlets`, `notification_prefs`. Both require auth.

- [ ] **Step 1: Write the failing test**

Create `/Users/kari/Documents/news app/backend/workers/api/test/me.test.ts`:

```typescript
import { describe, it, expect, beforeEach } from "vitest";
import { SELF, env } from "cloudflare:test";
import { mintSessionToken } from "@crimeboard/shared";

const NOW = 1_700_000_000;

beforeEach(async () => {
  await env.DB.exec("DELETE FROM users;");
  await env.DB.prepare(
    "INSERT INTO users (id, apple_sub, email, created_at, feed_mode, selected_topics, selected_outlets, excluded_outlets, notification_prefs) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
  )
    .bind(
      "user-1",
      "001234.abcdef",
      "user@example.com",
      NOW,
      "strict",
      JSON.stringify(["politics"]),
      JSON.stringify(["nytimes"]),
      JSON.stringify([]),
      JSON.stringify({ breaking: true })
    )
    .run();
});

async function authHeader(userId: string): Promise<string> {
  const token = await mintSessionToken({ userId, secret: env.SESSION_SECRET });
  return `Bearer ${token}`;
}

describe("GET /me", () => {
  it("returns the authenticated user's record", async () => {
    const res = await SELF.fetch("http://test/me", {
      headers: { Authorization: await authHeader("user-1") },
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as Record<string, unknown>;
    expect(body.id).toBe("user-1");
    expect(body.email).toBe("user@example.com");
    expect(body.feed_mode).toBe("strict");
    expect(body.selected_topics).toEqual(["politics"]);
    expect(body.selected_outlets).toEqual(["nytimes"]);
    expect(body.notification_prefs).toEqual({ breaking: true });
  });

  it("returns 401 without auth", async () => {
    const res = await SELF.fetch("http://test/me");
    expect(res.status).toBe(401);
  });

  it("returns 404 if the user row was deleted between auth and lookup", async () => {
    const auth = await authHeader("user-1");
    await env.DB.exec("DELETE FROM users;");
    const res = await SELF.fetch("http://test/me", { headers: { Authorization: auth } });
    expect(res.status).toBe(404);
  });
});

describe("PATCH /me", () => {
  it("updates feed_mode and selected_topics, leaves others untouched", async () => {
    const res = await SELF.fetch("http://test/me", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: await authHeader("user-1"),
      },
      body: JSON.stringify({
        feed_mode: "balanced",
        selected_topics: ["politics", "tech"],
      }),
    });
    expect(res.status).toBe(200);

    const row = await env.DB.prepare("SELECT feed_mode, selected_topics, selected_outlets FROM users WHERE id = ?")
      .bind("user-1")
      .first<{ feed_mode: string; selected_topics: string; selected_outlets: string }>();
    expect(row?.feed_mode).toBe("balanced");
    expect(JSON.parse(row!.selected_topics)).toEqual(["politics", "tech"]);
    expect(JSON.parse(row!.selected_outlets)).toEqual(["nytimes"]); // unchanged
  });

  it("rejects feed_mode outside the allowed values", async () => {
    const res = await SELF.fetch("http://test/me", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: await authHeader("user-1"),
      },
      body: JSON.stringify({ feed_mode: "wild" }),
    });
    expect(res.status).toBe(400);
  });

  it("rejects non-array selected_topics", async () => {
    const res = await SELF.fetch("http://test/me", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: await authHeader("user-1"),
      },
      body: JSON.stringify({ selected_topics: "politics" }),
    });
    expect(res.status).toBe(400);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm --filter @crimeboard/api run test
```

Expected: **FAIL** — `/me` 404s.

- [ ] **Step 3: Write minimal implementation**

Create `/Users/kari/Documents/news app/backend/workers/api/src/routes/me.ts`:

```typescript
import { Hono } from "hono";
import { sessionAuthn } from "../middleware/authn.ts";
import type { AppBindings } from "../types.ts";

const me = new Hono<AppBindings>();

interface UserRow {
  id: string;
  email: string | null;
  created_at: number;
  pro_until: number | null;
  feed_mode: "strict" | "balanced";
  selected_topics: string;
  selected_outlets: string;
  excluded_outlets: string;
  notification_prefs: string;
}

function rowToPublic(row: UserRow) {
  return {
    id: row.id,
    email: row.email,
    created_at: row.created_at,
    pro_until: row.pro_until,
    feed_mode: row.feed_mode,
    selected_topics: JSON.parse(row.selected_topics) as string[],
    selected_outlets: JSON.parse(row.selected_outlets) as string[],
    excluded_outlets: JSON.parse(row.excluded_outlets) as string[],
    notification_prefs: JSON.parse(row.notification_prefs) as Record<string, unknown>,
  };
}

me.use("*", sessionAuthn);

me.get("/", async (c) => {
  const row = await c.env.DB.prepare(
    "SELECT id, email, created_at, pro_until, feed_mode, selected_topics, selected_outlets, excluded_outlets, notification_prefs FROM users WHERE id = ?"
  )
    .bind(c.get("userId"))
    .first<UserRow>();
  if (!row) return c.json({ error: "user not found" }, 404);
  return c.json(rowToPublic(row));
});

interface PatchBody {
  feed_mode?: unknown;
  selected_topics?: unknown;
  selected_outlets?: unknown;
  excluded_outlets?: unknown;
  notification_prefs?: unknown;
}

function isStringArray(v: unknown): v is string[] {
  return Array.isArray(v) && v.every((x) => typeof x === "string");
}

me.patch("/", async (c) => {
  const body = (await c.req.json().catch(() => ({}))) as PatchBody;

  const updates: string[] = [];
  const binds: unknown[] = [];

  if (body.feed_mode !== undefined) {
    if (body.feed_mode !== "strict" && body.feed_mode !== "balanced") {
      return c.json({ error: "feed_mode must be 'strict' or 'balanced'" }, 400);
    }
    updates.push("feed_mode = ?");
    binds.push(body.feed_mode);
  }
  if (body.selected_topics !== undefined) {
    if (!isStringArray(body.selected_topics)) {
      return c.json({ error: "selected_topics must be a string array" }, 400);
    }
    updates.push("selected_topics = ?");
    binds.push(JSON.stringify(body.selected_topics));
  }
  if (body.selected_outlets !== undefined) {
    if (!isStringArray(body.selected_outlets)) {
      return c.json({ error: "selected_outlets must be a string array" }, 400);
    }
    updates.push("selected_outlets = ?");
    binds.push(JSON.stringify(body.selected_outlets));
  }
  if (body.excluded_outlets !== undefined) {
    if (!isStringArray(body.excluded_outlets)) {
      return c.json({ error: "excluded_outlets must be a string array" }, 400);
    }
    updates.push("excluded_outlets = ?");
    binds.push(JSON.stringify(body.excluded_outlets));
  }
  if (body.notification_prefs !== undefined) {
    if (typeof body.notification_prefs !== "object" || body.notification_prefs === null || Array.isArray(body.notification_prefs)) {
      return c.json({ error: "notification_prefs must be an object" }, 400);
    }
    updates.push("notification_prefs = ?");
    binds.push(JSON.stringify(body.notification_prefs));
  }

  if (updates.length === 0) {
    return c.json({ error: "no fields to update" }, 400);
  }

  binds.push(c.get("userId"));
  await c.env.DB.prepare(`UPDATE users SET ${updates.join(", ")} WHERE id = ?`)
    .bind(...binds)
    .run();

  const row = await c.env.DB.prepare(
    "SELECT id, email, created_at, pro_until, feed_mode, selected_topics, selected_outlets, excluded_outlets, notification_prefs FROM users WHERE id = ?"
  )
    .bind(c.get("userId"))
    .first<UserRow>();
  if (!row) return c.json({ error: "user not found" }, 404);
  return c.json(rowToPublic(row));
});

export default me;
```

- [ ] **Step 4: Wire `/me` into the router**

Edit `/Users/kari/Documents/news app/backend/workers/api/src/index.ts`:

```typescript
import { Hono } from "hono";
import auth from "./routes/auth.ts";
import me from "./routes/me.ts";
import type { AppBindings } from "./types.ts";

const app = new Hono<AppBindings>();

app.get("/health", (c) => c.json({ ok: true, service: "crimeboard-api" }));

app.route("/auth", auth);
app.route("/me", me);

export default app;
```

- [ ] **Step 5: Run the test to verify it passes**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm --filter @crimeboard/api run test
```

Expected: **PASS** — 14 tests now (1 smoke + 4 authn + 4 auth/apple + 5 me).

- [ ] **Step 6: Commit**

Run:
```bash
cd "/Users/kari/Documents/news app" && git add backend/workers/api/src/routes/me.ts backend/workers/api/test/me.test.ts backend/workers/api/src/index.ts && git commit -m "feat(api): GET / PATCH /me for user prefs (auth-gated)"
```

---

### Task 16: Verify the full auth flow end-to-end against the dev environment

**Files:** none — manual verification.

This is a smoke check that the deployed dev worker actually works. It catches issues that local tests miss (real D1, real KV, real APNs JWKS, real Cloudflare runtime).

- [ ] **Step 1: Re-deploy with the latest code**

Run:
```bash
cd "/Users/kari/Documents/news app/backend/workers/api" && pnpm exec wrangler deploy
```

Expected: deploy succeeds, prints the worker's public URL (e.g. `https://crimeboard-api.<your-subdomain>.workers.dev`). **Save the URL** — you'll need it.

- [ ] **Step 2: Hit /health on the live worker**

Run (substitute your URL):
```bash
curl -s https://crimeboard-api.<your-subdomain>.workers.dev/health
```

Expected: `{"ok":true,"service":"crimeboard-api"}`

- [ ] **Step 3: Hit /me without auth (should 401)**

Run:
```bash
curl -s -o /dev/null -w "%{http_code}\n" https://crimeboard-api.<your-subdomain>.workers.dev/me
```

Expected: `401`

- [ ] **Step 4: Hit /auth/apple with a clearly invalid token (should 401)**

Run:
```bash
curl -s -o /dev/null -w "%{http_code}\n" -X POST -H "Content-Type: application/json" -d '{"identityToken":"not.a.real.token"}' https://crimeboard-api.<your-subdomain>.workers.dev/auth/apple
```

Expected: `401`

(Full sign-in flow can't be tested via curl — it requires a real Apple identity token from a Sign-in-with-Apple flow. That happens once the iOS app is built. For now, the negative paths confirm the worker is correctly wired.)

---

## Phase 5 — Staging + production environments

### Task 17: Provision staging + production resources and configure environments

**Files:**
- Modify: `/Users/kari/Documents/news app/backend/workers/api/wrangler.toml`

We don't deploy to prod yet (no users to serve), but we provision the resources now so the env config is locked in and can't drift.

- [ ] **Step 1: Provision staging resources**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm exec wrangler d1 create crimeboard-staging && pnpm exec wrangler kv namespace create crimeboard-cache-staging && pnpm exec wrangler r2 bucket create crimeboard-archive-staging && pnpm exec wrangler queues create crimeboard-ingest-staging && pnpm exec wrangler queues create crimeboard-deepcheck-staging
```

Expected: each create command succeeds. **Save the D1 ID and KV ID** for staging.

- [ ] **Step 2: Provision production resources**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm exec wrangler d1 create crimeboard-prod && pnpm exec wrangler kv namespace create crimeboard-cache-prod && pnpm exec wrangler r2 bucket create crimeboard-archive-prod && pnpm exec wrangler queues create crimeboard-ingest-prod && pnpm exec wrangler queues create crimeboard-deepcheck-prod
```

Expected: each create command succeeds. **Save the D1 ID and KV ID** for prod.

- [ ] **Step 3: Add staging + production environments to wrangler.toml**

Edit `/Users/kari/Documents/news app/backend/workers/api/wrangler.toml` to append (replace placeholders with the IDs you just saved):

```toml

# === Staging environment ===
# Deploy with: pnpm run deploy:staging

[env.staging]
name = "crimeboard-api-staging"

[[env.staging.d1_databases]]
binding = "DB"
database_name = "crimeboard-staging"
database_id = "REPLACE_WITH_D1_DATABASE_ID_STAGING"
migrations_dir = "../../migrations"

[[env.staging.kv_namespaces]]
binding = "CACHE"
id = "REPLACE_WITH_KV_NAMESPACE_ID_STAGING"

[[env.staging.r2_buckets]]
binding = "ARCHIVE"
bucket_name = "crimeboard-archive-staging"

[[env.staging.queues.producers]]
binding = "INGEST_QUEUE"
queue = "crimeboard-ingest-staging"

[[env.staging.queues.producers]]
binding = "DEEPCHECK_QUEUE"
queue = "crimeboard-deepcheck-staging"

[env.staging.ai]
binding = "AI"

[env.staging.vars]
APPLE_AUDIENCE = "com.bworthy.crimeboard"

# === Production environment ===
# Deploy with: pnpm run deploy:prod

[env.production]
name = "crimeboard-api-prod"

[[env.production.d1_databases]]
binding = "DB"
database_name = "crimeboard-prod"
database_id = "REPLACE_WITH_D1_DATABASE_ID_PROD"
migrations_dir = "../../migrations"

[[env.production.kv_namespaces]]
binding = "CACHE"
id = "REPLACE_WITH_KV_NAMESPACE_ID_PROD"

[[env.production.r2_buckets]]
binding = "ARCHIVE"
bucket_name = "crimeboard-archive-prod"

[[env.production.queues.producers]]
binding = "INGEST_QUEUE"
queue = "crimeboard-ingest-prod"

[[env.production.queues.producers]]
binding = "DEEPCHECK_QUEUE"
queue = "crimeboard-deepcheck-prod"

[env.production.ai]
binding = "AI"

[env.production.vars]
APPLE_AUDIENCE = "com.bworthy.crimeboard"
```

- [ ] **Step 4: Set staging + production secrets**

Run for staging:
```bash
cd "/Users/kari/Documents/news app/backend/workers/api" && openssl rand -base64 48 | pnpm exec wrangler secret put SESSION_SECRET --env staging
```

Then for production:
```bash
cd "/Users/kari/Documents/news app/backend/workers/api" && openssl rand -base64 48 | pnpm exec wrangler secret put SESSION_SECRET --env production
```

Expected: each prints `✨ Success! Uploaded secret SESSION_SECRET`. (Use a *different* secret for each environment — never reuse.)

- [ ] **Step 5: Apply migrations to staging + production D1**

Run:
```bash
cd "/Users/kari/Documents/news app/backend/workers/api" && pnpm exec wrangler d1 migrations apply crimeboard-staging --remote && pnpm exec wrangler d1 migrations apply crimeboard-prod --remote
```

Expected: both migrations succeed.

- [ ] **Step 6: Deploy to staging**

Run:
```bash
cd "/Users/kari/Documents/news app/backend" && pnpm run deploy:staging
```

Expected: deploy succeeds, prints staging worker URL.

- [ ] **Step 7: Smoke-test staging**

Run (substitute your staging URL):
```bash
curl -s https://crimeboard-api-staging.<your-subdomain>.workers.dev/health
```

Expected: `{"ok":true,"service":"crimeboard-api"}`

- [ ] **Step 8: Commit**

Run:
```bash
cd "/Users/kari/Documents/news app" && git add backend/workers/api/wrangler.toml && git commit -m "feat(api): add staging and production environments to wrangler.toml"
```

---

## Phase 6 — Documentation

### Task 18: Backend README with operating instructions

**Files:**
- Create: `/Users/kari/Documents/news app/backend/README.md`

A short README so the engineer (or a future you) can come back in 6 months and remember how to operate this thing.

- [ ] **Step 1: Write the README**

Create `/Users/kari/Documents/news app/backend/README.md`:

````markdown
# THE CRIME BOARD — Backend

Cloudflare Workers backend monorepo. See `/PRODUCT.md` and `/DESIGN.md` at project root for product/visual context, and `/docs/superpowers/specs/2026-05-02-news-app-design.md` for the technical spec.

## Layout

```
backend/
├── migrations/           D1 schema migrations
├── packages/
│   └── shared/           Shared types + auth helpers (@crimeboard/shared)
└── workers/
    └── api/              The user-facing REST API (@crimeboard/api)
```

Future workers (`ingest`, `cluster-builder`, `deep-check`, `push`, `factcheck-sync`) land in `workers/` as separate packages.

## Prerequisites

- Node 20+
- pnpm 9+
- A Cloudflare account, with `wrangler login` already run

## Daily development

```bash
cd backend
pnpm install                            # one-time, after pulling changes
pnpm --filter @crimeboard/api run dev   # local dev server on :8787
pnpm test                               # all packages, all workers
pnpm typecheck                          # type-check everything
```

## Deploy

```bash
pnpm run deploy:dev        # → crimeboard-api.<subdomain>.workers.dev
pnpm run deploy:staging    # → crimeboard-api-staging.<subdomain>.workers.dev
pnpm run deploy:prod       # → crimeboard-api-prod.<subdomain>.workers.dev
```

Production deploy is intentionally manual — there is no CI/CD configured in this foundation plan. (Add a separate ops plan when ready.)

## D1 migrations

Add a new migration file under `migrations/` (number sequentially):

```bash
# Example
echo "ALTER TABLE outlets ADD COLUMN nickname TEXT;" > migrations/0002_outlet_nickname.sql
```

Then apply:

```bash
cd workers/api
pnpm exec wrangler d1 migrations apply crimeboard-dev --local      # local first
pnpm exec wrangler d1 migrations apply crimeboard-dev --remote     # then dev
pnpm exec wrangler d1 migrations apply crimeboard-staging --remote # then staging
pnpm exec wrangler d1 migrations apply crimeboard-prod --remote    # then prod
```

## Secrets

Set per-environment secrets via `wrangler secret put`:

```bash
cd workers/api
openssl rand -base64 48 | pnpm exec wrangler secret put SESSION_SECRET                # dev
openssl rand -base64 48 | pnpm exec wrangler secret put SESSION_SECRET --env staging  # staging
openssl rand -base64 48 | pnpm exec wrangler secret put SESSION_SECRET --env production # prod
```

Use a different secret per environment. Never commit secrets.

## Environments

| Env | D1 | KV | R2 | Queues | Worker URL |
|---|---|---|---|---|---|
| dev | `crimeboard-dev` | `crimeboard-cache-dev` | `crimeboard-archive-dev` | `crimeboard-{ingest,deepcheck}-dev` | `crimeboard-api.<subdomain>.workers.dev` |
| staging | `crimeboard-staging` | `crimeboard-cache-staging` | `crimeboard-archive-staging` | `crimeboard-{ingest,deepcheck}-staging` | `crimeboard-api-staging.<subdomain>.workers.dev` |
| production | `crimeboard-prod` | `crimeboard-cache-prod` | `crimeboard-archive-prod` | `crimeboard-{ingest,deepcheck}-prod` | `crimeboard-api-prod.<subdomain>.workers.dev` |

## Endpoints (current)

- `GET /health` — public, returns `{ ok, service }`
- `POST /auth/apple` — public, body `{ identityToken }` → `{ sessionToken, user }`
- `GET /me` — auth-gated, returns user record
- `PATCH /me` — auth-gated, body partial-update of user prefs

(More endpoints are added in subsequent plans.)

## Testing

```bash
cd backend
pnpm test
```

Tests run inside a real Workers runtime via `@cloudflare/vitest-pool-workers`. Each test file gets fresh D1 / KV per the vitest config.

The `pretest` hook on `@crimeboard/api` re-applies D1 migrations to the local test DB before each run.
````

- [ ] **Step 2: Commit**

Run:
```bash
cd "/Users/kari/Documents/news app" && git add backend/README.md && git commit -m "docs(backend): operating README with dev / deploy / migrations / secrets"
```

---

## Self-Review

Run through this checklist before declaring the plan complete on execution:

### Spec coverage check

| Spec requirement | Implemented in |
|---|---|
| Cloudflare backend (Workers, D1, KV, R2, Queues, Workers AI) | Tasks 5, 7, 11, 17 |
| D1 schema for 6 tables (outlets, clusters, articles, fact_checks, users, push_subscriptions) | Task 6 |
| Sign in with Apple JWT verification | Tasks 9, 10 |
| Session token mint/verify (HS256) | Task 8 |
| `POST /auth/apple` endpoint (verify identity token, upsert user, return session) | Task 14 |
| `GET /me` and `PATCH /me` endpoints | Task 15 |
| Auth middleware (Bearer session token) | Task 13 |
| Three environments (dev / staging / prod) | Tasks 5, 11, 17 |
| Vitest with `@cloudflare/vitest-pool-workers`, hits real D1 | Task 12 |
| `nodejs_compat` flag enabled (jose needs it for some operations) | Task 11 |
| 30-day session expiry | Task 8 |
| Apple JWKS cached in KV (1 hour TTL) | Task 9 |

Things in the spec deferred to later plans (intentional, not gaps):
- RSS ingestion + clustering (plan #3)
- Full read-API endpoints `/feed`, `/clusters/:id`, `/articles/:id`, `/factchecks/lookup`, `/outlets`, `/reports` (plan #4)
- Deep Check service + queue worker (plan #9)
- Push notifications + APNs (plan #14)
- Bias data refresh script (plan #5)

### Placeholder scan

Searched for "TBD", "TODO", "implement later", "appropriate error handling", "similar to Task N" — none found.

The only `REPLACE_WITH_*` strings are in `wrangler.toml` (account ID, D1 IDs, KV IDs from Task 5/17) where the engineer must paste real values they obtain from Wrangler. These are explicitly called out at the step that shows them.

### Type consistency

- `Env` type defined once in `packages/shared/src/env.ts` and imported everywhere via `@crimeboard/shared`. ✓
- `AppBindings` (`{ Bindings: Env; Variables: Variables }`) used consistently in api worker. ✓
- `mintSessionToken` / `verifySessionToken` parameter shapes match between session.ts, the authn middleware test, the auth route test, and the me route test. ✓
- `verifyAppleIdentityToken` signature matches between apple.ts, the apple test, and the auth route. ✓
- `UserRow` type is defined per-route (auth.ts and me.ts) — minor duplication but each is locally scoped. Acceptable for now; if a third route adds it, promote to `shared`.

---

## Done criteria

This plan is complete when:

- [ ] All 18 tasks above are checked off and committed
- [ ] `cd backend && pnpm test` passes (14 tests across smoke, authn, auth, me)
- [ ] `cd backend && pnpm typecheck` is clean
- [ ] `curl https://crimeboard-api.<subdomain>.workers.dev/health` returns 200 + ok payload
- [ ] `curl https://crimeboard-api-staging.<subdomain>.workers.dev/health` returns 200 + ok payload
- [ ] `wrangler d1 migrations apply` has been run against dev / staging / prod (verified in Tasks 11, 17)
- [ ] `SESSION_SECRET` is set in dev, staging, and prod (different value each)
- [ ] D1, KV, R2, Queues exist in dev, staging, prod
- [ ] `backend/README.md` documents how to develop, deploy, and operate the worker

The next plan to write after this one is **#3 (News ingestion + clustering pipeline)** or **#2 (iOS app foundation + DesignSystem)** — they don't share files and can be built in parallel.
