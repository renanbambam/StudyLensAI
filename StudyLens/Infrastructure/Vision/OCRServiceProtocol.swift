import UIKit

/// Text extraction from scanned images (implemented by VisionOCRService).
protocol OCRServiceProtocol {
    func extractText(from image: UIImage) async throws -> String
    func extractText(from imageURL: URL) async throws -> String
}
