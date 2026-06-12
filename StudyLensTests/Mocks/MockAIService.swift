import Foundation
@testable import StudyLens

final class MockAIService: AIGenerationServiceProtocol {

    var draftsToReturn: [FlashcardDraft] = []
    var improvedDraft = FlashcardDraft(front: "Improved front", back: "Improved back")
    var errorToThrow: StudyLensError?
    var generateCallCount = 0
    var lastRawText: String?
    var lastSubject: String?

    func generateFlashcards(from rawText: String, subject: String) async throws -> [FlashcardDraft] {
        generateCallCount += 1
        lastRawText = rawText
        lastSubject = subject
        if let errorToThrow { throw errorToThrow }
        return draftsToReturn
    }

    func improveCard(front: String, back: String) async throws -> FlashcardDraft {
        if let errorToThrow { throw errorToThrow }
        return improvedDraft
    }
}
