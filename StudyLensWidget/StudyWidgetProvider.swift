import WidgetKit
import SwiftUI

struct StudyWidgetEntry: TimelineEntry {
    let date: Date
    let deckId: UUID?
    let deckName: String
    let dueCount: Int
    let subjectColor: Color
    let streak: Int

    static let placeholder = StudyWidgetEntry(
        date: .now,
        deckId: nil,
        deckName: "Biology — Cells",
        dueCount: 12,
        subjectColor: Color(hex: "#16A34A"),
        streak: 5
    )
}

/// Reads the snapshot the main app wrote to App Group UserDefaults.
/// Timeline refreshes hourly; the app also forces a reload after each session.
struct StudyWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> StudyWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (StudyWidgetEntry) -> Void) {
        completion(context.isPreview ? .placeholder : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StudyWidgetEntry>) -> Void) {
        let refresh = Calendar.current.date(byAdding: .minute, value: 60, to: .now) ?? .now
        completion(Timeline(entries: [currentEntry()], policy: .after(refresh)))
    }

    private func currentEntry() -> StudyWidgetEntry {
        let snapshot = WidgetDataStore.read()
        return StudyWidgetEntry(
            date: .now,
            deckId: snapshot.deckId,
            deckName: snapshot.deckName,
            dueCount: snapshot.dueCount,
            subjectColor: Color(hex: snapshot.subjectColorHex),
            streak: snapshot.streak
        )
    }
}

/// Minimal hex-color parsing for the widget target (the app's DesignSystem is
/// not compiled into this extension).
extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        guard cleaned.count == 6, Scanner(string: cleaned).scanHexInt64(&value) else {
            self = .indigo
            return
        }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
