import Foundation
import os

/// Local event logging via os.Logger — no third-party SDK, no data leaves the
/// device. Events are inspectable in Console.app for debugging.
struct StudyAnalytics {

    private static let logger = Logger(
        subsystem: "com.renanbambam.studylens",
        category: "analytics"
    )

    func track(_ event: String, metadata: [String: String] = [:]) {
        if metadata.isEmpty {
            Self.logger.info("event=\(event, privacy: .public)")
        } else {
            let pairs = metadata
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: " ")
            Self.logger.info("event=\(event, privacy: .public) \(pairs, privacy: .public)")
        }
    }
}
