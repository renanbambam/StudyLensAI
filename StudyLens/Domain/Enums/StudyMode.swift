import Foundation

/// Card selection strategy for a study session.
/// Hashable + Identifiable so it can drive navigation destinations.
enum StudyMode: Hashable, Identifiable, Sendable {
    case allDue        // only cards whose nextReviewDate has passed
    case fullDeck      // all cards regardless of schedule
    case weakCards     // cards with easeFactor < 2.0

    var id: Self { self }

    var title: String {
        switch self {
        case .allDue: "Due Cards"
        case .fullDeck: "Full Deck"
        case .weakCards: "Weak Cards"
        }
    }
}
