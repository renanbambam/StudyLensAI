import Foundation
import Observation

enum AppTab: Hashable {
    case decks
    case scan
    case stats
}

/// Deep link format: studylens://study/<deck-uuid> (used by the widget).
@Observable
final class AppRouter {

    var selectedTab: AppTab = .decks

    /// Set by a deep link; DeckListView consumes it to push a study session.
    var pendingStudyDeckId: UUID?

    /// Reads and clears the deck name written by StartStudyIntent (Siri).
    func consumePendingIntentDeckName() -> String? {
        let defaults = UserDefaults(suiteName: WidgetDataStore.appGroupId)
        guard let name = defaults?.string(forKey: "intent.pendingDeckName") else { return nil }
        defaults?.removeObject(forKey: "intent.pendingDeckName")
        return name
    }

    func handle(url: URL) {
        guard url.scheme == "studylens" else { return }
        switch url.host {
        case "study":
            let idString = url.lastPathComponent
            if let deckId = UUID(uuidString: idString) {
                pendingStudyDeckId = deckId
            }
            selectedTab = .decks
        case "scan":
            selectedTab = .scan
        default:
            break
        }
    }
}
