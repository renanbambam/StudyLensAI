import Foundation
import SwiftData

final class FlashcardRepository: FlashcardRepositoryProtocol {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func addCard(to deck: Deck, front: String, back: String, hint: String?) throws -> Flashcard {
        let card = Flashcard(front: front, back: back, hint: hint)
        card.deck = deck
        context.insert(card)
        deck.updatedAt = .now
        try context.save()
        return card
    }

    func updateCard(_ card: Flashcard, front: String, back: String, hint: String?) throws {
        card.front = front
        card.back = back
        card.hint = hint
        card.deck?.updatedAt = .now
        try context.save()
    }

    func deleteCard(_ card: Flashcard) throws {
        let deck = card.deck
        context.delete(card)
        deck?.updatedAt = .now
        try context.save()
    }

    func applyReviewResult(_ result: SpacedRepetitionResult, to card: Flashcard) throws {
        card.easeFactor = result.newEaseFactor
        card.interval = result.newInterval
        card.repetitions = result.newRepetitions
        card.nextReviewDate = result.nextReviewDate
        card.lastReviewedAt = .now
        try context.save()
    }
}
