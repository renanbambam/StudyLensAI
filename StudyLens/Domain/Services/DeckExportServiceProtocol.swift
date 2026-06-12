import Foundation

/// Export targets for a deck (Phase 2: "Export deck as CSV / Anki format").
enum DeckExportFormat: String, CaseIterable {
    /// RFC-4180-style CSV with a header row: front,back,hint.
    case csv
    /// Tab-separated values without a header — the format Anki imports
    /// natively (fields map to Front, Back, plus an optional hint field).
    case ankiTSV

    var fileExtension: String {
        switch self {
        case .csv: "csv"
        case .ankiTSV: "txt"
        }
    }

    var label: String {
        switch self {
        case .csv: "CSV"
        case .ankiTSV: "Anki (TSV)"
        }
    }
}

/// Pure deck-to-text serialization. No file I/O, no UI — testable in isolation.
protocol DeckExportServiceProtocol {
    func export(deck: Deck, format: DeckExportFormat) -> String
}
