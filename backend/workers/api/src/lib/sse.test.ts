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
