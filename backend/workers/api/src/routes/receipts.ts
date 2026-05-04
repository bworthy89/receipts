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
