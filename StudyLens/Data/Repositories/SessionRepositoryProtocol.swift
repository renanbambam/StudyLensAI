import Foundation

/// Study session and review history persistence.
protocol SessionRepositoryProtocol {
    func startSession(deck: Deck) throws -> StudySession
    func recordReview(
        card: Flashcard,
        session: StudySession,
        rating: ReviewRating,
        responseTimeSeconds: Double
    ) throws
    func completeSession(_ session: StudySession) throws
    func fetchAllSessions() throws -> [StudySession]
    func fetchRecentSessions(limit: Int) throws -> [StudySession]
    func fetchReviews(withinDays days: Int) throws -> [CardReview]
}
