import Foundation

/// Result of one SM-2 calculation. The caller applies it to the card.
struct SpacedRepetitionResult: Equatable {
    let newInterval: Int
    let newEaseFactor: Double
    let newRepetitions: Int
    let nextReviewDate: Date
}

/// Pure SM-2 scheduling. No persistence, no UI — fully testable in isolation.
protocol SpacedRepetitionServiceProtocol {
    func calculateNextReview(card: Flashcard, rating: ReviewRating) -> SpacedRepetitionResult
}
