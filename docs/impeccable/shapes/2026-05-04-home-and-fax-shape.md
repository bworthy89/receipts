# Home + Fax — Design Brief

**Status:** confirmed (user-approved 2026-05-04)
**Scope:** Plan 5 — iOS scaffold + Home + Fax surfaces
**Skill:** `$impeccable shape Home and Fax`
**Inputs:** [PRODUCT.md](../../../PRODUCT.md), [DESIGN.md](../../../DESIGN.md), [spec](../../superpowers/specs/2026-05-04-for-real-app-design.md)

---

## 1. Feature Summary

The two iOS surfaces that produce a fax from a pasted URL. **Home** is a single-purpose paste box on a drenched Zesty Lemon surface. **Fax** is a sheet that slides up over Home and streams in claim-by-claim until the verdict arrives. Built so that a twenty-something on a packed L train can paste a link, screenshot the result, and drop it in a group chat before her stop — with one thumb.

## 2. Primary User Action

- **Home:** paste a URL (or tap the clipboard chip) → fax sheet slides up.
- **Fax:** watch claims fill in → final verdict pushes in from top → screenshot or tap Share.

## 3. Design Direction

- **Color strategy:** **Drenched** (per DESIGN.md). Drenched Zesty Lemon yellow surface, depth via color steps within the lemon family.
- **Scene sentence:** *"Twenty-something on a packed L train at 8am, scrolling, sees a wild claim, opens For Real?? to fact-check it before her stop — she has 90 seconds and one thumb."*
  - Forces: high contrast that survives bright ambient (overhead subway lighting through windows), thumb-reachable controls, motion that doesn't demand sustained attention (she might pocket the phone mid-stream and come back).
- **Anchor references:** **Oatly** + **CASETiFY** + **Liquid Death**. Bold color-block packaging, type-as-protagonist, sassy product names, anti-corporate gen-z energy. Triangulated lane: bold-color-block packaging-copy native to a phone screenshot.
- **Carries forward from DESIGN.md:** Drenched Rule, One Voice Rule, No-Mono Rule, No-Shadow Rule, Verdict-Glyph-Plus-Label Rule, AI-Slop Anti.
- **Carries forward from PRODUCT.md anti-references:** AI-slop / ChatGPT chat-bubble / Snopes / NYT / Linear / Duolingo / CRIME BOARD aesthetic — all banned.

## 4. Scope

- **Fidelity:** Production-ready (App Store quality).
- **Breadth:** Two surfaces (Home + Fax). Recent / Settings / Share Extension are out — they belong to Plans 6/7/8.
- **Interactivity:** Shipped-quality SwiftUI components, full state coverage.
- **Time intent:** Polish until it ships. Plan 5 is sized to be ~18–25 tasks.

## 5. Layout Strategy

### Home (drenched Zesty Lemon, full screen)

- **Top corner (right):** Small "Recent" glyph. First-class affordance but tucked. Single tap reveals history list.
- **Vertical center, slightly above:** ONE line of bestie copy in semibold headline weight. Sets voice on first launch and stays consistent across launches.
- **Vertical center:** Large paste box. Generous padding, humanist sans placeholder.
- **Below paste box (conditional):** When clipboard has a URL, a chip appears: *"Check `tiktok.com/@user/...`?"* — single tap analyzes.
- **Below the chip / paste box:** Whitespace (rhythm). Spacing varies; paste box gets more breathing room than the line above.

### Fax (sheet sliding up over Home)

- **Sheet shape with handle** at top, drenched Zesty Lemon inside.
- **Top of sheet:** the verdict slot, pre-allocated. Empty (subtle pulse) during streaming; verdict word pushes in from top when it arrives.
- **Just below verdict:** source metadata in Label weight (*"TIKTOK · @user"*).
- **Body:** three pre-allocated claim card slots in Lemon Cream (one step quieter). Each pulses subtly while waiting; populates as the SSE event arrives.
- **Bottom:** source list (links) + Share button.
- **For `skip` verdicts:** verdict word + bestie commentary only, no claim cards rendered. Short fax. The brevity IS the answer.

## 6. Key States

### Home states

| State | What renders |
|---|---|
| Default (no clipboard URL) | Paste box + bestie line + Recent glyph |
| Clipboard has URL | + Check-this chip below paste box, URL truncated to fit |
| Paste field filled, awaiting analyze | Primary-action emphasis on analyze affordance |
| In-flight (Fax sheet over Home) | Home dimmed / visually-paused beneath the sheet |
| Recent revealed | List overlay: rows with verdict glyph + provider + timestamp |

### Fax states

| State | What renders |
|---|---|
| Initial (just opened, nothing back yet) | Empty fax shell — verdict slot pulses, three claim slots pulse |
| Streaming, partial | Claim N populated; remaining slots still pulse |
| Final (`nope` / `mixed` / `yep`) | Verdict word pushed in, all claim cards filled, Share enabled |
| Final (`skip`) | Verdict word + commentary only, no claim cards |
| Failed | Error state in drenched lemon: friendly bestie error copy + "try again" affordance. Five variants per spec edge cases (`source_unreachable`, `provider_blocked`, `transcription_failed`, `paywalled`, `unsupported_provider`) |
| Cached (re-paste of known URL) | Fully-populated fax appears immediately, no streaming |
| Reduce Motion | Claims instant-place with brief color highlight; verdict appears in-place; no slides, no pushes |

## 7. Interaction Model

**Home:**

- Tap paste box → keyboard up, focus.
- Tap "Check `..." chip → Fax sheet slides up; `POST /v1/receipts` fires.
- Tap analyze with filled paste field → same as the chip path.
- Tap Recent glyph → list overlay reveals; tap a past row → Fax screen for that historical fax.

**Fax:**

- Pull-down → sheet retracts. If streaming, cancel SSE.
- Tap Share → iOS share sheet with rendered fax as image.
- Tap claim source → opens source in Safari (decision deferred; see Open Questions).
- Wait through streaming → claims populate as `claim_final` events arrive.
- Verdict → pushes in from top.

**Motion specifics** (the impeccable craft session resolves exact curves):

- Sheet up: ~350ms ease-out-quart.
- Claim card arrival: each fades + slides up 16pt, ~250ms ease-out-quart, no bounce.
- Verdict push-in: ~280ms ease-out-quint from top, brief settle.
- Cap at 200ms minimum (avoid broken feel) and ~400ms maximum (avoid sluggish).
- **Reduce Motion variant:** instant placements + 100ms color-highlight beat.

## 8. Content Requirements

**Home copy:**

- Paste placeholder: short (one to three words).
- Bestie line above paste: three candidates listed in §10 Open Questions; pick during a craft critique pass with the actual visual on screen.
- Clipboard chip: *"Check this link?"* + truncated URL in Label weight beneath.
- Recent: glyph only, no text label (small, top-right).

**Fax copy** (mostly backend-supplied):

- Verdict word: NOPE / MIXED / YEP / SKIP — display weight, all caps.
- Verdict commentary: 1–2 bestie sentences from backend `final_commentary`.
- Claim card label: *"CLAIM 1 OF 3"* — Label weight, slight tracking.
- Claim text + verdict glyph + commentary: backend-supplied.
- Source link: source title (truncated if long), Label weight.
- Share button: *"Share"* or icon-only.

**Error copy** (locked from spec §6):

- *"Couldn't reach this one — link may be private or pulled."*
- *"TikTok's playing hard to get. Try again in a sec."*
- *"Couldn't make out the audio."*
- *"Paywall blocked us — try a public mirror."*
- *"We don't speak that platform yet — coming later."*

## 9. Recommended References

For Plan 5 implementation:

- **PRODUCT.md** — strategic context (bestie tone, screenshot-bait, format-aware honesty).
- **DESIGN.md** — visual contract (Zesty Lemon palette, named rules, type direction).
- **For Real?? spec** (`docs/superpowers/specs/2026-05-04-for-real-app-design.md`) — surface map, state coverage, edge cases.
- **Apple HIG**: SwiftUI sheet presentation, animation primitives, Dynamic Type, Reduce Motion, VoiceOver labeling.

## 10. Open Questions

The implementer (or a `$impeccable critique` pass) resolves these during build:

1. **Recent glyph placement** — top-right (right-thumb reach) or top-left? Working assumption: top-right.
2. **Bestie copy on Home** — three candidates: *"What's this video on about?"* / *"Drop a link, bestie."* / *"Sus video? Run it."* Pick with the actual visual on screen.
3. **Source link tap behavior** — Safari handoff vs in-app `SFSafariViewController`. Safari is simpler; in-app preserves session.
4. **Background-cancel UX** — when the user backgrounds the app >30s mid-stream and the SSE cancels, what's the come-back state? Cleared paste field, or paste field still showing the last URL with a "retry?" affordance?
5. **The pre-allocated claim-slot pulse cadence** — frequency / depth of the breathing pulse. Working default: 0.4–0.6 alpha range, 1.5–2s cycle; resolve by eye in craft.
6. **Live Activity / Dynamic Island** — out of MVP per spec, but flagged as a high-leverage addition for v1.1. No seam stubbed in Plan 5.
