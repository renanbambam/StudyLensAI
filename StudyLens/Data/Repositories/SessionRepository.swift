import Foundation
import SwiftData

final class SessionRepository: SessionRepositoryProtocol {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func startSession(deck: Deck) throws -> StudySession {
        let session = StudySession(deck: deck)
        context.insert(session)
        try context.save()
        return session
    }

    func recordReview(
        card: Flashcard,
        session: StudySession,
        rating: ReviewRating,
        responseTimeSeconds: Double
    ) throws {
        let review = CardReview(
            flashcard: card,
            session: session,
            rating: rating,
            responseTimeSeconds: responseTimeSeconds
        )
        context.insert(review)
        session.cardsStudied += 1
        if rating.isCorrect {
            session.correctCount += 1
        }
        try context.save()
    }

    func completeSession(_ session: StudySession) throws {
        session.completedAt = .now
        session.retentionRate = session.cardsStudied > 0
            ? Double(session.correctCount) / Double(session.cardsStudied)
            : 0
        session.deck?.updatedAt = .now
        try context.save()
    }

    func fetchAllSessions() throws -> [StudySession] {
        let descriptor = FetchDescriptor<StudySession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchRecentSessions(limit: Int) throws -> [StudySession] {
        var descriptor = FetchDescriptor<StudySession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    func fetchReviews(withinDays days: Int) throws -> [CardReview] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .distantPast
        let descriptor = FetchDescriptor<CardReview>(
            predicate: #Predicate { $0.reviewedAt >= cutoff },
            sortBy: [SortDescriptor(\.reviewedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
}
