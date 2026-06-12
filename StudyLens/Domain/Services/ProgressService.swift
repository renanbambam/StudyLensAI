import Foundation

struct ProgressService: ProgressServiceProtocol {

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func getDailyStreak(sessions: [StudySession]) -> Int {
        let studiedDays = Set(
            sessions
                .filter { $0.completedAt != nil }
                .map { calendar.startOfDay(for: $0.startedAt) }
        )
        guard !studiedDays.isEmpty else { return 0 }

        // A streak is alive if the user studied today; otherwise it may still
        // be alive from yesterday (today simply hasn't been studied yet).
        let today = calendar.startOfDay(for: .now)
        var cursor = studiedDays.contains(today)
            ? today
            : calendar.date(byAdding: .day, value: -1, to: today) ?? today
        guard studiedDays.contains(cursor) else { return 0 }

        var streak = 0
        while studiedDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    func getRetentionRate(reviews: [CardReview], days: Int) -> Double {
        guard let cutoff = calendar.date(byAdding: .day, value: -days, to: .now) else { return 0 }
        let recent = reviews.filter { $0.reviewedAt >= cutoff }
        guard !recent.isEmpty else { return 0 }
        let correct = recent.filter { $0.rating.isCorrect }.count
        return Double(correct) / Double(recent.count)
    }

    func getHeatmapData(sessions: [StudySession]) -> [Date: Int] {
        sessions
            .filter { $0.completedAt != nil }
            .reduce(into: [:]) { counts, session in
                counts[calendar.startOfDay(for: session.startedAt), default: 0] += 1
            }
    }

    func getDueCountBySubject(decks: [Deck]) -> [String: Int] {
        decks
            .filter { !$0.isArchived }
            .reduce(into: [:]) { counts, deck in
                counts[deck.subject, default: 0] += deck.dueCount
            }
    }
}
