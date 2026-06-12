import Foundation
import SwiftData

/// CloudKit-backed SwiftData forbids unique constraints and requires default
/// values plus optional relationships; `id` uniqueness is guaranteed by UUID
/// generation instead of a schema constraint.
@Model
final class Deck {
    var id: UUID = UUID()
    var title: String = ""
    var subject: String = ""         // "Biology", "History", "Math"
    var colorHex: String = "#4F46E5"
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var isArchived: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \Flashcard.deck)
    var cards: [Flashcard]? = []

    @Relationship(deleteRule: .cascade, inverse: \StudySession.deck)
    var sessions: [StudySession]? = []

    init(title: String, subject: String, colorHex: String = "#4F46E5") {
        self.id = UUID()
        self.title = title
        self.subject = subject
        self.colorHex = colorHex
        self.createdAt = .now
        self.updatedAt = .now
    }

    var cardList: [Flashcard] { cards ?? [] }
    var sessionList: [StudySession] { sessions ?? [] }
    var dueCount: Int { cardList.filter(\.isDue).count }
    var totalCards: Int { cardList.count }
}
