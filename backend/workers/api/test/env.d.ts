declare module "cloudflare:test" {
  // Make ProvidedEnv match our shared Env so tests get full type-safety on env bindings.
  // eslint-disable-next-line @typescript-eslint/no-empty-object-type
  interface ProvidedEnv extends import("@crimeboard/shared").Env {}

  // SELF is provided by @cloudflare/vitest-pool-workers; this re-exports it
  export declare const SELF: Fetcher;
}
