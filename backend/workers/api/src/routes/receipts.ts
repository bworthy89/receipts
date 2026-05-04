import { Hono } from "hono";
import type { AppBindings } from "../types.ts";
import type { SourceType, SourceProvider } from "../lib/url.ts";
import { classifyUrl, hashUrl } from "../lib/url.ts";

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

receipts.get("/:id", async (c) => {
  const id = c.req.param("id");
  const row = await c.env.DB.prepare("SELECT id FROM receipts WHERE id = ?").bind(id).first();
  if (!row) return c.json({ error: "not found" }, 404);
  // Filled out in Task 7.
  return c.json({ error: "not implemented" }, 501);
});

export default receipts;
