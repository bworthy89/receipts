// Vitest setup file — runs once per test worker before any test file.
// Applies all D1 migrations from the migrations/ directory to the in-memory test D1
// so every test starts with the full schema. Without this, miniflare's D1 starts
// empty and tests would have to CREATE TABLE manually.

import { applyD1Migrations, env } from "cloudflare:test";

await applyD1Migrations(env.DB, env.TEST_MIGRATIONS);
