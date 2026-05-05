# Receipts Pipeline Skeleton — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the backend receipt pipeline plumbing for For Real?? — `receipts` and `claims` tables in D1, REST endpoints (`POST/GET/DELETE /v1/receipts`, `GET /v1/receipts/:id/stream` SSE), URL classification + cache, anonymous-device daily quota — all driven by a stubbed analyzer that emits fake claim events on a configurable delay. Real LLM, transcription, and scraping land in Plans 2–4 against this exact API.

**Architecture:** All routes added to the existing `workers/api` (Hono) worker. The stubbed analyzer runs inline inside the SSE handler — no new worker, no Durable Objects, no Queues yet. URL caching is by `url_hash = sha256(normalize(url))` and is global (a hit on any device returns the cached receipt). SSE uses Hono's `streamSSE`. New migration `0002_receipts_and_claims.sql` adds two tables; no schema changes to existing tables.

**Tech stack:** Cloudflare Workers, Hono 4.6, vitest 2.1 + `@cloudflare/vitest-pool-workers`, D1, TypeScript 5.5, pnpm 9. macOS / zsh.

**Skill applicability:** This is a backend-only plan — no UI, no copy, no visual decisions. The `impeccable` skill does not apply. iOS plans (#5–8) will invoke `impeccable` per the project's `user_ui_workflow` memory.

---

## Prerequisites

The engineer must already have:

- A working dev loop on `feat/for-real-pivot` branch — pnpm install completes, `pnpm --filter @crimeboard/api run test` passes against existing tests, `pnpm --filter @crimeboard/api run dev` starts wrangler dev.
- D1 dev database `crimeboard-dev` already provisioned (it was created in the foundation plan).
- The current spec read at least once: `docs/superpowers/specs/2026-05-04-for-real-app-design.md`.

---

## Out of scope for this plan (covered later)

- Real LLM-driven claim extraction and verification (Plan 2)
- Real article body fetch + parse (Plan 2)
- Real YouTube audio download + Whisper transcription (Plan 3)
- TikTok extraction (Plan 4)
- A separate `workers/receipts-analyzer` worker — the analyzer stays inline in `workers/api` until Plan 2 carves it out
- `users` table, Sign in with Apple, account-linked receipts (Plan 8)
- iOS client (Plans 5–7)

---

## File structure produced by this plan

```
/Users/kari/Documents/news-app/
└── backend/
    ├── migrations/
    │   └── 0002_receipts_and_claims.sql          [Task 1]
    └── workers/api/
        ├── wrangler.toml                          [Task 1, 12 — vars only]
        ├── src/
        │   ├── index.ts                           [Task 5 — route mount]
        │   ├── routes/
        │   │   └── receipts.ts                    [Tasks 5–11]
        │   └── lib/
        │       ├── url.ts                         [Tasks 2–3]
        │       ├── url.test.ts                    [Tasks 2–3]
        │       ├── sse.ts                         [Task 4]
        │       ├── sse.test.ts                    [Task 4]
        │       └── stub-pipeline.ts               [Task 10]
        └── test/
            └── receipts.test.ts                   [Tasks 5–12]
```

The existing `workers/api/src/lib/` directory does not exist yet; Task 2 creates it. No file under `packages/shared` is touched in this plan — receipt logic is api-worker-local for Plan 1 and only moves to shared when a second worker needs it (Plan 2).

---

## Type reference (used across multiple tasks)

These types are introduced in Task 5 (`routes/receipts.ts` and `lib/url.ts`) and referenced verbatim by later tasks. Listed here so cross-task signatures stay consistent.

```ts
// lib/url.ts
export type SourceType = "video" | "article";
export type SourceProvider = "tiktok" | "youtube" | "article";

export interface ClassifiedUrl {
  source_type: SourceType;
  source_provider: SourceProvider;
  normalized_url: string;
}

// routes/receipts.ts — D1 row types (mirror the migration exactly)
export interface ReceiptRow {
  id: string;
  source_url: string;
  url_hash: string;
  source_type: SourceType;
  source_provider: SourceProvider;
  title: string | null;
  status: "pending" | "streaming" | "done" | "failed";
  final_verdict: "nope" | "mixed" | "yep" | "skip" | null;
  final_commentary: string | null;
  error_code: string | null;
  device_id: string | null;     // null after soft delete
  user_id: string | null;
  created_at: number;     // Unix epoch seconds
  finished_at: number | null;
}

export interface ClaimRow {
  id: string;
  receipt_id: string;
  position: 1 | 2 | 3;
  claim_text: string;
  verdict: "nope" | "mixed" | "yep" | "skip";
  commentary: string;
  sources: string;        // JSON-encoded array of {url, title}
  resolved_at: number;
}
```

---

## Task 1: Migration — receipts and claims tables

**Files:**
- Create: `backend/migrations/0002_receipts_and_claims.sql`

- [ ] **Step 1: Write the migration**

Create `backend/migrations/0002_receipts_and_claims.sql` with:

```sql
-- 0002_receipts_and_claims.sql
-- Adds the For Real?? receipt artifact and its component claims.
-- All times stored as Unix epoch seconds (INTEGER) per the existing schema convention.
-- url_hash is sha256(normalized url) hex-encoded; used for global cache lookup.

CREATE TABLE receipts (
  id                TEXT    PRIMARY KEY,
  source_url        TEXT    NOT NULL,
  url_hash          TEXT    NOT NULL,
  source_type       TEXT    NOT NULL CHECK (source_type IN ('video', 'article')),
  source_provider   TEXT    NOT NULL CHECK (source_provider IN ('tiktok', 'youtube', 'article')),
  title             TEXT,
  status            TEXT    NOT NULL CHECK (status IN ('pending', 'streaming', 'done', 'failed')),
  final_verdict     TEXT             CHECK (final_verdict IS NULL OR final_verdict IN ('nope', 'mixed', 'yep', 'skip')),
  final_commentary  TEXT,
  error_code        TEXT,
  device_id         TEXT,           -- nullable: cleared by DELETE /v1/receipts/:id (soft delete)
  user_id           TEXT,
  created_at        INTEGER NOT NULL,
  finished_at       INTEGER
) STRICT;

CREATE INDEX idx_receipts_url_hash             ON receipts(url_hash);
CREATE INDEX idx_receipts_device_created_at    ON receipts(device_id, created_at DESC);
CREATE INDEX idx_receipts_user_created_at      ON receipts(user_id, created_at DESC) WHERE user_id IS NOT NULL;

CREATE TABLE claims (
  id            TEXT    PRIMARY KEY,
  receipt_id    TEXT    NOT NULL REFERENCES receipts(id),
  position      INTEGER NOT NULL CHECK (position IN (1, 2, 3)),
  claim_text    TEXT    NOT NULL,
  verdict       TEXT    NOT NULL CHECK (verdict IN ('nope', 'mixed', 'yep', 'skip')),
  commentary    TEXT    NOT NULL,
  sources       TEXT    NOT NULL DEFAULT '[]',
  resolved_at   INTEGER NOT NULL
) STRICT;

CREATE INDEX idx_claims_receipt_id ON claims(receipt_id);
CREATE UNIQUE INDEX idx_claims_receipt_position ON claims(receipt_id, position);
```

- [ ] **Step 2: Run the existing tests to confirm the new migration applies cleanly**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run`
Expected: PASS — all existing tests still pass. The vitest setup file (`workers/api/test/apply-migrations.ts`) re-runs `applyD1Migrations` per test, so a malformed SQL file would fail every test with a SQLITE error. A clean PASS confirms the migration is parseable.

- [ ] **Step 3: Apply the migration to the dev D1**

Run: `cd backend && pnpm --filter @crimeboard/api exec wrangler d1 migrations apply crimeboard-dev --local`
Expected output:
```
Migrations to be applied:
┌──────────────────────────────────┐
│ name                             │
├──────────────────────────────────┤
│ 0002_receipts_and_claims.sql     │
└──────────────────────────────────┘
✔ Migration applied successfully.
```

- [ ] **Step 4: Commit**

```bash
git add backend/migrations/0002_receipts_and_claims.sql
git commit -m "feat(db): add receipts and claims tables for For Real?? pipeline"
```

---

## Task 2: URL classifier

**Files:**
- Create: `backend/workers/api/src/lib/url.ts`
- Test: `backend/workers/api/src/lib/url.test.ts`

The classifier inspects a URL and returns its source type / provider, or null for unsupported inputs (Instagram, Facebook, raw mp4, malformed).

- [ ] **Step 1: Write failing test**

Create `backend/workers/api/src/lib/url.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import { classifyUrl } from "./url.ts";

describe("classifyUrl", () => {
  it("recognizes TikTok video URLs", () => {
    const result = classifyUrl("https://www.tiktok.com/@user/video/1234567890123456789");
    expect(result).toEqual({
      source_type: "video",
      source_provider: "tiktok",
      normalized_url: "https://www.tiktok.com/@user/video/1234567890123456789",
    });
  });

  it("recognizes vm.tiktok.com short links", () => {
    const result = classifyUrl("https://vm.tiktok.com/ZMabcdef/");
    expect(result?.source_provider).toBe("tiktok");
  });

  it("recognizes YouTube watch URLs", () => {
    const result = classifyUrl("https://www.youtube.com/watch?v=dQw4w9WgXcQ");
    expect(result?.source_provider).toBe("youtube");
    expect(result?.source_type).toBe("video");
  });

  it("recognizes youtu.be short links", () => {
    expect(classifyUrl("https://youtu.be/dQw4w9WgXcQ")?.source_provider).toBe("youtube");
  });

  it("recognizes YouTube Shorts URLs", () => {
    expect(classifyUrl("https://www.youtube.com/shorts/abc123")?.source_provider).toBe("youtube");
  });

  it("treats a normal news article URL as an article", () => {
    const result = classifyUrl("https://www.nytimes.com/2026/05/04/some-article.html");
    expect(result).toEqual({
      source_type: "article",
      source_provider: "article",
      normalized_url: "https://www.nytimes.com/2026/05/04/some-article.html",
    });
  });

  it("returns null for Instagram (unsupported provider)", () => {
    expect(classifyUrl("https://www.instagram.com/reel/abc/")).toBeNull();
  });

  it("returns null for Facebook (unsupported provider)", () => {
    expect(classifyUrl("https://www.facebook.com/watch/?v=123")).toBeNull();
  });

  it("returns null for X / Twitter video (out of scope)", () => {
    expect(classifyUrl("https://x.com/user/status/123/video/1")).toBeNull();
  });

  it("returns null for malformed URLs", () => {
    expect(classifyUrl("not a url")).toBeNull();
    expect(classifyUrl("")).toBeNull();
  });

  it("returns null for non-https schemes", () => {
    expect(classifyUrl("ftp://example.com/file")).toBeNull();
    expect(classifyUrl("javascript:alert(1)")).toBeNull();
  });
});
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run src/lib/url.test.ts`
Expected: FAIL — `Failed to load url from "./url.ts"` or `classifyUrl is not a function`.

- [ ] **Step 3: Implement `classifyUrl`**

Create `backend/workers/api/src/lib/url.ts`:

```ts
export type SourceType = "video" | "article";
export type SourceProvider = "tiktok" | "youtube" | "article";

export interface ClassifiedUrl {
  source_type: SourceType;
  source_provider: SourceProvider;
  normalized_url: string;
}

const TIKTOK_HOSTS = new Set(["tiktok.com", "www.tiktok.com", "vm.tiktok.com", "vt.tiktok.com", "m.tiktok.com"]);
const YOUTUBE_HOSTS = new Set(["youtube.com", "www.youtube.com", "m.youtube.com", "youtu.be"]);
const UNSUPPORTED_HOSTS = new Set([
  "instagram.com", "www.instagram.com",
  "facebook.com", "www.facebook.com", "fb.watch",
  "x.com", "twitter.com", "www.twitter.com",
  "bsky.app",
]);

export function classifyUrl(input: string): ClassifiedUrl | null {
  let url: URL;
  try {
    url = new URL(input);
  } catch {
    return null;
  }

  if (url.protocol !== "https:" && url.protocol !== "http:") return null;

  const host = url.host.toLowerCase();

  if (UNSUPPORTED_HOSTS.has(host)) return null;

  if (TIKTOK_HOSTS.has(host)) {
    return { source_type: "video", source_provider: "tiktok", normalized_url: url.toString() };
  }

  if (YOUTUBE_HOSTS.has(host)) {
    return { source_type: "video", source_provider: "youtube", normalized_url: url.toString() };
  }

  // Default: treat as article. Plan 2 may add extra rejections (e.g., known paywalled
  // domains) but for Plan 1 anything that isn't unsupported and isn't a known video
  // host is an article.
  return { source_type: "article", source_provider: "article", normalized_url: url.toString() };
}
```

- [ ] **Step 4: Run the test and confirm it passes**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run src/lib/url.test.ts`
Expected: PASS — all 11 cases.

- [ ] **Step 5: Commit**

```bash
git add backend/workers/api/src/lib/url.ts backend/workers/api/src/lib/url.test.ts
git commit -m "feat(api): add classifyUrl for TikTok / YouTube / article detection"
```

---

## Task 3: URL normalizer + hasher

**Files:**
- Modify: `backend/workers/api/src/lib/url.ts` (extend)
- Modify: `backend/workers/api/src/lib/url.test.ts` (extend)

The cache key is `sha256(normalize(url))`. Normalization strips tracking params and trailing slashes so `?utm_source=...` doesn't fragment the cache, and lowercases the host.

- [ ] **Step 1: Add the failing tests**

Append to `backend/workers/api/src/lib/url.test.ts`:

```ts
import { normalizeUrl, hashUrl } from "./url.ts";

describe("normalizeUrl", () => {
  it("strips utm_* and similar tracking params", () => {
    expect(normalizeUrl("https://example.com/page?utm_source=tw&utm_medium=x&id=42"))
      .toBe("https://example.com/page?id=42");
  });

  it("strips fragment", () => {
    expect(normalizeUrl("https://example.com/page#section")).toBe("https://example.com/page");
  });

  it("lowercases the host but not the path", () => {
    expect(normalizeUrl("https://YouTube.com/watch?v=ABC123"))
      .toBe("https://youtube.com/watch?v=ABC123");
  });

  it("removes a trailing slash from the path (not from root)", () => {
    expect(normalizeUrl("https://example.com/page/")).toBe("https://example.com/page");
    expect(normalizeUrl("https://example.com/")).toBe("https://example.com/");
  });

  it("returns the input unchanged if it cannot be parsed", () => {
    expect(normalizeUrl("not a url")).toBe("not a url");
  });
});

describe("hashUrl", () => {
  it("returns a 64-character lowercase hex sha256", async () => {
    const h = await hashUrl("https://example.com/page");
    expect(h).toMatch(/^[0-9a-f]{64}$/);
  });

  it("produces the same hash for the same input", async () => {
    const a = await hashUrl("https://example.com/page");
    const b = await hashUrl("https://example.com/page");
    expect(a).toBe(b);
  });

  it("produces different hashes for different inputs", async () => {
    const a = await hashUrl("https://example.com/a");
    const b = await hashUrl("https://example.com/b");
    expect(a).not.toBe(b);
  });
});
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run src/lib/url.test.ts`
Expected: FAIL — `normalizeUrl is not exported`, `hashUrl is not exported`.

- [ ] **Step 3: Add both functions to `lib/url.ts`**

Append to `backend/workers/api/src/lib/url.ts`:

```ts
const TRACKING_PARAMS = [
  "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
  "fbclid", "gclid", "mc_cid", "mc_eid", "igshid", "_branch_match_id",
];

export function normalizeUrl(input: string): string {
  let url: URL;
  try {
    url = new URL(input);
  } catch {
    return input;
  }
  for (const param of TRACKING_PARAMS) url.searchParams.delete(param);
  url.hash = "";
  url.host = url.host.toLowerCase();
  if (url.pathname.length > 1 && url.pathname.endsWith("/")) {
    url.pathname = url.pathname.slice(0, -1);
  }
  return url.toString();
}

export async function hashUrl(input: string): Promise<string> {
  const encoded = new TextEncoder().encode(normalizeUrl(input));
  const buf = await crypto.subtle.digest("SHA-256", encoded);
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
```

Note: `hashUrl` calls `normalizeUrl` itself, so callers can pass a raw user-supplied URL.

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run src/lib/url.test.ts`
Expected: PASS — all classifier and normalizer/hash tests pass.

- [ ] **Step 5: Commit**

```bash
git add backend/workers/api/src/lib/url.ts backend/workers/api/src/lib/url.test.ts
git commit -m "feat(api): add normalizeUrl + hashUrl for global receipt cache lookup"
```

---

## Task 4: SSE event formatter

**Files:**
- Create: `backend/workers/api/src/lib/sse.ts`
- Test: `backend/workers/api/src/lib/sse.test.ts`

Hono's `streamSSE` writes events directly, but we want a single helper that builds the typed event payloads we emit, so call sites (the stub pipeline now and the real pipeline later) can't drift from the wire format declared in the spec.

- [ ] **Step 1: Write the failing test**

Create `backend/workers/api/src/lib/sse.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import {
  statusEvent, claimFinalEvent, receiptFinalEvent, errorEvent,
  type StatusPayload, type ClaimFinalPayload, type ReceiptFinalPayload, type ErrorPayload,
} from "./sse.ts";

describe("SSE event helpers", () => {
  it("formats a status event", () => {
    const e = statusEvent({ status: "streaming" });
    expect(e).toEqual({ event: "status", data: '{"status":"streaming"}' });
  });

  it("formats a claim_final event", () => {
    const payload: ClaimFinalPayload = {
      position: 1,
      claim_text: "the sky is green",
      verdict: "nope",
      commentary: "bestie",
      sources: [{ url: "https://example.com", title: "ex" }],
    };
    const e = claimFinalEvent(payload);
    expect(e.event).toBe("claim_final");
    expect(JSON.parse(e.data)).toEqual(payload);
  });

  it("formats a receipt_final event", () => {
    const payload: ReceiptFinalPayload = { final_verdict: "nope", final_commentary: "yep nope" };
    const e = receiptFinalEvent(payload);
    expect(e.event).toBe("receipt_final");
    expect(JSON.parse(e.data)).toEqual(payload);
  });

  it("formats an error event", () => {
    const payload: ErrorPayload = { error_code: "transcription_failed", message: "boom" };
    const e = errorEvent(payload);
    expect(e.event).toBe("error");
    expect(JSON.parse(e.data)).toEqual(payload);
  });
});
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run src/lib/sse.test.ts`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement the helpers**

Create `backend/workers/api/src/lib/sse.ts`:

```ts
export interface StatusPayload {
  status: "pending" | "streaming" | "done" | "failed";
}

export interface ClaimFinalPayload {
  position: 1 | 2 | 3;
  claim_text: string;
  verdict: "nope" | "mixed" | "yep" | "skip";
  commentary: string;
  sources: Array<{ url: string; title: string }>;
}

export interface ReceiptFinalPayload {
  final_verdict: "nope" | "mixed" | "yep" | "skip";
  final_commentary: string;
}

export interface ErrorPayload {
  error_code: string;
  message: string;
}

export interface SseEvent {
  event: "status" | "claim_final" | "receipt_final" | "error";
  data: string;
}

export function statusEvent(payload: StatusPayload): SseEvent {
  return { event: "status", data: JSON.stringify(payload) };
}

export function claimFinalEvent(payload: ClaimFinalPayload): SseEvent {
  return { event: "claim_final", data: JSON.stringify(payload) };
}

export function receiptFinalEvent(payload: ReceiptFinalPayload): SseEvent {
  return { event: "receipt_final", data: JSON.stringify(payload) };
}

export function errorEvent(payload: ErrorPayload): SseEvent {
  return { event: "error", data: JSON.stringify(payload) };
}
```

- [ ] **Step 4: Run the test and confirm it passes**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run src/lib/sse.test.ts`
Expected: PASS — 4 cases.

- [ ] **Step 5: Commit**

```bash
git add backend/workers/api/src/lib/sse.ts backend/workers/api/src/lib/sse.test.ts
git commit -m "feat(api): add typed SSE event helpers for receipt stream"
```

---

## Task 5: Receipts route scaffold + mount

**Files:**
- Create: `backend/workers/api/src/routes/receipts.ts`
- Modify: `backend/workers/api/src/index.ts`
- Modify: `backend/workers/api/test/receipts.test.ts` (create)

This task wires an empty receipts router into the app and adds a smoke test that proves the route is mounted. Subsequent tasks fill in handlers.

- [ ] **Step 1: Write the failing smoke test**

Create `backend/workers/api/test/receipts.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import { SELF } from "cloudflare:test";

describe("receipts router mount", () => {
  it("returns 404 for an unknown receipt id (router is mounted)", async () => {
    const res = await SELF.fetch("http://test/v1/receipts/nonexistent", {
      headers: { "X-Receipts-Device": "device-A" },
    });
    expect(res.status).toBe(404);
  });
});
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run test/receipts.test.ts`
Expected: FAIL — Hono returns 404 with `text/plain` for an unmounted route, but the test will fail before that step because the route file doesn't exist yet (TypeScript compile error on subsequent tasks). For now, the test gets 404 from Hono's default not-found handler, which actually passes — that's the "router not mounted yet" no-op state. Confirm by reading the test output: if `expect(res.status).toBe(404)` passes, that's because nothing's mounted; we're about to mount something that will *also* return 404 for unknown ids. The next step is meaningful regardless.

- [ ] **Step 3: Create the router skeleton + the row types**

Create `backend/workers/api/src/routes/receipts.ts`:

```ts
import { Hono } from "hono";
import type { AppBindings } from "../types.ts";
import type { SourceType, SourceProvider } from "../lib/url.ts";

const receipts = new Hono<AppBindings>();

export interface ReceiptRow {
  id: string;
  source_url: string;
  url_hash: string;
  source_type: SourceType;
  source_provider: SourceProvider;
  title: string | null;
  status: "pending" | "streaming" | "done" | "failed";
  final_verdict: "nope" | "mixed" | "yep" | "skip" | null;
  final_commentary: string | null;
  error_code: string | null;
  device_id: string | null;     // null after soft delete
  user_id: string | null;
  created_at: number;
  finished_at: number | null;
}

export interface ClaimRow {
  id: string;
  receipt_id: string;
  position: 1 | 2 | 3;
  claim_text: string;
  verdict: "nope" | "mixed" | "yep" | "skip";
  commentary: string;
  sources: string;          // JSON-encoded array; parse at the boundary
  resolved_at: number;
}

receipts.get("/:id", async (c) => {
  const id = c.req.param("id");
  const row = await c.env.DB.prepare("SELECT id FROM receipts WHERE id = ?").bind(id).first();
  if (!row) return c.json({ error: "not found" }, 404);
  // Filled out in Task 7.
  return c.json({ error: "not implemented" }, 501);
});

export default receipts;
```

- [ ] **Step 4: Mount the router**

Edit `backend/workers/api/src/index.ts`:

Replace the file body with:

```ts
import { Hono } from "hono";
import auth from "./routes/auth.ts";
import me from "./routes/me.ts";
import receipts from "./routes/receipts.ts";
import type { AppBindings } from "./types.ts";

const app = new Hono<AppBindings>();

app.get("/health", (c) => c.json({ ok: true, service: "crimeboard-api" }));

app.route("/auth", auth);
app.route("/me", me);
app.route("/v1/receipts", receipts);

export default app;
```

- [ ] **Step 5: Run the test and confirm it passes meaningfully**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run test/receipts.test.ts`
Expected: PASS — the `/v1/receipts/nonexistent` request now hits the mounted handler, the D1 lookup returns no row, and the handler returns `{"error":"not found"}` with status 404.

- [ ] **Step 6: Commit**

```bash
git add backend/workers/api/src/routes/receipts.ts backend/workers/api/src/index.ts backend/workers/api/test/receipts.test.ts
git commit -m "feat(api): mount /v1/receipts router with row types and 404 stub"
```

---

## Task 6: POST /v1/receipts (create with idempotency cache)

**Files:**
- Modify: `backend/workers/api/src/routes/receipts.ts`
- Modify: `backend/workers/api/test/receipts.test.ts`

POST accepts `{ url }`, requires `X-Receipts-Device`, classifies the URL, and either returns a cached receipt or inserts a new pending one.

- [ ] **Step 1: Write the failing tests**

Append to `backend/workers/api/test/receipts.test.ts`:

```ts
describe("POST /v1/receipts", () => {
  it("creates a new pending receipt for a fresh YouTube URL", async () => {
    const res = await SELF.fetch("http://test/v1/receipts", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-A" },
      body: JSON.stringify({ url: "https://www.youtube.com/watch?v=fresh1" }),
    });
    expect(res.status).toBe(200);
    const body = await res.json() as { receipt_id: string; status: string; cached: boolean };
    expect(body.receipt_id).toMatch(/^[0-9a-f-]{36}$/);
    expect(body.status).toBe("pending");
    expect(body.cached).toBe(false);
  });

  it("returns the cached receipt globally on a second paste of the same URL", async () => {
    // First paste from device-A
    const firstRes = await SELF.fetch("http://test/v1/receipts", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-A" },
      body: JSON.stringify({ url: "https://www.youtube.com/watch?v=cached1" }),
    });
    const first = await firstRes.json() as { receipt_id: string };

    // Second paste from device-B — different device, same URL
    const secondRes = await SELF.fetch("http://test/v1/receipts", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-B" },
      body: JSON.stringify({ url: "https://www.youtube.com/watch?v=cached1" }),
    });
    const second = await secondRes.json() as { receipt_id: string; status: string; cached: boolean };

    expect(second.receipt_id).toBe(first.receipt_id);
    expect(second.cached).toBe(true);
  });

  it("ignores tracking params for cache lookup", async () => {
    const a = await SELF.fetch("http://test/v1/receipts", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-A" },
      body: JSON.stringify({ url: "https://www.youtube.com/watch?v=trk1" }),
    }).then((r) => r.json() as Promise<{ receipt_id: string }>);

    const b = await SELF.fetch("http://test/v1/receipts", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-B" },
      body: JSON.stringify({ url: "https://www.youtube.com/watch?v=trk1&utm_source=tw" }),
    }).then((r) => r.json() as Promise<{ receipt_id: string; cached: boolean }>);

    expect(b.receipt_id).toBe(a.receipt_id);
    expect(b.cached).toBe(true);
  });

  it("400s when X-Receipts-Device is missing", async () => {
    const res = await SELF.fetch("http://test/v1/receipts", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ url: "https://www.youtube.com/watch?v=foo" }),
    });
    expect(res.status).toBe(400);
    const body = await res.json() as { error: string };
    expect(body.error).toMatch(/device/i);
  });

  it("400s on a missing url field", async () => {
    const res = await SELF.fetch("http://test/v1/receipts", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-A" },
      body: JSON.stringify({}),
    });
    expect(res.status).toBe(400);
  });

  it("422s on an unsupported provider (Instagram)", async () => {
    const res = await SELF.fetch("http://test/v1/receipts", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-A" },
      body: JSON.stringify({ url: "https://www.instagram.com/reel/abc/" }),
    });
    expect(res.status).toBe(422);
    const body = await res.json() as { error: string; error_code: string };
    expect(body.error_code).toBe("unsupported_provider");
  });
});
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run test/receipts.test.ts`
Expected: FAIL — POST returns 404 because no POST handler is mounted.

- [ ] **Step 3: Add the POST handler**

Insert into `backend/workers/api/src/routes/receipts.ts`, immediately before the `receipts.get("/:id", ...)` handler:

```ts
import { classifyUrl, hashUrl } from "../lib/url.ts";

interface PostBody {
  url?: unknown;
}

receipts.post("/", async (c) => {
  const deviceId = c.req.header("X-Receipts-Device");
  if (!deviceId || deviceId.length === 0) {
    return c.json({ error: "missing X-Receipts-Device header" }, 400);
  }

  const body = (await c.req.json().catch(() => ({}))) as PostBody;
  if (typeof body.url !== "string" || body.url.length === 0) {
    return c.json({ error: "missing url" }, 400);
  }

  const classified = classifyUrl(body.url);
  if (!classified) {
    return c.json({ error: "unsupported provider", error_code: "unsupported_provider" }, 422);
  }

  const url_hash = await hashUrl(body.url);

  // Cache lookup is global: any prior receipt for this URL hash is reusable.
  // We prefer 'done' over 'streaming'/'pending' so a paste during another user's
  // analysis still gets a stable id (the SSE handler will replay or join).
  const cached = await c.env.DB.prepare(
    `SELECT id, status FROM receipts
       WHERE url_hash = ?
       ORDER BY CASE status
                  WHEN 'done' THEN 0
                  WHEN 'streaming' THEN 1
                  WHEN 'pending' THEN 2
                  WHEN 'failed' THEN 3
                END,
              created_at DESC
       LIMIT 1`
  )
    .bind(url_hash)
    .first<{ id: string; status: string }>();

  if (cached) {
    return c.json({ receipt_id: cached.id, status: cached.status, cached: true });
  }

  const id = crypto.randomUUID();
  const now = Math.floor(Date.now() / 1000);
  await c.env.DB.prepare(
    `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                           title, status, device_id, user_id, created_at)
     VALUES (?, ?, ?, ?, ?, NULL, 'pending', ?, NULL, ?)`
  )
    .bind(id, classified.normalized_url, url_hash, classified.source_type, classified.source_provider, deviceId, now)
    .run();

  return c.json({ receipt_id: id, status: "pending", cached: false });
});
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run test/receipts.test.ts`
Expected: PASS — all six POST cases.

- [ ] **Step 5: Commit**

```bash
git add backend/workers/api/src/routes/receipts.ts backend/workers/api/test/receipts.test.ts
git commit -m "feat(api): POST /v1/receipts with global url-hash idempotency"
```

---

## Task 7: GET /v1/receipts/:id (full receipt + claims)

**Files:**
- Modify: `backend/workers/api/src/routes/receipts.ts`
- Modify: `backend/workers/api/test/receipts.test.ts`

Returns the full receipt JSON, including any resolved claims. Used by iOS to fetch a finalized receipt or to recover state mid-stream.

- [ ] **Step 1: Write the failing tests**

Append to `backend/workers/api/test/receipts.test.ts`:

```ts
import { env } from "cloudflare:test";

describe("GET /v1/receipts/:id", () => {
  it("returns 404 for an unknown id", async () => {
    const res = await SELF.fetch("http://test/v1/receipts/00000000-0000-0000-0000-000000000000", {
      headers: { "X-Receipts-Device": "device-A" },
    });
    expect(res.status).toBe(404);
  });

  it("returns the receipt JSON with empty claims when pending", async () => {
    // Seed a pending receipt directly
    const id = crypto.randomUUID();
    const now = Math.floor(Date.now() / 1000);
    await env.DB.prepare(
      `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                             title, status, device_id, user_id, created_at)
       VALUES (?, ?, ?, 'video', 'youtube', NULL, 'pending', ?, NULL, ?)`
    ).bind(id, "https://www.youtube.com/watch?v=getme1", "hash-getme1", "device-A", now).run();

    const res = await SELF.fetch(`http://test/v1/receipts/${id}`, {
      headers: { "X-Receipts-Device": "device-A" },
    });
    expect(res.status).toBe(200);
    const body = await res.json() as {
      id: string;
      status: string;
      source_provider: string;
      claims: unknown[];
    };
    expect(body.id).toBe(id);
    expect(body.status).toBe("pending");
    expect(body.source_provider).toBe("youtube");
    expect(body.claims).toEqual([]);
  });

  it("returns claims sorted by position when present", async () => {
    const receiptId = crypto.randomUUID();
    const now = Math.floor(Date.now() / 1000);
    await env.DB.prepare(
      `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                             title, status, final_verdict, final_commentary,
                             device_id, user_id, created_at, finished_at)
       VALUES (?, ?, ?, 'article', 'article', 'Test', 'done', 'nope', 'bestie',
               ?, NULL, ?, ?)`
    ).bind(receiptId, "https://example.com/a", "hash-a", "device-A", now, now).run();

    // Insert position 2 first to confirm sort works
    await env.DB.prepare(
      `INSERT INTO claims (id, receipt_id, position, claim_text, verdict, commentary, sources, resolved_at)
       VALUES (?, ?, 2, 'second', 'mixed', 'meh', ?, ?)`
    ).bind(crypto.randomUUID(), receiptId, JSON.stringify([{ url: "https://s2", title: "s2" }]), now).run();
    await env.DB.prepare(
      `INSERT INTO claims (id, receipt_id, position, claim_text, verdict, commentary, sources, resolved_at)
       VALUES (?, ?, 1, 'first', 'nope', 'no', '[]', ?)`
    ).bind(crypto.randomUUID(), receiptId, now).run();

    const res = await SELF.fetch(`http://test/v1/receipts/${receiptId}`, {
      headers: { "X-Receipts-Device": "device-A" },
    });
    const body = await res.json() as {
      claims: Array<{ position: number; claim_text: string; sources: Array<{ url: string; title: string }> }>;
    };
    expect(body.claims.map((c) => c.position)).toEqual([1, 2]);
    expect(body.claims[0].claim_text).toBe("first");
    expect(body.claims[1].sources).toEqual([{ url: "https://s2", title: "s2" }]);
  });
});
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run test/receipts.test.ts`
Expected: FAIL — the placeholder returns 501 for found receipts.

- [ ] **Step 3: Replace the GET handler**

Replace the placeholder GET handler in `backend/workers/api/src/routes/receipts.ts` with:

```ts
receipts.get("/:id", async (c) => {
  const id = c.req.param("id");
  const row = await c.env.DB.prepare(
    `SELECT id, source_url, url_hash, source_type, source_provider, title, status,
            final_verdict, final_commentary, error_code, device_id, user_id,
            created_at, finished_at
       FROM receipts WHERE id = ?`
  ).bind(id).first<ReceiptRow>();

  if (!row) return c.json({ error: "not found" }, 404);

  const claimRows = await c.env.DB.prepare(
    `SELECT id, receipt_id, position, claim_text, verdict, commentary, sources, resolved_at
       FROM claims WHERE receipt_id = ? ORDER BY position ASC`
  ).bind(id).all<ClaimRow>();

  return c.json({
    id: row.id,
    source_url: row.source_url,
    source_type: row.source_type,
    source_provider: row.source_provider,
    title: row.title,
    status: row.status,
    final_verdict: row.final_verdict,
    final_commentary: row.final_commentary,
    error_code: row.error_code,
    created_at: row.created_at,
    finished_at: row.finished_at,
    claims: (claimRows.results ?? []).map((cr) => ({
      position: cr.position,
      claim_text: cr.claim_text,
      verdict: cr.verdict,
      commentary: cr.commentary,
      sources: JSON.parse(cr.sources) as Array<{ url: string; title: string }>,
      resolved_at: cr.resolved_at,
    })),
  });
});
```

Note we deliberately do not return `device_id`, `user_id`, or `url_hash` in the response — those are server-internal.

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run test/receipts.test.ts`
Expected: PASS — all GET cases plus everything from Task 6.

- [ ] **Step 5: Commit**

```bash
git add backend/workers/api/src/routes/receipts.ts backend/workers/api/test/receipts.test.ts
git commit -m "feat(api): GET /v1/receipts/:id returns receipt + ordered claims"
```

---

## Task 8: GET /v1/receipts (list for device)

**Files:**
- Modify: `backend/workers/api/src/routes/receipts.ts`
- Modify: `backend/workers/api/test/receipts.test.ts`

Lists the calling device's receipts, newest first, with optional `?limit=N&before=<created_at>` paging.

- [ ] **Step 1: Write the failing tests**

Append to `backend/workers/api/test/receipts.test.ts`:

```ts
describe("GET /v1/receipts (list)", () => {
  it("lists only the calling device's receipts, newest first", async () => {
    const now = Math.floor(Date.now() / 1000);
    const idA1 = crypto.randomUUID();
    const idA2 = crypto.randomUUID();
    const idB1 = crypto.randomUUID();
    await env.DB.prepare(
      `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                             title, status, device_id, user_id, created_at)
       VALUES (?, ?, ?, 'video', 'youtube', NULL, 'done', 'device-list-A', NULL, ?)`
    ).bind(idA1, "https://yt/a1", "h-a1", now - 100).run();
    await env.DB.prepare(
      `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                             title, status, device_id, user_id, created_at)
       VALUES (?, ?, ?, 'video', 'youtube', NULL, 'done', 'device-list-A', NULL, ?)`
    ).bind(idA2, "https://yt/a2", "h-a2", now).run();
    await env.DB.prepare(
      `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                             title, status, device_id, user_id, created_at)
       VALUES (?, ?, ?, 'video', 'youtube', NULL, 'done', 'device-list-B', NULL, ?)`
    ).bind(idB1, "https://yt/b1", "h-b1", now).run();

    const res = await SELF.fetch("http://test/v1/receipts", {
      headers: { "X-Receipts-Device": "device-list-A" },
    });
    expect(res.status).toBe(200);
    const body = await res.json() as { receipts: Array<{ id: string }> };
    const ids = body.receipts.map((r) => r.id);
    expect(ids).toEqual([idA2, idA1]); // newest first
    expect(ids).not.toContain(idB1);
  });

  it("respects ?limit=", async () => {
    const res = await SELF.fetch("http://test/v1/receipts?limit=1", {
      headers: { "X-Receipts-Device": "device-list-A" },
    });
    const body = await res.json() as { receipts: unknown[] };
    expect(body.receipts.length).toBe(1);
  });

  it("400s without device header", async () => {
    const res = await SELF.fetch("http://test/v1/receipts");
    expect(res.status).toBe(400);
  });
});
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run test/receipts.test.ts`
Expected: FAIL — `/v1/receipts` (no id) is not handled, falls through Hono's not-found.

- [ ] **Step 3: Add the list handler**

Insert into `backend/workers/api/src/routes/receipts.ts` immediately after the POST handler:

```ts
receipts.get("/", async (c) => {
  const deviceId = c.req.header("X-Receipts-Device");
  if (!deviceId || deviceId.length === 0) {
    return c.json({ error: "missing X-Receipts-Device header" }, 400);
  }

  const limitParam = parseInt(c.req.query("limit") ?? "20", 10);
  const limit = Number.isFinite(limitParam) ? Math.min(Math.max(limitParam, 1), 100) : 20;
  const beforeParam = parseInt(c.req.query("before") ?? "", 10);
  const before = Number.isFinite(beforeParam) ? beforeParam : null;

  const sql = before == null
    ? `SELECT id, source_url, source_type, source_provider, title, status,
              final_verdict, final_commentary, created_at, finished_at
         FROM receipts
        WHERE device_id = ?
        ORDER BY created_at DESC
        LIMIT ?`
    : `SELECT id, source_url, source_type, source_provider, title, status,
              final_verdict, final_commentary, created_at, finished_at
         FROM receipts
        WHERE device_id = ? AND created_at < ?
        ORDER BY created_at DESC
        LIMIT ?`;
  const stmt = before == null
    ? c.env.DB.prepare(sql).bind(deviceId, limit)
    : c.env.DB.prepare(sql).bind(deviceId, before, limit);

  const result = await stmt.all<Omit<ReceiptRow, "url_hash" | "device_id" | "user_id" | "error_code">>();
  return c.json({ receipts: result.results ?? [] });
});
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run test/receipts.test.ts`
Expected: PASS — list cases plus everything previous.

- [ ] **Step 5: Commit**

```bash
git add backend/workers/api/src/routes/receipts.ts backend/workers/api/test/receipts.test.ts
git commit -m "feat(api): GET /v1/receipts list with device filter and pagination"
```

---

## Task 9: DELETE /v1/receipts/:id (unlink from device)

**Files:**
- Modify: `backend/workers/api/src/routes/receipts.ts`
- Modify: `backend/workers/api/test/receipts.test.ts`

Per spec, delete is a "user-side" operation: the row stays in the DB so the global URL cache still works for other devices, but the calling device's ownership is removed.

- [ ] **Step 1: Write the failing tests**

Append to `backend/workers/api/test/receipts.test.ts`:

```ts
describe("DELETE /v1/receipts/:id", () => {
  it("unlinks the calling device but keeps the row for cache reuse", async () => {
    const now = Math.floor(Date.now() / 1000);
    const id = crypto.randomUUID();
    await env.DB.prepare(
      `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                             title, status, device_id, user_id, created_at)
       VALUES (?, ?, ?, 'video', 'youtube', NULL, 'done', 'device-del', NULL, ?)`
    ).bind(id, "https://yt/del", "h-del", now).run();

    const res = await SELF.fetch(`http://test/v1/receipts/${id}`, {
      method: "DELETE",
      headers: { "X-Receipts-Device": "device-del" },
    });
    expect(res.status).toBe(204);

    // Row still exists; device_id has been cleared.
    const row = await env.DB.prepare("SELECT device_id FROM receipts WHERE id = ?")
      .bind(id)
      .first<{ device_id: string | null }>();
    expect(row?.device_id).toBeNull();
  });

  it("404s on a missing id", async () => {
    const res = await SELF.fetch("http://test/v1/receipts/missing-id", {
      method: "DELETE",
      headers: { "X-Receipts-Device": "device-del" },
    });
    expect(res.status).toBe(404);
  });

  it("403s when the device does not own the receipt", async () => {
    const now = Math.floor(Date.now() / 1000);
    const id = crypto.randomUUID();
    await env.DB.prepare(
      `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                             title, status, device_id, user_id, created_at)
       VALUES (?, ?, ?, 'video', 'youtube', NULL, 'done', 'device-owner', NULL, ?)`
    ).bind(id, "https://yt/own", "h-own", now).run();

    const res = await SELF.fetch(`http://test/v1/receipts/${id}`, {
      method: "DELETE",
      headers: { "X-Receipts-Device": "device-stranger" },
    });
    expect(res.status).toBe(403);
  });
});
```

The migration already declares `device_id` as nullable (Task 1) — the POST handler always supplies one, but DELETE clears it.

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run test/receipts.test.ts`
Expected: FAIL — DELETE returns 404 (no handler) for the first case.

- [ ] **Step 3: Add the DELETE handler**

Append in `backend/workers/api/src/routes/receipts.ts`:

```ts
receipts.delete("/:id", async (c) => {
  const deviceId = c.req.header("X-Receipts-Device");
  if (!deviceId || deviceId.length === 0) {
    return c.json({ error: "missing X-Receipts-Device header" }, 400);
  }
  const id = c.req.param("id");
  const row = await c.env.DB.prepare("SELECT device_id FROM receipts WHERE id = ?")
    .bind(id)
    .first<{ device_id: string | null }>();
  if (!row) return c.json({ error: "not found" }, 404);
  if (row.device_id !== deviceId) return c.json({ error: "forbidden" }, 403);

  await c.env.DB.prepare("UPDATE receipts SET device_id = NULL WHERE id = ?")
    .bind(id)
    .run();
  return new Response(null, { status: 204 });
});
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run test/receipts.test.ts`
Expected: PASS — three DELETE cases plus everything previous.

- [ ] **Step 5: Commit**

```bash
git add backend/workers/api/src/routes/receipts.ts backend/workers/api/test/receipts.test.ts
git commit -m "feat(api): DELETE /v1/receipts/:id unlinks device, keeps row for global cache"
```

---

## Task 10: Stubbed pipeline runner

**Files:**
- Create: `backend/workers/api/src/lib/stub-pipeline.ts`

This is the inline async generator the SSE endpoint will iterate over. It owns the "advance the receipt through pending → streaming → done" lifecycle while emitting events. The real pipeline (Plan 2+) replaces this file's contents; the SSE handler is unchanged.

The stub handles all five status states correctly:
- `done` → replay claims + final from D1
- `failed` → emit a single `error` event with the stored `error_code`
- `streaming` → another connection is already running (or just finished writing); replay what's currently in D1 without starting a duplicate run
- `pending` → CAS-update to `streaming` (atomic). If the update affects 0 rows we lost the race — replay instead. If we won, emit fake claims with delays, then finalize
- (no row) → silently exit

The CAS guard is essential: without it, two clients connecting to the same pending receipt would both attempt to insert claims at positions 1–3 and the second would crash on the unique `(receipt_id, position)` index.

- [ ] **Step 1: Write the runner**

Create `backend/workers/api/src/lib/stub-pipeline.ts`:

```ts
import type { D1Database } from "@cloudflare/workers-types";
import {
  statusEvent, claimFinalEvent, receiptFinalEvent, errorEvent,
  type SseEvent, type ClaimFinalPayload,
} from "./sse.ts";
import type { ReceiptRow, ClaimRow } from "../routes/receipts.ts";

const STUB_CLAIMS: ClaimFinalPayload[] = [
  {
    position: 1,
    claim_text: "claim 1 text (stub)",
    verdict: "nope",
    commentary: "Bestie, no.",
    sources: [{ url: "https://example.com/source-1", title: "Stub source 1" }],
  },
  {
    position: 2,
    claim_text: "claim 2 text (stub)",
    verdict: "mixed",
    commentary: "Half right at best.",
    sources: [{ url: "https://example.com/source-2", title: "Stub source 2" }],
  },
  {
    position: 3,
    claim_text: "claim 3 text (stub)",
    verdict: "yep",
    commentary: "Actually checks out.",
    sources: [{ url: "https://example.com/source-3", title: "Stub source 3" }],
  },
];
const STUB_FINAL = {
  final_verdict: "mixed" as const,
  final_commentary: "Mixed bag, bestie. One real, one fake, one half-truth.",
};

const sleep = (ms: number) => (ms > 0 ? new Promise((r) => setTimeout(r, ms)) : Promise.resolve());

async function* replayFromD1(db: D1Database, receiptId: string, status: "streaming" | "done"): AsyncGenerator<SseEvent> {
  yield statusEvent({ status });
  const claimRows = await db.prepare(
    `SELECT position, claim_text, verdict, commentary, sources
       FROM claims WHERE receipt_id = ? ORDER BY position ASC`
  ).bind(receiptId).all<Pick<ClaimRow, "position" | "claim_text" | "verdict" | "commentary" | "sources">>();
  for (const cr of claimRows.results ?? []) {
    yield claimFinalEvent({
      position: cr.position,
      claim_text: cr.claim_text,
      verdict: cr.verdict,
      commentary: cr.commentary,
      sources: JSON.parse(cr.sources) as Array<{ url: string; title: string }>,
    });
  }
  if (status === "done") {
    const final = await db.prepare(
      `SELECT final_verdict, final_commentary FROM receipts WHERE id = ?`
    ).bind(receiptId).first<{ final_verdict: "nope" | "mixed" | "yep" | "skip"; final_commentary: string }>();
    if (final?.final_verdict && final?.final_commentary) {
      yield receiptFinalEvent({ final_verdict: final.final_verdict, final_commentary: final.final_commentary });
    }
  }
}

export async function* runStubPipeline(
  db: D1Database,
  receiptId: string,
  delayMs: number
): AsyncGenerator<SseEvent> {
  const receipt = await db.prepare(
    `SELECT id, status, error_code FROM receipts WHERE id = ?`
  ).bind(receiptId).first<Pick<ReceiptRow, "id" | "status" | "error_code">>();
  if (!receipt) return;

  // Terminal states — replay or emit error.
  if (receipt.status === "done") {
    yield* replayFromD1(db, receiptId, "done");
    return;
  }
  if (receipt.status === "failed") {
    yield errorEvent({ error_code: receipt.error_code ?? "unknown", message: "receipt previously failed" });
    return;
  }
  if (receipt.status === "streaming") {
    // Another connection is already running (or already finished writing claims).
    // Replay current state without starting a duplicate run.
    yield* replayFromD1(db, receiptId, "streaming");
    return;
  }

  // status === "pending" — try to claim the run with a CAS update.
  const cas = await db.prepare(
    `UPDATE receipts SET status = 'streaming' WHERE id = ? AND status = 'pending'`
  ).bind(receiptId).run();
  if (cas.meta.changes === 0) {
    // Lost the race — someone else moved it out of pending. Replay current state.
    const fresh = await db.prepare(`SELECT status FROM receipts WHERE id = ?`).bind(receiptId)
      .first<Pick<ReceiptRow, "status">>();
    if (fresh?.status === "done") yield* replayFromD1(db, receiptId, "done");
    else yield* replayFromD1(db, receiptId, "streaming");
    return;
  }
  yield statusEvent({ status: "streaming" });

  await sleep(delayMs);
  for (const claim of STUB_CLAIMS) {
    const claimId = crypto.randomUUID();
    const now = Math.floor(Date.now() / 1000);
    await db.prepare(
      `INSERT INTO claims (id, receipt_id, position, claim_text, verdict, commentary, sources, resolved_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
    )
      .bind(claimId, receiptId, claim.position, claim.claim_text, claim.verdict, claim.commentary,
            JSON.stringify(claim.sources), now)
      .run();
    yield claimFinalEvent(claim);
    await sleep(delayMs);
  }

  const finishedAt = Math.floor(Date.now() / 1000);
  await db.prepare(
    `UPDATE receipts SET status = 'done', final_verdict = ?, final_commentary = ?, finished_at = ?
       WHERE id = ?`
  )
    .bind(STUB_FINAL.final_verdict, STUB_FINAL.final_commentary, finishedAt, receiptId)
    .run();
  yield receiptFinalEvent(STUB_FINAL);
}
```

- [ ] **Step 2: Type-check (no separate test for the stub — covered via SSE endpoint test in Task 11)**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run`
Expected: PASS — existing tests still pass; stub is unused so no behavior change yet.

- [ ] **Step 3: Commit**

```bash
git add backend/workers/api/src/lib/stub-pipeline.ts
git commit -m "feat(api): add stub receipt pipeline (replays cached or simulates fresh)"
```

---

## Task 11: GET /v1/receipts/:id/stream (SSE endpoint)

**Files:**
- Modify: `backend/workers/api/src/routes/receipts.ts`
- Modify: `backend/workers/api/wrangler.toml` (add `STUB_DELAY_MS` var)
- Modify: `backend/workers/api/vitest.config.ts` (override `STUB_DELAY_MS` to "0" for tests)
- Modify: `packages/shared/src/env.ts` (add `STUB_DELAY_MS` to `Env`)
- Modify: `backend/workers/api/test/receipts.test.ts`

Hono's `streamSSE` writes SSE events to the response. We iterate the stub pipeline generator and forward each event.

- [ ] **Step 1: Add `STUB_DELAY_MS` to the shared `Env` type**

Edit `backend/packages/shared/src/env.ts`. Find the `Env` interface and add (alongside the existing `APPLE_AUDIENCE`, `SESSION_SECRET`, etc.):

```ts
STUB_DELAY_MS: string;  // numeric string; 0 in tests, ~600 in dev
```

- [ ] **Step 2: Add the var to `wrangler.toml`**

In `backend/workers/api/wrangler.toml`, in the existing `[vars]` block (and `[env.staging.vars]` / `[env.production.vars]` blocks), add:

```toml
STUB_DELAY_MS = "600"
```

- [ ] **Step 3: Override the var in tests**

Edit `backend/workers/api/vitest.config.ts`. In the `bindings:` block, add:

```ts
STUB_DELAY_MS: "0",
```

- [ ] **Step 4: Write the failing tests**

Append to `backend/workers/api/test/receipts.test.ts`:

```ts
async function readSse(res: Response): Promise<Array<{ event: string; data: unknown }>> {
  const text = await res.text();
  const events: Array<{ event: string; data: unknown }> = [];
  for (const block of text.split("\n\n").filter((b) => b.trim().length > 0)) {
    let event = "message";
    let dataLines: string[] = [];
    for (const line of block.split("\n")) {
      if (line.startsWith("event: ")) event = line.slice(7).trim();
      else if (line.startsWith("data: ")) dataLines.push(line.slice(6));
    }
    events.push({ event, data: JSON.parse(dataLines.join("\n")) });
  }
  return events;
}

describe("GET /v1/receipts/:id/stream", () => {
  it("404s for an unknown id", async () => {
    const res = await SELF.fetch("http://test/v1/receipts/missing/stream", {
      headers: { "X-Receipts-Device": "device-A" },
    });
    expect(res.status).toBe(404);
  });

  it("streams status, three claim_finals, then receipt_final for a fresh receipt", async () => {
    // Create a fresh pending receipt
    const postRes = await SELF.fetch("http://test/v1/receipts", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-stream" },
      body: JSON.stringify({ url: "https://www.youtube.com/watch?v=stream1" }),
    });
    const { receipt_id } = await postRes.json() as { receipt_id: string };

    const res = await SELF.fetch(`http://test/v1/receipts/${receipt_id}/stream`, {
      headers: { "X-Receipts-Device": "device-stream" },
    });
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toContain("text/event-stream");

    const events = await readSse(res);
    const types = events.map((e) => e.event);
    expect(types).toEqual([
      "status", "claim_final", "claim_final", "claim_final", "receipt_final",
    ]);
    const positions = events.filter((e) => e.event === "claim_final").map((e) => (e.data as { position: number }).position);
    expect(positions).toEqual([1, 2, 3]);

    // Receipt is now done
    const get = await SELF.fetch(`http://test/v1/receipts/${receipt_id}`, {
      headers: { "X-Receipts-Device": "device-stream" },
    });
    const body = await get.json() as { status: string; claims: unknown[] };
    expect(body.status).toBe("done");
    expect(body.claims.length).toBe(3);
  });

  it("replays from D1 when the receipt is already done", async () => {
    // First connection completes the receipt.
    const postRes = await SELF.fetch("http://test/v1/receipts", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-replay" },
      body: JSON.stringify({ url: "https://www.youtube.com/watch?v=replay1" }),
    });
    const { receipt_id } = await postRes.json() as { receipt_id: string };
    await SELF.fetch(`http://test/v1/receipts/${receipt_id}/stream`, {
      headers: { "X-Receipts-Device": "device-replay" },
    }).then(readSse);

    // Second connection should yield the same events without inserting more claims.
    const res = await SELF.fetch(`http://test/v1/receipts/${receipt_id}/stream`, {
      headers: { "X-Receipts-Device": "device-replay" },
    });
    const events = await readSse(res);
    expect(events.map((e) => e.event)).toEqual([
      "status", "claim_final", "claim_final", "claim_final", "receipt_final",
    ]);

    // Still exactly three claims in D1 (no duplicates from the replay).
    const claimCount = await env.DB.prepare("SELECT COUNT(*) as n FROM claims WHERE receipt_id = ?")
      .bind(receipt_id)
      .first<{ n: number }>();
    expect(claimCount?.n).toBe(3);
  });

  it("replays existing claims when the receipt is already streaming (no duplicate inserts)", async () => {
    // Simulate a concurrent connection by seeding a receipt in 'streaming' state with one
    // claim already written. A second SSE connection must not try to insert claims 1–3
    // (which would crash on the unique (receipt_id, position) index).
    const id = crypto.randomUUID();
    const now = Math.floor(Date.now() / 1000);
    await env.DB.prepare(
      `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                             title, status, device_id, user_id, created_at)
       VALUES (?, ?, ?, 'video', 'youtube', NULL, 'streaming', 'device-stream2', NULL, ?)`
    ).bind(id, "https://www.youtube.com/watch?v=stream2", "hash-stream2", now).run();
    await env.DB.prepare(
      `INSERT INTO claims (id, receipt_id, position, claim_text, verdict, commentary, sources, resolved_at)
       VALUES (?, ?, 1, 'partial', 'nope', 'mid-stream', '[]', ?)`
    ).bind(crypto.randomUUID(), id, now).run();

    const res = await SELF.fetch(`http://test/v1/receipts/${id}/stream`, {
      headers: { "X-Receipts-Device": "device-stream2" },
    });
    expect(res.status).toBe(200);
    const events = await readSse(res);
    expect(events.map((e) => e.event)).toEqual(["status", "claim_final"]);
    expect((events[0].data as { status: string }).status).toBe("streaming");

    // Still exactly one claim — no duplicate insert attempt.
    const claimCount = await env.DB.prepare("SELECT COUNT(*) as n FROM claims WHERE receipt_id = ?")
      .bind(id)
      .first<{ n: number }>();
    expect(claimCount?.n).toBe(1);
  });

  it("emits an error event when the receipt is in failed state", async () => {
    const id = crypto.randomUUID();
    const now = Math.floor(Date.now() / 1000);
    await env.DB.prepare(
      `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                             title, status, error_code, device_id, user_id, created_at)
       VALUES (?, ?, ?, 'video', 'tiktok', NULL, 'failed', 'provider_blocked', 'device-fail', NULL, ?)`
    ).bind(id, "https://vm.tiktok.com/failed", "hash-failed", now).run();

    const res = await SELF.fetch(`http://test/v1/receipts/${id}/stream`, {
      headers: { "X-Receipts-Device": "device-fail" },
    });
    const events = await readSse(res);
    expect(events.length).toBe(1);
    expect(events[0].event).toBe("error");
    expect((events[0].data as { error_code: string }).error_code).toBe("provider_blocked");
  });
});
```

- [ ] **Step 5: Run the tests and confirm they fail**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run test/receipts.test.ts`
Expected: FAIL — `/stream` returns 404.

- [ ] **Step 6: Add the SSE handler**

In `backend/workers/api/src/routes/receipts.ts`, add the import at the top:

```ts
import { streamSSE } from "hono/streaming";
import { runStubPipeline } from "../lib/stub-pipeline.ts";
```

Append the handler:

```ts
receipts.get("/:id/stream", async (c) => {
  const id = c.req.param("id");
  const exists = await c.env.DB.prepare("SELECT id FROM receipts WHERE id = ?").bind(id).first();
  if (!exists) return c.json({ error: "not found" }, 404);

  const delayMs = parseInt(c.env.STUB_DELAY_MS ?? "0", 10) || 0;

  return streamSSE(c, async (stream) => {
    for await (const ev of runStubPipeline(c.env.DB, id, delayMs)) {
      await stream.writeSSE({ event: ev.event, data: ev.data });
    }
  });
});
```

- [ ] **Step 7: Run the tests and confirm they pass**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run test/receipts.test.ts`
Expected: PASS — three SSE cases plus everything previous.

- [ ] **Step 8: Commit**

```bash
git add backend/workers/api/src/routes/receipts.ts \
        backend/workers/api/wrangler.toml \
        backend/workers/api/vitest.config.ts \
        backend/packages/shared/src/env.ts \
        backend/workers/api/test/receipts.test.ts
git commit -m "feat(api): GET /v1/receipts/:id/stream SSE endpoint backed by stub pipeline"
```

---

## Task 12: Daily quota enforcement

**Files:**
- Modify: `backend/workers/api/src/routes/receipts.ts`
- Modify: `backend/workers/api/test/receipts.test.ts`
- Modify: `backend/workers/api/wrangler.toml` (add `ANON_DAILY_CAP`)
- Modify: `backend/workers/api/vitest.config.ts` (override `ANON_DAILY_CAP=3` for cheap tests)
- Modify: `backend/packages/shared/src/env.ts` (add `ANON_DAILY_CAP`)

The cap is per `device_id` over the most recent 24h window. Cache hits are free — they don't consume quota. Plan 8 will add the higher signed-in cap; for now it's anon-only.

- [ ] **Step 1: Add the env var**

Edit `backend/packages/shared/src/env.ts` — add to `Env`:

```ts
ANON_DAILY_CAP: string;  // numeric string; 10 in dev, 3 in tests
```

Edit `backend/workers/api/wrangler.toml`. In `[vars]` and each `[env.*.vars]`:

```toml
ANON_DAILY_CAP = "10"
```

Edit `backend/workers/api/vitest.config.ts` — add to `bindings`:

```ts
ANON_DAILY_CAP: "3",
```

- [ ] **Step 2: Write the failing tests**

Append to `backend/workers/api/test/receipts.test.ts`:

```ts
describe("daily quota", () => {
  it("returns 429 once the device has hit the cap (3 in tests)", async () => {
    for (let i = 0; i < 3; i++) {
      const res = await SELF.fetch("http://test/v1/receipts", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-quota-A" },
        body: JSON.stringify({ url: `https://www.youtube.com/watch?v=quotaA${i}` }),
      });
      expect(res.status).toBe(200);
    }
    const fourth = await SELF.fetch("http://test/v1/receipts", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-quota-A" },
      body: JSON.stringify({ url: "https://www.youtube.com/watch?v=quotaA3" }),
    });
    expect(fourth.status).toBe(429);
    const body = await fourth.json() as { error_code: string };
    expect(body.error_code).toBe("daily_cap_reached");
  });

  it("does not count cache hits against the cap", async () => {
    // Seed a globally-cached receipt the test device hasn't touched.
    const cachedUrl = "https://www.youtube.com/watch?v=globalcache";
    await SELF.fetch("http://test/v1/receipts", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-priming" },
      body: JSON.stringify({ url: cachedUrl }),
    });

    // device-quota-B paste the same URL three times; all should be cache hits, not counted.
    for (let i = 0; i < 3; i++) {
      const r = await SELF.fetch("http://test/v1/receipts", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-quota-B" },
        body: JSON.stringify({ url: cachedUrl }),
      });
      const body = await r.json() as { cached: boolean };
      expect(body.cached).toBe(true);
    }

    // device-quota-B can still create three fresh receipts of its own.
    for (let i = 0; i < 3; i++) {
      const r = await SELF.fetch("http://test/v1/receipts", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-quota-B" },
        body: JSON.stringify({ url: `https://www.youtube.com/watch?v=quotaB${i}` }),
      });
      expect(r.status).toBe(200);
    }
  });
});
```

- [ ] **Step 3: Run the tests and confirm they fail**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run test/receipts.test.ts`
Expected: FAIL — fourth POST returns 200, no quota enforced.

- [ ] **Step 4: Enforce the quota in the POST handler**

In `backend/workers/api/src/routes/receipts.ts`, in the `receipts.post("/", ...)` handler, **after** the cache lookup (so cache hits short-circuit before the quota check) and **before** the INSERT, add:

```ts
const cap = parseInt(c.env.ANON_DAILY_CAP ?? "10", 10) || 10;
const since = Math.floor(Date.now() / 1000) - 24 * 60 * 60;
const used = await c.env.DB.prepare(
  `SELECT COUNT(*) as n FROM receipts WHERE device_id = ? AND created_at >= ?`
).bind(deviceId, since).first<{ n: number }>();
if ((used?.n ?? 0) >= cap) {
  return c.json(
    {
      error: "Whoa bestie, that's a lot of receipts today. Try again tomorrow — or sign in for a bigger limit.",
      error_code: "daily_cap_reached",
    },
    429
  );
}
```

- [ ] **Step 5: Run the tests and confirm they pass**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run test/receipts.test.ts`
Expected: PASS — quota cases plus everything previous.

- [ ] **Step 6: Commit**

```bash
git add backend/workers/api/src/routes/receipts.ts \
        backend/workers/api/test/receipts.test.ts \
        backend/workers/api/wrangler.toml \
        backend/workers/api/vitest.config.ts \
        backend/packages/shared/src/env.ts
git commit -m "feat(api): enforce 10/day anonymous quota on POST /v1/receipts"
```

---

## Task 13: Wrap-up — README, full-suite check, branch state

**Files:**
- Modify: `backend/README.md`

- [ ] **Step 1: Update the backend README**

Open `backend/README.md` and append a new section after the existing endpoint documentation:

```markdown
## /v1/receipts (For Real?? pipeline skeleton)

The receipt pipeline ships in stages. Plan 1 lays the plumbing — endpoints, schema, SSE, quota — driven by a stub analyzer that returns hardcoded claims. Plan 2 swaps the stub for real article extraction; Plans 3–4 add YouTube and TikTok.

All `/v1/receipts` endpoints require an `X-Receipts-Device` header (UUID generated by the iOS client on first launch). No `Authorization` header is required for Plan 1; Sign in with Apple lands in Plan 8.

| Endpoint | What it does |
|---|---|
| `POST /v1/receipts` | Body `{ url }`. Returns `{ receipt_id, status, cached }`. Cache lookup is global by SHA-256 of the normalized URL — pasting a known URL from any device returns the existing `receipt_id`. Cache hits do not count against the daily quota. |
| `GET  /v1/receipts/:id` | Full receipt JSON with ordered claims. 404 if unknown. |
| `GET  /v1/receipts/:id/stream` | SSE event stream — `status`, `claim_final` (×3), `receipt_final`. If the receipt is already `done`, the events are replayed from D1; otherwise the stub pipeline runs and persists. |
| `DELETE /v1/receipts/:id` | Unlinks the calling device from the row (requires ownership). Returns 204. The row stays for global cache reuse. |
| `GET  /v1/receipts` | Lists the calling device's receipts. `?limit=N&before=<created_at>` for paging. |

Vars (`wrangler.toml`):
- `STUB_DELAY_MS` — milliseconds between stub pipeline events. `600` in dev, `0` in tests.
- `ANON_DAILY_CAP` — receipts/day per anonymous device. `10` in dev, `3` in tests.
```

- [ ] **Step 2: Run the full test suite**

Run: `cd backend && pnpm --filter @crimeboard/api run test -- --run`
Expected: PASS — all existing tests (auth, me, health) plus all receipt tests.

- [ ] **Step 3: Smoke-test against wrangler dev**

Open one terminal: `cd backend && pnpm --filter @crimeboard/api run dev`. Open another:

```bash
# Create
curl -s -X POST http://127.0.0.1:8787/v1/receipts \
  -H "Content-Type: application/json" \
  -H "X-Receipts-Device: smoke-1" \
  -d '{"url":"https://www.youtube.com/watch?v=smoketest"}' | jq

# Stream — should print 5 events over ~3s (3 claims at 600ms apart)
curl -N -H "X-Receipts-Device: smoke-1" \
  http://127.0.0.1:8787/v1/receipts/<receipt_id_from_above>/stream

# Fetch finalized
curl -s -H "X-Receipts-Device: smoke-1" \
  http://127.0.0.1:8787/v1/receipts/<receipt_id> | jq
```

Expected: First call returns `{receipt_id, status:"pending", cached:false}`. Stream prints status / 3 claim_final / receipt_final SSE events. Final fetch shows `status:"done"` with three claims.

- [ ] **Step 4: Commit and close out the plan**

```bash
git add backend/README.md
git commit -m "docs(backend): document /v1/receipts plumbing (Plan 1)"
```

The branch `feat/for-real-pivot` now has Plans 0 (spec) + Plan 1 worth of commits. Open the PR per the project's PR-based workflow memory:

```bash
git push -u origin feat/for-real-pivot
gh pr create --title "Plan 1 — receipts pipeline skeleton (stubbed)" --body "$(cat <<'EOF'
## Summary
- Lays the receipt-pipeline plumbing for For Real??: tables, REST + SSE endpoints, URL classification + global cache, anonymous-device daily quota.
- All driven by a stubbed analyzer that emits hardcoded events on a configurable delay; Plan 2 swaps the stub for real LLM-based analysis.
- No iOS work, no `users` table, no SiwA — those are later plans.

## Test plan
- [ ] `pnpm --filter @crimeboard/api run test -- --run` passes all suites (auth, me, receipts).
- [ ] Smoke test against `wrangler dev`: create / stream / fetch a receipt with curl per the README.
- [ ] Confirm idempotency: second POST of the same URL from a different device returns `cached: true`.
- [ ] Confirm quota: 11th POST in a 24h window returns 429 with `error_code: "daily_cap_reached"`.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Done definition

Plan 1 is complete when:

- All 13 tasks above are committed on `feat/for-real-pivot`.
- `pnpm --filter @crimeboard/api run test -- --run` passes.
- The smoke-test curl sequence in Task 13 Step 3 returns the expected events.
- A PR is open against `main` (or whichever the project's base branch is).

Plan 2 (article-input branch) opens against the same branch, replacing the stub generator's body with real article scraping + LLM claim extraction. The endpoint contract, schema, and tests stay the same.
