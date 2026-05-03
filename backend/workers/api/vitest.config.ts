import { defineWorkersConfig, readD1Migrations } from "@cloudflare/vitest-pool-workers/config";
import path from "node:path";

// Read all migrations from the monorepo's migrations directory at config-load time.
// They get passed to miniflare as a binding so the test setup file can apply them
// to the in-memory D1 before each test file runs.
const migrationsDir = path.resolve(__dirname, "../../migrations");
const migrations = await readD1Migrations(migrationsDir);

export default defineWorkersConfig({
  test: {
    setupFiles: ["./test/apply-migrations.ts"],
    poolOptions: {
      workers: {
        wrangler: { configPath: "./wrangler.toml" },
        miniflare: {
          d1Databases: ["DB"],
          kvNamespaces: ["CACHE"],
          r2Buckets: ["ARCHIVE"],
          queueProducers: { INGEST_QUEUE: "crimeboard-ingest-dev", DEEPCHECK_QUEUE: "crimeboard-deepcheck-dev" },
          bindings: {
            APPLE_AUDIENCE: "com.bworthy.crimeboard.test",
            SESSION_SECRET: "test-session-secret-do-not-use-in-prod",
            TEST_MIGRATIONS: migrations,
          },
        },
      },
    },
  },
});
