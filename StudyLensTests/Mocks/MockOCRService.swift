import UIKit
@testable import StudyLens

final class MockOCRService: OCRServiceProtocol {

    var textToReturn = "Mock extracted text"
    var errorToThrow: StudyLensError?

    func extractText(from image: UIImage) async throws -> String {
        if let errorToThrow { throw errorToThrow }
        return textToReturn
    }

    func extractText(from imageURL: URL) async throws -> String {
        if let errorToThrow { throw errorToThrow }
        return textToReturn
    }
}
