import Foundation

/// User confidence rating for a reviewed card. Raw value feeds the SM-2 algorithm.
enum ReviewRating: Int, Codable, CaseIterable, Sendable {
    case again = 0   // complete blackout
    case hard = 1    // incorrect; easy to recall
    case good = 2    // correct with some effort
    case easy = 3    // perfect recall

    var label: String {
        switch self {
        case .again: "Again"
        case .hard: "Hard"
        case .good: "Good"
        case .easy: "Easy"
        }
    }

    /// Retention counts every rating except a blackout as correct.
    var isCorrect: Bool { self != .again }
}
