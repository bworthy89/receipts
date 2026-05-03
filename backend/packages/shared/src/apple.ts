import { jwtVerify, importJWK, type JWK } from "jose";
import type { AppleJwks } from "./jwks.ts";

const APPLE_ISSUER = "https://appleid.apple.com";

export interface AppleClaims {
  sub: string;
  email?: string;
  email_verified?: boolean;
  iat: number;
  exp: number;
}

export interface VerifyAppleParams {
  token: string;
  audience: string;
  jwks: AppleJwks;
}

/**
 * Verify an Apple identity token against the supplied JWKS.
 * Throws if signature, issuer, audience, or expiry is invalid.
 */
export async function verifyAppleIdentityToken(params: VerifyAppleParams): Promise<AppleClaims> {
  // Find the right key by kid from the JWT header.
  const { token, audience, jwks } = params;
  const headerSegment = token.split(".")[0];
  if (!headerSegment) {
    throw new Error("Apple token: malformed (no header segment)");
  }
  const header = JSON.parse(atob(headerSegment.replace(/-/g, "+").replace(/_/g, "/"))) as { kid?: string };
  if (!header.kid) {
    throw new Error("Apple token: missing kid in header");
  }
  const jwk = jwks.keys.find((k) => k.kid === header.kid);
  if (!jwk) {
    throw new Error(`Apple token: no key matches kid ${header.kid}`);
  }
  const key = await importJWK(jwk as JWK, "RS256");

  const { payload } = await jwtVerify(token, key, {
    issuer: APPLE_ISSUER,
    audience,
  });

  if (typeof payload.sub !== "string" || payload.sub.length === 0) {
    throw new Error("Apple token: missing sub");
  }

  return {
    sub: payload.sub,
    email: typeof payload.email === "string" ? payload.email : undefined,
    email_verified: typeof payload.email_verified === "boolean" ? payload.email_verified : undefined,
    iat: payload.iat ?? 0,
    exp: payload.exp ?? 0,
  };
}
