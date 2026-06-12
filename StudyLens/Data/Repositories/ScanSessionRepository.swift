import Foundation
import SwiftData

final class ScanSessionRepository: ScanSessionRepositoryProtocol {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func create(rawText: String, imageData: Data?) throws -> ScanSession {
        let scan = ScanSession(rawText: rawText, imageData: imageData)
        context.insert(scan)
        try context.save()
        return scan
    }

    func updateStatus(_ scan: ScanSession, to status: ScanStatus) throws {
        scan.status = status
        try context.save()
    }

    func linkGeneratedDeck(_ scan: ScanSession, deckId: UUID) throws {
        scan.generatedDeckId = deckId
        scan.status = .complete
        try context.save()
    }
}
