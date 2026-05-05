# iOS Scaffold + Home + Fax — Implementation Plan (Plan 5)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the For Real?? iOS app from scratch — delete the retired CRIME-BOARD-era packages, scaffold a new `ForReal` Xcode project with two SPM packages (`ForRealKit` for the data layer, `ForRealUI` for the views), and ship production-ready Home + Fax surfaces. After this plan ships, a user can paste a TikTok or YouTube URL into Home, watch the Fax sheet stream in claim-by-claim, see the verdict push in from the top, and screenshot the result.

**Architecture:** Clean iOS rebuild against the [confirmed shape brief](../../impeccable/shapes/2026-05-04-home-and-fax-shape.md). Two SPM packages — `ForRealKit` (Codable models, API client, SSE consumer, SwiftData store, Keychain device-id, `@Observable` coordinator) and `ForRealUI` (design tokens, Home view, Fax sheet view, all states + Reduce Motion variants + VoiceOver). The main app target stays small (app shell + sheet routing + DEBUG dev probe).

**Tech stack:** SwiftUI · iOS 26+ · Swift 6.2 strict-concurrency-complete · MV pattern with `@Observable` stores · Swift Testing (`@Test`, `#expect`, `@MainActor` for view suites) · XcodeGen-driven project · SwiftData for local cache · URLSession `bytes(for:)` for SSE.

**Skill applicability:** UI-heavy iOS plan — the `impeccable` skill **applies**. The confirmed shape brief at `docs/impeccable/shapes/2026-05-04-home-and-fax-shape.md` is the canonical input; PRODUCT.md and DESIGN.md are the upstream context. Re-run `$impeccable critique Home` and `$impeccable critique Fax` against the rendered surfaces after Task 22 (before the final commit) to validate against the brief.

---

## Prerequisites

The engineer must already have:

- **Plan 1's backend running**: `cd backend && pnpm --filter @crimeboard/api run dev` works; the `/v1/receipts` POST/GET/SSE endpoints respond against `crimeboard-dev`.
- **Xcode 16+** (Swift 6.2 toolchain).
- **`xcodegen`** installed: `brew install xcodegen`.
- The current spec, PRODUCT.md, DESIGN.md, and the shape brief read at least once.
- A clean working tree on `docs/for-real-context-refresh` (or whatever feature branch the user has chosen — Plan 5's tasks commit there).

---

## Out of scope for this plan (covered later)

- **Recent screen** (Plan 6) — Home has a Recent **glyph** that taps to nothing-yet (or a placeholder) in Plan 5; Plan 6 builds the actual list overlay.
- **Settings + Sign in with Apple** (Plan 8) — no auth UI in Plan 5.
- **Share Extension** target (Plan 7) — the main app target ships in Plan 5; the share extension is a separate target plan.
- **Live Activity / Dynamic Island** — flagged in shape brief Open Questions; not stubbed in Plan 5.
- **Anything iPad-specific** — universal layout is enough for v1.
- **Real LLM analysis** — Plan 5 develops against the stub pipeline already shipped in Plan 1.

---

## File structure produced by this plan

```
/Users/kari/Documents/news-app/
└── ios/
    ├── project.yml                                        [Task 2 — rewritten]
    ├── ForReal.xcodeproj                                  [Task 5 — generated]
    ├── ForReal/
    │   ├── ForRealApp.swift                               [Task 5]
    │   ├── ContentView.swift                              [Task 22]
    │   └── Info.plist                                     [Task 5]
    └── Packages/
        ├── ForRealKit/
        │   ├── Package.swift                              [Task 3]
        │   ├── Sources/ForRealKit/
        │   │   ├── Models/
        │   │   │   ├── Verdict.swift                      [Task 6]
        │   │   │   ├── SourceProvider.swift               [Task 6]
        │   │   │   ├── Fax.swift                          [Task 6]
        │   │   │   └── Claim.swift                        [Task 6]
        │   │   ├── API/
        │   │   │   ├── APIEnvironment.swift               [Task 7]
        │   │   │   ├── APIClient.swift                    [Tasks 7, 8, 9]
        │   │   │   ├── APIError.swift                     [Task 7]
        │   │   │   ├── DeviceID.swift                     [Task 10]
        │   │   │   └── SSEStreamConsumer.swift            [Task 11]
        │   │   ├── Store/
        │   │   │   ├── FaxStore.swift                     [Task 12 — SwiftData @Model + DAO]
        │   │   │   └── ReceiptCoordinator.swift           [Task 13 — @Observable]
        │   │   └── ForRealKit.swift                       [Task 3 — @_exported re-exports]
        │   └── Tests/ForRealKitTests/
        │       ├── ModelDecodingTests.swift               [Task 6]
        │       ├── APIClientTests.swift                   [Tasks 7–9]
        │       ├── DeviceIDTests.swift                    [Task 10]
        │       ├── SSEStreamConsumerTests.swift           [Task 11]
        │       ├── FaxStoreTests.swift                    [Task 12]
        │       └── ReceiptCoordinatorTests.swift          [Task 13]
        └── ForRealUI/
            ├── Package.swift                              [Task 4]
            ├── Sources/ForRealUI/
            │   ├── Tokens/
            │   │   ├── Color+Lemon.swift                  [Task 14]
            │   │   ├── Typography.swift                   [Task 15]
            │   │   └── Motion.swift                       [Task 16]
            │   ├── Home/
            │   │   ├── HomeView.swift                     [Task 17]
            │   │   └── ClipboardChip.swift                [Task 17]
            │   ├── Fax/
            │   │   ├── FaxSheet.swift                     [Task 18]
            │   │   ├── VerdictHeader.swift                [Tasks 18, 19]
            │   │   ├── ClaimCard.swift                    [Tasks 18, 19]
            │   │   ├── FaxErrorState.swift                [Task 20]
            │   │   ├── FaxSkipState.swift                 [Task 20]
            │   │   └── FaxShareButton.swift               [Task 21]
            │   └── ForRealUI.swift                        [Task 4 — @_exported]
            └── Tests/ForRealUITests/
                ├── ColorTokensTests.swift                 [Task 14]
                ├── TypographyTests.swift                  [Task 15]
                ├── MotionTokensTests.swift               [Task 16]
                ├── HomeViewSmokeTests.swift               [Task 17]
                ├── FaxSheetSmokeTests.swift               [Task 18]
                ├── FaxStreamingIntegrationTests.swift     [Task 19]
                ├── FaxErrorStateTests.swift               [Task 20]
                └── FaxShareTests.swift                    [Task 21]
```

The existing `ios/Receipts/` folder, `ios/Receipts.xcodeproj` (gitignored), and all of `ios/Packages/*` (Models, APIClient, PersistenceKit, OnDeviceAI, DesignSystem, Choreography, DailyBriefing, DeepCheck, Archive) are deleted in Task 1.

---

## Type reference

These types are introduced in Task 6 and referenced by every later task that touches the data layer. Listed here so cross-task signatures stay consistent.

```swift
// ForRealKit / Models / Verdict.swift
public enum Verdict: String, Codable, Sendable, CaseIterable {
    case nope, mixed, yep, skip
    public var glyph: String {
        switch self { case .nope: "❌"; case .mixed: "🤷"; case .yep: "✅"; case .skip: "🤔" }
    }
}

// ForRealKit / Models / SourceProvider.swift
public enum SourceType: String, Codable, Sendable { case video, article }
public enum SourceProvider: String, Codable, Sendable { case tiktok, youtube, article }

// ForRealKit / Models / Fax.swift
public struct Fax: Codable, Sendable, Equatable {
    public let id: String
    public let sourceURL: String
    public let sourceType: SourceType
    public let sourceProvider: SourceProvider
    public let title: String?
    public let status: Status
    public let finalVerdict: Verdict?
    public let finalCommentary: String?
    public let errorCode: String?
    public let createdAt: Int      // Unix epoch seconds
    public let finishedAt: Int?
    public let claims: [Claim]

    public enum Status: String, Codable, Sendable { case pending, streaming, done, failed }

    enum CodingKeys: String, CodingKey {
        case id
        case sourceURL = "source_url"
        case sourceType = "source_type"
        case sourceProvider = "source_provider"
        case title, status
        case finalVerdict = "final_verdict"
        case finalCommentary = "final_commentary"
        case errorCode = "error_code"
        case createdAt = "created_at"
        case finishedAt = "finished_at"
        case claims
    }
}

// ForRealKit / Models / Claim.swift
public struct Claim: Codable, Sendable, Equatable, Identifiable {
    public let position: Int          // 1, 2, 3
    public let claimText: String
    public let verdict: Verdict
    public let commentary: String
    public let sources: [Source]
    public let resolvedAt: Int

    public var id: Int { position }   // identity for SwiftUI ForEach

    public struct Source: Codable, Sendable, Equatable, Hashable {
        public let url: String
        public let title: String
    }

    enum CodingKeys: String, CodingKey {
        case position
        case claimText = "claim_text"
        case verdict, commentary, sources
        case resolvedAt = "resolved_at"
    }
}
```

---

## Task 1: Delete the retired iOS code

**Files:**
- Delete: `ios/Receipts/` (entire folder — `ReceiptsApp.swift`, `ContentView.swift`, `Info.plist`)
- Delete: `ios/Receipts.xcodeproj/` (gitignored, can just `rm -rf`)
- Delete: `ios/Packages/Models/`, `ios/Packages/APIClient/`, `ios/Packages/PersistenceKit/`, `ios/Packages/OnDeviceAI/`, `ios/Packages/DesignSystem/`, `ios/Packages/Choreography/`, `ios/Packages/DailyBriefing/`, `ios/Packages/DeepCheck/`, `ios/Packages/Archive/`

- [ ] **Step 1: Verify no other references will break**

Run from repo root: `grep -r "import Models\|import APIClient\|import DesignSystem\|import Choreography\|import DailyBriefing\|import DeepCheck\|import Archive\|import PersistenceKit\|import OnDeviceAI" --include="*.swift" ios/`
Expected: only matches inside the directories you're about to delete (or their tests) — nothing in iOS code that should survive. If any survives, stop and report.

- [ ] **Step 2: Delete**

```bash
cd ios
rm -rf Receipts/ Receipts.xcodeproj/
rm -rf Packages/Models Packages/APIClient Packages/PersistenceKit Packages/OnDeviceAI \
       Packages/DesignSystem Packages/Choreography Packages/DailyBriefing Packages/DeepCheck \
       Packages/Archive
```

- [ ] **Step 3: Verify the directory is empty enough**

Run: `ls ios/ ios/Packages/`
Expected: `ios/` contains only `project.yml`, `README.md`, and `.gitignore`. `ios/Packages/` is empty (or absent — it'll be re-created in later tasks).

- [ ] **Step 4: Commit**

```bash
git add -A ios/
git commit -m "chore(ios): delete retired CRIME-BOARD packages and Receipts target

Wipes the iOS surface area for the For Real?? rebuild. The data layer
(Models, APIClient, PersistenceKit, OnDeviceAI), the design system
(DesignSystem, Choreography), and every UI surface (DailyBriefing,
DeepCheck, Archive) are deleted. The new ForReal app + ForRealKit +
ForRealUI replace them in subsequent tasks."
```

---

## Task 2: Rewrite `ios/project.yml` for ForReal

**Files:**
- Modify: `ios/project.yml`

- [ ] **Step 1: Write the new project.yml**

Replace the entire contents of `ios/project.yml` with:

```yaml
name: ForReal
options:
  bundleIdPrefix: com.bworthy
  deploymentTarget:
    iOS: "26.0"
  developmentLanguage: en
  groupSortPosition: top
  generateEmptyDirectories: true

settings:
  base:
    SWIFT_VERSION: 6.2
    SWIFT_STRICT_CONCURRENCY: complete
    SWIFT_UPCOMING_FEATURE_INTERNAL_IMPORTS_BY_DEFAULT: YES
    ENABLE_USER_SCRIPT_SANDBOXING: YES

packages:
  ForRealKit:
    path: Packages/ForRealKit
  ForRealUI:
    path: Packages/ForRealUI

targets:
  ForReal:
    type: application
    sources:
      - path: ForReal
        excludes:
          - Info.plist
    dependencies:
      - package: ForRealKit
      - package: ForRealUI
    settings:
      PRODUCT_NAME: For Real
      PRODUCT_BUNDLE_IDENTIFIER: com.bworthy.forreal
      INFOPLIST_FILE: ForReal/Info.plist
      TARGETED_DEVICE_FAMILY: "1,2"
      SUPPORTS_MACCATALYST: NO
```

Note: `PRODUCT_NAME` is `For Real` (with the space) so the home-screen app name displays as "For Real" — the `??` is reserved for marketing copy because Apple disallows certain characters in `PRODUCT_NAME`. The bundle ID stays alphanumeric (`com.bworthy.forreal`).

- [ ] **Step 2: Don't run xcodegen yet**

Building requires the package directories and the `ForReal/` source folder to exist (Tasks 3–5). Skip running `xcodegen` here.

- [ ] **Step 3: Commit**

```bash
git add ios/project.yml
git commit -m "chore(ios): rewrite project.yml for ForReal target + new packages"
```

---

## Task 3: Create `ForRealKit` package skeleton

**Files:**
- Create: `ios/Packages/ForRealKit/Package.swift`
- Create: `ios/Packages/ForRealKit/Sources/ForRealKit/ForRealKit.swift`
- Create: `ios/Packages/ForRealKit/Tests/ForRealKitTests/ForRealKitTests.swift`

- [ ] **Step 1: Write the package manifest**

Create `ios/Packages/ForRealKit/Package.swift`:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ForRealKit",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [
        .library(name: "ForRealKit", targets: ["ForRealKit"]),
    ],
    targets: [
        .target(name: "ForRealKit"),
        .testTarget(name: "ForRealKitTests", dependencies: ["ForRealKit"]),
    ],
    swiftLanguageModes: [.v6]
)
```

- [ ] **Step 2: Write a minimal source file so the target compiles**

Create `ios/Packages/ForRealKit/Sources/ForRealKit/ForRealKit.swift`:

```swift
// Public surface for ForRealKit. Real types live alongside this file (Models/, API/, Store/).
// This file exists so the empty target compiles before Task 6 introduces real models.

import Foundation

public enum ForRealKit {
    public static let version = "0.1.0"
}
```

- [ ] **Step 3: Write a smoke test**

Create `ios/Packages/ForRealKit/Tests/ForRealKitTests/ForRealKitTests.swift`:

```swift
import Testing
@testable import ForRealKit

@Suite("ForRealKit smoke")
struct ForRealKitSmokeTests {
    @Test("version string is non-empty")
    func versionStringIsNonEmpty() {
        #expect(!ForRealKit.version.isEmpty)
    }
}
```

- [ ] **Step 4: Build + test**

Run: `cd ios/Packages/ForRealKit && swift test`
Expected: PASS — 1 test, "ForRealKit smoke / version string is non-empty".

- [ ] **Step 5: Commit**

```bash
git add ios/Packages/ForRealKit/
git commit -m "feat(ios/ForRealKit): scaffold package with smoke test"
```

---

## Task 4: Create `ForRealUI` package skeleton

**Files:**
- Create: `ios/Packages/ForRealUI/Package.swift`
- Create: `ios/Packages/ForRealUI/Sources/ForRealUI/ForRealUI.swift`
- Create: `ios/Packages/ForRealUI/Tests/ForRealUITests/ForRealUITests.swift`

- [ ] **Step 1: Write the manifest**

Create `ios/Packages/ForRealUI/Package.swift`:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ForRealUI",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [
        .library(name: "ForRealUI", targets: ["ForRealUI"]),
    ],
    dependencies: [
        .package(path: "../ForRealKit"),
    ],
    targets: [
        .target(name: "ForRealUI", dependencies: ["ForRealKit"]),
        .testTarget(name: "ForRealUITests", dependencies: ["ForRealUI"]),
    ],
    swiftLanguageModes: [.v6]
)
```

- [ ] **Step 2: Write a minimal source file**

Create `ios/Packages/ForRealUI/Sources/ForRealUI/ForRealUI.swift`:

```swift
// Public surface for ForRealUI. Views live alongside this file (Tokens/, Home/, Fax/).
import Foundation
@_exported import ForRealKit

public enum ForRealUI {
    public static let version = "0.1.0"
}
```

- [ ] **Step 3: Write a smoke test**

Create `ios/Packages/ForRealUI/Tests/ForRealUITests/ForRealUITests.swift`:

```swift
import Testing
@testable import ForRealUI

@Suite("ForRealUI smoke")
struct ForRealUISmokeTests {
    @Test("version string is non-empty")
    func versionStringIsNonEmpty() {
        #expect(!ForRealUI.version.isEmpty)
    }
}
```

- [ ] **Step 4: Build + test**

Run: `cd ios/Packages/ForRealUI && swift test`
Expected: PASS — 1 test.

- [ ] **Step 5: Commit**

```bash
git add ios/Packages/ForRealUI/
git commit -m "feat(ios/ForRealUI): scaffold package with smoke test (depends on ForRealKit)"
```

---

## Task 5: Create the `ForReal` app target — hello-world

**Files:**
- Create: `ios/ForReal/ForRealApp.swift`
- Create: `ios/ForReal/Info.plist`

- [ ] **Step 1: Write the app entry point**

Create `ios/ForReal/ForRealApp.swift`:

```swift
import SwiftUI

@main
struct ForRealApp: App {
    var body: some Scene {
        WindowGroup {
            // Real ContentView lands in Task 22.
            Text("For Real??")
                .font(.largeTitle.bold())
        }
    }
}
```

- [ ] **Step 2: Write Info.plist**

Create `ios/ForReal/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>For Real??</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>arm64</string>
    </array>
</dict>
</plist>
```

`CFBundleDisplayName` is `For Real??` — `??` IS allowed here (display name accepts more characters than `PRODUCT_NAME`).

- [ ] **Step 3: Generate the Xcode project**

Run: `cd ios && xcodegen generate`
Expected output: `Generated project successfully` and `ios/ForReal.xcodeproj` exists.

- [ ] **Step 4: Build the app**

Run:
```bash
cd ios
xcodebuild -project ForReal.xcodeproj -scheme ForReal \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 5: Commit**

```bash
git add ios/ForReal/ ios/project.yml
git commit -m "feat(ios): scaffold ForReal app target (hello-world entry + Info.plist)"
```

---

## Task 6: ForRealKit Codable models

**Files:**
- Create: `ios/Packages/ForRealKit/Sources/ForRealKit/Models/Verdict.swift`
- Create: `ios/Packages/ForRealKit/Sources/ForRealKit/Models/SourceProvider.swift`
- Create: `ios/Packages/ForRealKit/Sources/ForRealKit/Models/Fax.swift`
- Create: `ios/Packages/ForRealKit/Sources/ForRealKit/Models/Claim.swift`
- Create: `ios/Packages/ForRealKit/Tests/ForRealKitTests/ModelDecodingTests.swift`

The wire format is snake_case (per the locked convention); Swift types use camelCase via `CodingKeys`.

- [ ] **Step 1: Write the decoding tests first (TDD)**

Create `ios/Packages/ForRealKit/Tests/ForRealKitTests/ModelDecodingTests.swift`:

```swift
import Testing
import Foundation
@testable import ForRealKit

@Suite("Fax model decoding")
struct ModelDecodingTests {

    @Test("decodes a complete done fax with three claims")
    func decodesCompleteDoneFax() throws {
        let json = """
        {
            "id": "fax-1",
            "source_url": "https://www.youtube.com/watch?v=abc",
            "source_type": "video",
            "source_provider": "youtube",
            "title": null,
            "status": "done",
            "final_verdict": "nope",
            "final_commentary": "Bestie no.",
            "error_code": null,
            "created_at": 1700000000,
            "finished_at": 1700000060,
            "claims": [
                {
                    "position": 1,
                    "claim_text": "first",
                    "verdict": "nope",
                    "commentary": "no",
                    "sources": [{"url": "https://s1", "title": "s1"}],
                    "resolved_at": 1700000020
                },
                {
                    "position": 2,
                    "claim_text": "second",
                    "verdict": "mixed",
                    "commentary": "meh",
                    "sources": [],
                    "resolved_at": 1700000030
                },
                {
                    "position": 3,
                    "claim_text": "third",
                    "verdict": "yep",
                    "commentary": "yep",
                    "sources": [{"url": "https://s3", "title": "s3"}],
                    "resolved_at": 1700000040
                }
            ]
        }
        """.data(using: .utf8)!

        let fax = try JSONDecoder().decode(Fax.self, from: json)

        #expect(fax.id == "fax-1")
        #expect(fax.sourceProvider == .youtube)
        #expect(fax.status == .done)
        #expect(fax.finalVerdict == .nope)
        #expect(fax.claims.count == 3)
        #expect(fax.claims[0].verdict == .nope)
        #expect(fax.claims[0].sources.first?.url == "https://s1")
    }

    @Test("decodes a pending fax with empty claims")
    func decodesPendingFax() throws {
        let json = """
        {
            "id": "fax-2",
            "source_url": "https://tiktok.com/x",
            "source_type": "video",
            "source_provider": "tiktok",
            "title": null,
            "status": "pending",
            "final_verdict": null,
            "final_commentary": null,
            "error_code": null,
            "created_at": 1700000000,
            "finished_at": null,
            "claims": []
        }
        """.data(using: .utf8)!

        let fax = try JSONDecoder().decode(Fax.self, from: json)
        #expect(fax.status == .pending)
        #expect(fax.finalVerdict == nil)
        #expect(fax.claims.isEmpty)
    }

    @Test("Verdict glyphs are stable")
    func verdictGlyphsAreStable() {
        #expect(Verdict.nope.glyph == "❌")
        #expect(Verdict.mixed.glyph == "🤷")
        #expect(Verdict.yep.glyph == "✅")
        #expect(Verdict.skip.glyph == "🤔")
    }
}
```

- [ ] **Step 2: Run; confirm fail**

Run: `cd ios/Packages/ForRealKit && swift test`
Expected: FAIL — `Verdict`, `SourceProvider`, `Fax`, `Claim` not found.

- [ ] **Step 3: Implement the four models**

Create `ios/Packages/ForRealKit/Sources/ForRealKit/Models/Verdict.swift`:

```swift
import Foundation

public enum Verdict: String, Codable, Sendable, CaseIterable, Hashable {
    case nope, mixed, yep, skip

    public var glyph: String {
        switch self {
        case .nope:  "❌"
        case .mixed: "🤷"
        case .yep:   "✅"
        case .skip:  "🤔"
        }
    }
}
```

Create `ios/Packages/ForRealKit/Sources/ForRealKit/Models/SourceProvider.swift`:

```swift
import Foundation

public enum SourceType: String, Codable, Sendable { case video, article }

public enum SourceProvider: String, Codable, Sendable {
    case tiktok, youtube, article
}
```

Create `ios/Packages/ForRealKit/Sources/ForRealKit/Models/Fax.swift`:

```swift
import Foundation

public struct Fax: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let sourceURL: String
    public let sourceType: SourceType
    public let sourceProvider: SourceProvider
    public let title: String?
    public let status: Status
    public let finalVerdict: Verdict?
    public let finalCommentary: String?
    public let errorCode: String?
    public let createdAt: Int
    public let finishedAt: Int?
    public let claims: [Claim]

    public enum Status: String, Codable, Sendable, Equatable {
        case pending, streaming, done, failed
    }

    enum CodingKeys: String, CodingKey {
        case id
        case sourceURL = "source_url"
        case sourceType = "source_type"
        case sourceProvider = "source_provider"
        case title, status
        case finalVerdict = "final_verdict"
        case finalCommentary = "final_commentary"
        case errorCode = "error_code"
        case createdAt = "created_at"
        case finishedAt = "finished_at"
        case claims
    }

    public init(
        id: String,
        sourceURL: String,
        sourceType: SourceType,
        sourceProvider: SourceProvider,
        title: String?,
        status: Status,
        finalVerdict: Verdict?,
        finalCommentary: String?,
        errorCode: String?,
        createdAt: Int,
        finishedAt: Int?,
        claims: [Claim]
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.sourceType = sourceType
        self.sourceProvider = sourceProvider
        self.title = title
        self.status = status
        self.finalVerdict = finalVerdict
        self.finalCommentary = finalCommentary
        self.errorCode = errorCode
        self.createdAt = createdAt
        self.finishedAt = finishedAt
        self.claims = claims
    }
}
```

Create `ios/Packages/ForRealKit/Sources/ForRealKit/Models/Claim.swift`:

```swift
import Foundation

public struct Claim: Codable, Sendable, Equatable, Identifiable {
    public let position: Int
    public let claimText: String
    public let verdict: Verdict
    public let commentary: String
    public let sources: [Source]
    public let resolvedAt: Int

    public var id: Int { position }

    public struct Source: Codable, Sendable, Equatable, Hashable {
        public let url: String
        public let title: String

        public init(url: String, title: String) {
            self.url = url
            self.title = title
        }
    }

    enum CodingKeys: String, CodingKey {
        case position
        case claimText = "claim_text"
        case verdict, commentary, sources
        case resolvedAt = "resolved_at"
    }

    public init(
        position: Int,
        claimText: String,
        verdict: Verdict,
        commentary: String,
        sources: [Source],
        resolvedAt: Int
    ) {
        self.position = position
        self.claimText = claimText
        self.verdict = verdict
        self.commentary = commentary
        self.sources = sources
        self.resolvedAt = resolvedAt
    }
}
```

- [ ] **Step 4: Run; confirm pass**

Run: `cd ios/Packages/ForRealKit && swift test`
Expected: PASS — 4 tests (1 smoke + 3 model decoding).

- [ ] **Step 5: Commit**

```bash
git add ios/Packages/ForRealKit/Sources/ForRealKit/Models/ ios/Packages/ForRealKit/Tests/ForRealKitTests/ModelDecodingTests.swift
git commit -m "feat(ios/ForRealKit): Codable Verdict, SourceProvider, Fax, Claim models"
```

---

## Task 7: ForRealKit APIClient skeleton + GET /v1/receipts/:id

**Files:**
- Create: `ios/Packages/ForRealKit/Sources/ForRealKit/API/APIEnvironment.swift`
- Create: `ios/Packages/ForRealKit/Sources/ForRealKit/API/APIError.swift`
- Create: `ios/Packages/ForRealKit/Sources/ForRealKit/API/APIClient.swift`
- Create: `ios/Packages/ForRealKit/Tests/ForRealKitTests/APIClientTests.swift`

The API client mirrors the existing-project pattern (URLSession + async/await) but adds the `X-Receipts-Device` header and uses snake_case wire format.

- [ ] **Step 1: Write a failing test for `getFax`**

Create `ios/Packages/ForRealKit/Tests/ForRealKitTests/APIClientTests.swift`:

```swift
import Testing
import Foundation
@testable import ForRealKit

@Suite("APIClient — getFax (live network — requires deployed dev worker on :8787)")
struct APIClientGetFaxTests {

    @Test("404s for an unknown id")
    func unknownIdReturnsNotFound() async throws {
        let client = APIClient(environment: .dev, deviceID: "test-device-fr-iOS-1")
        do {
            _ = try await client.getFax(id: "00000000-0000-0000-0000-000000000000")
            Issue.record("expected APIError.notFound")
        } catch APIError.notFound {
            // expected
        }
    }
}
```

- [ ] **Step 2: Run; confirm fail**

Run: `cd ios/Packages/ForRealKit && swift test --filter APIClientGetFaxTests`
Expected: FAIL — `APIClient`, `APIError.notFound`, `APIEnvironment.dev` not found.

- [ ] **Step 3: Implement the env + error + client**

Create `ios/Packages/ForRealKit/Sources/ForRealKit/API/APIEnvironment.swift`:

```swift
import Foundation

public enum APIEnvironment: Sendable {
    case dev
    case staging
    case production
    case custom(URL)

    public var baseURL: URL {
        switch self {
        case .dev:        URL(string: "http://127.0.0.1:8787")!
        case .staging:    URL(string: "https://crimeboard-api-staging.workers.dev")!
        case .production: URL(string: "https://crimeboard-api.workers.dev")!
        case .custom(let url): url
        }
    }
}
```

Create `ios/Packages/ForRealKit/Sources/ForRealKit/API/APIError.swift`:

```swift
import Foundation

public enum APIError: Error, Sendable, Equatable {
    case notFound
    case forbidden
    case unsupportedProvider
    case dailyCapReached(message: String)
    case http(status: Int, body: String?)
    case decoding(message: String)
    case transport(message: String)
}
```

Create `ios/Packages/ForRealKit/Sources/ForRealKit/API/APIClient.swift`:

```swift
import Foundation

public final class APIClient: Sendable {
    public let environment: APIEnvironment
    public let deviceID: String
    private let session: URLSession

    public init(environment: APIEnvironment, deviceID: String, session: URLSession = .shared) {
        self.environment = environment
        self.deviceID = deviceID
        self.session = session
    }

    // MARK: - Endpoints

    public func getFax(id: String) async throws -> Fax {
        try await get("/v1/receipts/\(id)")
    }

    // MARK: - Internal

    func get<T: Decodable>(_ path: String) async throws -> T {
        try await send(method: "GET", path: path, body: Optional<EmptyBody>.none)
    }

    func send<B: Encodable, T: Decodable>(method: String, path: String, body: B?) async throws -> T {
        var request = URLRequest(url: environment.baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(deviceID, forHTTPHeaderField: "X-Receipts-Device")

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(message: String(describing: error))
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport(message: "non-HTTP response")
        }

        switch http.statusCode {
        case 200..<300:
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw APIError.decoding(message: String(describing: error))
            }
        case 404:
            throw APIError.notFound
        case 403:
            throw APIError.forbidden
        case 422:
            throw APIError.unsupportedProvider
        case 429:
            let body = String(data: data, encoding: .utf8)
            throw APIError.dailyCapReached(message: body ?? "")
        default:
            throw APIError.http(status: http.statusCode, body: String(data: data, encoding: .utf8))
        }
    }

    private struct EmptyBody: Encodable {}
}
```

- [ ] **Step 4: Confirm the dev backend is running, then run the test**

In one terminal: `cd backend && pnpm --filter @crimeboard/api run dev`. In another:
```bash
cd ios/Packages/ForRealKit && swift test --filter APIClientGetFaxTests
```
Expected: PASS — the 404 case lands.

- [ ] **Step 5: Commit**

```bash
git add ios/Packages/ForRealKit/Sources/ForRealKit/API/ ios/Packages/ForRealKit/Tests/ForRealKitTests/APIClientTests.swift
git commit -m "feat(ios/ForRealKit): APIClient with GET /v1/receipts/:id (404 path)"
```

---

## Task 8: APIClient — POST /v1/receipts (idempotency response)

**Files:**
- Modify: `ios/Packages/ForRealKit/Sources/ForRealKit/API/APIClient.swift`
- Modify: `ios/Packages/ForRealKit/Tests/ForRealKitTests/APIClientTests.swift`

POST returns `{ receipt_id, status, cached }`. Cache hits return `cached: true` from any device.

- [ ] **Step 1: Write the failing tests**

Append to `ios/Packages/ForRealKit/Tests/ForRealKitTests/APIClientTests.swift`:

```swift
@Suite("APIClient — postFax (live network)")
struct APIClientPostFaxTests {

    @Test("creates a fresh pending fax for a YouTube URL")
    func freshURL() async throws {
        let device = "test-device-fr-post-\(Int.random(in: 100_000...999_999))"
        let client = APIClient(environment: .dev, deviceID: device)
        let result = try await client.postFax(url: "https://www.youtube.com/watch?v=fr-fresh-\(UUID().uuidString)")

        #expect(!result.receiptID.isEmpty)
        #expect(result.status == "pending")
        #expect(result.cached == false)
    }

    @Test("returns cached for a re-paste of a known URL")
    func cachedURL() async throws {
        let url = "https://www.youtube.com/watch?v=fr-cache-\(UUID().uuidString)"
        let deviceA = "test-device-fr-post-A-\(Int.random(in: 100_000...999_999))"
        let deviceB = "test-device-fr-post-B-\(Int.random(in: 100_000...999_999))"

        let first = try await APIClient(environment: .dev, deviceID: deviceA).postFax(url: url)
        let second = try await APIClient(environment: .dev, deviceID: deviceB).postFax(url: url)

        #expect(first.receiptID == second.receiptID)
        #expect(second.cached == true)
    }

    @Test("422s on Instagram (unsupported provider)")
    func unsupportedProvider() async throws {
        let client = APIClient(environment: .dev, deviceID: "test-device-fr-instagram")
        do {
            _ = try await client.postFax(url: "https://www.instagram.com/reel/abc/")
            Issue.record("expected APIError.unsupportedProvider")
        } catch APIError.unsupportedProvider {
            // expected
        }
    }
}
```

- [ ] **Step 2: Run; confirm fail**

Run: `cd ios/Packages/ForRealKit && swift test --filter APIClientPostFaxTests`
Expected: FAIL — `postFax` not defined.

- [ ] **Step 3: Implement postFax**

Append to `ios/Packages/ForRealKit/Sources/ForRealKit/API/APIClient.swift`:

```swift
extension APIClient {

    public struct PostFaxResult: Decodable, Sendable, Equatable {
        public let receiptID: String
        public let status: String
        public let cached: Bool

        enum CodingKeys: String, CodingKey {
            case receiptID = "receipt_id"
            case status
            case cached
        }
    }

    public func postFax(url: String) async throws -> PostFaxResult {
        struct Body: Encodable { let url: String }
        return try await send(method: "POST", path: "/v1/receipts", body: Body(url: url))
    }
}
```

- [ ] **Step 4: Run; confirm pass**

Run: `cd ios/Packages/ForRealKit && swift test --filter APIClientPostFaxTests`
Expected: PASS — 3 tests.

- [ ] **Step 5: Commit**

```bash
git add ios/Packages/ForRealKit/Sources/ForRealKit/API/APIClient.swift ios/Packages/ForRealKit/Tests/ForRealKitTests/APIClientTests.swift
git commit -m "feat(ios/ForRealKit): APIClient.postFax (idempotency response)"
```

---

## Task 9: APIClient — list + delete

**Files:**
- Modify: `ios/Packages/ForRealKit/Sources/ForRealKit/API/APIClient.swift`
- Modify: `ios/Packages/ForRealKit/Tests/ForRealKitTests/APIClientTests.swift`

- [ ] **Step 1: Write failing tests**

Append to `APIClientTests.swift`:

```swift
@Suite("APIClient — list + delete (live network)")
struct APIClientListDeleteTests {

    @Test("list returns the calling device's faxes")
    func listForDevice() async throws {
        let device = "test-device-fr-list-\(Int.random(in: 100_000...999_999))"
        let client = APIClient(environment: .dev, deviceID: device)
        _ = try await client.postFax(url: "https://www.youtube.com/watch?v=fr-list-\(UUID().uuidString)")

        let summaries = try await client.listFaxes(limit: 10, before: nil)
        #expect(!summaries.isEmpty)
    }

    @Test("delete unlinks a fax owned by the device")
    func deleteOwnFax() async throws {
        let device = "test-device-fr-delete-\(Int.random(in: 100_000...999_999))"
        let client = APIClient(environment: .dev, deviceID: device)
        let result = try await client.postFax(url: "https://www.youtube.com/watch?v=fr-delete-\(UUID().uuidString)")

        try await client.deleteFax(id: result.receiptID)

        // After delete, listing should not show it.
        let summaries = try await client.listFaxes(limit: 10, before: nil)
        #expect(!summaries.contains { $0.id == result.receiptID })
    }

    @Test("delete on missing id throws notFound")
    func deleteMissingID() async throws {
        let client = APIClient(environment: .dev, deviceID: "test-device-fr-delete-missing")
        do {
            try await client.deleteFax(id: "00000000-0000-0000-0000-000000000000")
            Issue.record("expected APIError.notFound")
        } catch APIError.notFound {
            // expected
        }
    }
}
```

- [ ] **Step 2: Run; confirm fail**

Run: `cd ios/Packages/ForRealKit && swift test --filter APIClientListDeleteTests`
Expected: FAIL — `listFaxes`, `deleteFax`, `FaxSummary` not defined.

- [ ] **Step 3: Implement**

Append to `APIClient.swift`:

```swift
public struct FaxSummary: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let sourceURL: String
    public let sourceType: SourceType
    public let sourceProvider: SourceProvider
    public let title: String?
    public let status: Fax.Status
    public let finalVerdict: Verdict?
    public let finalCommentary: String?
    public let createdAt: Int
    public let finishedAt: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case sourceURL = "source_url"
        case sourceType = "source_type"
        case sourceProvider = "source_provider"
        case title, status
        case finalVerdict = "final_verdict"
        case finalCommentary = "final_commentary"
        case createdAt = "created_at"
        case finishedAt = "finished_at"
    }
}

extension APIClient {

    public func listFaxes(limit: Int?, before: Int?) async throws -> [FaxSummary] {
        var path = "/v1/receipts"
        var params: [String] = []
        if let limit { params.append("limit=\(limit)") }
        if let before { params.append("before=\(before)") }
        if !params.isEmpty { path += "?" + params.joined(separator: "&") }

        struct Wrapper: Decodable { let receipts: [FaxSummary] }
        let wrapper: Wrapper = try await get(path)
        return wrapper.receipts
    }

    public func deleteFax(id: String) async throws {
        var request = URLRequest(url: environment.baseURL.appendingPathComponent("/v1/receipts/\(id)"))
        request.httpMethod = "DELETE"
        request.setValue(deviceID, forHTTPHeaderField: "X-Receipts-Device")

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport(message: "non-HTTP response")
        }
        switch http.statusCode {
        case 204: return
        case 404: throw APIError.notFound
        case 403: throw APIError.forbidden
        default:  throw APIError.http(status: http.statusCode, body: nil)
        }
    }
}
```

- [ ] **Step 4: Run; confirm pass**

Run: `cd ios/Packages/ForRealKit && swift test --filter APIClientListDeleteTests`
Expected: PASS — 3 tests.

- [ ] **Step 5: Commit**

```bash
git add ios/Packages/ForRealKit/Sources/ForRealKit/API/APIClient.swift ios/Packages/ForRealKit/Tests/ForRealKitTests/APIClientTests.swift
git commit -m "feat(ios/ForRealKit): APIClient list + delete"
```

---

## Task 10: DeviceID (Keychain-backed UUID)

**Files:**
- Create: `ios/Packages/ForRealKit/Sources/ForRealKit/API/DeviceID.swift`
- Create: `ios/Packages/ForRealKit/Tests/ForRealKitTests/DeviceIDTests.swift`

The device ID is a UUID generated on first launch and persisted in Keychain so it survives reinstall (per spec §4 State).

- [ ] **Step 1: Write failing tests**

Create `ios/Packages/ForRealKit/Tests/ForRealKitTests/DeviceIDTests.swift`:

```swift
import Testing
import Foundation
@testable import ForRealKit

@Suite("DeviceID")
struct DeviceIDTests {

    @Test("generates a UUID-shaped string when none is stored")
    func generatesNewUUID() {
        let store = InMemoryDeviceIDStore()
        let id = DeviceID.resolve(store: store)
        #expect(id.count == 36)
        #expect(id.contains("-"))
    }

    @Test("returns the same id on subsequent calls")
    func stableAcrossCalls() {
        let store = InMemoryDeviceIDStore()
        let a = DeviceID.resolve(store: store)
        let b = DeviceID.resolve(store: store)
        #expect(a == b)
    }
}

final class InMemoryDeviceIDStore: DeviceIDStore, @unchecked Sendable {
    private var value: String?
    func read() -> String? { value }
    func write(_ id: String) { value = id }
}
```

- [ ] **Step 2: Run; confirm fail**

Run: `cd ios/Packages/ForRealKit && swift test --filter DeviceIDTests`
Expected: FAIL — `DeviceID`, `DeviceIDStore` not defined.

- [ ] **Step 3: Implement DeviceID + Keychain-backed store**

Create `ios/Packages/ForRealKit/Sources/ForRealKit/API/DeviceID.swift`:

```swift
import Foundation
#if canImport(Security)
import Security
#endif

public protocol DeviceIDStore: Sendable {
    func read() -> String?
    func write(_ id: String)
}

public enum DeviceID {

    /// Resolves the device's stable ID, generating + persisting one if none exists.
    public static func resolve(store: any DeviceIDStore = KeychainDeviceIDStore()) -> String {
        if let existing = store.read() { return existing }
        let fresh = UUID().uuidString
        store.write(fresh)
        return fresh
    }
}

#if canImport(Security)
public final class KeychainDeviceIDStore: DeviceIDStore, Sendable {

    private let service = "com.bworthy.forreal.device-id"
    private let account = "default"

    public init() {}

    public func read() -> String? {
        let query: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrService as String:     service,
            kSecAttrAccount as String:     account,
            kSecReturnData as String:      true,
            kSecMatchLimit as String:      kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let str = String(data: data, encoding: .utf8)
        else { return nil }
        return str
    }

    public func write(_ id: String) {
        let data = Data(id.utf8)
        let query: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrService as String:     service,
            kSecAttrAccount as String:     account,
        ]
        SecItemDelete(query as CFDictionary)
        var attrs = query
        attrs[kSecValueData as String]   = data
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attrs as CFDictionary, nil)
    }
}
#else
// Fallback for non-Security platforms (e.g., the macOS test host has Security, but for
// completeness if this ever runs on Linux or in a worker context).
public final class KeychainDeviceIDStore: DeviceIDStore, Sendable {
    public init() {}
    public func read() -> String? { nil }
    public func write(_ id: String) {}
}
#endif
```

- [ ] **Step 4: Run; confirm pass**

Run: `cd ios/Packages/ForRealKit && swift test --filter DeviceIDTests`
Expected: PASS — 2 tests.

- [ ] **Step 5: Commit**

```bash
git add ios/Packages/ForRealKit/Sources/ForRealKit/API/DeviceID.swift ios/Packages/ForRealKit/Tests/ForRealKitTests/DeviceIDTests.swift
git commit -m "feat(ios/ForRealKit): DeviceID with Keychain-backed store"
```

---

## Task 11: SSE stream consumer

**Files:**
- Create: `ios/Packages/ForRealKit/Sources/ForRealKit/API/SSEStreamConsumer.swift`
- Create: `ios/Packages/ForRealKit/Tests/ForRealKitTests/SSEStreamConsumerTests.swift`

Wraps `URLSession.bytes(for:)` to consume `event:` / `data:` blocks and emit a typed event stream that the UI can iterate.

- [ ] **Step 1: Write the parsing test (no network)**

Create `ios/Packages/ForRealKit/Tests/ForRealKitTests/SSEStreamConsumerTests.swift`:

```swift
import Testing
import Foundation
@testable import ForRealKit

@Suite("SSE block parser")
struct SSEParserTests {

    @Test("parses a status event")
    func parsesStatus() throws {
        let block = "event: status\ndata: {\"status\":\"streaming\"}"
        let event = try SSEStreamConsumer.parseBlock(block)

        if case .status(let payload) = event {
            #expect(payload.status == "streaming")
        } else {
            Issue.record("expected status event")
        }
    }

    @Test("parses a claim_final event")
    func parsesClaim() throws {
        let block = """
        event: claim_final
        data: {"position":1,"claim_text":"x","verdict":"nope","commentary":"no","sources":[]}
        """
        let event = try SSEStreamConsumer.parseBlock(block)
        if case .claimFinal(let claim) = event {
            #expect(claim.position == 1)
            #expect(claim.verdict == .nope)
        } else {
            Issue.record("expected claim_final event")
        }
    }

    @Test("parses a receipt_final event")
    func parsesFinal() throws {
        let block = """
        event: receipt_final
        data: {"final_verdict":"mixed","final_commentary":"meh"}
        """
        let event = try SSEStreamConsumer.parseBlock(block)
        if case .receiptFinal(let payload) = event {
            #expect(payload.finalVerdict == .mixed)
            #expect(payload.finalCommentary == "meh")
        } else {
            Issue.record("expected receipt_final event")
        }
    }

    @Test("parses an error event")
    func parsesError() throws {
        let block = """
        event: error
        data: {"error_code":"provider_blocked","message":"oops"}
        """
        let event = try SSEStreamConsumer.parseBlock(block)
        if case .error(let payload) = event {
            #expect(payload.errorCode == "provider_blocked")
        } else {
            Issue.record("expected error event")
        }
    }
}

@Suite("SSEStreamConsumer (live network — requires deployed dev worker)")
struct SSEStreamConsumerLiveTests {

    @Test("end-to-end: post then stream produces the full event sequence")
    func postThenStream() async throws {
        let device = "test-device-fr-sse-\(Int.random(in: 100_000...999_999))"
        let client = APIClient(environment: .dev, deviceID: device)
        let post = try await client.postFax(url: "https://www.youtube.com/watch?v=fr-sse-\(UUID().uuidString)")

        let consumer = SSEStreamConsumer(environment: .dev, deviceID: device)
        var events: [SSEStreamConsumer.Event] = []
        for try await event in consumer.events(forFaxID: post.receiptID) {
            events.append(event)
        }

        let kinds = events.map { $0.kindLabel }
        #expect(kinds == ["status", "claim_final", "claim_final", "claim_final", "receipt_final"])
    }
}
```

- [ ] **Step 2: Run; confirm fail**

Run: `cd ios/Packages/ForRealKit && swift test --filter SSEParserTests`
Expected: FAIL — `SSEStreamConsumer` not defined.

- [ ] **Step 3: Implement the consumer**

Create `ios/Packages/ForRealKit/Sources/ForRealKit/API/SSEStreamConsumer.swift`:

```swift
import Foundation

public actor SSEStreamConsumer {

    public enum Event: Sendable {
        case status(StatusPayload)
        case claimFinal(Claim)
        case receiptFinal(ReceiptFinalPayload)
        case error(ErrorPayload)

        public var kindLabel: String {
            switch self {
            case .status:        "status"
            case .claimFinal:    "claim_final"
            case .receiptFinal:  "receipt_final"
            case .error:         "error"
            }
        }
    }

    public struct StatusPayload: Decodable, Sendable, Equatable {
        public let status: String
    }

    public struct ReceiptFinalPayload: Decodable, Sendable, Equatable {
        public let finalVerdict: Verdict
        public let finalCommentary: String

        enum CodingKeys: String, CodingKey {
            case finalVerdict = "final_verdict"
            case finalCommentary = "final_commentary"
        }
    }

    public struct ErrorPayload: Decodable, Sendable, Equatable {
        public let errorCode: String
        public let message: String

        enum CodingKeys: String, CodingKey {
            case errorCode = "error_code"
            case message
        }
    }

    private let environment: APIEnvironment
    private let deviceID: String
    private let session: URLSession

    public init(environment: APIEnvironment, deviceID: String, session: URLSession = .shared) {
        self.environment = environment
        self.deviceID = deviceID
        self.session = session
    }

    public func events(forFaxID id: String) -> AsyncThrowingStream<Event, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = URLRequest(url: environment.baseURL.appendingPathComponent("/v1/receipts/\(id)/stream"))
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.setValue(deviceID, forHTTPHeaderField: "X-Receipts-Device")

                    let (bytes, response) = try await session.bytes(for: request)
                    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                        throw APIError.http(status: status, body: nil)
                    }

                    var buffer = ""
                    for try await line in bytes.lines {
                        if line.isEmpty {
                            // End of one event block.
                            if !buffer.isEmpty {
                                let event = try Self.parseBlock(buffer)
                                continuation.yield(event)
                                buffer = ""
                            }
                        } else {
                            if !buffer.isEmpty { buffer += "\n" }
                            buffer += line
                        }
                    }
                    // Trailing block without final blank.
                    if !buffer.isEmpty {
                        let event = try Self.parseBlock(buffer)
                        continuation.yield(event)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Parses a single SSE event block (event: + data: lines, no trailing blank).
    public static func parseBlock(_ block: String) throws -> Event {
        var eventName = "message"
        var dataLines: [String] = []
        for line in block.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.hasPrefix("event: ") {
                eventName = String(line.dropFirst("event: ".count)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data: ") {
                dataLines.append(String(line.dropFirst("data: ".count)))
            }
        }
        let data = Data(dataLines.joined(separator: "\n").utf8)

        switch eventName {
        case "status":
            return .status(try JSONDecoder().decode(StatusPayload.self, from: data))
        case "claim_final":
            return .claimFinal(try JSONDecoder().decode(Claim.self, from: data))
        case "receipt_final":
            return .receiptFinal(try JSONDecoder().decode(ReceiptFinalPayload.self, from: data))
        case "error":
            return .error(try JSONDecoder().decode(ErrorPayload.self, from: data))
        default:
            throw APIError.decoding(message: "unknown event: \(eventName)")
        }
    }
}
```

- [ ] **Step 4: Run; confirm pass**

With `pnpm --filter @crimeboard/api run dev` running in another terminal:
```bash
cd ios/Packages/ForRealKit && swift test --filter SSEParserTests --filter SSEStreamConsumerLiveTests
```
Expected: PASS — 5 tests (4 parser + 1 live). Note: the live test takes ~3s per the stub `STUB_DELAY_MS=600`.

- [ ] **Step 5: Commit**

```bash
git add ios/Packages/ForRealKit/Sources/ForRealKit/API/SSEStreamConsumer.swift ios/Packages/ForRealKit/Tests/ForRealKitTests/SSEStreamConsumerTests.swift
git commit -m "feat(ios/ForRealKit): SSEStreamConsumer for /v1/receipts/:id/stream"
```

---

## Task 12: SwiftData FaxStore

**Files:**
- Create: `ios/Packages/ForRealKit/Sources/ForRealKit/Store/FaxStore.swift`
- Create: `ios/Packages/ForRealKit/Tests/ForRealKitTests/FaxStoreTests.swift`

Local persistence so the user can re-open a past fax (the Recent screen, Plan 6, will read from this).

- [ ] **Step 1: Write failing tests**

Create `ios/Packages/ForRealKit/Tests/ForRealKitTests/FaxStoreTests.swift`:

```swift
import Testing
import Foundation
import SwiftData
@testable import ForRealKit

@Suite("FaxStore")
@MainActor
struct FaxStoreTests {

    private func makeStore() throws -> FaxStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PersistedFax.self, PersistedClaim.self,
            configurations: config
        )
        return FaxStore(container: container)
    }

    @Test("upsert + fetch round-trips a fax")
    func upsertFetch() throws {
        let store = try makeStore()
        let fax = sampleFax(id: "fax-x", verdict: .nope)
        try store.upsert(fax)

        let fetched = try store.fetch(id: "fax-x")
        #expect(fetched?.id == "fax-x")
        #expect(fetched?.finalVerdict == .nope)
        #expect(fetched?.claims.count == 3)
    }

    @Test("listMostRecent returns newest first")
    func listMostRecent() throws {
        let store = try makeStore()
        try store.upsert(sampleFax(id: "old", createdAt: 100))
        try store.upsert(sampleFax(id: "new", createdAt: 200))

        let list = try store.listMostRecent(limit: 10)
        #expect(list.map(\.id) == ["new", "old"])
    }

    @Test("upsert is idempotent on id")
    func upsertIdempotent() throws {
        let store = try makeStore()
        try store.upsert(sampleFax(id: "same", verdict: .nope))
        try store.upsert(sampleFax(id: "same", verdict: .yep))

        let list = try store.listMostRecent(limit: 10)
        #expect(list.count == 1)
        #expect(list.first?.finalVerdict == .yep)
    }

    private func sampleFax(id: String, verdict: Verdict = .nope, createdAt: Int = 1700000000) -> Fax {
        Fax(
            id: id,
            sourceURL: "https://yt/\(id)",
            sourceType: .video,
            sourceProvider: .youtube,
            title: nil,
            status: .done,
            finalVerdict: verdict,
            finalCommentary: "test",
            errorCode: nil,
            createdAt: createdAt,
            finishedAt: createdAt + 60,
            claims: (1...3).map {
                Claim(position: $0, claimText: "c\($0)", verdict: .nope, commentary: "no",
                      sources: [], resolvedAt: createdAt + $0)
            }
        )
    }
}
```

- [ ] **Step 2: Run; confirm fail**

Run: `cd ios/Packages/ForRealKit && swift test --filter FaxStoreTests`
Expected: FAIL — `FaxStore`, `PersistedFax`, `PersistedClaim` not defined.

- [ ] **Step 3: Implement FaxStore**

Create `ios/Packages/ForRealKit/Sources/ForRealKit/Store/FaxStore.swift`:

```swift
import Foundation
import SwiftData

@Model
public final class PersistedFax {
    @Attribute(.unique) public var id: String
    public var sourceURL: String
    public var sourceTypeRaw: String
    public var sourceProviderRaw: String
    public var title: String?
    public var statusRaw: String
    public var finalVerdictRaw: String?
    public var finalCommentary: String?
    public var errorCode: String?
    public var createdAt: Int
    public var finishedAt: Int?

    @Relationship(deleteRule: .cascade, inverse: \PersistedClaim.fax)
    public var claims: [PersistedClaim] = []

    public init(
        id: String, sourceURL: String, sourceTypeRaw: String, sourceProviderRaw: String,
        title: String?, statusRaw: String, finalVerdictRaw: String?, finalCommentary: String?,
        errorCode: String?, createdAt: Int, finishedAt: Int?
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.sourceTypeRaw = sourceTypeRaw
        self.sourceProviderRaw = sourceProviderRaw
        self.title = title
        self.statusRaw = statusRaw
        self.finalVerdictRaw = finalVerdictRaw
        self.finalCommentary = finalCommentary
        self.errorCode = errorCode
        self.createdAt = createdAt
        self.finishedAt = finishedAt
    }
}

@Model
public final class PersistedClaim {
    public var position: Int
    public var claimText: String
    public var verdictRaw: String
    public var commentary: String
    /// JSON-encoded array of {url,title}.
    public var sourcesJSON: String
    public var resolvedAt: Int
    public var fax: PersistedFax?

    public init(position: Int, claimText: String, verdictRaw: String, commentary: String,
                sourcesJSON: String, resolvedAt: Int) {
        self.position = position
        self.claimText = claimText
        self.verdictRaw = verdictRaw
        self.commentary = commentary
        self.sourcesJSON = sourcesJSON
        self.resolvedAt = resolvedAt
    }
}

@MainActor
public final class FaxStore {

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    public init(container: ModelContainer) {
        self.container = container
    }

    public func upsert(_ fax: Fax) throws {
        // If exists, delete its claims and update; otherwise insert.
        let id = fax.id
        let descriptor = FetchDescriptor<PersistedFax>(predicate: #Predicate { $0.id == id })
        if let existing = try context.fetch(descriptor).first {
            // Cascade-delete existing claims via SwiftData.
            for c in existing.claims { context.delete(c) }
            existing.sourceURL = fax.sourceURL
            existing.sourceTypeRaw = fax.sourceType.rawValue
            existing.sourceProviderRaw = fax.sourceProvider.rawValue
            existing.title = fax.title
            existing.statusRaw = fax.status.rawValue
            existing.finalVerdictRaw = fax.finalVerdict?.rawValue
            existing.finalCommentary = fax.finalCommentary
            existing.errorCode = fax.errorCode
            existing.createdAt = fax.createdAt
            existing.finishedAt = fax.finishedAt
            existing.claims = try fax.claims.map { try Self.persisted(from: $0, context: context) }
        } else {
            let row = PersistedFax(
                id: fax.id, sourceURL: fax.sourceURL,
                sourceTypeRaw: fax.sourceType.rawValue,
                sourceProviderRaw: fax.sourceProvider.rawValue,
                title: fax.title, statusRaw: fax.status.rawValue,
                finalVerdictRaw: fax.finalVerdict?.rawValue,
                finalCommentary: fax.finalCommentary,
                errorCode: fax.errorCode,
                createdAt: fax.createdAt, finishedAt: fax.finishedAt
            )
            context.insert(row)
            row.claims = try fax.claims.map { try Self.persisted(from: $0, context: context) }
        }
        try context.save()
    }

    public func fetch(id: String) throws -> Fax? {
        let descriptor = FetchDescriptor<PersistedFax>(predicate: #Predicate { $0.id == id })
        guard let row = try context.fetch(descriptor).first else { return nil }
        return try Self.fax(from: row)
    }

    public func listMostRecent(limit: Int) throws -> [Fax] {
        var descriptor = FetchDescriptor<PersistedFax>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor).map { try Self.fax(from: $0) }
    }

    // MARK: - Bridges

    private static func persisted(from claim: Claim, context: ModelContext) throws -> PersistedClaim {
        let json = try JSONEncoder().encode(claim.sources)
        let p = PersistedClaim(
            position: claim.position,
            claimText: claim.claimText,
            verdictRaw: claim.verdict.rawValue,
            commentary: claim.commentary,
            sourcesJSON: String(data: json, encoding: .utf8) ?? "[]",
            resolvedAt: claim.resolvedAt
        )
        context.insert(p)
        return p
    }

    private static func fax(from row: PersistedFax) throws -> Fax {
        let claims: [Claim] = try row.claims
            .sorted { $0.position < $1.position }
            .map {
                let sources = try JSONDecoder().decode([Claim.Source].self, from: Data($0.sourcesJSON.utf8))
                guard let verdict = Verdict(rawValue: $0.verdictRaw) else {
                    throw APIError.decoding(message: "bad verdict in store: \($0.verdictRaw)")
                }
                return Claim(
                    position: $0.position, claimText: $0.claimText, verdict: verdict,
                    commentary: $0.commentary, sources: sources, resolvedAt: $0.resolvedAt
                )
            }

        guard let sourceType = SourceType(rawValue: row.sourceTypeRaw),
              let sourceProvider = SourceProvider(rawValue: row.sourceProviderRaw),
              let status = Fax.Status(rawValue: row.statusRaw)
        else {
            throw APIError.decoding(message: "bad enum in store")
        }
        let finalVerdict = row.finalVerdictRaw.flatMap(Verdict.init(rawValue:))
        return Fax(
            id: row.id, sourceURL: row.sourceURL,
            sourceType: sourceType, sourceProvider: sourceProvider,
            title: row.title, status: status,
            finalVerdict: finalVerdict, finalCommentary: row.finalCommentary,
            errorCode: row.errorCode,
            createdAt: row.createdAt, finishedAt: row.finishedAt,
            claims: claims
        )
    }
}
```

- [ ] **Step 4: Run; confirm pass**

Run: `cd ios/Packages/ForRealKit && swift test --filter FaxStoreTests`
Expected: PASS — 3 tests.

- [ ] **Step 5: Commit**

```bash
git add ios/Packages/ForRealKit/Sources/ForRealKit/Store/FaxStore.swift ios/Packages/ForRealKit/Tests/ForRealKitTests/FaxStoreTests.swift
git commit -m "feat(ios/ForRealKit): SwiftData FaxStore (upsert/fetch/listMostRecent)"
```

---

## Task 13: `@Observable` ReceiptCoordinator

**Files:**
- Create: `ios/Packages/ForRealKit/Sources/ForRealKit/Store/ReceiptCoordinator.swift`
- Create: `ios/Packages/ForRealKit/Tests/ForRealKitTests/ReceiptCoordinatorTests.swift`

The coordinator owns the in-flight stream state (which fax, which claims arrived, final verdict, error). The Fax view reads from it; SSE events from the consumer mutate it; on `receipt_final` it persists to the FaxStore. This is the MV "store" the brief refers to.

- [ ] **Step 1: Write failing tests (in-memory client + store)**

Create `ios/Packages/ForRealKit/Tests/ForRealKitTests/ReceiptCoordinatorTests.swift`:

```swift
import Testing
import Foundation
import SwiftData
@testable import ForRealKit

@Suite("ReceiptCoordinator")
@MainActor
struct ReceiptCoordinatorTests {

    @Test("starting analysis transitions to streaming and yields claims")
    func happyPath() async throws {
        let mockClient = MockAPIClient()
        let mockConsumer = MockSSEConsumer(events: [
            .status(.init(status: "streaming")),
            .claimFinal(.fixture(position: 1, verdict: .nope)),
            .claimFinal(.fixture(position: 2, verdict: .mixed)),
            .claimFinal(.fixture(position: 3, verdict: .yep)),
            .receiptFinal(.init(finalVerdict: .mixed, finalCommentary: "ok")),
        ])
        let store = try inMemoryStore()
        let coord = ReceiptCoordinator(client: mockClient, consumer: mockConsumer, store: store)

        #expect(coord.state == .idle)
        try await coord.analyze(url: "https://yt/x")

        // After completion, state is .final with the synthesized fax.
        if case .final(let fax) = coord.state {
            #expect(fax.finalVerdict == .mixed)
            #expect(fax.claims.count == 3)
            #expect(fax.status == .done)
        } else {
            Issue.record("expected .final, got \(coord.state)")
        }

        // Persisted to the store.
        let persisted = try store.fetch(id: fax(coord.state).id)
        #expect(persisted?.finalVerdict == .mixed)
    }

    @Test("error event transitions to .failed")
    func errorPath() async throws {
        let mockClient = MockAPIClient()
        let mockConsumer = MockSSEConsumer(events: [
            .error(.init(errorCode: "provider_blocked", message: "oops")),
        ])
        let store = try inMemoryStore()
        let coord = ReceiptCoordinator(client: mockClient, consumer: mockConsumer, store: store)

        try await coord.analyze(url: "https://tt/x")

        if case .failed(let code) = coord.state {
            #expect(code == "provider_blocked")
        } else {
            Issue.record("expected .failed")
        }
    }

    private func fax(_ state: ReceiptCoordinator.State) -> Fax {
        if case .final(let fax) = state { return fax }
        fatalError("not final")
    }

    private func inMemoryStore() throws -> FaxStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistedFax.self, PersistedClaim.self, configurations: config)
        return FaxStore(container: container)
    }
}

// MARK: - Test doubles

extension Claim {
    static func fixture(position: Int, verdict: Verdict) -> Claim {
        Claim(position: position, claimText: "c\(position)", verdict: verdict,
              commentary: "x", sources: [], resolvedAt: 1700000000 + position)
    }
}

final class MockAPIClient: ReceiptAPI, @unchecked Sendable {
    var lastURL: String?
    func postFax(url: String) async throws -> APIClient.PostFaxResult {
        lastURL = url
        return .init(receiptID: "fax-mock", status: "pending", cached: false)
    }
}

final class MockSSEConsumer: ReceiptSSE, @unchecked Sendable {
    private var events: [SSEStreamConsumer.Event]
    init(events: [SSEStreamConsumer.Event]) { self.events = events }
    func events(forFaxID id: String) -> AsyncThrowingStream<SSEStreamConsumer.Event, Error> {
        let captured = events
        return AsyncThrowingStream { continuation in
            Task {
                for e in captured { continuation.yield(e) }
                continuation.finish()
            }
        }
    }
}
```

- [ ] **Step 2: Run; confirm fail**

Run: `cd ios/Packages/ForRealKit && swift test --filter ReceiptCoordinatorTests`
Expected: FAIL — `ReceiptCoordinator`, `ReceiptAPI`, `ReceiptSSE` not defined.

- [ ] **Step 3: Implement coordinator + protocols**

Create `ios/Packages/ForRealKit/Sources/ForRealKit/Store/ReceiptCoordinator.swift`:

```swift
import Foundation
import Observation

public protocol ReceiptAPI: Sendable {
    func postFax(url: String) async throws -> APIClient.PostFaxResult
}

public protocol ReceiptSSE: Sendable {
    func events(forFaxID id: String) -> AsyncThrowingStream<SSEStreamConsumer.Event, Error>
}

extension APIClient: ReceiptAPI {}
extension SSEStreamConsumer: ReceiptSSE {}

@Observable
@MainActor
public final class ReceiptCoordinator {

    public enum State: Equatable {
        case idle
        case streaming(faxID: String, partial: [Claim], final: PartialFinal?)
        case final(Fax)
        case failed(errorCode: String)

        public struct PartialFinal: Equatable, Sendable {
            public var verdict: Verdict
            public var commentary: String
        }
    }

    public private(set) var state: State = .idle

    private let client: any ReceiptAPI
    private let consumer: any ReceiptSSE
    private let store: FaxStore

    public init(client: any ReceiptAPI, consumer: any ReceiptSSE, store: FaxStore) {
        self.client = client
        self.consumer = consumer
        self.store = store
    }

    public func analyze(url: String) async throws {
        let post = try await client.postFax(url: url)
        let faxID = post.receiptID

        var partial: [Claim] = []
        var final: State.PartialFinal?
        state = .streaming(faxID: faxID, partial: partial, final: final)

        for try await event in consumer.events(forFaxID: faxID) {
            switch event {
            case .status:
                continue
            case .claimFinal(let claim):
                partial.append(claim)
                state = .streaming(faxID: faxID, partial: partial, final: final)
            case .receiptFinal(let payload):
                final = .init(verdict: payload.finalVerdict, commentary: payload.finalCommentary)
                state = .streaming(faxID: faxID, partial: partial, final: final)
            case .error(let payload):
                state = .failed(errorCode: payload.errorCode)
                return
            }
        }

        guard let final else {
            // Stream ended without a receipt_final; treat as failure.
            state = .failed(errorCode: "stream_ended_unexpectedly")
            return
        }

        let now = Int(Date().timeIntervalSince1970)
        let fax = Fax(
            id: faxID,
            sourceURL: url,
            sourceType: inferType(from: url),
            sourceProvider: inferProvider(from: url),
            title: nil,
            status: .done,
            finalVerdict: final.verdict,
            finalCommentary: final.commentary,
            errorCode: nil,
            createdAt: now,
            finishedAt: now,
            claims: partial.sorted { $0.position < $1.position }
        )
        try store.upsert(fax)
        state = .final(fax)
    }

    public func reset() { state = .idle }

    // MARK: - URL inference (lightweight; the backend already classifies authoritatively)

    private func inferType(from url: String) -> SourceType {
        if url.contains("tiktok.com") || url.contains("youtube.com") || url.contains("youtu.be") {
            return .video
        }
        return .article
    }

    private func inferProvider(from url: String) -> SourceProvider {
        if url.contains("tiktok.com") { return .tiktok }
        if url.contains("youtube.com") || url.contains("youtu.be") { return .youtube }
        return .article
    }
}
```

- [ ] **Step 4: Run; confirm pass**

Run: `cd ios/Packages/ForRealKit && swift test --filter ReceiptCoordinatorTests`
Expected: PASS — 2 tests.

- [ ] **Step 5: Commit**

```bash
git add ios/Packages/ForRealKit/Sources/ForRealKit/Store/ReceiptCoordinator.swift ios/Packages/ForRealKit/Tests/ForRealKitTests/ReceiptCoordinatorTests.swift
git commit -m "feat(ios/ForRealKit): @Observable ReceiptCoordinator (in-flight stream + persist)"
```

---

## Task 14: ForRealUI color tokens (Zesty Lemon palette)

**Files:**
- Create: `ios/Packages/ForRealUI/Sources/ForRealUI/Tokens/Color+Lemon.swift`
- Create: `ios/Packages/ForRealUI/Tests/ForRealUITests/ColorTokensTests.swift`

Per DESIGN.md: Zesty Lemon (#FFFF66) → Lemon Cream (#FFE566) → Lemon Sage (#D6D58B) → Olive Anchor (#B3B347), plus warm Charcoal (NOT #000) for body type.

- [ ] **Step 1: Write failing tests**

Create `ios/Packages/ForRealUI/Tests/ForRealUITests/ColorTokensTests.swift`:

```swift
import Testing
import SwiftUI
@testable import ForRealUI

@Suite("Color tokens")
struct ColorTokensTests {

    @Test("zesty lemon palette is defined")
    func paletteDefined() {
        // We don't compare Color values directly (cross-platform fidelity flaky); we
        // just confirm the static accessors exist and produce distinct Color values.
        let lemon = Color.zestyLemon
        let cream = Color.lemonCream
        let sage = Color.lemonSage
        let olive = Color.oliveAnchor
        let charcoal = Color.lemonCharcoal
        // Compile-time check is enough.
        _ = (lemon, cream, sage, olive, charcoal)
    }
}
```

- [ ] **Step 2: Run; confirm fail**

Run: `cd ios/Packages/ForRealUI && swift test --filter ColorTokensTests`
Expected: FAIL — `Color.zestyLemon` etc. not defined.

- [ ] **Step 3: Implement the palette**

Create `ios/Packages/ForRealUI/Sources/ForRealUI/Tokens/Color+Lemon.swift`:

```swift
import SwiftUI

public extension Color {
    /// Drenched primary surface. The fax IS this color.
    static let zestyLemon  = Color(red: 1.00, green: 1.00, blue: 0.40)   // #FFFF66
    /// One step quieter — claim card backgrounds.
    static let lemonCream  = Color(red: 1.00, green: 0.898, blue: 0.40)  // #FFE566
    /// Tertiary surfaces, dividers, inactive states.
    static let lemonSage   = Color(red: 0.839, green: 0.835, blue: 0.545) // #D6D58B
    /// Deep end of the same hue family — grounded chrome.
    static let oliveAnchor = Color(red: 0.702, green: 0.702, blue: 0.278) // #B3B347
    /// Body type. Warm near-black. Explicitly NOT #000.
    static let lemonCharcoal = Color(red: 0.118, green: 0.106, blue: 0.082) // ~OKLCH 18% L tinted toward yellow
}
```

- [ ] **Step 4: Run; confirm pass**

Run: `cd ios/Packages/ForRealUI && swift test --filter ColorTokensTests`
Expected: PASS — 1 test.

- [ ] **Step 5: Commit**

```bash
git add ios/Packages/ForRealUI/Sources/ForRealUI/Tokens/Color+Lemon.swift ios/Packages/ForRealUI/Tests/ForRealUITests/ColorTokensTests.swift
git commit -m "feat(ios/ForRealUI): Zesty Lemon color tokens"
```

---

## Task 15: ForRealUI typography wrapper

**Files:**
- Create: `ios/Packages/ForRealUI/Sources/ForRealUI/Tokens/Typography.swift`
- Create: `ios/Packages/ForRealUI/Tests/ForRealUITests/TypographyTests.swift`

The shape brief locks **single humanist sans across the entire app**. SwiftUI's `Font.system(.rounded, design: .default)` with weight contrast does most of the work; we wrap it for consistency.

- [ ] **Step 1: Write failing tests**

Create `ios/Packages/ForRealUI/Tests/ForRealUITests/TypographyTests.swift`:

```swift
import Testing
import SwiftUI
@testable import ForRealUI

@Suite("Typography tokens")
struct TypographyTests {

    @Test("type scale is defined")
    func scaleDefined() {
        let _ = ForRealType.verdictDisplay
        let _ = ForRealType.headline
        let _ = ForRealType.body
        let _ = ForRealType.label
    }
}
```

- [ ] **Step 2: Run; confirm fail**

Run: `cd ios/Packages/ForRealUI && swift test --filter TypographyTests`
Expected: FAIL — `ForRealType` not defined.

- [ ] **Step 3: Implement**

Create `ios/Packages/ForRealUI/Sources/ForRealUI/Tokens/Typography.swift`:

```swift
import SwiftUI

/// One humanist sans family across the whole app. Weight + size do the hierarchy work.
/// Sizes are starting points; Dynamic Type scales them.
public enum ForRealType {
    /// 56pt heavy — the verdict word on the fax. Single largest type element on any screen.
    public static let verdictDisplay: Font = .system(size: 56, weight: .heavy, design: .default)
    /// 24pt semibold — claim text and primary copy.
    public static let headline: Font = .system(size: 24, weight: .semibold, design: .default)
    /// 16pt regular — bestie commentary, source titles.
    public static let body: Font = .system(size: 16, weight: .regular, design: .default)
    /// 12pt medium — metadata. Slight tracking via .tracking(...) at the call site.
    public static let label: Font = .system(size: 12, weight: .medium, design: .default)
}

public extension View {
    /// Convenience: apply ForRealType.label and the project's standard tracking + uppercase.
    func forRealLabelStyle() -> some View {
        self.font(ForRealType.label)
            .tracking(1.2)
            .textCase(.uppercase)
    }
}
```

- [ ] **Step 4: Run; confirm pass**

Run: `cd ios/Packages/ForRealUI && swift test --filter TypographyTests`
Expected: PASS — 1 test.

- [ ] **Step 5: Commit**

```bash
git add ios/Packages/ForRealUI/Sources/ForRealUI/Tokens/Typography.swift ios/Packages/ForRealUI/Tests/ForRealUITests/TypographyTests.swift
git commit -m "feat(ios/ForRealUI): typography tokens (humanist sans, weight-driven hierarchy)"
```

---

## Task 16: ForRealUI motion tokens

**Files:**
- Create: `ios/Packages/ForRealUI/Sources/ForRealUI/Tokens/Motion.swift`
- Create: `ios/Packages/ForRealUI/Tests/ForRealUITests/MotionTokensTests.swift`

Per the shape brief: sheet up ~350ms ease-out-quart; claim arrival ~250ms ease-out-quart fade+slide-16pt; verdict push-in ~280ms ease-out-quint. Reduce Motion swaps for 100ms color highlights.

- [ ] **Step 1: Write failing tests**

Create `ios/Packages/ForRealUI/Tests/ForRealUITests/MotionTokensTests.swift`:

```swift
import Testing
import SwiftUI
@testable import ForRealUI

@Suite("Motion tokens")
struct MotionTokensTests {

    @Test("durations are within the brief's 200–400ms range")
    func durationsInRange() {
        #expect(ForRealMotion.sheetUp.duration >= 0.2)
        #expect(ForRealMotion.sheetUp.duration <= 0.4)
        #expect(ForRealMotion.claimArrival.duration >= 0.2)
        #expect(ForRealMotion.claimArrival.duration <= 0.4)
        #expect(ForRealMotion.verdictPushIn.duration >= 0.2)
        #expect(ForRealMotion.verdictPushIn.duration <= 0.4)
    }

    @Test("reduce motion duration is short")
    func reduceMotionShort() {
        #expect(ForRealMotion.reduceMotionHighlight.duration <= 0.15)
    }
}
```

- [ ] **Step 2: Run; confirm fail**

Run: `cd ios/Packages/ForRealUI && swift test --filter MotionTokensTests`
Expected: FAIL — `ForRealMotion` not defined.

- [ ] **Step 3: Implement**

Create `ios/Packages/ForRealUI/Sources/ForRealUI/Tokens/Motion.swift`:

```swift
import SwiftUI

public struct ForRealMotionToken: Equatable, Sendable {
    public let duration: Double
    public let curve: Animation
}

public enum ForRealMotion {
    /// Fax sheet rising over Home. ~350ms ease-out-quart.
    public static let sheetUp = ForRealMotionToken(
        duration: 0.35,
        curve: .timingCurve(0.165, 0.84, 0.44, 1.0, duration: 0.35) // ease-out-quart
    )

    /// Claim card appearing — fade + slide-up 16pt. ~250ms ease-out-quart.
    public static let claimArrival = ForRealMotionToken(
        duration: 0.25,
        curve: .timingCurve(0.165, 0.84, 0.44, 1.0, duration: 0.25)
    )

    /// Verdict word pushing in from the top. ~280ms ease-out-quint.
    public static let verdictPushIn = ForRealMotionToken(
        duration: 0.28,
        curve: .timingCurve(0.23, 1.0, 0.32, 1.0, duration: 0.28) // ease-out-quint
    )

    /// Reduce-Motion highlight beat — quick color flash to mark arrival.
    public static let reduceMotionHighlight = ForRealMotionToken(
        duration: 0.10,
        curve: .easeOut(duration: 0.10)
    )
}
```

- [ ] **Step 4: Run; confirm pass**

Run: `cd ios/Packages/ForRealUI && swift test --filter MotionTokensTests`
Expected: PASS — 2 tests.

- [ ] **Step 5: Commit**

```bash
git add ios/Packages/ForRealUI/Sources/ForRealUI/Tokens/Motion.swift ios/Packages/ForRealUI/Tests/ForRealUITests/MotionTokensTests.swift
git commit -m "feat(ios/ForRealUI): motion tokens (ease-out-quart/quint + Reduce Motion variants)"
```

---

## Task 17: Home view (paste box, bestie line, clipboard chip, Recent glyph)

**Files:**
- Create: `ios/Packages/ForRealUI/Sources/ForRealUI/Home/HomeView.swift`
- Create: `ios/Packages/ForRealUI/Sources/ForRealUI/Home/ClipboardChip.swift`
- Create: `ios/Packages/ForRealUI/Tests/ForRealUITests/HomeViewSmokeTests.swift`

The Home screen renders on the drenched Zesty Lemon surface. Layout per shape brief §5:
- Top-right: Recent glyph (small, tap-to-reveal — Plan 6 fills in the overlay).
- Vertical center, slightly above: bestie line. Working copy: *"Drop a link, bestie."* (one of three candidates from Open Q2; pick this one as the default and let `$impeccable critique` revisit).
- Vertical center: paste box. Generous padding.
- Below paste box (conditional): clipboard chip when system clipboard contains a URL.

- [ ] **Step 1: Write the smoke tests (view-construction tests are @MainActor)**

Create `ios/Packages/ForRealUI/Tests/ForRealUITests/HomeViewSmokeTests.swift`:

```swift
import Testing
import SwiftUI
@testable import ForRealUI

@Suite("HomeView smoke")
@MainActor
struct HomeViewSmokeTests {

    @Test("constructs without a clipboard URL")
    func defaultState() {
        let view = HomeView(
            clipboardURL: nil,
            onAnalyze: { _ in },
            onRecentTap: {}
        )
        let _: any View = view
    }

    @Test("constructs with a clipboard URL (chip variant)")
    func clipboardState() {
        let view = HomeView(
            clipboardURL: "https://www.youtube.com/watch?v=abc",
            onAnalyze: { _ in },
            onRecentTap: {}
        )
        let _: any View = view
    }
}
```

- [ ] **Step 2: Run; confirm fail**

Run: `cd ios/Packages/ForRealUI && swift test --filter HomeViewSmokeTests`
Expected: FAIL — `HomeView` not defined.

- [ ] **Step 3: Implement HomeView + ClipboardChip**

Create `ios/Packages/ForRealUI/Sources/ForRealUI/Home/ClipboardChip.swift`:

```swift
#if os(iOS)
import SwiftUI

struct ClipboardChip: View {
    let url: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Text("Check this link?")
                    .font(ForRealType.body.weight(.semibold))
                Text(truncated(url))
                    .forRealLabelStyle()
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.lemonCream, in: RoundedRectangle(cornerRadius: 6))
            .foregroundStyle(Color.lemonCharcoal)
        }
        .accessibilityLabel("Check this link in the clipboard")
        .accessibilityValue(url)
    }

    private func truncated(_ s: String) -> String {
        // The Label-style font already truncates; pass-through here keeps alignment consistent.
        s
    }
}
#endif
```

Create `ios/Packages/ForRealUI/Sources/ForRealUI/Home/HomeView.swift`:

```swift
#if os(iOS)
import SwiftUI

public struct HomeView: View {
    public let clipboardURL: String?
    public let onAnalyze: (String) -> Void
    public let onRecentTap: () -> Void

    @State private var pasteText: String = ""
    @FocusState private var pasteFocused: Bool

    public init(
        clipboardURL: String?,
        onAnalyze: @escaping (String) -> Void,
        onRecentTap: @escaping () -> Void
    ) {
        self.clipboardURL = clipboardURL
        self.onAnalyze = onAnalyze
        self.onRecentTap = onRecentTap
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.zestyLemon.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()
                Text("Drop a link, bestie.")
                    .font(ForRealType.headline)
                    .foregroundStyle(Color.lemonCharcoal)
                    .accessibilityHeading(.h1)

                pasteBox
                    .padding(.horizontal, 24)

                if let clipboardURL {
                    ClipboardChip(url: clipboardURL) { onAnalyze(clipboardURL) }
                        .padding(.horizontal, 24)
                }

                Spacer()
                Spacer()
            }

            Button(action: onRecentTap) {
                Image(systemName: "tray.full")
                    .font(.system(size: 18, weight: .medium))
                    .padding(12)
                    .foregroundStyle(Color.lemonCharcoal)
            }
            .accessibilityLabel("Recent faxes")
            .padding(.top, 8)
            .padding(.trailing, 8)
        }
    }

    private var pasteBox: some View {
        HStack(spacing: 12) {
            TextField("paste a link", text: $pasteText, axis: .vertical)
                .font(ForRealType.headline)
                .foregroundStyle(Color.lemonCharcoal)
                .focused($pasteFocused)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .onSubmit(submitIfValid)

            if !pasteText.isEmpty {
                Button(action: submitIfValid) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32, weight: .bold))
                }
                .foregroundStyle(Color.oliveAnchor)
                .accessibilityLabel("Analyze")
            }
        }
        .padding(20)
        .background(Color.lemonCream, in: RoundedRectangle(cornerRadius: 8))
    }

    private func submitIfValid() {
        let trimmed = pasteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onAnalyze(trimmed)
    }
}
#endif
```

- [ ] **Step 4: Run; confirm pass**

Run: `cd ios/Packages/ForRealUI && swift test --filter HomeViewSmokeTests`
Expected: PASS — 2 tests.

- [ ] **Step 5: Commit**

```bash
git add ios/Packages/ForRealUI/Sources/ForRealUI/Home/ ios/Packages/ForRealUI/Tests/ForRealUITests/HomeViewSmokeTests.swift
git commit -m "feat(ios/ForRealUI): HomeView with paste box, bestie line, clipboard chip, Recent glyph"
```

---

## Task 18: Fax sheet shell (pre-allocated slots)

**Files:**
- Create: `ios/Packages/ForRealUI/Sources/ForRealUI/Fax/FaxSheet.swift`
- Create: `ios/Packages/ForRealUI/Sources/ForRealUI/Fax/VerdictHeader.swift`
- Create: `ios/Packages/ForRealUI/Sources/ForRealUI/Fax/ClaimCard.swift`
- Create: `ios/Packages/ForRealUI/Tests/ForRealUITests/FaxSheetSmokeTests.swift`

Initial state (per shape brief Q3 round 3): the sheet appears with the verdict slot pre-allocated and three claim card slots pulsing. Plan 5's Task 19 wires up the streaming integration that fills them.

- [ ] **Step 1: Write smoke tests for the four shell states**

Create `ios/Packages/ForRealUI/Tests/ForRealUITests/FaxSheetSmokeTests.swift`:

```swift
import Testing
import SwiftUI
@testable import ForRealUI
@testable import ForRealKit

@Suite("FaxSheet shell smoke")
@MainActor
struct FaxSheetSmokeTests {

    @Test("renders empty pre-allocated shell")
    func emptyShell() {
        let view = FaxSheet(state: .initial)
        let _: any View = view
    }

    @Test("renders streaming with one claim")
    func partialStreaming() {
        let claim = Claim(position: 1, claimText: "x", verdict: .nope, commentary: "no", sources: [], resolvedAt: 0)
        let view = FaxSheet(state: .streaming(partial: [claim], finalVerdict: nil, finalCommentary: nil))
        let _: any View = view
    }

    @Test("renders final state with three claims")
    func finalState() {
        let claims = (1...3).map {
            Claim(position: $0, claimText: "c\($0)", verdict: .nope, commentary: "no", sources: [], resolvedAt: 0)
        }
        let view = FaxSheet(state: .final(verdict: .nope, commentary: "bestie no", claims: claims))
        let _: any View = view
    }
}
```

- [ ] **Step 2: Run; confirm fail**

Run: `cd ios/Packages/ForRealUI && swift test --filter FaxSheetSmokeTests`
Expected: FAIL — `FaxSheet`, `FaxSheet.State` not defined.

- [ ] **Step 3: Implement the shell components**

Create `ios/Packages/ForRealUI/Sources/ForRealUI/Fax/VerdictHeader.swift`:

```swift
#if os(iOS)
import SwiftUI
import ForRealKit

struct VerdictHeader: View {
    let verdict: Verdict?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("VERDICT").forRealLabelStyle().foregroundStyle(Color.oliveAnchor)
            if let verdict {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(verdict.rawValue.uppercased())
                        .font(ForRealType.verdictDisplay)
                        .foregroundStyle(Color.lemonCharcoal)
                    Text(verdict.glyph).font(.system(size: 44))
                }
            } else {
                Text("…")
                    .font(ForRealType.verdictDisplay)
                    .foregroundStyle(Color.lemonCharcoal.opacity(0.25))
            }
        }
    }
}
#endif
```

Create `ios/Packages/ForRealUI/Sources/ForRealUI/Fax/ClaimCard.swift`:

```swift
#if os(iOS)
import SwiftUI
import ForRealKit

struct ClaimCard: View {
    let position: Int
    let claim: Claim?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CLAIM \(position) OF 3").forRealLabelStyle()
                .foregroundStyle(Color.oliveAnchor)
            if let claim {
                HStack(alignment: .top, spacing: 8) {
                    Text(claim.verdict.glyph).font(.system(size: 18))
                    Text(claim.claimText)
                        .font(ForRealType.headline)
                        .foregroundStyle(Color.lemonCharcoal)
                }
                Text(claim.commentary)
                    .font(ForRealType.body)
                    .foregroundStyle(Color.lemonCharcoal.opacity(0.85))
            } else {
                Rectangle().fill(Color.lemonSage.opacity(0.45)).frame(height: 56)
                    .accessibilityHidden(true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lemonCream, in: RoundedRectangle(cornerRadius: 8))
    }
}
#endif
```

Create `ios/Packages/ForRealUI/Sources/ForRealUI/Fax/FaxSheet.swift`:

```swift
#if os(iOS)
import SwiftUI
import ForRealKit

public struct FaxSheet: View {

    public enum State: Equatable {
        case initial
        case streaming(partial: [Claim], finalVerdict: Verdict?, finalCommentary: String?)
        case final(verdict: Verdict, commentary: String, claims: [Claim])
        case skip(commentary: String)
        case failed(errorCode: String)
    }

    public let state: State

    public init(state: State) { self.state = state }

    public var body: some View {
        ZStack {
            Color.zestyLemon.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VerdictHeader(verdict: currentVerdict)
                    if let commentary = currentCommentary {
                        Text(commentary)
                            .font(ForRealType.headline.weight(.regular))
                            .foregroundStyle(Color.lemonCharcoal)
                    }
                    if !isSkip {
                        ForEach(1...3, id: \.self) { i in
                            ClaimCard(position: i, claim: claim(at: i))
                        }
                    }
                }
                .padding(24)
            }
        }
    }

    // MARK: - Derived

    private var currentVerdict: Verdict? {
        switch state {
        case .initial:                                  nil
        case .streaming(_, let verdict, _):             verdict
        case .final(let verdict, _, _):                 verdict
        case .skip:                                     .skip
        case .failed:                                   nil
        }
    }

    private var currentCommentary: String? {
        switch state {
        case .initial:                                  nil
        case .streaming(_, _, let commentary):          commentary
        case .final(_, let commentary, _):              commentary
        case .skip(let commentary):                     commentary
        case .failed:                                   nil
        }
    }

    private var isSkip: Bool {
        if case .skip = state { return true }
        return false
    }

    private func claim(at position: Int) -> Claim? {
        switch state {
        case .initial:                                       return nil
        case .streaming(let partial, _, _):                  return partial.first(where: { $0.position == position })
        case .final(_, _, let claims):                       return claims.first(where: { $0.position == position })
        case .skip, .failed:                                 return nil
        }
    }
}
#endif
```

- [ ] **Step 4: Run; confirm pass**

Run: `cd ios/Packages/ForRealUI && swift test --filter FaxSheetSmokeTests`
Expected: PASS — 3 tests.

- [ ] **Step 5: Commit**

```bash
git add ios/Packages/ForRealUI/Sources/ForRealUI/Fax/ ios/Packages/ForRealUI/Tests/ForRealUITests/FaxSheetSmokeTests.swift
git commit -m "feat(ios/ForRealUI): FaxSheet shell with VerdictHeader + ClaimCard slots"
```

---

## Task 19: Fax streaming integration + motion (claim arrivals + verdict push-in + Reduce Motion)

**Files:**
- Modify: `ios/Packages/ForRealUI/Sources/ForRealUI/Fax/ClaimCard.swift` (add transition)
- Modify: `ios/Packages/ForRealUI/Sources/ForRealUI/Fax/VerdictHeader.swift` (add transition)
- Modify: `ios/Packages/ForRealUI/Sources/ForRealUI/Fax/FaxSheet.swift` (use ReceiptCoordinator state)
- Create: `ios/Packages/ForRealUI/Tests/ForRealUITests/FaxStreamingIntegrationTests.swift`

The ClaimCard's transition: fade + slide-up 16pt at `claimArrival` curve, OR Reduce-Motion: 100ms color highlight. The verdict word: pushes in from top OR Reduce-Motion: appears in place with highlight.

- [ ] **Step 1: Write the integration test (uses an in-memory coordinator)**

Create `ios/Packages/ForRealUI/Tests/ForRealUITests/FaxStreamingIntegrationTests.swift`:

```swift
import Testing
import SwiftUI
import SwiftData
@testable import ForRealUI
@testable import ForRealKit

@Suite("FaxSheet — streaming integration")
@MainActor
struct FaxStreamingIntegrationTests {

    @Test("FaxSheet derives state from coordinator (idle → streaming → final)")
    func deriveStateFromCoordinator() async throws {
        let mockClient = MockAPIClient()
        let mockConsumer = MockSSEConsumer(events: [
            .status(.init(status: "streaming")),
            .claimFinal(.fixture(position: 1, verdict: .nope)),
            .claimFinal(.fixture(position: 2, verdict: .mixed)),
            .claimFinal(.fixture(position: 3, verdict: .yep)),
            .receiptFinal(.init(finalVerdict: .mixed, finalCommentary: "ok")),
        ])
        let store = try makeStore()
        let coord = ReceiptCoordinator(client: mockClient, consumer: mockConsumer, store: store)

        let viewIdle = FaxSheet(state: .from(coord.state))
        if case .initial = viewIdle.state { /* ok */ } else { Issue.record("expected .initial") }

        try await coord.analyze(url: "https://yt/x")

        let viewFinal = FaxSheet(state: .from(coord.state))
        if case .final(let verdict, _, let claims) = viewFinal.state {
            #expect(verdict == .mixed)
            #expect(claims.count == 3)
        } else {
            Issue.record("expected .final")
        }
    }

    private func makeStore() throws -> FaxStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistedFax.self, PersistedClaim.self, configurations: config)
        return FaxStore(container: container)
    }
}
```

- [ ] **Step 2: Run; confirm fail**

Run: `cd ios/Packages/ForRealUI && swift test --filter FaxStreamingIntegrationTests`
Expected: FAIL — `FaxSheet.State.from(...)` adapter not defined.

- [ ] **Step 3: Add the adapter + the motion treatments**

Append to `ios/Packages/ForRealUI/Sources/ForRealUI/Fax/FaxSheet.swift`:

```swift
public extension FaxSheet.State {
    /// Derives the view-side state from a coordinator's runtime state.
    static func from(_ coordState: ReceiptCoordinator.State) -> FaxSheet.State {
        switch coordState {
        case .idle:
            return .initial
        case .streaming(_, let partial, let final):
            return .streaming(partial: partial, finalVerdict: final?.verdict, finalCommentary: final?.commentary)
        case .final(let fax):
            if fax.finalVerdict == .skip {
                return .skip(commentary: fax.finalCommentary ?? "")
            }
            return .final(verdict: fax.finalVerdict ?? .mixed, commentary: fax.finalCommentary ?? "", claims: fax.claims)
        case .failed(let code):
            return .failed(errorCode: code)
        }
    }
}
```

Modify `ios/Packages/ForRealUI/Sources/ForRealUI/Fax/ClaimCard.swift` — wrap the populated body in a transition. Replace the populated branch:

```swift
// Replace the existing populated branch with:
if let claim {
    populatedBody(claim)
        .transition(reducedMotion
            ? .opacity
            : .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .opacity))
} else {
    Rectangle().fill(Color.lemonSage.opacity(0.45)).frame(height: 56)
        .accessibilityHidden(true)
}
```

Add at the top of `ClaimCard`:
```swift
@Environment(\.accessibilityReduceMotion) private var reducedMotion
```

Refactor the populated body into a private method:
```swift
@ViewBuilder
private func populatedBody(_ claim: Claim) -> some View {
    HStack(alignment: .top, spacing: 8) {
        Text(claim.verdict.glyph).font(.system(size: 18))
        Text(claim.claimText)
            .font(ForRealType.headline)
            .foregroundStyle(Color.lemonCharcoal)
    }
    Text(claim.commentary)
        .font(ForRealType.body)
        .foregroundStyle(Color.lemonCharcoal.opacity(0.85))
}
```

Modify `VerdictHeader.swift` — wrap the populated branch with the verdict push-in transition:

```swift
@Environment(\.accessibilityReduceMotion) private var reducedMotion

// In body, replace the if-let-verdict branch:
if let verdict {
    populated(verdict)
        .transition(reducedMotion
            ? .opacity
            : .asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .opacity))
} else {
    Text("…")
        .font(ForRealType.verdictDisplay)
        .foregroundStyle(Color.lemonCharcoal.opacity(0.25))
}

@ViewBuilder
private func populated(_ verdict: Verdict) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
        Text(verdict.rawValue.uppercased())
            .font(ForRealType.verdictDisplay)
            .foregroundStyle(Color.lemonCharcoal)
        Text(verdict.glyph).font(.system(size: 44))
    }
}
```

In `FaxSheet.swift`, drive transitions with the right animation. Add at the top of the struct:

```swift
@Environment(\.accessibilityReduceMotion) private var reducedMotion
```

Add a private animation key — a `String` summarizing what's currently visible so SwiftUI knows when to animate:

```swift
private var animationKey: String {
    switch state {
    case .initial:                                      "initial"
    case .streaming(let partial, let v, _):             "streaming-claims-\(partial.count)-verdict-\(v?.rawValue ?? "nil")"
    case .final(let v, _, let claims):                  "final-\(v.rawValue)-claims-\(claims.count)"
    case .skip:                                         "skip"
    case .failed(let code):                             "failed-\(code)"
    }
}
```

And on the outer `ZStack { ... }`, append:

```swift
.animation(
    reducedMotion ? ForRealMotion.reduceMotionHighlight.curve : ForRealMotion.claimArrival.curve,
    value: animationKey
)
```

The `animationKey` changes whenever the visible content changes (claim added, verdict arrived, state shifted), which triggers SwiftUI to play each subview's `.transition(...)`.

- [ ] **Step 4: Run; confirm pass**

Run: `cd ios/Packages/ForRealUI && swift test --filter FaxStreamingIntegrationTests --filter FaxSheetSmokeTests`
Expected: PASS — 4 tests.

- [ ] **Step 5: Commit**

```bash
git add ios/Packages/ForRealUI/
git commit -m "feat(ios/ForRealUI): FaxSheet streaming integration + claim/verdict transitions (Reduce Motion variants included)"
```

---

## Task 20: Fax error states + skip variant

**Files:**
- Create: `ios/Packages/ForRealUI/Sources/ForRealUI/Fax/FaxErrorState.swift`
- Create: `ios/Packages/ForRealUI/Sources/ForRealUI/Fax/FaxSkipState.swift`
- Modify: `ios/Packages/ForRealUI/Sources/ForRealUI/Fax/FaxSheet.swift` (route `.skip` and `.failed` cases)
- Create: `ios/Packages/ForRealUI/Tests/ForRealUITests/FaxErrorStateTests.swift`

Five error variants per spec §6 (`source_unreachable`, `provider_blocked`, `transcription_failed`, `paywalled`, `unsupported_provider`); each maps to a friendly bestie line. Skip variant renders just verdict + commentary, no claim cards.

- [ ] **Step 1: Write failing tests**

Create `ios/Packages/ForRealUI/Tests/ForRealUITests/FaxErrorStateTests.swift`:

```swift
import Testing
import SwiftUI
@testable import ForRealUI

@Suite("Fax error + skip variants")
@MainActor
struct FaxErrorStateTests {

    @Test("skip variant constructs and renders only verdict + commentary")
    func skipVariant() {
        let view = FaxSheet(state: .skip(commentary: "all vibes."))
        let _: any View = view
    }

    @Test("each error code has a friendly bestie copy")
    func errorCopyExists() {
        #expect(!FaxErrorCopy.message(for: "source_unreachable").isEmpty)
        #expect(!FaxErrorCopy.message(for: "provider_blocked").isEmpty)
        #expect(!FaxErrorCopy.message(for: "transcription_failed").isEmpty)
        #expect(!FaxErrorCopy.message(for: "paywalled").isEmpty)
        #expect(!FaxErrorCopy.message(for: "unsupported_provider").isEmpty)
        // Unknown code falls back gracefully.
        #expect(!FaxErrorCopy.message(for: "definitely_not_a_real_code").isEmpty)
    }

    @Test("failed state constructs")
    func failedState() {
        let view = FaxSheet(state: .failed(errorCode: "provider_blocked"))
        let _: any View = view
    }
}
```

- [ ] **Step 2: Run; confirm fail**

Run: `cd ios/Packages/ForRealUI && swift test --filter FaxErrorStateTests`
Expected: FAIL — `FaxErrorCopy` not defined.

- [ ] **Step 3: Implement the variants**

Create `ios/Packages/ForRealUI/Sources/ForRealUI/Fax/FaxErrorState.swift`:

```swift
#if os(iOS)
import SwiftUI

public enum FaxErrorCopy {
    public static func message(for errorCode: String) -> String {
        switch errorCode {
        case "source_unreachable":   "Couldn't reach this one — link may be private or pulled."
        case "provider_blocked":     "TikTok's playing hard to get. Try again in a sec."
        case "transcription_failed": "Couldn't make out the audio."
        case "paywalled":            "Paywall blocked us — try a public mirror."
        case "unsupported_provider": "We don't speak that platform yet — coming later."
        default:                     "Something fell over. Try again?"
        }
    }
}

struct FaxErrorState: View {
    let errorCode: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("OOPS").forRealLabelStyle().foregroundStyle(Color.oliveAnchor)
            Text(FaxErrorCopy.message(for: errorCode))
                .font(ForRealType.headline)
                .foregroundStyle(Color.lemonCharcoal)
            Button(action: onRetry) {
                Text("Try again")
                    .font(ForRealType.body.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .foregroundStyle(Color.zestyLemon)
                    .background(Color.lemonCharcoal, in: RoundedRectangle(cornerRadius: 6))
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
#endif
```

Create `ios/Packages/ForRealUI/Sources/ForRealUI/Fax/FaxSkipState.swift`:

```swift
#if os(iOS)
import SwiftUI
import ForRealKit

struct FaxSkipState: View {
    let commentary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VerdictHeader(verdict: .skip)
            Text(commentary)
                .font(ForRealType.headline.weight(.regular))
                .foregroundStyle(Color.lemonCharcoal)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
#endif
```

Modify `FaxSheet.swift` to thread an `onRetry` callback through and route `.failed` and `.skip` to their dedicated views. Add the property + initializer parameter:

```swift
public let onRetry: () -> Void

public init(state: State, onRetry: @escaping () -> Void = {}) {
    self.state = state
    self.onRetry = onRetry
}
```

Replace the body with:

```swift
public var body: some View {
    ZStack {
        Color.zestyLemon.ignoresSafeArea()
        switch state {
        case .skip(let commentary):
            FaxSkipState(commentary: commentary)
        case .failed(let errorCode):
            FaxErrorState(errorCode: errorCode, onRetry: onRetry)
        default:
            defaultBody
        }
    }
}

private var defaultBody: some View {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            VerdictHeader(verdict: currentVerdict)
            if let commentary = currentCommentary {
                Text(commentary)
                    .font(ForRealType.headline.weight(.regular))
                    .foregroundStyle(Color.lemonCharcoal)
            }
            ForEach(1...3, id: \.self) { i in
                ClaimCard(position: i, claim: claim(at: i))
            }
        }
        .padding(24)
    }
}
```

(The retry callback is wired in Task 22 from ContentView; for the unit test it's a no-op.)

- [ ] **Step 4: Run; confirm pass**

Run: `cd ios/Packages/ForRealUI && swift test --filter FaxErrorStateTests`
Expected: PASS — 3 tests.

- [ ] **Step 5: Commit**

```bash
git add ios/Packages/ForRealUI/Sources/ForRealUI/Fax/ ios/Packages/ForRealUI/Tests/ForRealUITests/FaxErrorStateTests.swift
git commit -m "feat(ios/ForRealUI): Fax error variants + skip variant"
```

---

## Task 21: Fax Share button (rendered fax → image → iOS share sheet)

**Files:**
- Create: `ios/Packages/ForRealUI/Sources/ForRealUI/Fax/FaxShareButton.swift`
- Modify: `ios/Packages/ForRealUI/Sources/ForRealUI/Fax/FaxSheet.swift` (mount the button in `.final` and `.skip`)
- Create: `ios/Packages/ForRealUI/Tests/ForRealUITests/FaxShareTests.swift`

Use SwiftUI's `ImageRenderer` to convert the fax content into a UIImage on demand, then `ShareLink`.

- [ ] **Step 1: Write smoke test**

Create `ios/Packages/ForRealUI/Tests/ForRealUITests/FaxShareTests.swift`:

```swift
import Testing
import SwiftUI
@testable import ForRealUI
@testable import ForRealKit

@Suite("FaxShareButton")
@MainActor
struct FaxShareTests {

    @Test("constructs given a renderable fax")
    func constructs() {
        let claims = (1...3).map {
            Claim(position: $0, claimText: "x", verdict: .nope, commentary: "no", sources: [], resolvedAt: 0)
        }
        let view = FaxShareButton(verdict: .nope, commentary: "nope", claims: claims)
        let _: any View = view
    }
}
```

- [ ] **Step 2: Run; confirm fail**

Run: `cd ios/Packages/ForRealUI && swift test --filter FaxShareTests`
Expected: FAIL — `FaxShareButton` not defined.

- [ ] **Step 3: Implement**

Create `ios/Packages/ForRealUI/Sources/ForRealUI/Fax/FaxShareButton.swift`:

```swift
#if os(iOS)
import SwiftUI
import UIKit
import ForRealKit

public struct FaxShareButton: View {
    let verdict: Verdict
    let commentary: String
    let claims: [Claim]

    public init(verdict: Verdict, commentary: String, claims: [Claim]) {
        self.verdict = verdict
        self.commentary = commentary
        self.claims = claims
    }

    public var body: some View {
        ShareLink(item: rendered(), preview: SharePreview("My fax says \(verdict.rawValue)", image: rendered())) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share")
            }
            .font(ForRealType.body.weight(.semibold))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .foregroundStyle(Color.zestyLemon)
            .background(Color.lemonCharcoal, in: RoundedRectangle(cornerRadius: 6))
        }
        .accessibilityLabel("Share fax")
    }

    private func rendered() -> Image {
        let renderable = FaxRenderableForSharing(verdict: verdict, commentary: commentary, claims: claims)
        let renderer = ImageRenderer(content: renderable)
        renderer.scale = 3.0  // 3x for retina + iMessage thumbnail clarity
        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "exclamationmark.circle")
    }
}

/// A self-contained, screenshot-shaped layout used only for the share image.
/// Independent of the on-screen FaxSheet so the share image stays consistent
/// even if the on-screen layout changes.
struct FaxRenderableForSharing: View {
    let verdict: Verdict
    let commentary: String
    let claims: [Claim]

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 4) {
                Text("VERDICT")
                    .forRealLabelStyle().foregroundStyle(Color.oliveAnchor)
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(verdict.rawValue.uppercased())
                        .font(ForRealType.verdictDisplay)
                    Text(verdict.glyph).font(.system(size: 56))
                }
                .foregroundStyle(Color.lemonCharcoal)
            }

            Text(commentary)
                .font(ForRealType.headline.weight(.regular))
                .foregroundStyle(Color.lemonCharcoal)

            VStack(spacing: 12) {
                ForEach(claims) { claim in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CLAIM \(claim.position) OF 3")
                            .forRealLabelStyle().foregroundStyle(Color.oliveAnchor)
                        HStack(alignment: .top, spacing: 8) {
                            Text(claim.verdict.glyph).font(.system(size: 18))
                            Text(claim.claimText)
                                .font(ForRealType.headline)
                                .foregroundStyle(Color.lemonCharcoal)
                        }
                        Text(claim.commentary)
                            .font(ForRealType.body)
                            .foregroundStyle(Color.lemonCharcoal.opacity(0.85))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.lemonCream, in: RoundedRectangle(cornerRadius: 8))
                }
            }

            Text("From For Real??")
                .forRealLabelStyle().foregroundStyle(Color.oliveAnchor)
        }
        .padding(28)
        .frame(width: 1080, alignment: .leading)
        .background(Color.zestyLemon)
    }
}
#endif
```

Modify `FaxSheet.swift` — in `.final` rendering, append the share button at the bottom of `defaultBody`:

```swift
if case .final(let verdict, let commentary, let claims) = state {
    FaxShareButton(verdict: verdict, commentary: commentary, claims: claims)
        .padding(.top, 8)
}
```

- [ ] **Step 4: Run; confirm pass**

Run: `cd ios/Packages/ForRealUI && swift test --filter FaxShareTests`
Expected: PASS — 1 test.

- [ ] **Step 5: Commit**

```bash
git add ios/Packages/ForRealUI/Sources/ForRealUI/Fax/FaxShareButton.swift ios/Packages/ForRealUI/Sources/ForRealUI/Fax/FaxSheet.swift ios/Packages/ForRealUI/Tests/ForRealUITests/FaxShareTests.swift
git commit -m "feat(ios/ForRealUI): FaxShareButton (ImageRenderer + ShareLink)"
```

---

## Task 22: ForReal app shell — ContentView + sheet routing + DEBUG dev probe

**Files:**
- Create: `ios/ForReal/ContentView.swift`
- Modify: `ios/ForReal/ForRealApp.swift` (mount ContentView, inject SwiftData container, inject coordinator)

- [ ] **Step 1: Write the app shell + dev probe**

Create `ios/ForReal/ContentView.swift`:

```swift
import SwiftUI
import SwiftData
import ForRealKit
import ForRealUI

struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var coordinator: ReceiptCoordinator
    @State private var presentingFax = false
    @State private var clipboardURL: String?

    init() {
        // Real coordinator wired up in body via .task once model context is available.
        // Placeholder so the @State var has an initial value; the real one is reassigned in .task.
        let container = try! ModelContainer(
            for: PersistedFax.self, PersistedClaim.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let store = FaxStore(container: container)
        let deviceID = DeviceID.resolve()
        let client = APIClient(environment: .dev, deviceID: deviceID)
        let consumer = SSEStreamConsumer(environment: .dev, deviceID: deviceID)
        _coordinator = State(initialValue: ReceiptCoordinator(client: client, consumer: consumer, store: store))
    }

    var body: some View {
        HomeView(
            clipboardURL: clipboardURL,
            onAnalyze: { url in
                presentingFax = true
                Task { try? await coordinator.analyze(url: url) }
            },
            onRecentTap: {
                // Plan 6 fills this in.
            }
        )
        .task { await refreshClipboard() }
        .sheet(isPresented: $presentingFax, onDismiss: { coordinator.reset() }) {
            FaxSheet(
                state: .from(coordinator.state),
                onRetry: { presentingFax = false }   // Plan 5: retry dismisses the sheet so the user re-pastes.
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        #if DEBUG
        .overlay(alignment: .bottomTrailing) { DevToolsButton().padding() }
        #endif
    }

    @MainActor
    private func refreshClipboard() async {
        // UIPasteboard read requires user permission; only check on app open / foreground.
        if UIPasteboard.general.hasURLs, let url = UIPasteboard.general.url {
            clipboardURL = url.absoluteString
        }
    }
}

#if DEBUG
import UIKit

private struct DevToolsButton: View {
    @State private var showing = false
    var body: some View {
        Button { showing = true } label: {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 16, weight: .medium))
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
                .foregroundStyle(Color.lemonCharcoal)
        }
        .sheet(isPresented: $showing) { DevToolsSheet() }
    }
}

private struct DevToolsSheet: View {
    @State private var posting = false
    @State private var lastReceiptID: String?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Dev — POST /v1/receipts") {
                    Button("Post a fresh YouTube URL") {
                        Task { await postFresh() }
                    }
                    .disabled(posting)
                    if posting { ProgressView() }
                    if let lastReceiptID { Text("receipt_id: \(lastReceiptID)").font(.caption.monospaced()) }
                    if let error { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Dev tools")
        }
    }

    private func postFresh() async {
        posting = true; defer { posting = false }
        let device = DeviceID.resolve()
        let client = APIClient(environment: .dev, deviceID: device)
        do {
            let r = try await client.postFax(url: "https://www.youtube.com/watch?v=dev-\(UUID().uuidString)")
            lastReceiptID = r.receiptID
            error = nil
        } catch {
            self.error = String(describing: error)
        }
    }
}
#endif
```

Replace `ios/ForReal/ForRealApp.swift` with:

```swift
import SwiftUI
import SwiftData
import ForRealKit

@main
struct ForRealApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [PersistedFax.self, PersistedClaim.self])
        }
    }
}
```

- [ ] **Step 2: Regenerate the project + build the app**

Run:
```bash
cd ios && xcodegen generate
xcodebuild -project ForReal.xcodeproj -scheme ForReal \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO
```
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Run the impeccable critique pass against the rendered home + fax**

Open Simulator, run the app, and run two critique sessions:

```bash
$impeccable critique Home
$impeccable critique Fax
```

For each: present screenshots / screen recordings to the impeccable critique skill. If critique surfaces blocking issues, fix them and re-build. Most likely surfaced issues will be the bestie line copy choice (resolve from the three candidates), the Recent glyph icon (currently `tray.full`; impeccable may suggest a different SF Symbol that better matches the brand), and visual rhythm of the paste box (padding, position).

- [ ] **Step 4: Commit**

```bash
git add ios/ForReal/
git commit -m "feat(ios): ContentView shell — Home + Fax sheet + DEBUG dev probe"
```

---

## Task 23: Wrap-up — README, full-suite check, branch state

**Files:**
- Create / modify: `ios/README.md`

- [ ] **Step 1: Update / rewrite `ios/README.md`**

Replace the file body with:

```markdown
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
```

- [ ] **Step 2: Run the full iOS test suite**

```bash
cd ios/Packages/ForRealKit && swift test
cd ios/Packages/ForRealUI && swift test
```

Expected: all tests pass (counts approximate — there are ~30 tests across both packages).

- [ ] **Step 3: Build the app one more time**

```bash
cd ios && xcodebuild -project ForReal.xcodeproj -scheme ForReal \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4: Commit + close out the plan**

```bash
git add ios/README.md
git commit -m "docs(ios): document For Real?? iOS architecture (Plan 5 wrap-up)"
```

The branch state at this point includes Plan 5's iOS work plus the earlier docs commits. The branch should be reviewable as a single PR — the controller will follow the project's PR-based workflow when the user is ready to push.

---

## Done definition

Plan 5 is complete when:

- All 23 tasks above are committed.
- Both packages pass `swift test`.
- The app builds via `xcodebuild ... build CODE_SIGNING_ALLOWED=NO`.
- An `$impeccable critique Home` and `$impeccable critique Fax` pass has been run with the simulator open and any blocking issues are addressed.
- The Open Questions in the shape brief have been resolved during craft (or explicitly deferred to a future polish pass).

The next plan (Plan 6) builds the Recent screen on top of `FaxStore.listMostRecent`. The next-plus-one (Plan 7) ships the Share Extension target. Plan 8 adds Sign in with Apple + Settings.
