import Foundation

/// Pure statistics over study history. Inputs are plain arrays so the service
/// stays free of persistence concerns and is trivially testable.
protocol ProgressServiceProtocol {
    /// Consecutive days (ending today or yesterday) with at least one completed session.
    func getDailyStreak(sessions: [StudySession]) -> Int
    /// Fraction of correct reviews within the last `days` days. 0 when there are none.
    func getRetentionRate(reviews: [CardReview], days: Int) -> Double
    /// Sessions per day, keyed by start of day — feeds the heatmap calendar.
    func getHeatmapData(sessions: [StudySession]) -> [Date: Int]
    /// Due-card totals grouped by subject, ignoring archived decks.
    func getDueCountBySubject(decks: [Deck]) -> [String: Int]
}
