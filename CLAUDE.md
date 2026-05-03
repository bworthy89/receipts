# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

**receipts** (public brand) / **THE CRIME BOARD** (codename + design metaphor) — a native iOS news-as-investigation app for news-skeptical adults. Cork-board UI metaphor where stories are "cases," outlets are "persons of interest," and the hero feature (**Deep Check**) plays a visible animated investigation in front of the user. The motion choreography (pin-drops, red-string draws, polaroid develops, stamp slams) is the trust mechanic, not polish — PRODUCT.md is explicit about this.

Two sub-projects in one repo:
- `backend/` — Cloudflare Workers monorepo (TypeScript)
- `ios/` — Native SwiftUI app (iOS 26+, Swift 6.2)

## Read these first, in this order

Every UI / copy / visual / product task must start by reading the canonical docs at project root:

1. **`AGENTS.md`** — TL;DR launchpad with hard prohibitions and palette/voice summary.
2. **`PRODUCT.md`** — strategic spec: register=`product`, voice (*tactile, wry, sovereign*), anti-references (Apple News / NYT / Ground News / Duolingo / LinkedIn — if a screen could be lifted from any of these the design has failed), accessibility posture (WCAG 2.2 AA + first-class Reduce Motion path).
3. **`DESIGN.md`** — visual system: palette (Cork / Paper / Ink / Evidence), two-voices typography rule (serif=story, mono=file), elevation rules, motion vocabulary, named rules (Red-String Rule, No-Pure-Black/White Rule, Cork-Texture-Never-Decorative Rule, Two-Voices Rule, On-The-Board Rule). Currently in seed mode — re-extract via `$impeccable document` once more components exist.
4. **`docs/superpowers/specs/`** — technical specs (current: `2026-05-02-news-app-design.md`).
5. **`docs/superpowers/plans/`** — implementation plans, one per work unit.
6. **`docs/impeccable/shapes/`** — confirmed UX/UI design briefs (output of `$impeccable shape`), which are the prerequisite for craft.

If a UI design instinct conflicts with these docs, the docs win — and skipping them produces generic AI-slop output that ignores the project's intentional anti-references.

## Workflow conventions

These are non-obvious and consistently enforced:

- **PR-based, never to main.** Every implementation plan / craft / fix lands on a feature branch (`feat/`, `fix/`, `docs/`, `chore/`) and ships as a PR. The repo is public at `bworthy89/receipts`. Greptile reviews PRs automatically; address its findings before merging.
- **Plans live in `docs/superpowers/plans/`** and are written via the `superpowers:writing-plans` skill before implementation. Each plan starts with a "Skill applicability" line (UI plans use `impeccable`; backend plans don't).
- **UI work goes through impeccable.** Run `$impeccable shape <feature>` first (Q&A discovery → confirmed design brief committed under `docs/impeccable/shapes/`), then `$impeccable craft <feature>` to build (with in-Simulator critique-and-fix passes). Never craft without a user-confirmed shape brief.
- **Backend work skips impeccable.** Backend plans note `Skill applicability: backend-only — impeccable does not apply.`
- **API wire format is snake_case everywhere.** Every JSON key on the receipts API uses `snake_case` (`session_token`, `feed_mode`, `selected_topics`). iOS Codable types use camelCase Swift properties paired with explicit `CodingKeys` overrides. Backend response objects use explicit `snake_case` keys, not JS shorthand. Locked in PR #1 review.
- **Public brand `receipts` vs. codename `crimeboard`.** Engineering namespace stays `crimeboard` (Cloudflare resources `crimeboard-{dev,staging,prod}`, npm packages `@crimeboard/*`, worker name `crimeboard-api`). User-facing copy / App Store / marketing uses `receipts` (lowercase wordmark) or `Receipts` in prose. Don't collapse the two.
- **Detective-procedural vocabulary in user-facing copy.** Never use generic news-app phrasing ("articles," "saved stories," "topics"). Use *cases*, *sources*, *persons of interest*, *the beat*, *cold case*, *closed*, *days on the beat*, *Senior Detective* (Pro tier), *Quiet day on the beat. Allegedly.* (empty state).

## Backend (`backend/`)

Cloudflare-only stack. **Path must not contain spaces** (workerd module resolution breaks; project root is `/Users/kari/Documents/news-app/` with hyphen). pnpm 11; the workspace's `allowBuilds: { esbuild: true, sharp: true, workerd: true }` block in `pnpm-workspace.yaml` must remain populated or install scripts silently skip and the toolchain breaks.

```bash
cd backend
pnpm install
pnpm --filter @crimeboard/api run dev    # local dev :8787 — uses --local D1
pnpm test                                 # all packages, all workers
pnpm typecheck                            # all packages
pnpm --filter @crimeboard/api run test    # just api worker tests
pnpm --filter @crimeboard/shared run test # just shared package tests

pnpm run deploy:dev | deploy:staging | deploy:prod
```

Tests run inside a real Workers runtime via `@cloudflare/vitest-pool-workers`. D1 migrations are auto-applied to the test runtime by `workers/api/test/apply-migrations.ts` (a vitest setup file). The `pretest` hook re-applies migrations to the local-dev D1.

**Workers AI binding is per-worker.** Don't add `[ai] binding = "AI"` to a worker's `wrangler.toml` unless that worker actually invokes AI — vitest-pool-workers can't emulate the wrapped binding and tests will fail to start. The shared `Env` type still declares `AI`, but only workers that use it should bind it.

**D1 migrations** under `backend/migrations/` (numbered sequentially). After adding one:
```bash
cd backend/workers/api
pnpm exec wrangler d1 migrations apply crimeboard-dev --local
pnpm exec wrangler d1 migrations apply crimeboard-dev --remote
pnpm exec wrangler d1 migrations apply crimeboard-staging --env staging --remote
pnpm exec wrangler d1 migrations apply crimeboard-prod --env production --remote
```

**Architecture (per the technical spec):** hybrid execution model — server does *shared* work (RSS ingestion, clustering via Workers AI embeddings, deep-check, push triggers), iOS device does *personal* work (per-article summaries, first-pass verdicts, reading-diet analytics) using Apple Foundation Models. Server is Cloudflare-only: Workers + D1 + KV + R2 + Queues + Workers AI. Auth is Sign in with Apple → server verifies the identity JWT against Apple's JWKS (cached in KV) → mints an HS256 session token (in `@crimeboard/shared/src/session.ts`) that the iOS app sends as `Authorization: Bearer …`.

## iOS app (`ios/`)

XcodeGen drives `Receipts.xcodeproj` from `project.yml` (the `.xcodeproj` is gitignored — regenerate after editing `project.yml`):

```bash
cd ios
xcodegen generate
open Receipts.xcodeproj   # or build/run from the command line:

xcodebuild -project Receipts.xcodeproj -scheme Receipts \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO

# Per-package tests (Swift Testing framework — @Test, #expect — not XCTest):
cd ios/Packages/Models && swift test
cd ios/Packages/APIClient && swift test         # includes live network tests against deployed dev/staging
cd ios/Packages/PersistenceKit && swift test    # exercises real Keychain
cd ios/Packages/DesignSystem && swift test
cd ios/Packages/OnDeviceAI && swift build       # no tests yet
```

**Path must not contain spaces** (same workerd issue affects vitest-pool-workers in the backend; vestigial constraint here is that the test target builds for macOS host).

**Conventions:**
- Swift 6.2 with strict concurrency complete. `Sendable` is `any Sendable` (the explicit `any` keyword is required).
- MV pattern with `@Observable` stores; no MVVM-per-View.
- Local SPM packages in `ios/Packages/` — each one focused, dependencies one-way (Models → APIClient → PersistenceKit; DesignSystem → Choreography → feature packages).
- Bundle ID `com.bworthy.receipts`. iOS 26+ minimum (Foundation Models requirement).
- The dev probe ContentView calls `APIClient(environment: .dev).health()` and shows the response — proves the whole stack works end-to-end. DEBUG builds also show a "View DesignSystem Catalog" button presenting `DesignSystemCatalog` as a sheet.

**`DesignSystem` package is the visual contract** (palette, fonts, elevation, spacing, MotionMode + MotionVariant, 5 substrate primitives — CorkBoard, PaperSurface, MonoLabel, StoryText, MarkerNote). Every UI surface composes from these tokens; never hand-roll colors, fonts, or shadows. The `DesignSystemCatalog` view is the visual contract — when iterating tokens, present this catalog in the simulator and screenshot for review.

**Color token rules baked into the package:**
- `Color.cork` / `paper` / `ink` / `evidence` / `sepia` / `pencil` are the only public color tokens. Internal `Color.shadowTint` is for the elevation modifiers only.
- "Dim Room" dark mode — same warm palette lighting-shifted, NOT system inverted dark. Light + dark variants resolve via UIKit (`UITraitCollection`) on iOS and AppKit (`NSAppearance`) on macOS host.
- The Red-String Rule is non-negotiable: `Color.evidence` is for connection / verdict / flag only, never general accents.

## Skills you'll use

User-invocable via `Skill` tool — never invoke skills not in the available list:

- **`superpowers:brainstorming`** — turn an idea into a confirmed spec (output: `docs/superpowers/specs/<date>-<topic>-design.md`).
- **`superpowers:writing-plans`** — turn a spec into an implementation plan (output: `docs/superpowers/plans/<date>-<feature>.md`). Plan granularity is bite-sized: each step is one action.
- **`superpowers:subagent-driven-development`** — execute a plan task-by-task, fresh subagent per task, two-stage review between.
- **`impeccable shape <feature>`** — Q&A design interview, output a confirmed design brief at `docs/impeccable/shapes/<date>-<feature>-shape.md`.
- **`impeccable craft <feature>`** — implement from a confirmed shape brief; iterate via in-Simulator critique-and-fix passes.
- **`impeccable critique <target>` / `polish <target>`** — review / final pass.
- **`impeccable document`** — re-extract DESIGN.md from real SwiftUI code (run after enough components exist to upgrade DESIGN.md from seed mode).

The impeccable skill enforces a **preflight gate**: shape brief MUST be user-confirmed before craft can edit files. Don't bypass.

## Working memory

Project memory lives at `~/.claude/projects/-Users-kari-Documents-news-app/memory/` and is auto-loaded each session. Saved conventions there include the brand/codename split, the snake_case wire format rule, the PR-based workflow, the path-no-spaces gotcha, the pnpm 11 build approvals, the Workers AI binding rule, and the impeccable skill applicability convention. When you learn something non-obvious about how the user wants to work, save it as a memory.
