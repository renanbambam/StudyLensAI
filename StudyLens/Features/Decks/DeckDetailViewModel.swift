import Foundation
import Observation

/// Wrapper so a generated export file can drive `.sheet(item:)`.
struct ExportedFile: Identifiable {
    let id = UUID()
    let url: URL
}

@Observable
final class DeckDetailViewModel {

    var deck: Deck?
    var cards: [Flashcard] = []
    var editingCard: Flashcard?
    var isAddingCard = false
    var isImproving = false
    var exportedFile: ExportedFile?
    var error: StudyLensError?

    private let flashcardRepository: FlashcardRepositoryProtocol
    private let aiService: AIGenerationServiceProtocol
    private let exportService: DeckExportServiceProtocol

    init(
        deck: Deck,
        flashcardRepository: FlashcardRepositoryProtocol,
        aiService: AIGenerationServiceProtocol,
        exportService: DeckExportServiceProtocol
    ) {
        self.deck = deck
        self.flashcardRepository = flashcardRepository
        self.aiService = aiService
        self.exportService = exportService
        refreshCards()
    }

    func refreshCards() {
        cards = (deck?.cardList ?? []).sorted { $0.createdAt < $1.createdAt }
    }

    @MainActor
    func addCard(front: String, back: String) async {
        guard let deck else { return }
        do {
            _ = try flashcardRepository.addCard(to: deck, front: front, back: back, hint: nil)
            refreshCards()
        } catch {
            self.error = .persistenceFailure(error.localizedDescription)
        }
    }

    @MainActor
    func updateCard(_ card: Flashcard, front: String, back: String) async {
        do {
            try flashcardRepository.updateCard(card, front: front, back: back, hint: card.hint)
            refreshCards()
        } catch {
            self.error = .persistenceFailure(error.localizedDescription)
        }
    }

    @MainActor
    func deleteCard(_ card: Flashcard) async {
        do {
            try flashcardRepository.deleteCard(card)
            refreshCards()
        } catch {
            self.error = .persistenceFailure(error.localizedDescription)
        }
    }

    @MainActor
    func export(format: DeckExportFormat) {
        guard let deck else { return }
        let content = exportService.export(deck: deck, format: format)

        let safeTitle = deck.title
            .components(separatedBy: CharacterSet.alphanumerics.union(.whitespaces).inverted)
            .joined()
            .trimmingCharacters(in: .whitespaces)
        let fileName = "\(safeTitle.isEmpty ? "deck" : safeTitle).\(format.fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            exportedFile = ExportedFile(url: url)
        } catch {
            self.error = .persistenceFailure(error.localizedDescription)
        }
    }

    /// Asks Claude to rewrite the card more clearly, then persists the result.
    @MainActor
    func improveCard(_ card: Flashcard) async {
        isImproving = true
        defer { isImproving = false }
        do {
            let draft = try await aiService.improveCard(front: card.front, back: card.back)
            try flashcardRepository.updateCard(card, front: draft.front, back: draft.back, hint: draft.hint)
            refreshCards()
        } catch let aiError as StudyLensError {
            error = aiError
        } catch {
            self.error = .invalidAIResponse
        }
    }
}
