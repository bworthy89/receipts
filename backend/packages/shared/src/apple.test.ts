import { describe, it, expect, beforeAll } from "vitest";
import { generateKeyPair, exportJWK, SignJWT, type KeyLike } from "jose";
import { verifyAppleIdentityToken } from "./apple.ts";

// We generate a keypair at test-time so we can sign tokens that pass real cryptographic verification.
let privateKey: KeyLike;
let publicJwk: { kty: string; n: string; e: string; kid: string; alg: string; use: string };

const AUDIENCE = "com.bworthy.crimeboard";

beforeAll(async () => {
  const { publicKey, privateKey: priv } = await generateKeyPair("RS256", { extractable: true });
  privateKey = priv;
  const jwk = await exportJWK(publicKey);
  publicJwk = {
    kty: "RSA",
    n: jwk.n!,
    e: jwk.e!,
    kid: "test-key-1",
    alg: "RS256",
    use: "sig",
  };
});

async function makeToken(overrides: Partial<{ sub: string; aud: string; iss: string; email: string; expSeconds: number }> = {}) {
  const now = Math.floor(Date.now() / 1000);
  const builder = new SignJWT({ email: overrides.email })
    .setProtectedHeader({ alg: "RS256", kid: "test-key-1" })
    .setIssuer(overrides.iss ?? "https://appleid.apple.com")
    .setAudience(overrides.aud ?? AUDIENCE)
    .setSubject(overrides.sub ?? "001234.abcdef.5678")
    .setIssuedAt(now)
    .setExpirationTime(now + (overrides.expSeconds ?? 600));
  return builder.sign(privateKey);
}

describe("verifyAppleIdentityToken", () => {
  it("returns claims for a valid token", async () => {
    const token = await makeToken({ email: "user@example.com" });
    const claims = await verifyAppleIdentityToken({
      token,
      audience: AUDIENCE,
      jwks: { keys: [publicJwk] },
    });
    expect(claims.sub).toBe("001234.abcdef.5678");
    expect(claims.email).toBe("user@example.com");
  });

  it("rejects a token with the wrong audience", async () => {
    const token = await makeToken({ aud: "com.someoneelse.app" });
    await expect(
      verifyAppleIdentityToken({ token, audience: AUDIENCE, jwks: { keys: [publicJwk] } })
    ).rejects.toThrow();
  });

  it("rejects a token with the wrong issuer", async () => {
    const token = await makeToken({ iss: "https://evil.example.com" });
    await expect(
      verifyAppleIdentityToken({ token, audience: AUDIENCE, jwks: { keys: [publicJwk] } })
    ).rejects.toThrow();
  });

  it("rejects an expired token", async () => {
    const token = await makeToken({ expSeconds: -10 });
    await expect(
      verifyAppleIdentityToken({ token, audience: AUDIENCE, jwks: { keys: [publicJwk] } })
    ).rejects.toThrow();
  });

  it("returns claims when email is absent (Apple omits it after first sign-in)", async () => {
    const token = await makeToken();
    const claims = await verifyAppleIdentityToken({
      token,
      audience: AUDIENCE,
      jwks: { keys: [publicJwk] },
    });
    expect(claims.sub).toBe("001234.abcdef.5678");
    expect(claims.email).toBeUndefined();
  });
});
