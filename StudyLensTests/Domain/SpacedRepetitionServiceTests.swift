import XCTest
@testable import StudyLens

final class SpacedRepetitionServiceTests: XCTestCase {

    private let service = SpacedRepetitionService()

    private func makeCard(
        easeFactor: Double = 2.5,
        interval: Int = 0,
        repetitions: Int = 0
    ) -> Flashcard {
        let card = Flashcard(front: "Q", back: "A")
        card.easeFactor = easeFactor
        card.interval = interval
        card.repetitions = repetitions
        return card
    }

    // MARK: - Again (rating 0)

    func testAgainResetsRepetitionsAndSchedulesTomorrow() {
        let card = makeCard(easeFactor: 2.5, interval: 12, repetitions: 4)
        let result = service.calculateNextReview(card: card, rating: .again)

        XCTAssertEqual(result.newRepetitions, 0)
        XCTAssertEqual(result.newInterval, 1)
        // EF for q=0: 2.5 + (0.1 - 3*(0.08 + 3*0.02)) = 2.5 - 0.32 = 2.18
        XCTAssertEqual(result.newEaseFactor, 2.18, accuracy: 0.0001)
    }

    // MARK: - Interval ladder

    func testFirstSuccessfulReviewIsOneDay() {
        let card = makeCard()
        let result = service.calculateNextReview(card: card, rating: .good)

        XCTAssertEqual(result.newRepetitions, 1)
        XCTAssertEqual(result.newInterval, 1)
    }

    func testSecondSuccessfulReviewIsSixDays() {
        let card = makeCard(interval: 1, repetitions: 1)
        let result = service.calculateNextReview(card: card, rating: .good)

        XCTAssertEqual(result.newRepetitions, 2)
        XCTAssertEqual(result.newInterval, 6)
    }

    func testThirdReviewMultipliesIntervalByEaseFactor() {
        let card = makeCard(easeFactor: 2.5, interval: 6, repetitions: 2)
        let result = service.calculateNextReview(card: card, rating: .easy)

        // EF for q=3: 2.5 + 0.1 = 2.6 → interval = Int(6 * 2.6) = 15
        XCTAssertEqual(result.newRepetitions, 3)
        XCTAssertEqual(result.newEaseFactor, 2.6, accuracy: 0.0001)
        XCTAssertEqual(result.newInterval, 15)
    }

    // MARK: - Ease factor behavior

    func testEaseFactorNeverDropsBelowFloor() {
        let card = makeCard(easeFactor: 1.3, interval: 1, repetitions: 1)
        let result = service.calculateNextReview(card: card, rating: .again)

        XCTAssertEqual(result.newEaseFactor, 1.3, accuracy: 0.0001)
    }

    func testHardReducesEaseFactor() {
        let card = makeCard(easeFactor: 2.5)
        let result = service.calculateNextReview(card: card, rating: .hard)

        // EF for q=1: 2.5 + (0.1 - 2*(0.08 + 2*0.02)) = 2.5 - 0.14 = 2.36
        XCTAssertEqual(result.newEaseFactor, 2.36, accuracy: 0.0001)
        XCTAssertEqual(result.newRepetitions, 1)
    }

    func testGoodKeepsEaseFactorRoughlyStable() {
        let card = makeCard(easeFactor: 2.5)
        let result = service.calculateNextReview(card: card, rating: .good)

        // EF for q=2: 2.5 + (0.1 - 1*(0.08 + 0.02)) = 2.5
        XCTAssertEqual(result.newEaseFactor, 2.5, accuracy: 0.0001)
    }

    // MARK: - Next review date

    func testNextReviewDateMatchesInterval() throws {
        let card = makeCard(interval: 1, repetitions: 1)
        let result = service.calculateNextReview(card: card, rating: .good)

        let expected = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 6, to: .now))
        XCTAssertEqual(
            result.nextReviewDate.timeIntervalSince1970,
            expected.timeIntervalSince1970,
            accuracy: 5
        )
    }
}
