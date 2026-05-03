import { describe, it, expect } from "vitest";
import { SELF, env } from "cloudflare:test";
import { Hono } from "hono";
import { mintSessionToken } from "@crimeboard/shared";
import { sessionAuthn } from "../src/middleware/authn.ts";
import type { AppBindings } from "../src/types.ts";

// Mount a tiny test app inside the test that uses the middleware so we don't
// need to wire it into the production router until the next task.
function makeTestApp() {
  const app = new Hono<AppBindings>();
  app.use("/protected/*", sessionAuthn);
  app.get("/protected/whoami", (c) => c.json({ userId: c.get("userId") }));
  return app;
}

describe("sessionAuthn middleware", () => {
  it("returns 401 when Authorization header is missing", async () => {
    const app = makeTestApp();
    const res = await app.request("/protected/whoami", {}, env);
    expect(res.status).toBe(401);
  });

  it("returns 401 when Authorization header is malformed", async () => {
    const app = makeTestApp();
    const res = await app.request(
      "/protected/whoami",
      { headers: { Authorization: "NotBearer xyz" } },
      env
    );
    expect(res.status).toBe(401);
  });

  it("returns 401 when token is invalid", async () => {
    const app = makeTestApp();
    const res = await app.request(
      "/protected/whoami",
      { headers: { Authorization: "Bearer not.a.real.token" } },
      env
    );
    expect(res.status).toBe(401);
  });

  it("attaches userId from a valid token and proceeds", async () => {
    const token = await mintSessionToken({ userId: "user-abc", secret: env.SESSION_SECRET });
    const app = makeTestApp();
    const res = await app.request(
      "/protected/whoami",
      { headers: { Authorization: `Bearer ${token}` } },
      env
    );
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ userId: "user-abc" });
  });
});
