import type { MiddlewareHandler } from "hono";
import { verifySessionToken } from "@crimeboard/shared";
import type { AppBindings } from "../types.ts";

export const sessionAuthn: MiddlewareHandler<AppBindings> = async (c, next) => {
  const auth = c.req.header("Authorization");
  if (!auth || !auth.startsWith("Bearer ")) {
    return c.json({ error: "unauthorized" }, 401);
  }
  const token = auth.slice("Bearer ".length).trim();
  if (token.length === 0) {
    return c.json({ error: "unauthorized" }, 401);
  }
  try {
    const claims = await verifySessionToken({ token, secret: c.env.SESSION_SECRET });
    c.set("userId", claims.userId);
  } catch {
    return c.json({ error: "unauthorized" }, 401);
  }
  await next();
  return;
};
