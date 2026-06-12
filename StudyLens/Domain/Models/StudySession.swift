import Foundation
import SwiftData

/// One complete study session for a deck.
@Model
final class StudySession {
    var id: UUID = UUID()
    var deck: Deck?
    var startedAt: Date = Date.now
    var completedAt: Date?
    var cardsStudied: Int = 0
    var correctCount: Int = 0
    var retentionRate: Double = 0    // correctCount / cardsStudied

    @Relationship(deleteRule: .cascade, inverse: \CardReview.session)
    var reviews: [CardReview]? = []

    init(deck: Deck? = nil) {
        self.id = UUID()
        self.deck = deck
        self.startedAt = .now
    }
}
