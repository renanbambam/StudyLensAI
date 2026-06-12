import Foundation

/// Deck persistence boundary. ViewModels never touch ModelContext directly.
protocol DeckRepositoryProtocol {
    func fetchAll(includeArchived: Bool) throws -> [Deck]
    func fetch(by id: UUID) throws -> Deck?
    func create(title: String, subject: String, colorHex: String) throws -> Deck
    /// Creates a deck pre-populated from AI-generated drafts (scan flow).
    func createDeck(title: String, subject: String, colorHex: String, drafts: [FlashcardDraft]) throws -> Deck
    func delete(_ deck: Deck) throws
    func setArchived(_ deck: Deck, archived: Bool) throws
}
