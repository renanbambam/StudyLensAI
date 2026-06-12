import Foundation
@testable import StudyLens

final class MockDeckRepository: DeckRepositoryProtocol {

    var decks: [Deck] = []
    var createDeckCallCount = 0
    var lastCreatedDrafts: [FlashcardDraft] = []
    var errorToThrow: Error?

    func fetchAll(includeArchived: Bool) throws -> [Deck] {
        if let errorToThrow { throw errorToThrow }
        return includeArchived ? decks : decks.filter { !$0.isArchived }
    }

    func fetch(by id: UUID) throws -> Deck? {
        if let errorToThrow { throw errorToThrow }
        return decks.first { $0.id == id }
    }

    func create(title: String, subject: String, colorHex: String) throws -> Deck {
        if let errorToThrow { throw errorToThrow }
        let deck = Deck(title: title, subject: subject, colorHex: colorHex)
        decks.append(deck)
        return deck
    }

    func createDeck(title: String, subject: String, colorHex: String, drafts: [FlashcardDraft]) throws -> Deck {
        if let errorToThrow { throw errorToThrow }
        createDeckCallCount += 1
        lastCreatedDrafts = drafts
        let deck = Deck(title: title, subject: subject, colorHex: colorHex)
        decks.append(deck)
        return deck
    }

    func delete(_ deck: Deck) throws {
        if let errorToThrow { throw errorToThrow }
        decks.removeAll { $0.id == deck.id }
    }

    func setArchived(_ deck: Deck, archived: Bool) throws {
        if let errorToThrow { throw errorToThrow }
        deck.isArchived = archived
    }
}
