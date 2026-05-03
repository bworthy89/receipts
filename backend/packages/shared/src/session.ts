import { sign, verify } from "hono/jwt";

export interface SessionClaims {
  userId: string;
  iat: number;
  exp: number;
}

export interface MintParams {
  userId: string;
  secret: string;
  /** Token lifetime in seconds. Default: 30 days. Pass a negative value for an already-expired token (testing only). */
  expiresInSeconds?: number;
}

export interface VerifyParams {
  token: string;
  secret: string;
}

const DEFAULT_EXPIRY_SECONDS = 60 * 60 * 24 * 30; // 30 days

export async function mintSessionToken(params: MintParams): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const expiresIn = params.expiresInSeconds ?? DEFAULT_EXPIRY_SECONDS;
  const payload = {
    userId: params.userId,
    iat: now,
    exp: now + expiresIn,
  };
  return sign(payload, params.secret, "HS256");
}

export async function verifySessionToken(params: VerifyParams): Promise<SessionClaims> {
  // hono/jwt's verify throws on invalid signature, malformed token, or expired exp.
  const decoded = await verify(params.token, params.secret, "HS256");
  const obj = decoded as Record<string, unknown>;
  if (typeof obj.userId !== "string" || obj.userId.length === 0) {
    throw new Error("Session token missing userId claim");
  }
  return {
    userId: obj.userId,
    iat: obj.iat as number,
    exp: obj.exp as number,
  };
}
