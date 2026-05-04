import { Hono } from "hono";
import auth from "./routes/auth.ts";
import me from "./routes/me.ts";
import receipts from "./routes/receipts.ts";
import type { AppBindings } from "./types.ts";

const app = new Hono<AppBindings>();

app.get("/health", (c) => c.json({ ok: true, service: "crimeboard-api" }));

app.route("/auth", auth);
app.route("/me", me);
app.route("/v1/receipts", receipts);

export default app;
