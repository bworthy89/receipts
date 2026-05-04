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
