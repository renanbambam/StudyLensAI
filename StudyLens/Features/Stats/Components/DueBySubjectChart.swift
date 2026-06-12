import SwiftUI
import Charts

struct DueBySubjectChart: View {
    let data: [String: Int]

    private var entries: [(subject: String, count: Int)] {
        data.filter { $0.value > 0 }
            .sorted { $0.value > $1.value }
            .map { (subject: $0.key, count: $0.value) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cards due by subject")
                .font(.statLabel)
                .foregroundStyle(.secondary)

            if entries.isEmpty {
                Text("Nothing due — nice work!")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                Chart(entries, id: \.subject) { entry in
                    BarMark(
                        x: .value("Due", entry.count),
                        y: .value("Subject", entry.subject)
                    )
                    .foregroundStyle(Color.accentPrimary)
                    .annotation(position: .trailing) {
                        Text("\(entry.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: CGFloat(entries.count) * 36 + 20)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
