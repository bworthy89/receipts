export type SourceType = "video" | "article";
export type SourceProvider = "tiktok" | "youtube" | "article";

export interface ClassifiedUrl {
  source_type: SourceType;
  source_provider: SourceProvider;
  normalized_url: string;
}

const TIKTOK_HOSTS = new Set(["tiktok.com", "www.tiktok.com", "vm.tiktok.com", "vt.tiktok.com", "m.tiktok.com"]);
const YOUTUBE_HOSTS = new Set(["youtube.com", "www.youtube.com", "m.youtube.com", "youtu.be"]);
const UNSUPPORTED_HOSTS = new Set([
  "instagram.com", "www.instagram.com",
  "facebook.com", "www.facebook.com", "fb.watch",
  "x.com", "twitter.com", "www.twitter.com",
  "bsky.app",
]);

export function classifyUrl(input: string): ClassifiedUrl | null {
  let url: URL;
  try {
    url = new URL(input);
  } catch {
    return null;
  }

  if (url.protocol !== "https:" && url.protocol !== "http:") return null;

  const host = url.host.toLowerCase();

  if (UNSUPPORTED_HOSTS.has(host)) return null;

  if (TIKTOK_HOSTS.has(host)) {
    return { source_type: "video", source_provider: "tiktok", normalized_url: url.toString() };
  }

  if (YOUTUBE_HOSTS.has(host)) {
    return { source_type: "video", source_provider: "youtube", normalized_url: url.toString() };
  }

  // Default: treat as article. Plan 2 may add extra rejections (e.g., known paywalled
  // domains) but for Plan 1 anything that isn't unsupported and isn't a known video
  // host is an article.
  return { source_type: "article", source_provider: "article", normalized_url: url.toString() };
}
