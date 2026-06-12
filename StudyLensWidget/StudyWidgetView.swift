import SwiftUI
import WidgetKit

/// Home Screen widget: deck with most due cards + streak.
/// Tapping deep-links into a study session via the studylens:// URL scheme.
struct StudyWidgetView: View {
    let entry: StudyWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(entry.subjectColor)
                    .frame(width: 10, height: 10)
                Text(entry.deckName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Spacer()
            }

            Spacer()

            if entry.dueCount > 0 {
                Text("\(entry.dueCount)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.subjectColor)
                Text("cards due today")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.green)
                Text("All caught up!")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Label("\(entry.streak) day streak", systemImage: "flame.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.orange)
        }
        .padding(2)
        .widgetURL(deepLinkURL)
    }

    private var deepLinkURL: URL? {
        guard let deckId = entry.deckId else { return URL(string: "studylens://scan") }
        return URL(string: "studylens://study/\(deckId.uuidString)")
    }
}
