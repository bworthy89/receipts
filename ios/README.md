# receipts — iOS app

Native SwiftUI iOS 26+ app for the receipts news-as-investigation product. See `/PRODUCT.md` and `/DESIGN.md` for product/visual context, `/docs/superpowers/specs/2026-05-02-news-app-design.md` for the technical spec.

## Layout

```
ios/
├── project.yml         XcodeGen spec — single source of truth for the .xcodeproj
├── Receipts.xcodeproj  Generated (gitignored); regenerate with `xcodegen generate`
├── Receipts/           App target sources (entry, ContentView, Info.plist)
└── Packages/           Local SPM packages
    ├── Models/         Codable structs matching the backend's API
    ├── APIClient/      URLSession-based client for the receipts backend
    ├── PersistenceKit/ Keychain-backed session token storage
    └── OnDeviceAI/     Apple Foundation Models wrapper (shell — methods added by feature plans)
```

Future packages (`DesignSystem`, `Choreography`, `BoardFeature`, `CaseFileFeature`, `DeepCheckFeature`, etc.) land here as separate SPM packages. **`DesignSystem` and `Choreography` are designed via the impeccable workflow** — see `/AGENTS.md`.

## Prerequisites

- Xcode 26+
- macOS 15+
- Homebrew
- XcodeGen (`brew install xcodegen`)
- Apple Developer team (free or paid) — needed for signing if you want to run on a real device. Simulator runs do not require signing.

## First-time setup

```bash
cd ios
xcodegen generate           # creates Receipts.xcodeproj
open Receipts.xcodeproj     # opens in Xcode
```

## Build

Command line (simulator):

```bash
cd ios
xcodebuild -project Receipts.xcodeproj -scheme Receipts \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

Or just press ⌘B in Xcode after opening the project.

## Run in simulator

In Xcode: ⌘R with an iOS 26+ simulator selected.

Or by command line:

```bash
cd ios
xcrun simctl boot "iPhone 17 Pro"   # boots if not already
open -a Simulator
# build, install, launch — see Task 9 of the foundation plan for the full command
```

## Test

Per-package:

```bash
cd ios/Packages/Models && swift test
cd ios/Packages/APIClient && swift test
cd ios/Packages/PersistenceKit && swift test
cd ios/Packages/OnDeviceAI && swift build  # no tests yet
```

Or run all from the workspace in Xcode (⌘U).

**Note:** `APIClient/Tests/HealthTests` hits the live deployed dev + staging workers. If the network is down or the workers are down, those tests fail with a transport error — that's an environmental issue, not a code issue.

## Bundle ID and environments

- **Bundle ID:** `com.bworthy.receipts`
- **Backend environments** (`APIEnvironment.dev` / `.staging` / `.production`):
  - dev: `https://crimeboard-api.bworthy89.workers.dev`
  - staging: `https://crimeboard-api-staging.bworthy89.workers.dev`
  - production: `https://crimeboard-api-prod.bworthy89.workers.dev` (not yet deployed)

The dev probe in `ContentView.swift` is hardcoded to `.dev`. Future feature plans will configure environment selection properly (per-build-config + a settings toggle).

## Conventions

- **Swift 6.2** with strict concurrency complete.
- **Swift Testing framework** (`@Test`, `#expect`), not XCTest.
- **MV pattern** with `@Observable` stores; no MVVM-per-View.
- **Detective-procedural vocabulary** in user-facing copy — see `/PRODUCT.md`. Never use generic news-app phrasing.
- **The cork-board metaphor + choreographed motion are the design language** — see `/DESIGN.md`. Use the impeccable workflow before designing any UI surface.
