import Foundation

struct DeckExportService: DeckExportServiceProtocol {

    func export(deck: Deck, format: DeckExportFormat) -> String {
        // Deterministic order: oldest card first.
        let cards = deck.cardList.sorted { $0.createdAt < $1.createdAt }
        return switch format {
        case .csv: exportCSV(cards: cards)
        case .ankiTSV: exportAnkiTSV(cards: cards)
        }
    }

    private func exportCSV(cards: [Flashcard]) -> String {
        var lines = ["front,back,hint"]
        for card in cards {
            lines.append([
                escapeCSVField(card.front),
                escapeCSVField(card.back),
                escapeCSVField(card.hint ?? "")
            ].joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    /// RFC 4180: quote fields containing commas, quotes, or newlines;
    /// double any embedded quotes.
    private func escapeCSVField(_ field: String) -> String {
        let needsQuoting = field.contains(",") || field.contains("\"") || field.contains("\n")
        guard needsQuoting else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private func exportAnkiTSV(cards: [Flashcard]) -> String {
        cards.map { card in
            [card.front, card.back, card.hint ?? ""]
                .map(sanitizeTSVField)
                .joined(separator: "\t")
        }
        .joined(separator: "\n")
    }

    /// TSV has no escaping mechanism — replace structural characters with spaces.
    private func sanitizeTSVField(_ field: String) -> String {
        field
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
    }
}
