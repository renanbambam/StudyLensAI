import Foundation

/// Flashcard CRUD within a deck.
protocol FlashcardRepositoryProtocol {
    func addCard(to deck: Deck, front: String, back: String, hint: String?) throws -> Flashcard
    func updateCard(_ card: Flashcard, front: String, back: String, hint: String?) throws
    func deleteCard(_ card: Flashcard) throws
    /// Persists an SM-2 result after a review.
    func applyReviewResult(_ result: SpacedRepetitionResult, to card: Flashcard) throws
}
