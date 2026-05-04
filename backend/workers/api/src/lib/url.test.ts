import { describe, it, expect } from "vitest";
import { classifyUrl, normalizeUrl, hashUrl } from "./url.ts";

describe("classifyUrl", () => {
  it("recognizes TikTok video URLs", () => {
    const result = classifyUrl("https://www.tiktok.com/@user/video/1234567890123456789");
    expect(result).toEqual({
      source_type: "video",
      source_provider: "tiktok",
      normalized_url: "https://www.tiktok.com/@user/video/1234567890123456789",
    });
  });

  it("recognizes vm.tiktok.com short links", () => {
    const result = classifyUrl("https://vm.tiktok.com/ZMabcdef/");
    expect(result?.source_provider).toBe("tiktok");
  });

  it("recognizes YouTube watch URLs", () => {
    const result = classifyUrl("https://www.youtube.com/watch?v=dQw4w9WgXcQ");
    expect(result?.source_provider).toBe("youtube");
    expect(result?.source_type).toBe("video");
  });

  it("recognizes youtu.be short links", () => {
    expect(classifyUrl("https://youtu.be/dQw4w9WgXcQ")?.source_provider).toBe("youtube");
  });

  it("recognizes YouTube Shorts URLs", () => {
    expect(classifyUrl("https://www.youtube.com/shorts/abc123")?.source_provider).toBe("youtube");
  });

  it("treats a normal news article URL as an article", () => {
    const result = classifyUrl("https://www.nytimes.com/2026/05/04/some-article.html");
    expect(result).toEqual({
      source_type: "article",
      source_provider: "article",
      normalized_url: "https://www.nytimes.com/2026/05/04/some-article.html",
    });
  });

  it("returns null for Instagram (unsupported provider)", () => {
    expect(classifyUrl("https://www.instagram.com/reel/abc/")).toBeNull();
  });

  it("returns null for Facebook (unsupported provider)", () => {
    expect(classifyUrl("https://www.facebook.com/watch/?v=123")).toBeNull();
  });

  it("returns null for X / Twitter video (out of scope)", () => {
    expect(classifyUrl("https://x.com/user/status/123/video/1")).toBeNull();
  });

  it("returns null for malformed URLs", () => {
    expect(classifyUrl("not a url")).toBeNull();
    expect(classifyUrl("")).toBeNull();
  });

  it("returns null for non-https schemes", () => {
    expect(classifyUrl("ftp://example.com/file")).toBeNull();
    expect(classifyUrl("javascript:alert(1)")).toBeNull();
  });
});

describe("normalizeUrl", () => {
  it("strips utm_* and similar tracking params", () => {
    expect(normalizeUrl("https://example.com/page?utm_source=tw&utm_medium=x&id=42"))
      .toBe("https://example.com/page?id=42");
  });

  it("strips fragment", () => {
    expect(normalizeUrl("https://example.com/page#section")).toBe("https://example.com/page");
  });

  it("lowercases the host but not the path", () => {
    expect(normalizeUrl("https://YouTube.com/watch?v=ABC123"))
      .toBe("https://youtube.com/watch?v=ABC123");
  });

  it("removes a trailing slash from the path (not from root)", () => {
    expect(normalizeUrl("https://example.com/page/")).toBe("https://example.com/page");
    expect(normalizeUrl("https://example.com/")).toBe("https://example.com/");
  });

  it("returns the input unchanged if it cannot be parsed", () => {
    expect(normalizeUrl("not a url")).toBe("not a url");
  });
});

describe("hashUrl", () => {
  it("returns a 64-character lowercase hex sha256", async () => {
    const h = await hashUrl("https://example.com/page");
    expect(h).toMatch(/^[0-9a-f]{64}$/);
  });

  it("produces the same hash for the same input", async () => {
    const a = await hashUrl("https://example.com/page");
    const b = await hashUrl("https://example.com/page");
    expect(a).toBe(b);
  });

  it("produces different hashes for different inputs", async () => {
    const a = await hashUrl("https://example.com/a");
    const b = await hashUrl("https://example.com/b");
    expect(a).not.toBe(b);
  });
});
