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
