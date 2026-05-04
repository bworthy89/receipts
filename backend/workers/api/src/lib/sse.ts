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
