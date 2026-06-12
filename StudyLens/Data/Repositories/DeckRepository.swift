import Foundation
import SwiftData

final class DeckRepository: DeckRepositoryProtocol {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll(includeArchived: Bool) throws -> [Deck] {
        var descriptor = FetchDescriptor<Deck>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        if !includeArchived {
            descriptor.predicate = #Predicate { !$0.isArchived }
        }
        return try context.fetch(descriptor)
    }

    func fetch(by id: UUID) throws -> Deck? {
        var descriptor = FetchDescriptor<Deck>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func create(title: String, subject: String, colorHex: String) throws -> Deck {
        let deck = Deck(title: title, subject: subject, colorHex: colorHex)
        context.insert(deck)
        try context.save()
        return deck
    }

    func createDeck(title: String, subject: String, colorHex: String, drafts: [FlashcardDraft]) throws -> Deck {
        let deck = Deck(title: title, subject: subject, colorHex: colorHex)
        context.insert(deck)
        for draft in drafts {
            let card = Flashcard(front: draft.front, back: draft.back, hint: draft.hint)
            card.deck = deck
            context.insert(card)
        }
        try context.save()
        return deck
    }

    func delete(_ deck: Deck) throws {
        context.delete(deck)
        try context.save()
    }

    func setArchived(_ deck: Deck, archived: Bool) throws {
        deck.isArchived = archived
        deck.updatedAt = .now
        try context.save()
    }
}
