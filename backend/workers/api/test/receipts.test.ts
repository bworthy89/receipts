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
    const firstRes = await SELF.fetch("http://test/v1/receipts", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-A" },
      body: JSON.stringify({ url: "https://www.youtube.com/watch?v=cached1" }),
    });
    const first = await firstRes.json() as { receipt_id: string };

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
