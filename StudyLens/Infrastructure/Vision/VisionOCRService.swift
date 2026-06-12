import UIKit
import Vision

/// Vision Framework OCR tuned for handwriting recognition.
final class VisionOCRService: OCRServiceProtocol {

    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { throw StudyLensError.ocrFailed }
        return try await recognizeText(handler: VNImageRequestHandler(cgImage: cgImage))
    }

    func extractText(from imageURL: URL) async throws -> String {
        try await recognizeText(handler: VNImageRequestHandler(url: imageURL))
    }

    private func recognizeText(handler: VNImageRequestHandler) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if error != nil {
                    continuation.resume(throwing: StudyLensError.ocrFailed)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                let text = lines.joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if text.isEmpty {
                    continuation.resume(throwing: StudyLensError.emptyScan)
                } else {
                    continuation.resume(returning: text)
                }
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: StudyLensError.ocrFailed)
            }
        }
    }
}
