# StudyLens AI

```
███████╗████████╗██╗   ██╗██████╗ ██╗   ██╗██╗     ███████╗███╗   ██╗███████╗
██╔════╝╚══██╔══╝██║   ██║██╔══██╗╚██╗ ██╔╝██║     ██╔════╝████╗  ██║██╔════╝
███████╗   ██║   ██║   ██║██║  ██║ ╚████╔╝ ██║     █████╗  ██╔██╗ ██║███████╗
╚════██║   ██║   ██║   ██║██║  ██║  ╚██╔╝  ██║     ██╔══╝  ██║╚██╗██║╚════██║
███████║   ██║   ╚██████╔╝██████╔╝   ██║   ███████╗███████╗██║ ╚████║███████║
╚══════╝   ╚═╝    ╚═════╝ ╚═════╝    ╚═╝   ╚══════╝╚══════╝╚═╝  ╚═══╝╚══════╝
  S T U D Y L E N S   A I   —   I O S   S T U D Y   C O M P A N I O N
```

**Native iOS study companion with AI-powered flashcard generation and OCR.**  
SwiftUI · SwiftData · Vision · CloudKit · Claude API · WidgetKit

---

## Overview

StudyLens AI is a native iOS study tool that scans handwritten notes via the device camera, extracts text using Vision Framework OCR, and uses Claude API to generate structured flashcard decks. Cards are reviewed using a spaced repetition algorithm; progress syncs across devices via CloudKit; the daily study streak appears on a Home Screen widget.

It is not a notes app. It is a study engine — scan once, study everywhere, let the AI do the pedagogical heavy lifting.

Features:
- **Scan & Extract** — point camera at notebook, Vision OCR extracts text from handwriting
- **AI Deck Generation** — Claude receives raw OCR text and returns structured flashcards (front/back + difficulty hint)
- **Manual Deck Builder** — create cards manually or edit AI-generated ones
- **Spaced Repetition** — SM-2 algorithm schedules next review for each card
- **Study Session** — flip cards, rate confidence (Again / Hard / Good / Easy)
- **Progress Dashboard** — streak, cards due today, retention rate, heatmap calendar
- **iCloud Sync** — SwiftData + CloudKit syncs all decks and progress across iPhone/iPad/Mac
- **Home Screen Widget** — "cards due today" count + subject name via WidgetKit
- **App Intents** — "Start studying [deck name]" via Siri Shortcuts

---

## Stack

| Layer | Technology | Role |
|---|---|---|
| UI | SwiftUI | Declarative UI, animations, navigation |
| State | @Observable + @Environment | ViewModel state; no external state library |
| Persistence | SwiftData | Local storage with iCloud sync |
| Sync | CloudKit (via SwiftData) | Cross-device sync, zero extra code |
| OCR | Vision Framework | `VNRecognizeTextRequest` — handwriting recognition |
| Camera | AVFoundation + VisionKit | `VNDocumentCameraViewController` for scan UI |
| AI | Anthropic Claude API | Flashcard generation from raw OCR text |
| Networking | URLSession async/await | Claude API calls; no third-party HTTP lib |
| Widgets | WidgetKit | Home Screen + Lock Screen widget |
| Siri | App Intents | "Start deck" shortcut |
| Architecture | MVVM + Feature-sliced | One ViewModel per screen; feature folders |
| Dependency Injection | Environment + init injection | No DI framework needed for iOS scope |
| Secrets | Keychain | Claude API key stored securely |
| CI | GitHub Actions + Xcode Cloud | Build, test, lint (SwiftLint) |

---

## Architecture Principles

```
MVVM + Feature-Sliced Architecture

┌─────────────────────────────────────────────────────────────────────┐
│  Views (SwiftUI)         Screens · Components · Navigation           │
│  ──────────────────────────────────────────────────────────────────  │
│  ViewModels (@Observable) Business logic per screen                  │
│                          Coordinates services, formats for View      │
│  ──────────────────────────────────────────────────────────────────  │
│  Services (Domain)       SpacedRepetitionService · OCRService        │
│                          AIGenerationService · ProgressService       │
│  ──────────────────────────────────────────────────────────────────  │
│  Repositories            DeckRepository · FlashcardRepository        │
│                          SessionRepository (SwiftData queries)       │
│  ──────────────────────────────────────────────────────────────────  │
│  Infrastructure          Vision · AVFoundation · Claude API          │
│                          CloudKit · Keychain · WidgetKit             │
└─────────────────────────────────────────────────────────────────────┘

Rule: Views know only their ViewModel. Services have no UIKit/SwiftUI imports.
```

- **MVVM strict** — Views are dumb; ViewModels are `@Observable`; no business logic in Views
- **Feature-sliced folders** — code grouped by feature (Scan, Deck, Study, Stats), not by type
- **One ViewModel per screen** — `ScanViewModel`, `DeckListViewModel`, `StudySessionViewModel`, etc.
- **Services are pure Swift** — `SpacedRepetitionService`, `OCRService`, `AIGenerationService` have zero SwiftUI imports; testable in isolation
- **Repositories abstract SwiftData** — ViewModels never call ModelContext directly
- **SOLID** — protocols for every service; implementations injected at app launch
- **File limit** — target ~200 lines; split anything above ~350 lines
- **No Combine** — use `async/await` throughout; `@Observable` replaces most Combine patterns

---

## Domain Model (SwiftData)

```swift
// Deck — a named collection of flashcards
@Model
class Deck {
    @Attribute(.unique) var id: UUID
    var title: String
    var subject: String          // "Biology", "History", "Math"
    var colorHex: String         // used for UI color coding
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool
    @Relationship(deleteRule: .cascade) var cards: [Flashcard]
    @Relationship(deleteRule: .cascade) var sessions: [StudySession]

    // Computed (not stored)
    var dueCount: Int { cards.filter { $0.isDue }.count }
    var totalCards: Int { cards.count }
}

// Flashcard — a single question/answer card
@Model
class Flashcard {
    @Attribute(.unique) var id: UUID
    var front: String            // question / term
    var back: String             // answer / definition
    var hint: String?            // optional AI-generated hint
    var deck: Deck?

    // SM-2 spaced repetition fields
    var easeFactor: Double       // default 2.5
    var interval: Int            // days until next review
    var repetitions: Int         // consecutive correct answers
    var nextReviewDate: Date
    var lastReviewedAt: Date?
    var createdAt: Date

    var isDue: Bool { nextReviewDate <= Date.now }
}

// StudySession — one complete study session for a deck
@Model
class StudySession {
    @Attribute(.unique) var id: UUID
    var deck: Deck?
    var startedAt: Date
    var completedAt: Date?
    var cardsStudied: Int
    var correctCount: Int
    var retentionRate: Double    // correctCount / cardsStudied
}

// CardReview — individual card rating within a session
@Model
class CardReview {
    @Attribute(.unique) var id: UUID
    var flashcard: Flashcard?
    var session: StudySession?
    var rating: ReviewRating     // Again | Hard | Good | Easy
    var reviewedAt: Date
    var responseTimeSeconds: Double
}

// ScanSession — raw OCR scan for deck generation
@Model
class ScanSession {
    @Attribute(.unique) var id: UUID
    var rawText: String          // OCR output
    var imageData: Data?         // thumbnail of scanned page
    var generatedDeckId: UUID?   // FK to Deck created from this scan
    var scannedAt: Date
    var status: ScanStatus       // pending | generating | complete | failed
}
```

---

## Enums

```swift
enum ReviewRating: Int, Codable {
    case again = 0   // complete blackout
    case hard = 1    // incorrect; easy to recall
    case good = 2    // correct with some effort
    case easy = 3    // perfect recall
}

enum ScanStatus: String, Codable {
    case pending, generating, complete, failed
}

enum StudyMode {
    case allDue        // only due cards
    case fullDeck      // all cards regardless of schedule
    case weakCards     // easeFactor < 2.0
}
```

---

## Services

```swift
// SpacedRepetitionService — pure SM-2 algorithm
protocol SpacedRepetitionServiceProtocol {
    func calculateNextReview(card: Flashcard, rating: ReviewRating) -> SpacedRepetitionResult
}

struct SpacedRepetitionResult {
    let newInterval: Int
    let newEaseFactor: Double
    let newRepetitions: Int
    let nextReviewDate: Date
}

// OCRService — wraps Vision Framework
protocol OCRServiceProtocol {
    func extractText(from image: UIImage) async throws -> String
    func extractText(from imageURL: URL) async throws -> String
}

// AIGenerationService — wraps Claude API
protocol AIGenerationServiceProtocol {
    func generateFlashcards(from rawText: String, subject: String) async throws -> [FlashcardDraft]
    func improveCard(front: String, back: String) async throws -> FlashcardDraft
}

struct FlashcardDraft {
    let front: String
    let back: String
    let hint: String?
    let difficulty: String    // "easy" | "medium" | "hard"
}

// ProgressService — calculates stats
protocol ProgressServiceProtocol {
    func getDailyStreak(sessions: [StudySession]) -> Int
    func getRetentionRate(reviews: [CardReview], days: Int) -> Double
    func getHeatmapData(sessions: [StudySession]) -> [Date: Int]
    func getDueCountBySubject(decks: [Deck]) -> [String: Int]
}
```

---

## Claude API Integration

```swift
// AIGenerationService implementation
// Prompt instructs Claude to return ONLY valid JSON — no markdown, no preamble.
// Claude receives raw OCR text and returns array of flashcard objects.

struct ClaudeFlashcardRequest: Encodable {
    let model: String = "claude-sonnet-4-20250514"
    let max_tokens: Int = 2000
    let messages: [ClaudeMessage]
    let system: String
}

// System prompt (stored in Prompts/flashcard_generation_v1.swift):
// "You are a study assistant. Given raw text from handwritten notes,
//  extract the key concepts and generate flashcards.
//  Respond ONLY with a valid JSON array, no markdown, no preamble.
//  Each object: {\"front\": string, \"back\": string, \"hint\": string|null, \"difficulty\": \"easy\"|\"medium\"|\"hard\"}"

// Response parsing: strips any accidental markdown fences, decodes [FlashcardDraft]
// API key: fetched from Keychain, never hardcoded or in plist
```

---

## ViewModels

```swift
// ScanViewModel
@Observable class ScanViewModel {
    var scannedImage: UIImage?
    var extractedText: String = ""
    var generatedDrafts: [FlashcardDraft] = []
    var isScanning: Bool = false
    var isGenerating: Bool = false
    var error: StudyLensError?
    var showDeckNaming: Bool = false

    // Dependencies injected via init
    private let ocrService: OCRServiceProtocol
    private let aiService: AIGenerationServiceProtocol
    private let deckRepository: DeckRepositoryProtocol

    func scanDocument(image: UIImage) async { ... }
    func generateFlashcards(subject: String) async { ... }
    func saveDeck(title: String, subject: String) async { ... }
    func retryGeneration() async { ... }
}

// DeckListViewModel
@Observable class DeckListViewModel {
    var decks: [Deck] = []
    var searchQuery: String = ""
    var selectedSubject: String? = nil
    var sortOption: DeckSortOption = .lastStudied

    var filteredDecks: [Deck] { ... }   // computed, no async

    func loadDecks() async { ... }
    func deleteDeck(_ deck: Deck) async { ... }
    func archiveDeck(_ deck: Deck) async { ... }
}

// StudySessionViewModel
@Observable class StudySessionViewModel {
    var currentCard: Flashcard?
    var isFlipped: Bool = false
    var progress: Double = 0.0
    var sessionComplete: Bool = false
    var cardsRemaining: Int = 0
    var sessionStats: SessionStats?

    private let srService: SpacedRepetitionServiceProtocol
    private let sessionRepository: SessionRepositoryProtocol

    func startSession(deck: Deck, mode: StudyMode) { ... }
    func rate(_ rating: ReviewRating) async { ... }
    func flipCard() { ... }
}

// StatsViewModel
@Observable class StatsViewModel {
    var streak: Int = 0
    var totalCardsStudied: Int = 0
    var weeklyRetentionRate: Double = 0.0
    var heatmapData: [Date: Int] = [:]
    var dueCountBySubject: [String: Int] = [:]
    var recentSessions: [StudySession] = []

    func loadStats() async { ... }
}

// DeckDetailViewModel
@Observable class DeckDetailViewModel {
    var deck: Deck?
    var cards: [Flashcard] = []
    var editingCard: Flashcard?
    var isAddingCard: Bool = false

    func addCard(front: String, back: String) async { ... }
    func updateCard(_ card: Flashcard, front: String, back: String) async { ... }
    func deleteCard(_ card: Flashcard) async { ... }
    func improveCard(_ card: Flashcard) async { ... }   // calls Claude to rewrite
}
```

---

## Project Structure

```
StudyLens/
│
├── StudyLens/                        # Main app target
│   │
│   ├── App/
│   │   ├── StudyLensApp.swift        # @main, ModelContainer setup, DI wiring
│   │   ├── AppDependencies.swift     # creates all services + repositories
│   │   └── Navigation/
│   │       └── AppRouter.swift       # NavigationPath / tab routing
│   │
│   ├── Features/
│   │   │
│   │   ├── Scan/                     # Camera scan + OCR + AI generation
│   │   │   ├── ScanView.swift        # VNDocumentCameraViewController wrapper
│   │   │   ├── ScanViewModel.swift
│   │   │   ├── ReviewGeneratedCardsView.swift  # edit AI drafts before saving
│   │   │   └── Components/
│   │   │       ├── ScanPreviewCard.swift
│   │   │       └── CardDraftRow.swift
│   │   │
│   │   ├── Decks/                    # Deck list, detail, card editor
│   │   │   ├── DeckListView.swift
│   │   │   ├── DeckListViewModel.swift
│   │   │   ├── DeckDetailView.swift
│   │   │   ├── DeckDetailViewModel.swift
│   │   │   ├── CreateDeckView.swift
│   │   │   └── Components/
│   │   │       ├── DeckCard.swift    # card tile with due count badge
│   │   │       └── FlashcardRow.swift
│   │   │
│   │   ├── Study/                    # Study session screen
│   │   │   ├── StudySessionView.swift
│   │   │   ├── StudySessionViewModel.swift
│   │   │   ├── SessionCompleteView.swift
│   │   │   └── Components/
│   │   │       ├── FlashcardFlipView.swift   # 3D flip animation
│   │   │       ├── RatingButtons.swift       # Again / Hard / Good / Easy
│   │   │       └── SessionProgressBar.swift
│   │   │
│   │   └── Stats/                    # Progress dashboard
│   │       ├── StatsView.swift
│   │       ├── StatsViewModel.swift
│   │       └── Components/
│   │           ├── StreakBadge.swift
│   │           ├── RetentionChart.swift      # Charts framework
│   │           ├── HeatmapView.swift
│   │           └── DueBySubjectChart.swift
│   │
│   ├── Domain/
│   │   ├── Models/                   # SwiftData @Model classes
│   │   │   ├── Deck.swift
│   │   │   ├── Flashcard.swift
│   │   │   ├── StudySession.swift
│   │   │   ├── CardReview.swift
│   │   │   └── ScanSession.swift
│   │   ├── Enums/
│   │   │   ├── ReviewRating.swift
│   │   │   ├── ScanStatus.swift
│   │   │   └── StudyMode.swift
│   │   └── Services/
│   │       ├── SpacedRepetitionService.swift        # SM-2 algorithm
│   │       ├── SpacedRepetitionServiceProtocol.swift
│   │       ├── ProgressService.swift
│   │       └── ProgressServiceProtocol.swift
│   │
│   ├── Data/
│   │   ├── Repositories/
│   │   │   ├── DeckRepository.swift
│   │   │   ├── DeckRepositoryProtocol.swift
│   │   │   ├── FlashcardRepository.swift
│   │   │   ├── FlashcardRepositoryProtocol.swift
│   │   │   ├── SessionRepository.swift
│   │   │   └── SessionRepositoryProtocol.swift
│   │   └── Persistence/
│   │       └── PersistenceController.swift  # ModelContainer factory + CloudKit config
│   │
│   ├── Infrastructure/
│   │   ├── AI/
│   │   │   ├── ClaudeAIService.swift         # implements AIGenerationServiceProtocol
│   │   │   ├── AIGenerationServiceProtocol.swift
│   │   │   ├── ClaudeAPIModels.swift          # Codable request/response structs
│   │   │   └── KeychainHelper.swift           # stores/reads API key
│   │   ├── Vision/
│   │   │   ├── VisionOCRService.swift         # implements OCRServiceProtocol
│   │   │   └── OCRServiceProtocol.swift
│   │   └── Analytics/
│   │       └── StudyAnalytics.swift           # local event logging (no third-party)
│   │
│   ├── Prompts/
│   │   └── flashcard_generation_v1.swift      # prompt as versioned Swift const
│   │
│   ├── DesignSystem/
│   │   ├── Colors.swift               # semantic color tokens
│   │   ├── Typography.swift
│   │   └── Components/
│   │       ├── PrimaryButton.swift
│   │       ├── SubjectBadge.swift
│   │       └── LoadingOverlay.swift
│   │
│   └── Errors/
│       └── StudyLensError.swift       # typed error enum for all features
│
├── StudyLensWidget/                   # WidgetKit target
│   ├── StudyLensWidget.swift          # @main widget bundle
│   ├── StudyWidgetView.swift          # Home Screen widget: deck name + due count
│   ├── LockScreenWidgetView.swift     # Lock Screen: streak count
│   └── StudyWidgetProvider.swift      # TimelineProvider, reads shared AppGroup data
│
├── StudyLensIntents/                  # App Intents target
│   └── StartStudyIntent.swift         # "Start studying [deck]" Siri shortcut
│
├── StudyLensTests/                    # Unit test target
│   ├── Domain/
│   │   ├── SpacedRepetitionServiceTests.swift
│   │   └── ProgressServiceTests.swift
│   ├── Infrastructure/
│   │   └── ClaudeAIServiceTests.swift   # mock URLSession
│   └── Mocks/
│       ├── MockDeckRepository.swift
│       ├── MockAIService.swift
│       └── MockOCRService.swift
│
├── StudyLensUITests/                  # UI test target
│   └── ScanFlowUITests.swift
│
├── .swiftlint.yml
├── .github/
│   └── workflows/
│       └── ci.yml                     # xcodebuild test + SwiftLint
└── README.md
```

---

## Spaced Repetition — SM-2 Algorithm

```swift
// SpacedRepetitionService — pure function, zero dependencies
func calculateNextReview(card: Flashcard, rating: ReviewRating) -> SpacedRepetitionResult {
    var newEF = card.easeFactor + (0.1 - (3 - rating.rawValue) * (0.08 + (3 - rating.rawValue) * 0.02))
    newEF = max(1.3, newEF)

    var newReps = card.repetitions
    var newInterval = card.interval

    if rating == .again {
        newReps = 0
        newInterval = 1
    } else {
        newReps += 1
        newInterval = switch newReps {
            case 1: 1
            case 2: 6
            default: Int(Double(card.interval) * newEF)
        }
    }

    let nextDate = Calendar.current.date(byAdding: .day, value: newInterval, to: .now)!
    return SpacedRepetitionResult(newInterval: newInterval, newEaseFactor: newEF,
                                  newRepetitions: newReps, nextReviewDate: nextDate)
}
```

---

## Widget — Home Screen

```swift
// Shows: deck with most due cards, due count, subject color
// Data shared via App Group UserDefaults (written by main app on background task)
struct StudyWidgetEntry: TimelineEntry {
    let date: Date
    let deckName: String
    let dueCount: Int
    let subjectColor: Color
    let streak: Int
}

// Timeline refreshes every 60 minutes or when app writes new data
// Tapping widget deep-links to StudySessionView for that deck via URL scheme
```

---

## CloudKit Sync

```swift
// PersistenceController.swift — enables iCloud sync with 3 lines
let configuration = ModelConfiguration(
    schema: Schema([Deck.self, Flashcard.self, StudySession.self, CardReview.self, ScanSession.self]),
    cloudKitDatabase: .private("iCloud.com.renanbambam.studylens")
)
let container = try ModelContainer(for: schema, configurations: [configuration])
// SwiftData handles merge/conflict resolution automatically
```

---

## Claude API — Prompt Strategy

```swift
// Prompts/flashcard_generation_v1.swift
// Version-stamped so prompt changes are trackable in Git
let FLASHCARD_GENERATION_SYSTEM_V1 = """
You are a study assistant that transforms raw notes into flashcards.

Rules:
- Generate between 5 and 20 flashcards depending on content density
- Each front is a question or term (max 15 words)
- Each back is the answer or definition (max 40 words)
- Hint is an optional memory cue (max 10 words, null if not helpful)
- Difficulty: "easy" for recall, "medium" for application, "hard" for analysis
- Return ONLY a valid JSON array. No markdown. No preamble. No trailing text.

Format: [{"front":"...","back":"...","hint":null,"difficulty":"medium"}]
"""
```

---

## Info.plist Permissions Required

```xml
NSCameraUsageDescription     "StudyLens uses the camera to scan your notes"
NSPhotoLibraryUsageDescription "StudyLens can import notes from your photo library"
```

---

## Quick Start

```bash
# Prerequisites: macOS 14+, Xcode 16+, active Apple Developer account

# 1. Clone
git clone https://github.com/renanbambam/studylens-ai
cd studylens-ai

# 2. Open in Xcode
open StudyLens.xcodeproj

# 3. Set your Team in Signing & Capabilities

# 4. Run on simulator or device
# Cmd+R

# 5. Set Claude API key on first launch
# The app prompts for it and stores in Keychain
```

---

## GitHub Actions CI

```yaml
# .github/workflows/ci.yml
jobs:
  build-and-test:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - name: SwiftLint
        run: swiftlint lint --strict
      - name: Build and test
        run: |
          xcodebuild test \
            -scheme StudyLens \
            -destination 'platform=iOS Simulator,name=iPhone 16' \
            -resultBundlePath TestResults.xcresult
```

---

## Roadmap

### Phase 1 — MVP
| Feature | Status |
|---|---|
| VNDocumentCameraViewController scan flow | 🔜 |
| Vision OCR text extraction | 🔜 |
| Claude API flashcard generation | 🔜 |
| Manual deck creation | 🔜 |
| SwiftData persistence | 🔜 |
| SM-2 spaced repetition engine | 🔜 |
| Study session with card flip | 🔜 |
| CloudKit iCloud sync | 🔜 |
| Home Screen widget (WidgetKit) | 🔜 |
| Progress stats dashboard | 🔜 |
| Unit tests for domain services | 🔜 |

### Phase 2
| Feature | Status |
|---|---|
| Lock Screen widget (streak) | ⏳ |
| Siri App Intent ("Start studying Biology") | ⏳ |
| PDF import (scan from Files) | ⏳ |
| Haptic feedback on card ratings | ⏳ |
| Export deck as CSV / Anki format | ⏳ |

---

## Architecture Decisions

| Decision | Choice | Reason |
|---|---|---|
| Persistence | SwiftData | Native iOS 17+; CloudKit sync built-in; no extra code |
| State management | @Observable | iOS 17 replacement for ObservableObject; cleaner syntax |
| Networking | URLSession async/await | No Alamofire — one less dependency, simpler Keychain auth |
| No Combine | async/await throughout | Combine adds complexity; async/await is idiomatic in iOS 17+ |
| Spaced repetition | SM-2 | Battle-tested algorithm; simple to implement and test |
| DI approach | init injection | iOS projects don't need Swinject; Environment + init is enough |
| Widget data sharing | App Group UserDefaults | Simplest way to pass deck data to widget extension |
| Prompt storage | Versioned Swift constants | Trackable in Git; easy to diff prompt changes |

---

