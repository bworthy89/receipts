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
