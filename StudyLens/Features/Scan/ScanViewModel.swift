import UIKit
import Observation

@Observable
final class ScanViewModel {

    var scannedImage: UIImage?
    var extractedText: String = ""
    var generatedDrafts: [FlashcardDraft] = []
    var isScanning = false
    var isGenerating = false
    var error: StudyLensError?
    var showDeckNaming = false

    private(set) var lastSubject: String = ""
    private(set) var currentScan: ScanSession?

    private let ocrService: OCRServiceProtocol
    private let aiService: AIGenerationServiceProtocol
    private let deckRepository: DeckRepositoryProtocol
    private let scanSessionRepository: ScanSessionRepositoryProtocol
    private let analytics: StudyAnalytics

    init(
        ocrService: OCRServiceProtocol,
        aiService: AIGenerationServiceProtocol,
        deckRepository: DeckRepositoryProtocol,
        scanSessionRepository: ScanSessionRepositoryProtocol,
        analytics: StudyAnalytics = StudyAnalytics()
    ) {
        self.ocrService = ocrService
        self.aiService = aiService
        self.deckRepository = deckRepository
        self.scanSessionRepository = scanSessionRepository
        self.analytics = analytics
    }

    @MainActor
    func scanDocument(image: UIImage) async {
        scannedImage = image
        isScanning = true
        error = nil
        defer { isScanning = false }

        do {
            extractedText = try await ocrService.extractText(from: image)
            // Trace record is best-effort: a persistence hiccup here must not
            // block the user's scan flow.
            currentScan = try? scanSessionRepository.create(
                rawText: extractedText,
                imageData: Self.thumbnailData(from: image)
            )
            analytics.track("scan_ocr_succeeded", metadata: ["chars": "\(extractedText.count)"])
        } catch let scanError as StudyLensError {
            error = scanError
        } catch {
            self.error = .ocrFailed
        }
    }

    /// Renders the PDF's first page through the same OCR pipeline as a scan.
    @MainActor
    func importPDF(from url: URL) async {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        guard let image = PDFPageRenderer.firstPageImage(from: url) else {
            error = .pdfImportFailed
            return
        }
        analytics.track("pdf_imported")
        await scanDocument(image: image)
    }

    @MainActor
    func generateFlashcards(subject: String) async {
        guard !extractedText.isEmpty else {
            error = .emptyScan
            return
        }
        lastSubject = subject
        isGenerating = true
        error = nil
        defer { isGenerating = false }

        if let scan = currentScan {
            try? scanSessionRepository.updateStatus(scan, to: .generating)
        }
        do {
            generatedDrafts = try await aiService.generateFlashcards(
                from: extractedText,
                subject: subject
            )
        } catch let aiError as StudyLensError {
            error = aiError
            markScanFailed()
        } catch {
            self.error = .invalidAIResponse
            markScanFailed()
        }
    }

    @MainActor
    func retryGeneration() async {
        await generateFlashcards(subject: lastSubject.isEmpty ? "General" : lastSubject)
    }

    @MainActor
    func saveDeck(title: String, subject: String) async {
        do {
            let deck = try deckRepository.createDeck(
                title: title,
                subject: subject,
                colorHex: DeckPalette.random,
                drafts: generatedDrafts
            )
            if let scan = currentScan {
                try? scanSessionRepository.linkGeneratedDeck(scan, deckId: deck.id)
            }
            analytics.track("deck_created_from_scan", metadata: ["cards": "\(generatedDrafts.count)"])
            reset()
        } catch {
            self.error = .persistenceFailure(error.localizedDescription)
        }
    }

    func removeDraft(_ draft: FlashcardDraft) {
        generatedDrafts.removeAll { $0.id == draft.id }
    }

    func updateDraft(_ draft: FlashcardDraft) {
        guard let index = generatedDrafts.firstIndex(where: { $0.id == draft.id }) else { return }
        generatedDrafts[index] = draft
    }

    func reset() {
        scannedImage = nil
        extractedText = ""
        generatedDrafts = []
        showDeckNaming = false
        currentScan = nil
        error = nil
    }

    private func markScanFailed() {
        guard let scan = currentScan else { return }
        try? scanSessionRepository.updateStatus(scan, to: .failed)
    }

    private static func thumbnailData(from image: UIImage, maxDimension: CGFloat = 400) -> Data? {
        let largestSide = max(image.size.width, image.size.height)
        guard largestSide > 0 else { return nil }
        let scale = min(1, maxDimension / largestSide)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let thumbnail = UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return thumbnail.jpegData(compressionQuality: 0.6)
    }
}
