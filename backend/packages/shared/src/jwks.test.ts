import { describe, it, expect, vi, beforeEach } from "vitest";
import { fetchAppleJwks } from "./jwks.ts";

const MOCK_JWKS = {
  keys: [
    {
      kty: "RSA",
      kid: "test-key-id",
      use: "sig",
      alg: "RS256",
      n: "mock-modulus",
      e: "AQAB",
    },
  ],
};

function makeKvStub() {
  const store = new Map<string, string>();
  return {
    store,
    kv: {
      get: vi.fn(async (key: string) => store.get(key) ?? null),
      put: vi.fn(async (key: string, value: string, _opts?: unknown) => {
        store.set(key, value);
      }),
    } as unknown as KVNamespace,
  };
}

describe("fetchAppleJwks", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it("returns parsed JWKS on cache miss and stores it in KV", async () => {
    const fetchMock = vi.fn(async () =>
      new Response(JSON.stringify(MOCK_JWKS), { status: 200 })
    );
    vi.stubGlobal("fetch", fetchMock);

    const { kv, store } = makeKvStub();
    const jwks = await fetchAppleJwks(kv);

    expect(jwks).toEqual(MOCK_JWKS);
    expect(fetchMock).toHaveBeenCalledOnce();
    expect(store.get("apple-jwks")).toBe(JSON.stringify(MOCK_JWKS));
  });

  it("returns cached JWKS without calling fetch on cache hit", async () => {
    const fetchMock = vi.fn();
    vi.stubGlobal("fetch", fetchMock);

    const { kv, store } = makeKvStub();
    store.set("apple-jwks", JSON.stringify(MOCK_JWKS));

    const jwks = await fetchAppleJwks(kv);

    expect(jwks).toEqual(MOCK_JWKS);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("throws if Apple returns non-200", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => new Response("oops", { status: 503 }))
    );

    const { kv } = makeKvStub();
    await expect(fetchAppleJwks(kv)).rejects.toThrow(/Apple JWKS/);
  });
});
