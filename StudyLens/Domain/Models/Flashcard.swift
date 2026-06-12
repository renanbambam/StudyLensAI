import Foundation
import SwiftData

/// A single question/answer card with SM-2 scheduling state.
@Model
final class Flashcard {
    var id: UUID = UUID()
    var front: String = ""
    var back: String = ""
    var hint: String?
    var deck: Deck?

    // SM-2 spaced repetition fields
    var easeFactor: Double = 2.5
    var interval: Int = 0            // days until next review
    var repetitions: Int = 0         // consecutive correct answers
    var nextReviewDate: Date = Date.now
    var lastReviewedAt: Date?
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \CardReview.flashcard)
    var reviews: [CardReview]? = []

    init(front: String, back: String, hint: String? = nil) {
        self.id = UUID()
        self.front = front
        self.back = back
        self.hint = hint
        self.easeFactor = 2.5
        self.interval = 0
        self.repetitions = 0
        self.nextReviewDate = .now
        self.createdAt = .now
    }

    var isDue: Bool { nextReviewDate <= Date.now }
    var isWeak: Bool { easeFactor < 2.0 }
}
