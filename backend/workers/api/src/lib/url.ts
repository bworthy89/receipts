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

const TRACKING_PARAMS = [
  "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
  "fbclid", "gclid", "mc_cid", "mc_eid", "igshid", "_branch_match_id",
];

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

export function normalizeUrl(input: string): string {
  let url: URL;
  try {
    url = new URL(input);
  } catch {
    return input;
  }
  for (const param of TRACKING_PARAMS) url.searchParams.delete(param);
  url.hash = "";
  url.host = url.host.toLowerCase();
  if (url.pathname.length > 1 && url.pathname.endsWith("/")) {
    url.pathname = url.pathname.slice(0, -1);
  }
  return url.toString();
}

export async function hashUrl(input: string): Promise<string> {
  const encoded = new TextEncoder().encode(normalizeUrl(input));
  const buf = await crypto.subtle.digest("SHA-256", encoded);
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
