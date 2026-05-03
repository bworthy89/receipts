import { Hono } from "hono";
import { sessionAuthn } from "../middleware/authn.ts";
import type { AppBindings } from "../types.ts";

const me = new Hono<AppBindings>();

interface UserRow {
  id: string;
  email: string | null;
  created_at: number;
  pro_until: number | null;
  feed_mode: "strict" | "balanced";
  selected_topics: string;
  selected_outlets: string;
  excluded_outlets: string;
  notification_prefs: string;
}

function rowToPublic(row: UserRow) {
  return {
    id: row.id,
    email: row.email,
    created_at: row.created_at,
    pro_until: row.pro_until,
    feed_mode: row.feed_mode,
    selected_topics: JSON.parse(row.selected_topics) as string[],
    selected_outlets: JSON.parse(row.selected_outlets) as string[],
    excluded_outlets: JSON.parse(row.excluded_outlets) as string[],
    notification_prefs: JSON.parse(row.notification_prefs) as Record<string, unknown>,
  };
}

me.use("*", sessionAuthn);

me.get("/", async (c) => {
  const row = await c.env.DB.prepare(
    "SELECT id, email, created_at, pro_until, feed_mode, selected_topics, selected_outlets, excluded_outlets, notification_prefs FROM users WHERE id = ?"
  )
    .bind(c.get("userId"))
    .first<UserRow>();
  if (!row) return c.json({ error: "user not found" }, 404);
  return c.json(rowToPublic(row));
});

interface PatchBody {
  feed_mode?: unknown;
  selected_topics?: unknown;
  selected_outlets?: unknown;
  excluded_outlets?: unknown;
  notification_prefs?: unknown;
}

function isStringArray(v: unknown): v is string[] {
  return Array.isArray(v) && v.every((x) => typeof x === "string");
}

me.patch("/", async (c) => {
  const body = (await c.req.json().catch(() => ({}))) as PatchBody;

  const updates: string[] = [];
  const binds: unknown[] = [];

  if (body.feed_mode !== undefined) {
    if (body.feed_mode !== "strict" && body.feed_mode !== "balanced") {
      return c.json({ error: "feed_mode must be 'strict' or 'balanced'" }, 400);
    }
    updates.push("feed_mode = ?");
    binds.push(body.feed_mode);
  }
  if (body.selected_topics !== undefined) {
    if (!isStringArray(body.selected_topics)) {
      return c.json({ error: "selected_topics must be a string array" }, 400);
    }
    updates.push("selected_topics = ?");
    binds.push(JSON.stringify(body.selected_topics));
  }
  if (body.selected_outlets !== undefined) {
    if (!isStringArray(body.selected_outlets)) {
      return c.json({ error: "selected_outlets must be a string array" }, 400);
    }
    updates.push("selected_outlets = ?");
    binds.push(JSON.stringify(body.selected_outlets));
  }
  if (body.excluded_outlets !== undefined) {
    if (!isStringArray(body.excluded_outlets)) {
      return c.json({ error: "excluded_outlets must be a string array" }, 400);
    }
    updates.push("excluded_outlets = ?");
    binds.push(JSON.stringify(body.excluded_outlets));
  }
  if (body.notification_prefs !== undefined) {
    if (
      typeof body.notification_prefs !== "object" ||
      body.notification_prefs === null ||
      Array.isArray(body.notification_prefs)
    ) {
      return c.json({ error: "notification_prefs must be an object" }, 400);
    }
    updates.push("notification_prefs = ?");
    binds.push(JSON.stringify(body.notification_prefs));
  }

  if (updates.length === 0) {
    return c.json({ error: "no fields to update" }, 400);
  }

  binds.push(c.get("userId"));
  await c.env.DB.prepare(`UPDATE users SET ${updates.join(", ")} WHERE id = ?`)
    .bind(...binds)
    .run();

  const row = await c.env.DB.prepare(
    "SELECT id, email, created_at, pro_until, feed_mode, selected_topics, selected_outlets, excluded_outlets, notification_prefs FROM users WHERE id = ?"
  )
    .bind(c.get("userId"))
    .first<UserRow>();
  if (!row) return c.json({ error: "user not found" }, 404);
  return c.json(rowToPublic(row));
});

export default me;
