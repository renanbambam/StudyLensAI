import Foundation
import SwiftData

/// Production uses the private CloudKit database so SwiftData syncs across
/// devices; previews and tests use an in-memory, local-only container.
enum PersistenceController {

    static let schema = Schema([
        Deck.self,
        Flashcard.self,
        StudySession.self,
        CardReview.self,
        ScanSession.self
    ])

    /// True when running as a unit-test host or under UI tests. Tests use an
    /// isolated in-memory store; this also avoids the CloudKit setup path,
    /// which raises an uncatchable ObjC exception when the iCloud entitlement
    /// is absent (e.g. unsigned CI builds).
    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || CommandLine.arguments.contains("--uitesting")
    }

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        if inMemory || isRunningTests {
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [configuration])
        }

        // Prefer CloudKit sync; fall back to a local-only store when iCloud is
        // unavailable (simulator without an account, CI, missing entitlement)
        // so the app remains usable offline.
        let cloudConfiguration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private("iCloud.com.renanbambam.studylens")
        )
        if let container = try? ModelContainer(for: schema, configurations: [cloudConfiguration]) {
            return container
        }
        let localConfiguration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [localConfiguration])
    }
}
