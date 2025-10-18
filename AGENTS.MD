# About the project
- MovieWatch is a SwiftUI iOS app that helps track movies to watch and syncs metadata from TMDB.
- Source code lives under `MovieWatch/`. `MovieWatchApp.swift` bootstraps a shared SwiftData `ModelContainer` for the `Movie` model.
- Feature-specific views sit in `MovieWatch/Features/` (e.g. `MovieList`, `MovieDetail`, `Search`). Cross-cutting code is in `MovieWatch/Shared/` (`Design`, `Models`, `Services`, `Stores`).
- Persistence relies on SwiftData models (`Movie`, `Provider`). Store logic is handled in `MovieStore`, while network enrichment happens through `Shared/Services/MovieAPI.swift`.
- The UI is written with SwiftUI and leverages Observation (`@Observable`) and Swift concurrency. Most labels and copy are in Italian; keep new strings consistent unless requested otherwise.

# Configuration
- Duplicate `MovieWatch/Secrets.plist.sample` into `MovieWatch/Secrets.plist`.
- Populate at least `TMDB_READ_TOKEN`; optional keys `LANGUAGE` and `WATCH_REGION` default to `it-IT` and `IT` if omitted.
- Add the file to the `MovieWatch` target in Xcode so it ends up in the main bundle. The file is ignored by Git—do not commit it.
- When `Secrets.plist` is missing or empty, the app falls back to Info.plist keys. You can temporarily add those for local debugging but remove them before committing.

# Build & runtime
- Open `MovieWatch.xcodeproj` in Xcode 15.4+ (SwiftData + Observation require iOS 17 SDK or newer).
- CLI example for a local build: `xcodebuild -project MovieWatch.xcodeproj -scheme MovieWatch -destination 'platform=iOS Simulator,name=iPhone 15' build`.
- There are no dedicated test targets yet. If you add tests, wire them to the `MovieWatch` scheme so `xcodebuild ... test` works.
- SwiftUI previews pull real data from SwiftData. Supply sample data in previews or use `.modelContainer(for:inMemory:)` to avoid mutating the on-disk store.

# Development notes
- Network access flows through `MovieAPI`; keep requests cancellable and run UI updates on the main actor to avoid SwiftData warnings.
- `MovieStore` and `SearchStore` orchestrate async work. Preserve their debounce/cancellation behavior when extending them.
- Shared design helpers (`Glass`, `NoisyBackground`, etc.) provide the app’s look & feel. Reuse them before introducing new styling primitives.
- Assets live in `MovieWatch/Assets.xcassets`. Make changes through Xcode so catalog metadata stays valid.
- Prefer small, composable SwiftUI views. Keep state at the feature/store level and pass bindings down.
- Every time you choose to do something important, related to coding or a new framework logic, that need a mention on AGENTS.md update this file.
- Simplified `MovieDetailView` section rendering and availability grouping to reduce duplicated layout logic (Codex).
- Persisted movie runtime metadata from TMDB and added a detail slider to track watch progress (Codex).

# Coding guidelines
- Default to spaces for indentation (existing Swift files use four-space indents).
- Use English for code comments and documentation unless the product copy needs Italian.
- Favor SOLID, KISS, DRY, and YAGNI; avoid speculative abstractions.
- Gate new async behavior behind `@MainActor` when mutating SwiftData models or UI state.
- Ensure new dependencies (SFSymbols, colors, etc.) exist on the minimum deployment target before relying on them.
