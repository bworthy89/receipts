import { describe, it, expect } from "vitest";
import { classifyUrl } from "./url.ts";

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
