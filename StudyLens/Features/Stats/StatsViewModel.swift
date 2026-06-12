import Foundation
import Observation

@Observable
final class StatsViewModel {

    var streak = 0
    var totalCardsStudied = 0
    var weeklyRetentionRate: Double = 0
    var heatmapData: [Date: Int] = [:]
    var dueCountBySubject: [String: Int] = [:]
    var recentSessions: [StudySession] = []
    var error: StudyLensError?

    private let progressService: ProgressServiceProtocol
    private let sessionRepository: SessionRepositoryProtocol
    private let deckRepository: DeckRepositoryProtocol

    init(
        progressService: ProgressServiceProtocol,
        sessionRepository: SessionRepositoryProtocol,
        deckRepository: DeckRepositoryProtocol
    ) {
        self.progressService = progressService
        self.sessionRepository = sessionRepository
        self.deckRepository = deckRepository
    }

    @MainActor
    func loadStats() async {
        do {
            let sessions = try sessionRepository.fetchAllSessions()
            let reviews = try sessionRepository.fetchReviews(withinDays: 7)
            let decks = try deckRepository.fetchAll(includeArchived: false)

            streak = progressService.getDailyStreak(sessions: sessions)
            totalCardsStudied = sessions.reduce(0) { $0 + $1.cardsStudied }
            weeklyRetentionRate = progressService.getRetentionRate(reviews: reviews, days: 7)
            heatmapData = progressService.getHeatmapData(sessions: sessions)
            dueCountBySubject = progressService.getDueCountBySubject(decks: decks)
            recentSessions = Array(sessions.prefix(5))
        } catch {
            self.error = .persistenceFailure(error.localizedDescription)
        }
    }
}
