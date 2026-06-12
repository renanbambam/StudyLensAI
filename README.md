# StudyLens AI

**Native iOS study companion with AI-powered flashcard generation and OCR.**
SwiftUI · SwiftData · Vision · CloudKit · Claude API · WidgetKit

Scan handwritten notes with the camera, extract text with Vision OCR, and let
Claude generate structured flashcard decks. Review with SM-2 spaced repetition,
track progress (streak, retention, heatmap), sync via iCloud, and see cards due
today on a Home Screen widget.

> Full requirements and design live in [`Studylens architecture.MD`](Studylens%20architecture.MD)
> — the source of truth for this project. Execution status is tracked in [`TODO.md`](TODO.md).

## Getting Started

Prerequisites: macOS 14+, Xcode 16+, an Apple Developer account.

```bash
git clone https://github.com/renanbambam/studylens-ai
cd studylens-ai

# The Xcode project is generated, not versioned (no pbxproj merge conflicts)
brew install xcodegen
xcodegen generate

open StudyLens.xcodeproj
# Set your Team in Signing & Capabilities, then Cmd+R
```

On first launch the app prompts for a Claude API key and stores it in the
Keychain — it is never hardcoded, written to a plist, or committed.

## Architecture

MVVM + feature-sliced folders (`Scan`, `Decks`, `Study`, `Stats`), with strict
layering:

```
Views (SwiftUI) → ViewModels (@Observable) → Services / Repositories → Infrastructure
```

- **Views are dumb**; one `@Observable` ViewModel per screen, injected via init.
- **Services are pure Swift** (`SpacedRepetitionService`, `ProgressService`) —
  zero SwiftUI imports, fully unit-tested.
- **Repositories abstract SwiftData**; ViewModels never touch `ModelContext`.
- **Infrastructure** wraps Vision OCR, the Claude API (URLSession async/await),
  Keychain, and the App Group store shared with the widget.

## Testing

```bash
xcodebuild test -project StudyLens.xcodeproj -scheme StudyLens \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Unit tests cover the SM-2 algorithm, progress statistics, the Claude API client
(mocked `URLProtocol`, no real network), and the scan ViewModel (mocked OCR/AI/
repository). UI tests smoke-test launch and tab navigation. CI runs SwiftLint
(strict) plus the full test suite on every push (`.github/workflows/ci.yml`).

## Engineering decisions

| Decision | Rationale |
|---|---|
| XcodeGen instead of a versioned `.xcodeproj` | Declarative project, zero pbxproj merge conflicts; regenerated locally and in CI |
| `claude-sonnet-4-6` (architecture pinned `claude-sonnet-4-20250514`) | The pinned model was deprecated by Anthropic (retirement 2026-06-15); `claude-sonnet-4-6` is the official drop-in replacement |
| CloudKit-compatible SwiftData models | CloudKit forbids `@Attribute(.unique)` and requires defaults + optional relationships; models adjusted accordingly, same computed API as the spec |
| Local-store fallback when iCloud is unavailable | App stays fully usable offline / in simulators without an account |
| App Intents compiled into the app target | Apple guidance for intents that open the app; `StudyLensIntents/` folder kept per the architecture layout |
| Versioned prompts as Swift constants | `Prompts/flashcard_generation_v1.swift` etc. — prompt changes are diffable in Git |

## Known limitations

- This codebase was authored in an environment without macOS/Xcode, so
  compilation and tests are validated by CI (macOS runner) and locally in
  Xcode — not on the authoring machine.
- The scan flow (camera and PDF import) processes the first page of a
  multi-page document (MVP scope).
- CloudKit sync requires a physical device signed into iCloud to verify
  end-to-end; the app falls back to a local store everywhere else.
