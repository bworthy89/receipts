import { Hono } from "hono";
import {
  fetchAppleJwks,
  verifyAppleIdentityToken,
  mintSessionToken,
} from "@crimeboard/shared";
import type { AppBindings } from "../types.ts";

const auth = new Hono<AppBindings>();

interface AuthAppleBody {
  identity_token?: unknown;
}

interface UserRow {
  id: string;
  apple_sub: string;
  email: string | null;
  created_at: number;
  pro_until: number | null;
  feed_mode: "strict" | "balanced";
}

auth.post("/apple", async (c) => {
  const body = (await c.req.json().catch(() => ({}))) as AuthAppleBody;
  if (typeof body.identity_token !== "string" || body.identity_token.length === 0) {
    return c.json({ error: "missing identity_token" }, 400);
  }

  const jwks = await fetchAppleJwks(c.env.CACHE);
  let claims;
  try {
    claims = await verifyAppleIdentityToken({
      token: body.identity_token,
      audience: c.env.APPLE_AUDIENCE,
      jwks,
    });
  } catch {
    return c.json({ error: "invalid identity token" }, 401);
  }

  // Upsert: keep an existing user's email if Apple omits it on this sign-in.
  const now = Math.floor(Date.now() / 1000);
  const existing = await c.env.DB.prepare(
    "SELECT id, apple_sub, email, created_at, pro_until, feed_mode FROM users WHERE apple_sub = ?"
  )
    .bind(claims.sub)
    .first<UserRow>();

  let user: UserRow;
  if (existing) {
    // Only update email if Apple gave us a new one (i.e. don't overwrite to NULL).
    if (claims.email && claims.email !== existing.email) {
      await c.env.DB.prepare("UPDATE users SET email = ? WHERE id = ?")
        .bind(claims.email, existing.id)
        .run();
      existing.email = claims.email;
    }
    user = existing;
  } else {
    const id = crypto.randomUUID();
    await c.env.DB.prepare(
      "INSERT INTO users (id, apple_sub, email, created_at) VALUES (?, ?, ?, ?)"
    )
      .bind(id, claims.sub, claims.email ?? null, now)
      .run();
    user = {
      id,
      apple_sub: claims.sub,
      email: claims.email ?? null,
      created_at: now,
      pro_until: null,
      feed_mode: "strict",
    };
  }

  const sessionToken = await mintSessionToken({ userId: user.id, secret: c.env.SESSION_SECRET });

  return c.json({
    session_token: sessionToken,
    user: {
      id: user.id,
      email: user.email,
      created_at: user.created_at,
      pro_until: user.pro_until,
      feed_mode: user.feed_mode,
    },
  });
});

export default auth;
