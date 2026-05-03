<!-- SEED — re-run $impeccable document once there's SwiftUI code, to extract real tokens, components, and to generate the DESIGN.json sidecar. -->
---
name: THE CRIME BOARD
description: News as investigation — a cork-board iOS app for news-skeptical adults.
---

# Design System: THE CRIME BOARD

## 1. Overview

**Creative North Star: "The Open Case File"**

The system behaves like a working detective's desk at 11pm: cork board on the wall, paper evidence under the lamp, ink and stamps within arm's reach, a spool of red string for connections that the reader watches happen. Materials look like materials, not like UI textures dressed up as objects. The reader is addressed as a peer doing real work; the app's job is to pin the receipts in front of them and get out of the way.

This system explicitly rejects the broadsheet-app reverence of Apple News, Google News, NYT, and WaPo, and the gamified-trophy-room vocabulary of Duolingo and LinkedIn. There are no logo-as-authority cues, no XP bars, no trophy menus, no slot-machine swipe feeds. There is also no costume-piece kitsch — no fake film grain layered over screenshots, no gratuitous typewriter chrome around modern UI. The metaphor is a working stage, not a Halloween set.

**Key Characteristics:**
- Real-material palette (cork tan board, paper white, ink black, evidence red) used as named roles, not decorative splashes.
- Display serif for editorial weight; monospace for procedural metadata (case numbers, timestamps, source IDs, stamp inscriptions).
- Choreographed motion is the trust mechanic: pin-drops with weight, red-string draws stroke-by-stroke, polaroid develops, stamp slams with screen shake.
- Iconography is physical artifact (push pins, polaroids, file tabs, rubber stamps), not abstract glyphs.
- Voice is wry and procedural — *"Quiet day on the beat. Allegedly."* — never reverent, never mascot-cute.

## 2. Colors: The Working-Desk Palette

A four-role palette modeled on the physical artifacts of investigation. Each color is named for the object it's drawn from, not for its hue.

### Primary
- **Cork Tan** *(value to be resolved during implementation — warm mid-chroma tan in the OKLCH ~70% L / ~0.04 C / ~80° H neighborhood)*: the board itself. The ambient surface of nearly every screen — the substrate everything else gets pinned to. Carries texture (subtle, low-contrast cork grain), never used as a flat fill.

### Secondary
- **Evidence Red** *(value to be resolved during implementation — a saturated red-yarn red, not a UI alert red; OKLCH ~55% L / ~0.20 C / ~25° H neighborhood)*: red string between connected sources, verdict stamps ("BUSTED", "CONFIRMED"), urgent / flagged states. Restricted color — its rarity is the point. **Never used for general UI accents (buttons, links, focus rings).**

### Tertiary
- **Polaroid Sepia** *(value to be resolved during implementation — warm faded cream-yellow, OKLCH ~88% L / ~0.04 C / ~70° H neighborhood)*: aged-paper backgrounds for archived case files, polaroid borders, the developing-image animation midpoint. Signals time depth (older, stored, resolved).

### Neutral
- **Paper White** *(value to be resolved during implementation — warm off-white, OKLCH ~96% L / ~0.005 C / ~75° H — explicitly NOT #fff)*: evidence cards, polaroid faces, source dossiers — the surfaces that hold readable content on top of the cork.
- **Ink Black** *(value to be resolved during implementation — soft warm near-black, OKLCH ~18% L / ~0.01 C / ~75° H — explicitly NOT #000)*: body type, marker-style annotations, stamp ink. Tinted toward the cork hue to keep the palette unified.
- **Pencil Gray** *(value to be resolved during implementation — warm mid-gray, OKLCH ~55% L / ~0.005 C / ~75° H)*: secondary type, dividers, disabled states, subtle map-string lines that haven't been "drawn" yet.

### Named Rules

**The Red-String Rule.** Evidence Red is reserved for *connection, verdict, and flag*. Buttons, links, focus rings, tab indicators, and accent decoration must use Ink Black, Cork Tan, or Pencil Gray instead. If everything is red, nothing is.

**The No-Pure-Black, No-Pure-White Rule.** Neither `#000` nor `#fff` ever appears. All neutrals carry trace warmth (low chroma toward the cork hue) so screens feel like paper under a lamp, not like a stock UI.

**The Cork-Texture-Never-Decorative Rule.** Cork grain texture only appears on surfaces that *are* the board. It never wraps cards, bezels, modals, or chrome. Texture without function reads as theme.

## 3. Typography

**Display Font:** *[serif pairing to be chosen at implementation — direction: a contemporary editorial serif with high contrast and humanist warmth, NOT a stuffy Caslon revival or a tech-startup geometric serif. Reference points: Söhne Breit, Tiempos Headline, Lyon Display, Reckless.]*
**Mono Font:** *[monospace pairing to be chosen at implementation — direction: a typewriter-evoking but contemporary mono with a small x-height and warm character, NOT pure Courier and NOT a tech-bro geometric mono like JetBrains. Reference points: Berkeley Mono, GT America Mono, ABC Diatype Mono, Pitch.]*

**Character:** Editorial serif carries the *story* (headlines, dek, verdict copy in stamps); mono carries the *file* (case numbers, timestamps, source IDs, BiasMeter readouts, stamp inscriptions, archive metadata). Two voices, clearly assigned. The serif is the headline of a newspaper clipping; the mono is the typewriter on the desk.

### Hierarchy

*Sizes are seed-mode placeholders; the iOS Dynamic Type ramp will be authoritative.*

- **Display** (serif, light-to-regular weight, ~32–44pt): top-of-case headlines, daily-briefing reveal type. Sparse use — once per screen at most.
- **Headline** (serif, regular, ~22–28pt): story titles on the board.
- **Title** (serif, medium, ~17pt): card titles, section headers inside dossiers.
- **Body** (serif, regular, ~16pt, ~1.5 line-height, capped at 65–75ch): article body, source quotes, dek copy.
- **Label** (mono, medium, ~11–13pt, slight tracking, often UPPERCASE): case numbers, stamp inscriptions, source IDs, timestamps, BiasMeter labels — the procedural metadata layer.
- **Marker** *(optional accent — handwritten/marker face, used sparingly)*: post-it callouts, "PERSON OF INTEREST" sticker overlays, archive marginalia. Never used for body or anything readers must scan quickly.

### Named Rules

**The Two-Voices Rule.** Editorial serif for the *story*; monospace for the *file*. Ambiguous text (e.g. button labels, nav items) uses mono so the file voice anchors the chrome.

**The No-Costume-Type Rule.** Marker / handwritten faces are seasoning, not structure. They appear on overlays, callouts, and stamp faces — never on body, headlines, or controls.

**The Dynamic Type Honors The File Rule.** Mono labels scale with Dynamic Type the same as body. Procedural metadata is content, not chrome — it stays legible at the largest accessibility sizes. (Stamp text inside an image-rendered stamp is exempt; the labeled VoiceOver string carries the meaning.)

## 4. Elevation

The system is **layered, not lifted**: depth comes from things being physically *on top of* other things — paper on cork, polaroid on paper, pin through polaroid into cork — not from generic blue-tinted drop shadows. Most surfaces sit flat against the board; shadows belong only to objects that physically would cast them.

### Shadow Vocabulary

*Exact values to be resolved during implementation.*

- **Pinned-card shadow** — the small, soft, slightly-offset shadow under a paper card pinned to cork. Tight blur, low offset, low opacity — the card is *on* the board, not floating above it.
- **Polaroid shadow** — slightly heavier than the pinned-card shadow, with a hint of asymmetry as if the polaroid is curling at one corner.
- **Lifted-while-dragging shadow** — appears only during direct manipulation (the user is moving a pin, dragging a card to the archive). Larger blur, larger offset, darker. Disappears on release.

### Named Rules

**The On-The-Board Rule.** Resting elements are pinned, not floating. Default elevation is low and warm-tinted, not the generic blue-gray "Material elevation 4" drop shadow. If a card looks like it's hovering over the cork instead of pinned to it, the shadow is wrong.

**The Lift-On-Touch Rule.** Heavy shadows are reserved for elements actively being manipulated. They communicate "this is in your hand right now" — they should never appear on idle UI.

## 5. Components

*Omitted in seed mode — no SwiftUI components exist yet. The next pass of `$impeccable document` (after implementation begins) will extract real button, card, dossier, pin, polaroid, stamp, and string-connection components and generate the `DESIGN.json` sidecar so the live panel renders them.*

Direction notes for the first pass of implementation, so the eventual extraction has a target:

- **Pinned card** — paper-white evidence card with a single push-pin (top-left or top-center), small pinned-card shadow, ink-black body type. The pin is a real interactive object: tapping it can re-pin the card to the board.
- **Polaroid** — square-ish image with a thick paper border, slight rotation (±2–4°) at rest, polaroid shadow. Captions inside the white border use the marker face for the handwritten-on-bottom-edge feel; system metadata uses mono.
- **Stamp** — verdict graphic (CONFIRMED / BUSTED / COLD CASE / CLOSED) with mono inscription, slight rotation, ink-bleed edges. Stamps are *placed*, not pressed — they appear with a slam animation and stay slightly off-axis.
- **Red-string connection** — animated stroke between two pinned objects. Drawn stroke-by-stroke during Deep Check; static after. Has a subtle shadow underneath suggesting it lies on the cork.
- **Source dossier** — full-screen sheet styled as a manila folder: tab at the top with mono case-number label, paper-white interior, body content with serif body type and mono metadata blocks. Pull-to-close mimics closing the folder.
- **Daily Briefing** — top-of-feed header that wakes the board: lights flicker on, new pins appear in sequence, mono date stamp slams into the corner.
- **BiasMeter dossier** — evidence list with checkbox-marked findings, source attributions in mono, never a single bar-chart score. Multiple discrete pieces of evidence shown, not one number.
- **Pro-tier** styling — labeled in mono as **SENIOR DETECTIVE** with a stamp glyph; never with a gold crown or premium-badge cliché.

## 6. Do's and Don'ts

### Do:
- **Do** treat Cork Tan as the substrate of the entire app. New screens start from cork and add paper, not from paper and add cork as a decoration.
- **Do** assign every typography decision to either *story* (serif) or *file* (mono). If a label feels like neither, it's probably mono — chrome belongs to the file voice.
- **Do** invest in the choreographed pin-drop, red-string draw, polaroid develop, and stamp slam from day one. These are not polish-pass animations — they're the core trust mechanic. If shipping Reduce Motion fallbacks delays the v1, ship the fallbacks first and then the theatre.
- **Do** keep Evidence Red truly rare. A screen with two red strings on it should feel charged. A screen with eight has lost the rule.
- **Do** write empty states, errors, and loading copy in the wry-procedural voice modeled in PRODUCT.md (*"Quiet day on the beat. Allegedly."*).
- **Do** carry mono labels for case numbers, timestamps, source IDs, and stamp inscriptions across every surface, including archive search results and notification copy. The file voice is what makes this app legible as itself.
- **Do** present BiasMeter as a *dossier* — a collected list of evidence the user can read — not as a single number with a colored bar.

### Don't:
- **Don't** ever ship `#000` or `#fff`. Every neutral carries warm trace chroma toward the cork hue.
- **Don't** use Evidence Red for general accents — buttons, links, focus rings, tab indicators. **The Red-String Rule** is non-negotiable. Reserve red for connection, verdict, and flag.
- **Don't** wrap cork texture around chrome elements (modals, tab bars, sheets). Cork is the board, not a decoration.
- **Don't** introduce XP bars, level-up popups, badge menus, or trophy rooms — the whole **Duolingo / LinkedIn** anti-reference from PRODUCT.md is a Don't here too. Achievement lives in the archive as a case file, period.
- **Don't** lift the broadsheet-app templates of **Apple News, Google News, NYT, or WaPo** — generic story cards with publisher logos, anonymous algorithmic feeds, reverent serif chrome. PRODUCT.md names these by name; the visual system rejects them by name.
- **Don't** mimic **Ground News / AllSides** balance-as-bar-chart UI. Cross-source visibility is rendered as physical evidence on the board, not as a horizontal stacked-bar widget.
- **Don't** dress modern controls in costume-piece kitsch — fake film grain over the whole screen, gratuitous typewriter-paper backgrounds behind every button, sepia filters on UI icons. The metaphor is a working stage, not a Halloween set.
- **Don't** use generic blue-gray Material drop shadows. **The On-The-Board Rule.** Surfaces are pinned, not floating; shadows are warm-tinted and tight.
- **Don't** ship the marker / handwritten face inside body, headlines, controls, or anywhere a sighted user has to scan quickly. Marker is overlay seasoning only.
- **Don't** confuse "tactile" with "skeuomorphic clutter". Materials should feel *present*, not noisy. If the cork grain is competing with the body type for attention, the texture is too loud.
