import Foundation

/// Persistence for scan traceability records (ScanSession lifecycle:
/// pending → generating → complete | failed, linked to the generated deck).
protocol ScanSessionRepositoryProtocol {
    func create(rawText: String, imageData: Data?) throws -> ScanSession
    func updateStatus(_ scan: ScanSession, to status: ScanStatus) throws
    /// Marks the scan complete and records which deck it produced.
    func linkGeneratedDeck(_ scan: ScanSession, deckId: UUID) throws
}
