import Foundation
import Observation

enum DeckSortOption: String, CaseIterable {
    case lastStudied = "Last Studied"
    case title = "Title"
    case dueCount = "Due Cards"
}

@Observable
final class DeckListViewModel {

    var decks: [Deck] = []
    var searchQuery: String = ""
    var selectedSubject: String?
    var sortOption: DeckSortOption = .lastStudied
    var error: StudyLensError?

    private let deckRepository: DeckRepositoryProtocol

    init(deckRepository: DeckRepositoryProtocol) {
        self.deckRepository = deckRepository
    }

    var subjects: [String] {
        Array(Set(decks.map(\.subject))).sorted()
    }

    var filteredDecks: [Deck] {
        var result = decks

        if let selectedSubject {
            result = result.filter { $0.subject == selectedSubject }
        }
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(query)
                    || $0.subject.localizedCaseInsensitiveContains(query)
            }
        }
        return switch sortOption {
        case .lastStudied: result.sorted { $0.updatedAt > $1.updatedAt }
        case .title: result.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .dueCount: result.sorted { $0.dueCount > $1.dueCount }
        }
    }

    @MainActor
    func loadDecks() async {
        do {
            decks = try deckRepository.fetchAll(includeArchived: false)
        } catch {
            self.error = .persistenceFailure(error.localizedDescription)
        }
    }

    @MainActor
    func deleteDeck(_ deck: Deck) async {
        do {
            try deckRepository.delete(deck)
            await loadDecks()
        } catch {
            self.error = .persistenceFailure(error.localizedDescription)
        }
    }

    @MainActor
    func archiveDeck(_ deck: Deck) async {
        do {
            try deckRepository.setArchived(deck, archived: true)
            await loadDecks()
        } catch {
            self.error = .persistenceFailure(error.localizedDescription)
        }
    }

    @MainActor
    func createDeck(title: String, subject: String, colorHex: String) async {
        do {
            _ = try deckRepository.create(title: title, subject: subject, colorHex: colorHex)
            await loadDecks()
        } catch {
            self.error = .persistenceFailure(error.localizedDescription)
        }
    }

    func deck(with id: UUID) -> Deck? {
        decks.first { $0.id == id }
    }
}
