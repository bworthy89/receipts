import { describe, it, expect } from "vitest";
import { mintSessionToken, verifySessionToken } from "./session.ts";

const SECRET = "test-secret-do-not-use-in-prod";

describe("session token", () => {
  it("round-trips a user id", async () => {
    const token = await mintSessionToken({ userId: "user-123", secret: SECRET });
    const claims = await verifySessionToken({ token, secret: SECRET });
    expect(claims.userId).toBe("user-123");
  });

  it("rejects a token signed with a different secret", async () => {
    const token = await mintSessionToken({ userId: "user-123", secret: SECRET });
    await expect(
      verifySessionToken({ token, secret: "wrong-secret" })
    ).rejects.toThrow();
  });

  it("rejects a tampered token", async () => {
    const token = await mintSessionToken({ userId: "user-123", secret: SECRET });
    const tampered = token.slice(0, -2) + "XX";
    await expect(
      verifySessionToken({ token: tampered, secret: SECRET })
    ).rejects.toThrow();
  });

  it("rejects an expired token", async () => {
    const token = await mintSessionToken({
      userId: "user-123",
      secret: SECRET,
      expiresInSeconds: -10, // already expired
    });
    await expect(
      verifySessionToken({ token, secret: SECRET })
    ).rejects.toThrow();
  });
});
