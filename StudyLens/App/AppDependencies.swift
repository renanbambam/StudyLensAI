import Foundation
import SwiftData
import WidgetKit

/// Composition root: creates services and repositories once and injects them
/// into ViewModels.
@MainActor
final class AppDependencies {

    let deckRepository: DeckRepositoryProtocol
    let flashcardRepository: FlashcardRepositoryProtocol
    let sessionRepository: SessionRepositoryProtocol
    let scanSessionRepository: ScanSessionRepositoryProtocol
    let spacedRepetitionService: SpacedRepetitionServiceProtocol
    let progressService: ProgressServiceProtocol
    let exportService: DeckExportServiceProtocol
    let ocrService: OCRServiceProtocol
    let aiService: AIGenerationServiceProtocol
    let keychain: KeychainHelper
    let analytics: StudyAnalytics

    init(modelContext: ModelContext) {
        self.deckRepository = DeckRepository(context: modelContext)
        self.flashcardRepository = FlashcardRepository(context: modelContext)
        self.sessionRepository = SessionRepository(context: modelContext)
        self.scanSessionRepository = ScanSessionRepository(context: modelContext)
        self.spacedRepetitionService = SpacedRepetitionService()
        self.progressService = ProgressService()
        self.exportService = DeckExportService()
        self.ocrService = VisionOCRService()
        self.keychain = KeychainHelper()
        self.analytics = StudyAnalytics()
        self.aiService = ClaudeAIService(keyProvider: keychain, analytics: analytics)
    }

    /// Called on app foreground and after a session ends.
    func refreshWidgetSnapshot() {
        guard let decks = try? deckRepository.fetchAll(includeArchived: false),
              let sessions = try? sessionRepository.fetchAllSessions() else { return }

        let streak = progressService.getDailyStreak(sessions: sessions)
        let topDeck = decks.max { $0.dueCount < $1.dueCount }

        let snapshot: WidgetSnapshot
        if let topDeck, topDeck.dueCount > 0 {
            snapshot = WidgetSnapshot(
                deckId: topDeck.id,
                deckName: topDeck.title,
                dueCount: topDeck.dueCount,
                subjectColorHex: topDeck.colorHex,
                streak: streak
            )
        } else {
            snapshot = WidgetSnapshot(
                deckId: nil,
                deckName: decks.first?.title ?? "No decks yet",
                dueCount: 0,
                subjectColorHex: decks.first?.colorHex ?? "#4F46E5",
                streak: streak
            )
        }
        WidgetDataStore.write(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
