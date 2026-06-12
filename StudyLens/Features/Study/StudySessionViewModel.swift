import Foundation
import Observation

struct SessionStats: Equatable {
    let cardsStudied: Int
    let correctCount: Int
    let retentionRate: Double
    let durationSeconds: TimeInterval
}

@Observable
final class StudySessionViewModel {

    var currentCard: Flashcard?
    var isFlipped = false
    var progress: Double = 0
    var sessionComplete = false
    var cardsRemaining = 0
    var sessionStats: SessionStats?
    var error: StudyLensError?

    private var queue: [Flashcard] = []
    private var totalCards = 0
    private var session: StudySession?
    private var sessionStartedAt = Date.now
    private var cardShownAt = Date.now

    private let srService: SpacedRepetitionServiceProtocol
    private let sessionRepository: SessionRepositoryProtocol
    private let flashcardRepository: FlashcardRepositoryProtocol
    private let onSessionEnd: @MainActor () -> Void

    init(
        srService: SpacedRepetitionServiceProtocol,
        sessionRepository: SessionRepositoryProtocol,
        flashcardRepository: FlashcardRepositoryProtocol,
        onSessionEnd: @escaping @MainActor () -> Void = {}
    ) {
        self.srService = srService
        self.sessionRepository = sessionRepository
        self.flashcardRepository = flashcardRepository
        self.onSessionEnd = onSessionEnd
    }

    func startSession(deck: Deck, mode: StudyMode) {
        let cards = deck.cardList
        queue = switch mode {
        case .allDue: cards.filter(\.isDue).shuffled()
        case .fullDeck: cards.shuffled()
        case .weakCards: cards.filter(\.isWeak).shuffled()
        }
        totalCards = queue.count
        cardsRemaining = totalCards
        sessionStartedAt = .now
        guard !queue.isEmpty else {
            sessionComplete = true
            return
        }

        do {
            session = try sessionRepository.startSession(deck: deck)
        } catch {
            self.error = .persistenceFailure(error.localizedDescription)
        }
        advance()
    }

    func flipCard() {
        isFlipped.toggle()
    }

    @MainActor
    func rate(_ rating: ReviewRating) async {
        guard let card = currentCard, let session else { return }

        let responseTime = Date.now.timeIntervalSince(cardShownAt)
        let result = srService.calculateNextReview(card: card, rating: rating)

        do {
            try flashcardRepository.applyReviewResult(result, to: card)
            try sessionRepository.recordReview(
                card: card,
                session: session,
                rating: rating,
                responseTimeSeconds: responseTime
            )
        } catch {
            self.error = .persistenceFailure(error.localizedDescription)
        }

        if queue.isEmpty {
            await complete()
        } else {
            advance()
        }
    }

    private func advance() {
        guard !queue.isEmpty else { return }
        currentCard = queue.removeFirst()
        isFlipped = false
        cardShownAt = .now
        cardsRemaining = queue.count + 1
        progress = totalCards > 0 ? Double(totalCards - queue.count - 1) / Double(totalCards) : 0
    }

    @MainActor
    private func complete() async {
        guard let session else { return }
        do {
            try sessionRepository.completeSession(session)
        } catch {
            self.error = .persistenceFailure(error.localizedDescription)
        }
        sessionStats = SessionStats(
            cardsStudied: session.cardsStudied,
            correctCount: session.correctCount,
            retentionRate: session.retentionRate,
            durationSeconds: Date.now.timeIntervalSince(sessionStartedAt)
        )
        currentCard = nil
        progress = 1
        cardsRemaining = 0
        sessionComplete = true
        onSessionEnd()
    }
}
