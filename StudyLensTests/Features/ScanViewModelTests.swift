import XCTest
import UIKit
@testable import StudyLens

@MainActor
final class ScanViewModelTests: XCTestCase {

    private var ocr: MockOCRService!
    private var ai: MockAIService!
    private var deckRepository: MockDeckRepository!
    private var scanRepository: MockScanSessionRepository!
    private var viewModel: ScanViewModel!

    override func setUp() {
        super.setUp()
        ocr = MockOCRService()
        ai = MockAIService()
        deckRepository = MockDeckRepository()
        scanRepository = MockScanSessionRepository()
        viewModel = ScanViewModel(
            ocrService: ocr,
            aiService: ai,
            deckRepository: deckRepository,
            scanSessionRepository: scanRepository
        )
    }

    func testScanDocumentStoresExtractedText() async {
        ocr.textToReturn = "Photosynthesis converts light to energy"

        await viewModel.scanDocument(image: UIImage())

        XCTAssertEqual(viewModel.extractedText, "Photosynthesis converts light to energy")
        XCTAssertNil(viewModel.error)
    }

    func testScanDocumentSurfacesOCRError() async {
        ocr.errorToThrow = .emptyScan

        await viewModel.scanDocument(image: UIImage())

        XCTAssertEqual(viewModel.error, .emptyScan)
        XCTAssertTrue(viewModel.extractedText.isEmpty)
    }

    func testGenerateFlashcardsPassesTextAndSubjectToAI() async {
        ocr.textToReturn = "raw notes"
        ai.draftsToReturn = [FlashcardDraft(front: "F", back: "B")]
        await viewModel.scanDocument(image: UIImage())

        await viewModel.generateFlashcards(subject: "Biology")

        XCTAssertEqual(ai.lastSubject, "Biology")
        XCTAssertEqual(ai.lastRawText, "raw notes")
        XCTAssertEqual(viewModel.generatedDrafts.count, 1)
    }

    func testGenerateWithoutScanSetsEmptyScanError() async {
        await viewModel.generateFlashcards(subject: "Biology")

        XCTAssertEqual(viewModel.error, .emptyScan)
        XCTAssertEqual(ai.generateCallCount, 0)
    }

    func testGenerateSurfacesAIError() async {
        ocr.textToReturn = "notes"
        ai.errorToThrow = .missingAPIKey
        await viewModel.scanDocument(image: UIImage())

        await viewModel.generateFlashcards(subject: "Math")

        XCTAssertEqual(viewModel.error, .missingAPIKey)
    }

    func testSaveDeckPersistsDraftsAndResetsState() async {
        ocr.textToReturn = "notes"
        ai.draftsToReturn = [
            FlashcardDraft(front: "F1", back: "B1"),
            FlashcardDraft(front: "F2", back: "B2")
        ]
        await viewModel.scanDocument(image: UIImage())
        await viewModel.generateFlashcards(subject: "History")

        await viewModel.saveDeck(title: "WW2 Basics", subject: "History")

        XCTAssertEqual(deckRepository.createDeckCallCount, 1)
        XCTAssertEqual(deckRepository.lastCreatedDrafts.count, 2)
        XCTAssertTrue(viewModel.generatedDrafts.isEmpty)
        XCTAssertTrue(viewModel.extractedText.isEmpty)
    }

    // MARK: - ScanSession traceability

    func testScanCreatesTraceRecordWithRawText() async {
        ocr.textToReturn = "raw notes"

        await viewModel.scanDocument(image: UIImage())

        XCTAssertEqual(scanRepository.createdScans.count, 1)
        XCTAssertEqual(scanRepository.createdScans[0].rawText, "raw notes")
        XCTAssertEqual(scanRepository.createdScans[0].status, .pending)
    }

    func testGenerationFailureMarksScanFailed() async {
        ocr.textToReturn = "notes"
        ai.errorToThrow = .invalidAIResponse
        await viewModel.scanDocument(image: UIImage())

        await viewModel.generateFlashcards(subject: "Math")

        XCTAssertEqual(scanRepository.statusUpdates, [.generating, .failed])
    }

    func testSaveDeckLinksScanToGeneratedDeck() async {
        ocr.textToReturn = "notes"
        ai.draftsToReturn = [FlashcardDraft(front: "F", back: "B")]
        await viewModel.scanDocument(image: UIImage())
        await viewModel.generateFlashcards(subject: "History")

        await viewModel.saveDeck(title: "Deck", subject: "History")

        XCTAssertEqual(scanRepository.linkedDeckIds.count, 1)
        XCTAssertEqual(scanRepository.linkedDeckIds[0], deckRepository.decks[0].id)
        XCTAssertEqual(scanRepository.createdScans[0].status, .complete)
    }

    func testRemoveAndUpdateDraft() async {
        ocr.textToReturn = "notes"
        ai.draftsToReturn = [
            FlashcardDraft(front: "Keep", back: "B"),
            FlashcardDraft(front: "Remove", back: "B")
        ]
        await viewModel.scanDocument(image: UIImage())
        await viewModel.generateFlashcards(subject: "Math")

        let toRemove = viewModel.generatedDrafts[1]
        viewModel.removeDraft(toRemove)
        XCTAssertEqual(viewModel.generatedDrafts.count, 1)

        var edited = viewModel.generatedDrafts[0]
        edited.front = "Edited"
        viewModel.updateDraft(edited)
        XCTAssertEqual(viewModel.generatedDrafts[0].front, "Edited")
    }
}
