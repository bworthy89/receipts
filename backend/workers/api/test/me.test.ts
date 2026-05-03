import { describe, it, expect, beforeEach } from "vitest";
import { SELF, env } from "cloudflare:test";
import { mintSessionToken } from "@crimeboard/shared";

const NOW = 1_700_000_000;

beforeEach(async () => {
  await env.DB.exec("DELETE FROM users;");
  await env.DB.prepare(
    "INSERT INTO users (id, apple_sub, email, created_at, feed_mode, selected_topics, selected_outlets, excluded_outlets, notification_prefs) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
  )
    .bind(
      "user-1",
      "001234.abcdef",
      "user@example.com",
      NOW,
      "strict",
      JSON.stringify(["politics"]),
      JSON.stringify(["nytimes"]),
      JSON.stringify([]),
      JSON.stringify({ breaking: true })
    )
    .run();
});

async function authHeader(userId: string): Promise<string> {
  const token = await mintSessionToken({ userId, secret: env.SESSION_SECRET });
  return `Bearer ${token}`;
}

describe("GET /me", () => {
  it("returns the authenticated user's record", async () => {
    const res = await SELF.fetch("http://test/me", {
      headers: { Authorization: await authHeader("user-1") },
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as Record<string, unknown>;
    expect(body.id).toBe("user-1");
    expect(body.email).toBe("user@example.com");
    expect(body.feed_mode).toBe("strict");
    expect(body.selected_topics).toEqual(["politics"]);
    expect(body.selected_outlets).toEqual(["nytimes"]);
    expect(body.notification_prefs).toEqual({ breaking: true });
  });

  it("returns 401 without auth", async () => {
    const res = await SELF.fetch("http://test/me");
    expect(res.status).toBe(401);
  });

  it("returns 404 if the user row was deleted between auth and lookup", async () => {
    const auth = await authHeader("user-1");
    await env.DB.exec("DELETE FROM users;");
    const res = await SELF.fetch("http://test/me", { headers: { Authorization: auth } });
    expect(res.status).toBe(404);
  });
});

describe("PATCH /me", () => {
  it("updates feed_mode and selected_topics, leaves others untouched", async () => {
    const res = await SELF.fetch("http://test/me", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: await authHeader("user-1"),
      },
      body: JSON.stringify({
        feed_mode: "balanced",
        selected_topics: ["politics", "tech"],
      }),
    });
    expect(res.status).toBe(200);

    const row = await env.DB.prepare("SELECT feed_mode, selected_topics, selected_outlets FROM users WHERE id = ?")
      .bind("user-1")
      .first<{ feed_mode: string; selected_topics: string; selected_outlets: string }>();
    expect(row?.feed_mode).toBe("balanced");
    expect(JSON.parse(row!.selected_topics)).toEqual(["politics", "tech"]);
    expect(JSON.parse(row!.selected_outlets)).toEqual(["nytimes"]); // unchanged
  });

  it("rejects feed_mode outside the allowed values", async () => {
    const res = await SELF.fetch("http://test/me", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: await authHeader("user-1"),
      },
      body: JSON.stringify({ feed_mode: "wild" }),
    });
    expect(res.status).toBe(400);
  });

  it("rejects non-array selected_topics", async () => {
    const res = await SELF.fetch("http://test/me", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: await authHeader("user-1"),
      },
      body: JSON.stringify({ selected_topics: "politics" }),
    });
    expect(res.status).toBe(400);
  });
});
