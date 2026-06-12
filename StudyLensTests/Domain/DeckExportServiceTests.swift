import XCTest
import SwiftData
@testable import StudyLens

final class DeckExportServiceTests: XCTestCase {

    private let service = DeckExportService()

    private struct CardSpec {
        let front: String
        let back: String
        var hint: String?
    }

    /// Builds a deck with cards inside an in-memory container (relationships
    /// require a live container).
    private func makeDeck(cards: [CardSpec]) throws -> Deck {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)

        let deck = Deck(title: "Test Deck", subject: "Biology")
        context.insert(deck)
        for (index, spec) in cards.enumerated() {
            let card = Flashcard(front: spec.front, back: spec.back, hint: spec.hint)
            // Deterministic ordering: oldest first.
            card.createdAt = Date(timeIntervalSince1970: TimeInterval(index))
            context.insert(card)
            card.deck = deck
        }
        try context.save()
        return deck
    }

    // MARK: - CSV

    func testCSVHasHeaderAndOneRowPerCard() throws {
        let deck = try makeDeck(cards: [
            CardSpec(front: "What is a cell?", back: "Basic unit of life", hint: "Smallest"),
            CardSpec(front: "Define osmosis", back: "Water diffusion", hint: nil)
        ])

        let csv = service.export(deck: deck, format: .csv)
        let lines = csv.components(separatedBy: "\n")

        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0], "front,back,hint")
        XCTAssertEqual(lines[1], "What is a cell?,Basic unit of life,Smallest")
        XCTAssertEqual(lines[2], "Define osmosis,Water diffusion,")
    }

    func testCSVEscapesCommasQuotesAndNewlines() throws {
        let deck = try makeDeck(cards: [
            CardSpec(front: "A, B", back: "He said \"hi\"", hint: "line1\nline2")
        ])

        let csv = service.export(deck: deck, format: .csv)
        let dataLine = csv.components(separatedBy: "\n").dropFirst().joined(separator: "\n")

        XCTAssertEqual(dataLine, "\"A, B\",\"He said \"\"hi\"\"\",\"line1\nline2\"")
    }

    func testCSVOfEmptyDeckIsHeaderOnly() throws {
        let deck = try makeDeck(cards: [])
        XCTAssertEqual(service.export(deck: deck, format: .csv), "front,back,hint")
    }

    // MARK: - Anki TSV

    func testAnkiTSVHasNoHeaderAndTabSeparators() throws {
        let deck = try makeDeck(cards: [
            CardSpec(front: "Front 1", back: "Back 1", hint: "Hint 1"),
            CardSpec(front: "Front 2", back: "Back 2", hint: nil)
        ])

        let tsv = service.export(deck: deck, format: .ankiTSV)
        let lines = tsv.components(separatedBy: "\n")

        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines[0], "Front 1\tBack 1\tHint 1")
        XCTAssertEqual(lines[1], "Front 2\tBack 2\t")
    }

    func testAnkiTSVSanitizesTabsAndNewlines() throws {
        let deck = try makeDeck(cards: [
            CardSpec(front: "has\ttab", back: "has\nnewline", hint: nil)
        ])

        let tsv = service.export(deck: deck, format: .ankiTSV)

        XCTAssertEqual(tsv, "has tab\thas newline\t")
    }

    func testExportOrdersCardsByCreationDate() throws {
        let deck = try makeDeck(cards: [
            CardSpec(front: "Oldest", back: "B", hint: nil),
            CardSpec(front: "Newest", back: "B", hint: nil)
        ])

        let tsv = service.export(deck: deck, format: .ankiTSV)

        XCTAssertTrue(tsv.hasPrefix("Oldest"))
    }
}
