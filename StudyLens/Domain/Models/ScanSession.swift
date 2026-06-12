import Foundation
import SwiftData

/// A raw OCR scan kept for traceability between a scanned page and the deck
/// generated from it.
@Model
final class ScanSession {
    var id: UUID = UUID()
    var rawText: String = ""
    @Attribute(.externalStorage) var imageData: Data?  // thumbnail of scanned page
    var generatedDeckId: UUID?       // Deck created from this scan
    var scannedAt: Date = Date.now
    var statusValue: String = ScanStatus.pending.rawValue

    init(rawText: String, imageData: Data? = nil) {
        self.id = UUID()
        self.rawText = rawText
        self.imageData = imageData
        self.scannedAt = .now
        self.statusValue = ScanStatus.pending.rawValue
    }

    var status: ScanStatus {
        get { ScanStatus(rawValue: statusValue) ?? .pending }
        set { statusValue = newValue.rawValue }
    }
}
