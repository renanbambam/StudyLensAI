import Foundation

/// SM-2 algorithm (SuperMemo 2), as specified in the architecture document.
///
/// Ratings map to SM-2 quality via `ReviewRating.rawValue` (0...3). An `again`
/// rating resets repetitions and schedules the card for tomorrow; everything
/// else grows the interval: 1 day, 6 days, then interval * ease factor.
struct SpacedRepetitionService: SpacedRepetitionServiceProtocol {

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func calculateNextReview(card: Flashcard, rating: ReviewRating) -> SpacedRepetitionResult {
        let quality = Double(rating.rawValue)
        var newEaseFactor = card.easeFactor + (0.1 - (3 - quality) * (0.08 + (3 - quality) * 0.02))
        newEaseFactor = max(1.3, newEaseFactor)

        var newRepetitions = card.repetitions
        var newInterval = card.interval

        if rating == .again {
            newRepetitions = 0
            newInterval = 1
        } else {
            newRepetitions += 1
            newInterval = switch newRepetitions {
            case 1: 1
            case 2: 6
            default: max(1, Int(Double(card.interval) * newEaseFactor))
            }
        }

        let nextDate = calendar.date(byAdding: .day, value: newInterval, to: .now) ?? .now
        return SpacedRepetitionResult(
            newInterval: newInterval,
            newEaseFactor: newEaseFactor,
            newRepetitions: newRepetitions,
            nextReviewDate: nextDate
        )
    }
}
