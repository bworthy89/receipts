# For Real?? iOS

Native SwiftUI app. iOS 26+, Swift 6.2 strict concurrency complete.

## Setup

```bash
brew install xcodegen
cd ios
xcodegen generate
open ForReal.xcodeproj
```

## Build / test

```bash
# Build the app
cd ios
xcodebuild -project ForReal.xcodeproj -scheme ForReal \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO

# Per-package tests (Swift Testing — @Test, #expect)
cd ios/Packages/ForRealKit && swift test
cd ios/Packages/ForRealUI && swift test
```

ForRealKit's APIClient and SSE tests hit the deployed dev backend. Run `pnpm --filter @crimeboard/api run dev` from `backend/` first.

## Architecture

- `ForReal` — main app target (iOS). `ContentView` owns the Home + Fax sheet routing.
- `ForRealShare` — share extension (Plan 7).
- `Packages/ForRealKit` — Codable models, APIClient, SSEStreamConsumer, SwiftData FaxStore, ReceiptCoordinator.
- `Packages/ForRealUI` — color / type / motion tokens, HomeView, FaxSheet (with VerdictHeader, ClaimCard, FaxErrorState, FaxSkipState, FaxShareButton).

The app spits out **a fax** (the user-facing artifact term). The codebase still uses `receipts` everywhere it's load-bearing for engineering — DB tables, API endpoints, the `receipts-analyzer` worker name — because renaming infrastructure earns no user-visible value. See `project_brand_codename.md` in working memory for the four-layer naming model.

## Visual contract

- `PRODUCT.md` (root) — strategic context: bestie tone, screenshot-bait, format-aware honesty.
- `DESIGN.md` (root) — visual system: drenched Zesty Lemon palette, humanist sans, named rules.
- `docs/impeccable/shapes/2026-05-04-home-and-fax-shape.md` — confirmed shape brief Plan 5 implements against.
