import type { Env } from "@crimeboard/shared";

/** Hono variables stashed by middleware. */
export interface Variables {
  userId: string;
}

export type AppBindings = { Bindings: Env; Variables: Variables };
