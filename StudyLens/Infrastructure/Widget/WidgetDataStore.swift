import Foundation

/// Snapshot the main app writes for the widget extension to read.
/// Shared with the StudyLensWidget target via App Group UserDefaults.
struct WidgetSnapshot: Codable, Equatable {
    let deckId: UUID?
    let deckName: String
    let dueCount: Int
    let subjectColorHex: String
    let streak: Int
    let updatedAt: Date

    init(
        deckId: UUID?,
        deckName: String,
        dueCount: Int,
        subjectColorHex: String,
        streak: Int,
        updatedAt: Date = .now
    ) {
        self.deckId = deckId
        self.deckName = deckName
        self.dueCount = dueCount
        self.subjectColorHex = subjectColorHex
        self.streak = streak
        self.updatedAt = updatedAt
    }

    static let empty = WidgetSnapshot(
        deckId: nil,
        deckName: "No decks yet",
        dueCount: 0,
        subjectColorHex: "#4F46E5",
        streak: 0,
        updatedAt: .distantPast
    )
}

enum WidgetDataStore {

    static let appGroupId = "group.com.renanbambam.studylens"
    private static let snapshotKey = "widget.snapshot"

    static func write(_ snapshot: WidgetSnapshot) {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
    }

    static func read() -> WidgetSnapshot {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }
}
