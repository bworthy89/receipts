<!-- SEED — re-run $impeccable document once Plan 5 lands SwiftUI code, to extract real tokens, components, and to generate the .impeccable/design.json sidecar. -->
---
name: For Real??
description: A sassy iOS fact-check utility — drenched lemon yellow, humanist sans, the fax is the artifact.
---

# Design System: For Real??

## 1. Overview

**Creative North Star: "The Drenched Lemon Fax"**

For Real?? produces one artifact: **the fax** — a fact-check verdict you can screenshot into a group chat. The visual system supports that one job and rejects every adjacent reflex.

The system commits to a **drenched yellow surface** (Zesty Lemon — bright lemon to muted olive) carried by **a single humanist sans** across the entire app. Color is the substrate, not a decoration. Type is the protagonist; copy carries the layout. The fax is bold, type-forward, and unmistakable as a thumbnail in iMessage.

This system explicitly rejects:

- **The "obvious AI" aesthetic** — cream-and-sage palettes, ✨ sparkle icons, frosted-glass cards, "AI-native" SaaS marketing. The single most-direct anti.
- **Generic chat-bubble UI** — ChatGPT / Claude-style centered chat windows. The fax is an artifact, not a conversation.
- **Institutional fact-check sites** (Snopes, PolitiFact) — narrow columns, stock photos, "we are the truth referee" tone.
- **Broadsheet reverence** (Apple News, NYT) — serif solemnity, publisher-logo authority.
- **Productivity SaaS slickness** (Linear, Notion) — sleek-but-faceless. We're a utility, not a tool.
- **The retired CRIME BOARD aesthetic** — cork-board, manila folders, polaroids, push pins, red string, stamps, monospace receipt-printer chrome. This metaphor is dead and shouldn't reappear.

The aesthetic anchor is **Oatly** — packaging copy as design, sassy type-forward layouts, color as identity. The fax should feel related to an Oatly carton: drenched in its color, copy the protagonist, no hidden cleverness.

**Key Characteristics:**
- Drenched Zesty Lemon surface — color IS the substrate
- One humanist sans family across the entire app — no mono, no serif
- Choreographed motion: the streaming claim-fill is the hero
- Type-forward layout — copy carries the design, no decorative chrome
- Flat, no shadows; depth is steps within the lemon family
- High contrast for screenshot legibility at iMessage-thumbnail size

## 2. Colors

A four-step yellow palette anchored on Zesty Lemon — bright lemon as the surface, drifting through cream and pale olive into deep olive for grounded chrome.

### Primary

- **Zesty Lemon** (#FFFF66) — the drenched surface. The fax IS this color. Used as the primary background of the fax card, the home paste screen, the Recent list — the substrate everything sits on.

### Tertiary

- **Lemon Cream** (#FFE566) — slightly muted lemon for nested surfaces inside the fax (claim-card backgrounds, paste-from-clipboard chip). One step quieter than Zesty Lemon, so claim cards read as nested without leaving the surface color family.
- **Lemon Sage** (#D6D58B) — pale olive-green for tertiary surfaces, inactive states, dividers. Same hue family, lower vibrancy.
- **Olive Anchor** (#B3B347) — deep olive for grounded chrome (status bar tints, secondary type on light surfaces, key-line accents). The dark end of the same hue family.

### Neutral

- **Charcoal** *(value to be resolved during implementation — warm near-black, OKLCH ~18% L / ~0.01 C / ~95° H — explicitly NOT `#000`)*: body type and verdict display type on Zesty Lemon. Tinted toward yellow so it reads as belonging to the palette, not as foreign black.

### Named Rules

**The Drenched Rule.** The surface IS the color. Zesty Lemon is the substrate of every screen. The fax doesn't sit on white with a yellow accent; the fax IS yellow, and white never appears as a background. If you reach for white "for breathing room," the layout is wrong, not the palette.

**The No-Pure-Black, No-White-Backgrounds Rule.** Neither `#000` nor any `#fff`-as-surface ever appears. All neutrals carry trace warmth toward yellow.

**The Verdict-Glyph-Plus-Label Rule.** Verdict identity (`nope`, `mixed`, `yep`, `skip`) carries text label, glyph (❌🤷✅🤔), and structural placement — never color alone. iMessage thumbnail compression is brutal; a fax must remain legible at thumbnail size on a yellow-on-yellow surface.

## 3. Typography

**Family:** *[a contemporary humanist sans, to be chosen at implementation. Direction: warm, opinionated, slightly editorial — NOT a tech-startup geometric (Inter, Geist, JetBrains) and NOT a Material/Roboto-like neutral. Reference points: GT America, Söhne, ABC Diatype, Founders Grotesk — and the actual Oatly typeface (Söhne-adjacent) is a directional anchor.]*

**Character:** One typographic voice across the whole app. Headlines, body, labels, timestamps — all the same family. Hierarchy is weight-and-size, never face-change. Explicitly **no monospace receipt-printer chrome** — even though the schema is named `receipts`, the user never sees mono. The brand is humanist warmth, not utility-terminal.

### Hierarchy

*Sizes are seed-mode placeholders; iOS Dynamic Type ramp will be authoritative.*

- **Verdict Display** (humanist sans, heavy weight, ~48–72pt, tight tracking): the verdict word on the fax (NOPE / MIXED / YEP / SKIP). The single largest type element on any screen — the screenshot's centerpiece.
- **Headline** (humanist sans, semibold, ~24–28pt): claim text on each claim card; primary copy on the home paste screen.
- **Body** (humanist sans, regular, ~16–17pt, ~1.4 line-height, capped at 65–75ch): bestie commentary lines, source titles.
- **Label** (humanist sans, medium, ~12–13pt, slight tracking, often UPPERCASE): metadata — timestamp, source provider, claim position numbers ("CLAIM 1 OF 3").

### Named Rules

**The One Voice Rule.** One humanist sans family across the entire app. No mono. No serif. No "decorative" face for accents. Hierarchy comes from weight + size, not from face changes.

**The Verdict-Carries-The-Type Rule.** The verdict word (NOPE / MIXED / YEP / SKIP) is always the largest type on the screen. Bestie commentary, sources, timestamps — all subordinate. If a screenshot compresses to a thumbnail and you can't read the verdict in one glance, the type hierarchy is wrong.

**The No-Mono Rule.** Monospace is forbidden in user-facing UI. The codebase is named `receipts` but the user-facing artifact is *the fax* and the visual brand is humanist. Receipt-printer aesthetics — register-tape mono, dotted tear-lines, "TOTAL" framing — never appear. This is the crisp anti the typography spec defends.

## 4. Elevation

**Flat by default; drenched all the way down.** The fax doesn't float. It's not a card on a background; it IS the background. Depth comes from color steps within the lemon family (Zesty Lemon → Lemon Cream → Lemon Sage), not from drop shadows.

### Named Rules

**The No-Shadow Rule.** No `box-shadow` on the fax, on claim cards, on the paste box, on the home screen, anywhere. Surfaces don't lift; the color shifts.

**The Color-Step-Is-Depth Rule.** Where a card needs to feel "below" or "inside" another, step one shade within the Zesty Lemon family (e.g., a claim card uses Lemon Cream against a Zesty Lemon background). No shadow, no border, no tint — just the next step on the palette.

## 5. Components

*Omitted in seed mode — no SwiftUI code in the new style yet. The next pass of `$impeccable document` (after Plan 5 lands the iOS scaffold) will extract real components and generate the `.impeccable/design.json` sidecar so the live panel renders them.*

Direction notes for the first pass of implementation, so the eventual extraction has a target:

- **The fax** — full-screen drenched-Zesty-Lemon surface. Verdict word at the top in heavy display weight. 2–3 claim cards stacked below, each on Lemon Cream (one step quieter), with claim text in semibold headline and bestie commentary in regular body. No icons except the verdict glyph. No drop shadows. Corner radius small (≤8pt) — the fax has paper-edge feel, not pillow-card.
- **The home paste screen** — drenched Zesty Lemon. Single large paste field with humanist sans placeholder copy. "Paste from clipboard" chip appears when a URL is detected. Tucked top-corner: small "Recent" label that reveals history.
- **The streaming-fill state** — claim cards animate in one at a time as the backend resolves. Each card slides up from below the previous; claim text appears first, verdict glyph + bestie commentary settle in on a brief second beat. No skeleton, no spinner — the claim slot is empty until the data arrives.
- **The Recent list** — drenched Zesty Lemon list of past faxes, each row showing verdict glyph + claim source + timestamp. Tap a row to reopen the full fax.
- **Reduce Motion variant** — claim cards instant-place with a brief highlight rather than slide; preserves the sequence and the proof-of-work feel without vestibular cost.

## 6. Do's and Don'ts

### Do:

- **Do** treat Zesty Lemon as the substrate of the entire app. Every screen starts from drenched yellow.
- **Do** assign every text decision to the single humanist sans family. Hierarchy comes from weight + size, not from face changes.
- **Do** invest in the streaming claim-fill choreography from day one. It's the hero motion, not polish.
- **Do** carry the verdict glyph + label everywhere — verdict identity is never color-alone.
- **Do** test fax layouts at 1080×1920 thumbnail compression (iMessage preview, screenshot-into-DM workflow). If the verdict isn't readable at thumbnail size, the layout has failed.
- **Do** keep copy carrying the design. The bestie commentary is the typographic protagonist of the fax body.
- **Do** step within the lemon family for nested surfaces (claim cards, chips, dividers). Color steps replace shadows everywhere.

### Don't:

- **Don't** ever ship `#000` or use `#fff` as a background. All neutrals carry warm trace chroma toward yellow.
- **Don't** introduce monospace anywhere user-facing. **The No-Mono Rule.** The schema is named `receipts` but the user-facing artifact is *the fax* and the visual brand is humanist warmth, not utility-terminal.
- **Don't** use drop shadows for depth. **The No-Shadow Rule.** Color steps within the lemon family carry depth; shadows don't appear at all.
- **Don't** introduce sparkle icons (✨), frosted-glass cards, cream-and-sage palettes, or any other "obvious AI design" cues. **The AI-Slop Anti.** If a designer would look at the fax and say "AI made that" without doubt, the design has failed.
- **Don't** lift the ChatGPT / Claude / generic LLM chat-bubble UI. The fax is an artifact, not a conversation. There is no chat thread, no message bubbles, no "AI typing..." indicator.
- **Don't** lift Snopes / PolitiFact's institutional-fact-check aesthetic — narrow columns, stock photos, headline-by-headline fact-check pages. Our fax is a screenshot, not a microsite.
- **Don't** lift Apple News / NYT broadsheet reverence — serif headlines, publisher-logo authority, narrow body columns. We're not deferring to anyone.
- **Don't** introduce streak panic, badges, XP bars, level-ups, or any other Duolingo / LinkedIn gamification. Satisfaction is the fax landing in a group chat, period.
- **Don't** lift Linear / Notion / generic dark-mode SaaS slickness. Our brand has personality; productivity SaaS doesn't.
- **Don't** put cork-board, manila-folder, polaroid, push-pin, red string, or any other CRIME BOARD-era investigation metaphor anywhere. That genre is retired and shouldn't reappear in the new system.
- **Don't** confuse "drenched" with "monotone." The lemon family has four steps for a reason; flat one-color screens read as unfinished, not as committed.
