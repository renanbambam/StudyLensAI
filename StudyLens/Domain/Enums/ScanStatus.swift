import Foundation

/// Lifecycle of a camera scan, from OCR capture to AI deck generation.
enum ScanStatus: String, Codable, Sendable {
    case pending
    case generating
    case complete
    case failed
}
