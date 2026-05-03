import { defineWorkersConfig } from "@cloudflare/vitest-pool-workers/config";

export default defineWorkersConfig({
  test: {
    poolOptions: {
      workers: {
        wrangler: {
          configPath: "./wrangler.toml",
          // Use test environment to exclude AI binding (not supported in miniflare)
          env: "test",
        },
        miniflare: {
          // Each test gets a fresh isolated D1; migrations are applied via the
          // `--local` D1 we set up in Task 11. For tests that require a clean
          // schema, we'll re-apply migrations in beforeAll.
          d1Databases: ["DB"],
          kvNamespaces: ["CACHE"],
          r2Buckets: ["ARCHIVE"],
          queueProducers: { INGEST_QUEUE: "crimeboard-ingest-dev", DEEPCHECK_QUEUE: "crimeboard-deepcheck-dev" },
          bindings: {
            APPLE_AUDIENCE: "com.bworthy.crimeboard.test",
            SESSION_SECRET: "test-session-secret-do-not-use-in-prod",
          },
        },
      },
    },
  },
});
