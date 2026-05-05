import { Hono } from "hono";
import { streamSSE } from "hono/streaming";
import type { AppBindings } from "../types.ts";
import type { SourceType, SourceProvider } from "../lib/url.ts";
import { classifyUrl, hashUrl } from "../lib/url.ts";
import { runStubPipeline } from "../lib/stub-pipeline.ts";

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

export default receipts;
