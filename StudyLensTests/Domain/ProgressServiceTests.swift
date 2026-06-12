import XCTest
import SwiftData
@testable import StudyLens

final class ProgressServiceTests: XCTestCase {

    private let service = ProgressService()
    private let calendar = Calendar.current

    private func session(daysAgo: Int, completed: Bool = true) -> StudySession {
        let session = StudySession()
        session.startedAt = calendar.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        if completed {
            session.completedAt = session.startedAt.addingTimeInterval(300)
        }
        return session
    }

    private func review(daysAgo: Int, rating: ReviewRating) -> CardReview {
        let review = CardReview(flashcard: nil, session: nil, rating: rating, responseTimeSeconds: 2)
        review.reviewedAt = calendar.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        return review
    }

    // MARK: - Streak

    func testStreakIsZeroWithNoSessions() {
        XCTAssertEqual(service.getDailyStreak(sessions: []), 0)
    }

    func testStreakCountsConsecutiveDaysIncludingToday() {
        let sessions = [session(daysAgo: 0), session(daysAgo: 1), session(daysAgo: 2)]
        XCTAssertEqual(service.getDailyStreak(sessions: sessions), 3)
    }

    func testStreakSurvivesWhenTodayNotYetStudied() {
        let sessions = [session(daysAgo: 1), session(daysAgo: 2)]
        XCTAssertEqual(service.getDailyStreak(sessions: sessions), 2)
    }

    func testStreakBreaksOnGap() {
        let sessions = [session(daysAgo: 0), session(daysAgo: 2), session(daysAgo: 3)]
        XCTAssertEqual(service.getDailyStreak(sessions: sessions), 1)
    }

    func testIncompleteSessionsDoNotCountTowardStreak() {
        let sessions = [session(daysAgo: 0, completed: false)]
        XCTAssertEqual(service.getDailyStreak(sessions: sessions), 0)
    }

    // MARK: - Retention

    func testRetentionRateZeroWithNoReviews() {
        XCTAssertEqual(service.getRetentionRate(reviews: [], days: 7), 0)
    }

    func testRetentionCountsNonAgainAsCorrect() {
        let reviews = [
            review(daysAgo: 1, rating: .easy),
            review(daysAgo: 1, rating: .good),
            review(daysAgo: 2, rating: .hard),
            review(daysAgo: 2, rating: .again)
        ]
        XCTAssertEqual(service.getRetentionRate(reviews: reviews, days: 7), 0.75, accuracy: 0.0001)
    }

    func testRetentionIgnoresReviewsOutsideWindow() {
        let reviews = [
            review(daysAgo: 1, rating: .again),
            review(daysAgo: 30, rating: .easy),
            review(daysAgo: 30, rating: .easy)
        ]
        XCTAssertEqual(service.getRetentionRate(reviews: reviews, days: 7), 0, accuracy: 0.0001)
    }

    // MARK: - Heatmap

    func testHeatmapGroupsSessionsByDay() {
        let sessions = [session(daysAgo: 0), session(daysAgo: 0), session(daysAgo: 1)]
        let heatmap = service.getHeatmapData(sessions: sessions)

        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        XCTAssertEqual(heatmap[today], 2)
        XCTAssertEqual(heatmap[yesterday], 1)
    }

    func testHeatmapExcludesIncompleteSessions() {
        let sessions = [session(daysAgo: 0, completed: false)]
        XCTAssertTrue(service.getHeatmapData(sessions: sessions).isEmpty)
    }

    // MARK: - Due by subject

    func testDueCountGroupsBySubjectAndSkipsArchived() throws {
        // Relationships need a live container; use an in-memory one.
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)

        let biology = Deck(title: "Cells", subject: "Biology")
        let history = Deck(title: "WW2", subject: "History")
        let archived = Deck(title: "Old", subject: "History")
        archived.isArchived = true
        [biology, history, archived].forEach { context.insert($0) }

        // Flashcards default to nextReviewDate = now → due immediately.
        for (deck, fronts) in [(biology, ["1", "2"]), (history, ["3"]), (archived, ["4"])] {
            for front in fronts {
                let card = Flashcard(front: front, back: front)
                context.insert(card)
                card.deck = deck
            }
        }
        try context.save()

        let result = service.getDueCountBySubject(decks: [biology, history, archived])
        XCTAssertEqual(result["Biology"], 2)
        XCTAssertEqual(result["History"], 1)
    }
}
