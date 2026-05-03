# AGENTS.md

Pointer file for AI agents (Claude Code, Codex, subagents) working in this repository.

## Design Context

Two project-root files own the design language. Read them before doing any UI, copy, or visual work.

- **[PRODUCT.md](./PRODUCT.md)** — strategic: register, target users, product purpose, brand personality, anti-references, design principles, accessibility posture. Answers *who / what / why*.
- **[DESIGN.md](./DESIGN.md)** — visual: color palette, typography, elevation, components, do's and don'ts. Currently a **seed** scaffold; re-run `$impeccable document` once SwiftUI code exists to extract real tokens. Answers *how it looks*.

### TL;DR for agents

- **Project:** THE CRIME BOARD — a news-as-investigation iOS (SwiftUI) app for news-skeptical adults.
- **Register:** product (the app UI itself; design serves the workflow).
- **North star:** *The Open Case File* — a working detective's desk at 11pm. Materials look like materials; the user is a peer doing real work.
- **Voice:** tactile, wry, sovereign. Stand-up comedian in copy, not press release. *"Quiet day on the beat. Allegedly."*
- **Palette:** four named roles — Cork Tan (board), Paper White (evidence), Ink Black (type), Evidence Red (connection / verdict, ≤10% of any screen via the **Red-String Rule**).
- **Type:** display serif for *story*, monospace for *file* (case numbers, timestamps, source IDs, stamp inscriptions). Marker face is overlay seasoning only.
- **Motion:** choreographed — pin-drops, red-string draws, polaroid develops, stamp slams. These are the **trust mechanic**, not polish-pass animations. Every theatrical animation must have a meaningful Reduce Motion fallback.
- **Hard prohibitions:** `#000` / `#fff`; red for general accents; XP bars, badge menus, trophy rooms; broadsheet-app reverence (Apple News / Google News / NYT / WaPo); balance-bar-chart UI (Ground News / AllSides); cork texture as decorative chrome; costume-piece kitsch (whole-screen film grain, sepia filters on icons).
- **Accessibility:** WCAG 2.2 AA + first-class Reduce Motion path + VoiceOver labels written in detective vocabulary, not raw element data.

For the full strategic and visual specs, read PRODUCT.md and DESIGN.md directly — those files are normative; this section is just a launchpad.

## Working with the impeccable skill

Design work runs through the `impeccable` skill (`.claude/skills/impeccable/`). Common entry points:

- `$impeccable shape <feature>` — plan UX/UI before code.
- `$impeccable craft <feature>` — shape, then build a feature end-to-end.
- `$impeccable document` — re-extract DESIGN.md once SwiftUI components exist (currently in seed mode).
- `$impeccable critique <target>` — heuristic UX review of an existing screen.
- `$impeccable polish <target>` — final quality pass before ship.

Always run the impeccable setup gates (context load, register confirmation, command reference, shape brief) before editing project files. Skipping them produces generic output that ignores the system above.
