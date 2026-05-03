const APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys";
const KV_KEY = "apple-jwks";
const CACHE_TTL_SECONDS = 60 * 60; // 1 hour

export interface AppleJwks {
  keys: Array<{
    kty: string;
    kid: string;
    use: string;
    alg: string;
    n: string;
    e: string;
  }>;
}

/**
 * Fetch Apple's JWKS, caching it in KV for CACHE_TTL_SECONDS.
 * Subsequent calls within the TTL hit the cache and don't network.
 */
export async function fetchAppleJwks(kv: KVNamespace): Promise<AppleJwks> {
  const cached = await kv.get(KV_KEY);
  if (cached !== null) {
    return JSON.parse(cached) as AppleJwks;
  }

  const response = await fetch(APPLE_JWKS_URL);
  if (!response.ok) {
    throw new Error(`Apple JWKS fetch failed: ${response.status} ${response.statusText}`);
  }
  const body = await response.text();
  // Don't await the put — fire-and-forget keeps auth latency minimal.
  // KV's put returns a Promise; in a Worker we'd usually use ctx.waitUntil(),
  // but the caller doesn't have ctx here. Awaiting is fine for a foundation.
  await kv.put(KV_KEY, body, { expirationTtl: CACHE_TTL_SECONDS });
  return JSON.parse(body) as AppleJwks;
}
