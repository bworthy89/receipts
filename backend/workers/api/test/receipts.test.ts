import { describe, it, expect } from "vitest";
import { SELF } from "cloudflare:test";
import { env } from "cloudflare:test";

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

describe("GET /v1/receipts/:id", () => {
  it("returns 404 for an unknown id", async () => {
    const res = await SELF.fetch("http://test/v1/receipts/00000000-0000-0000-0000-000000000000", {
      headers: { "X-Receipts-Device": "device-A" },
    });
    expect(res.status).toBe(404);
  });

  it("returns the receipt JSON with empty claims when pending", async () => {
    const id = crypto.randomUUID();
    const now = Math.floor(Date.now() / 1000);
    await env.DB.prepare(
      `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                             title, status, device_id, user_id, created_at)
       VALUES (?, ?, ?, 'video', 'youtube', NULL, 'pending', ?, NULL, ?)`
    ).bind(id, "https://www.youtube.com/watch?v=getme1", "hash-getme1", "device-A", now).run();

    const res = await SELF.fetch(`http://test/v1/receipts/${id}`, {
      headers: { "X-Receipts-Device": "device-A" },
    });
    expect(res.status).toBe(200);
    const body = await res.json() as {
      id: string;
      status: string;
      source_provider: string;
      claims: unknown[];
    };
    expect(body.id).toBe(id);
    expect(body.status).toBe("pending");
    expect(body.source_provider).toBe("youtube");
    expect(body.claims).toEqual([]);
  });

  it("returns claims sorted by position when present", async () => {
    const receiptId = crypto.randomUUID();
    const now = Math.floor(Date.now() / 1000);
    await env.DB.prepare(
      `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                             title, status, final_verdict, final_commentary,
                             device_id, user_id, created_at, finished_at)
       VALUES (?, ?, ?, 'article', 'article', 'Test', 'done', 'nope', 'bestie',
               ?, NULL, ?, ?)`
    ).bind(receiptId, "https://example.com/a", "hash-a", "device-A", now, now).run();

    // Insert position 2 first to confirm sort works
    await env.DB.prepare(
      `INSERT INTO claims (id, receipt_id, position, claim_text, verdict, commentary, sources, resolved_at)
       VALUES (?, ?, 2, 'second', 'mixed', 'meh', ?, ?)`
    ).bind(crypto.randomUUID(), receiptId, JSON.stringify([{ url: "https://s2", title: "s2" }]), now).run();
    await env.DB.prepare(
      `INSERT INTO claims (id, receipt_id, position, claim_text, verdict, commentary, sources, resolved_at)
       VALUES (?, ?, 1, 'first', 'nope', 'no', '[]', ?)`
    ).bind(crypto.randomUUID(), receiptId, now).run();

    const res = await SELF.fetch(`http://test/v1/receipts/${receiptId}`, {
      headers: { "X-Receipts-Device": "device-A" },
    });
    const body = await res.json() as {
      claims: Array<{ position: number; claim_text: string; sources: Array<{ url: string; title: string }> }>;
    };
    expect(body.claims.map((c) => c.position)).toEqual([1, 2]);
    expect(body.claims[0].claim_text).toBe("first");
    expect(body.claims[1].sources).toEqual([{ url: "https://s2", title: "s2" }]);
  });
});

describe("GET /v1/receipts (list)", () => {
  it("lists only the calling device's receipts, newest first", async () => {
    const now = Math.floor(Date.now() / 1000);
    const idA1 = crypto.randomUUID();
    const idA2 = crypto.randomUUID();
    const idB1 = crypto.randomUUID();
    await env.DB.prepare(
      `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                             title, status, device_id, user_id, created_at)
       VALUES (?, ?, ?, 'video', 'youtube', NULL, 'done', 'device-list-A', NULL, ?)`
    ).bind(idA1, "https://yt/a1", "h-a1", now - 100).run();
    await env.DB.prepare(
      `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                             title, status, device_id, user_id, created_at)
       VALUES (?, ?, ?, 'video', 'youtube', NULL, 'done', 'device-list-A', NULL, ?)`
    ).bind(idA2, "https://yt/a2", "h-a2", now).run();
    await env.DB.prepare(
      `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                             title, status, device_id, user_id, created_at)
       VALUES (?, ?, ?, 'video', 'youtube', NULL, 'done', 'device-list-B', NULL, ?)`
    ).bind(idB1, "https://yt/b1", "h-b1", now).run();

    const res = await SELF.fetch("http://test/v1/receipts", {
      headers: { "X-Receipts-Device": "device-list-A" },
    });
    expect(res.status).toBe(200);
    const body = await res.json() as { receipts: Array<{ id: string }> };
    const ids = body.receipts.map((r) => r.id);
    expect(ids).toEqual([idA2, idA1]); // newest first
    expect(ids).not.toContain(idB1);
  });

  it("respects ?limit=", async () => {
    const now = Math.floor(Date.now() / 1000);
    await env.DB.prepare(
      `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                             title, status, device_id, user_id, created_at)
       VALUES (?, ?, ?, 'video', 'youtube', NULL, 'done', 'device-list-A', NULL, ?)`
    ).bind(crypto.randomUUID(), "https://yt/lim1", "h-lim1", now - 10).run();
    await env.DB.prepare(
      `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                             title, status, device_id, user_id, created_at)
       VALUES (?, ?, ?, 'video', 'youtube', NULL, 'done', 'device-list-A', NULL, ?)`
    ).bind(crypto.randomUUID(), "https://yt/lim2", "h-lim2", now).run();

    const res = await SELF.fetch("http://test/v1/receipts?limit=1", {
      headers: { "X-Receipts-Device": "device-list-A" },
    });
    const body = await res.json() as { receipts: unknown[] };
    expect(body.receipts.length).toBe(1);
  });

  it("400s without device header", async () => {
    const res = await SELF.fetch("http://test/v1/receipts");
    expect(res.status).toBe(400);
  });
});

async function readSse(res: Response): Promise<Array<{ event: string; data: unknown }>> {
  const text = await res.text();
  const events: Array<{ event: string; data: unknown }> = [];
  for (const block of text.split("\n\n").filter((b) => b.trim().length > 0)) {
    let event = "message";
    let dataLines: string[] = [];
    for (const line of block.split("\n")) {
      if (line.startsWith("event: ")) event = line.slice(7).trim();
      else if (line.startsWith("data: ")) dataLines.push(line.slice(6));
    }
    events.push({ event, data: JSON.parse(dataLines.join("\n")) });
  }
  return events;
}

describe("GET /v1/receipts/:id/stream", () => {
  it("404s for an unknown id", async () => {
    const res = await SELF.fetch("http://test/v1/receipts/missing/stream", {
      headers: { "X-Receipts-Device": "device-A" },
    });
    expect(res.status).toBe(404);
  });

  it("streams status, three claim_finals, then receipt_final for a fresh receipt", async () => {
    const postRes = await SELF.fetch("http://test/v1/receipts", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-stream" },
      body: JSON.stringify({ url: "https://www.youtube.com/watch?v=stream1" }),
    });
    const { receipt_id } = await postRes.json() as { receipt_id: string };

    const res = await SELF.fetch(`http://test/v1/receipts/${receipt_id}/stream`, {
      headers: { "X-Receipts-Device": "device-stream" },
    });
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toContain("text/event-stream");

    const events = await readSse(res);
    const types = events.map((e) => e.event);
    expect(types).toEqual([
      "status", "claim_final", "claim_final", "claim_final", "receipt_final",
    ]);
    const positions = events.filter((e) => e.event === "claim_final").map((e) => (e.data as { position: number }).position);
    expect(positions).toEqual([1, 2, 3]);

    const get = await SELF.fetch(`http://test/v1/receipts/${receipt_id}`, {
      headers: { "X-Receipts-Device": "device-stream" },
    });
    const body = await get.json() as { status: string; claims: unknown[] };
    expect(body.status).toBe("done");
    expect(body.claims.length).toBe(3);
  });

  it("replays from D1 when the receipt is already done", async () => {
    const postRes = await SELF.fetch("http://test/v1/receipts", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-replay" },
      body: JSON.stringify({ url: "https://www.youtube.com/watch?v=replay1" }),
    });
    const { receipt_id } = await postRes.json() as { receipt_id: string };
    await SELF.fetch(`http://test/v1/receipts/${receipt_id}/stream`, {
      headers: { "X-Receipts-Device": "device-replay" },
    }).then(readSse);

    const res = await SELF.fetch(`http://test/v1/receipts/${receipt_id}/stream`, {
      headers: { "X-Receipts-Device": "device-replay" },
    });
    const events = await readSse(res);
    expect(events.map((e) => e.event)).toEqual([
      "status", "claim_final", "claim_final", "claim_final", "receipt_final",
    ]);

    const claimCount = await env.DB.prepare("SELECT COUNT(*) as n FROM claims WHERE receipt_id = ?")
      .bind(receipt_id)
      .first<{ n: number }>();
    expect(claimCount?.n).toBe(3);
  });

  it("replays existing claims when the receipt is already streaming (no duplicate inserts)", async () => {
    const id = crypto.randomUUID();
    const now = Math.floor(Date.now() / 1000);
    await env.DB.prepare(
      `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                             title, status, device_id, user_id, created_at)
       VALUES (?, ?, ?, 'video', 'youtube', NULL, 'streaming', 'device-stream2', NULL, ?)`
    ).bind(id, "https://www.youtube.com/watch?v=stream2", "hash-stream2", now).run();
    await env.DB.prepare(
      `INSERT INTO claims (id, receipt_id, position, claim_text, verdict, commentary, sources, resolved_at)
       VALUES (?, ?, 1, 'partial', 'nope', 'mid-stream', '[]', ?)`
    ).bind(crypto.randomUUID(), id, now).run();

    const res = await SELF.fetch(`http://test/v1/receipts/${id}/stream`, {
      headers: { "X-Receipts-Device": "device-stream2" },
    });
    expect(res.status).toBe(200);
    const events = await readSse(res);
    expect(events.map((e) => e.event)).toEqual(["status", "claim_final"]);
    expect((events[0].data as { status: string }).status).toBe("streaming");

    const claimCount = await env.DB.prepare("SELECT COUNT(*) as n FROM claims WHERE receipt_id = ?")
      .bind(id)
      .first<{ n: number }>();
    expect(claimCount?.n).toBe(1);
  });

  it("emits an error event when the receipt is in failed state", async () => {
    const id = crypto.randomUUID();
    const now = Math.floor(Date.now() / 1000);
    await env.DB.prepare(
      `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                             title, status, error_code, device_id, user_id, created_at)
       VALUES (?, ?, ?, 'video', 'tiktok', NULL, 'failed', 'provider_blocked', 'device-fail', NULL, ?)`
    ).bind(id, "https://vm.tiktok.com/failed", "hash-failed", now).run();

    const res = await SELF.fetch(`http://test/v1/receipts/${id}/stream`, {
      headers: { "X-Receipts-Device": "device-fail" },
    });
    const events = await readSse(res);
    expect(events.length).toBe(1);
    expect(events[0].event).toBe("error");
    expect((events[0].data as { error_code: string }).error_code).toBe("provider_blocked");
  });
});

describe("DELETE /v1/receipts/:id", () => {
  it("unlinks the calling device but keeps the row for cache reuse", async () => {
    const now = Math.floor(Date.now() / 1000);
    const id = crypto.randomUUID();
    await env.DB.prepare(
      `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                             title, status, device_id, user_id, created_at)
       VALUES (?, ?, ?, 'video', 'youtube', NULL, 'done', 'device-del', NULL, ?)`
    ).bind(id, "https://yt/del", "h-del", now).run();

    const res = await SELF.fetch(`http://test/v1/receipts/${id}`, {
      method: "DELETE",
      headers: { "X-Receipts-Device": "device-del" },
    });
    expect(res.status).toBe(204);

    // Row still exists; device_id has been cleared.
    const row = await env.DB.prepare("SELECT device_id FROM receipts WHERE id = ?")
      .bind(id)
      .first<{ device_id: string | null }>();
    expect(row?.device_id).toBeNull();
  });

  it("404s on a missing id", async () => {
    const res = await SELF.fetch("http://test/v1/receipts/missing-id", {
      method: "DELETE",
      headers: { "X-Receipts-Device": "device-del" },
    });
    expect(res.status).toBe(404);
  });

  it("403s when the device does not own the receipt", async () => {
    const now = Math.floor(Date.now() / 1000);
    const id = crypto.randomUUID();
    await env.DB.prepare(
      `INSERT INTO receipts (id, source_url, url_hash, source_type, source_provider,
                             title, status, device_id, user_id, created_at)
       VALUES (?, ?, ?, 'video', 'youtube', NULL, 'done', 'device-owner', NULL, ?)`
    ).bind(id, "https://yt/own", "h-own", now).run();

    const res = await SELF.fetch(`http://test/v1/receipts/${id}`, {
      method: "DELETE",
      headers: { "X-Receipts-Device": "device-stranger" },
    });
    expect(res.status).toBe(403);
  });
});

describe("daily quota", () => {
  it("returns 429 once the device has hit the cap (3 in tests)", async () => {
    for (let i = 0; i < 3; i++) {
      const res = await SELF.fetch("http://test/v1/receipts", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-quota-A" },
        body: JSON.stringify({ url: `https://www.youtube.com/watch?v=quotaA${i}` }),
      });
      expect(res.status).toBe(200);
    }
    const fourth = await SELF.fetch("http://test/v1/receipts", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-quota-A" },
      body: JSON.stringify({ url: "https://www.youtube.com/watch?v=quotaA3" }),
    });
    expect(fourth.status).toBe(429);
    const body = await fourth.json() as { error_code: string };
    expect(body.error_code).toBe("daily_cap_reached");
  });

  it("does not count cache hits against the cap", async () => {
    const cachedUrl = "https://www.youtube.com/watch?v=globalcache";
    await SELF.fetch("http://test/v1/receipts", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-priming" },
      body: JSON.stringify({ url: cachedUrl }),
    });

    for (let i = 0; i < 3; i++) {
      const r = await SELF.fetch("http://test/v1/receipts", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-quota-B" },
        body: JSON.stringify({ url: cachedUrl }),
      });
      const body = await r.json() as { cached: boolean };
      expect(body.cached).toBe(true);
    }

    for (let i = 0; i < 3; i++) {
      const r = await SELF.fetch("http://test/v1/receipts", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-Receipts-Device": "device-quota-B" },
        body: JSON.stringify({ url: `https://www.youtube.com/watch?v=quotaB${i}` }),
      });
      expect(r.status).toBe(200);
    }
  });
});
