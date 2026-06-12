import Foundation
@testable import StudyLens

final class MockScanSessionRepository: ScanSessionRepositoryProtocol {

    var createdScans: [ScanSession] = []
    var statusUpdates: [ScanStatus] = []
    var linkedDeckIds: [UUID] = []
    var errorToThrow: Error?

    func create(rawText: String, imageData: Data?) throws -> ScanSession {
        if let errorToThrow { throw errorToThrow }
        let scan = ScanSession(rawText: rawText, imageData: imageData)
        createdScans.append(scan)
        return scan
    }

    func updateStatus(_ scan: ScanSession, to status: ScanStatus) throws {
        if let errorToThrow { throw errorToThrow }
        scan.status = status
        statusUpdates.append(status)
    }

    func linkGeneratedDeck(_ scan: ScanSession, deckId: UUID) throws {
        if let errorToThrow { throw errorToThrow }
        scan.generatedDeckId = deckId
        scan.status = .complete
        linkedDeckIds.append(deckId)
    }
}
