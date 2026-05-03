declare module "cloudflare:test" {
  // Make ProvidedEnv match our shared Env so tests get full type-safety on env bindings.
  interface ProvidedEnv extends import("@crimeboard/shared").Env {
    /** D1 migrations injected via vitest.config.ts; applied by test/apply-migrations.ts. */
    TEST_MIGRATIONS: import("@cloudflare/vitest-pool-workers/config").D1Migration[];
  }
}
