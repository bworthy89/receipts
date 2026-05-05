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
  STUB_DELAY_MS: string;  // numeric string; 0 in tests, ~600 in dev

  // Secrets (set via `wrangler secret put`)
  SESSION_SECRET: string; // HMAC key for our session tokens
}
