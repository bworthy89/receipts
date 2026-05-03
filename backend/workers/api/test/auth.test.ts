import { describe, it, expect, beforeAll, beforeEach } from "vitest";
import { SELF, env } from "cloudflare:test";
import { generateKeyPair, exportJWK, SignJWT, type KeyLike } from "jose";

let privateKey: KeyLike;
let publicJwk: { kty: string; n: string; e: string; kid: string; alg: string; use: string };

beforeAll(async () => {
  const { publicKey, privateKey: priv } = await generateKeyPair("RS256", { extractable: true });
  privateKey = priv;
  const jwk = await exportJWK(publicKey);
  publicJwk = {
    kty: "RSA",
    n: jwk.n!,
    e: jwk.e!,
    kid: "test-key-1",
    alg: "RS256",
    use: "sig",
  };

  // Apply the DB schema so the users table exists in miniflare's in-memory D1.
  await env.DB.prepare(
    "CREATE TABLE IF NOT EXISTS users (id TEXT PRIMARY KEY, apple_sub TEXT UNIQUE, email TEXT, created_at INTEGER NOT NULL, pro_until INTEGER, feed_mode TEXT NOT NULL DEFAULT 'strict' CHECK (feed_mode IN ('strict', 'balanced')), selected_topics TEXT NOT NULL DEFAULT '[]', selected_outlets TEXT NOT NULL DEFAULT '[]', excluded_outlets TEXT NOT NULL DEFAULT '[]', notification_prefs TEXT NOT NULL DEFAULT '{}') STRICT"
  ).run();
});

beforeEach(async () => {
  // Pre-seed KV with our test JWKS so fetchAppleJwks hits cache and never networks.
  await env.CACHE.put("apple-jwks", JSON.stringify({ keys: [publicJwk] }));
  // Clear users between tests for isolation.
  await env.DB.exec("DELETE FROM users;");
});

async function makeAppleToken(sub: string, email: string | null = null): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const builder = new SignJWT({ ...(email ? { email } : {}) })
    .setProtectedHeader({ alg: "RS256", kid: "test-key-1" })
    .setIssuer("https://appleid.apple.com")
    .setAudience(env.APPLE_AUDIENCE)
    .setSubject(sub)
    .setIssuedAt(now)
    .setExpirationTime(now + 600);
  return builder.sign(privateKey);
}

describe("POST /auth/apple", () => {
  it("creates a new user on first sign-in and returns a session token", async () => {
    const identityToken = await makeAppleToken("001234.abcdef.5678", "user@example.com");
    const res = await SELF.fetch("http://test/auth/apple", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ identityToken }),
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { sessionToken: string; user: { id: string; email: string | null } };
    expect(body.sessionToken).toMatch(/^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/);
    expect(body.user.email).toBe("user@example.com");

    const row = await env.DB.prepare("SELECT id, apple_sub, email FROM users WHERE apple_sub = ?")
      .bind("001234.abcdef.5678")
      .first();
    expect(row).toBeTruthy();
    expect(row!.email).toBe("user@example.com");
  });

  it("reuses the existing user on subsequent sign-ins (no duplicate row)", async () => {
    const t1 = await makeAppleToken("001234.abcdef.5678", "user@example.com");
    await SELF.fetch("http://test/auth/apple", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ identityToken: t1 }),
    });
    // Apple omits email on subsequent sign-ins — verify we don't overwrite it with null.
    const t2 = await makeAppleToken("001234.abcdef.5678", null);
    const res = await SELF.fetch("http://test/auth/apple", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ identityToken: t2 }),
    });
    expect(res.status).toBe(200);

    const rows = await env.DB.prepare("SELECT id, email FROM users WHERE apple_sub = ?")
      .bind("001234.abcdef.5678")
      .all();
    expect(rows.results.length).toBe(1);
    expect(rows.results[0]!.email).toBe("user@example.com");
  });

  it("returns 400 when body is missing identityToken", async () => {
    const res = await SELF.fetch("http://test/auth/apple", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({}),
    });
    expect(res.status).toBe(400);
  });

  it("returns 401 when identityToken is invalid", async () => {
    const res = await SELF.fetch("http://test/auth/apple", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ identityToken: "not.a.real.token" }),
    });
    expect(res.status).toBe(401);
  });
});
