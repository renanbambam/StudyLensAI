import SwiftUI
import Charts

struct RetentionChart: View {
    let sessions: [StudySession]

    private var completedSessions: [StudySession] {
        sessions.filter { $0.completedAt != nil }.reversed()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Retention — recent sessions")
                .font(.statLabel)
                .foregroundStyle(.secondary)

            if completedSessions.isEmpty {
                Text("Complete a study session to see retention here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart(completedSessions, id: \.id) { session in
                    LineMark(
                        x: .value("Date", session.startedAt),
                        y: .value("Retention", session.retentionRate)
                    )
                    .foregroundStyle(Color.accentPrimary)
                    PointMark(
                        x: .value("Date", session.startedAt),
                        y: .value("Retention", session.retentionRate)
                    )
                    .foregroundStyle(Color.accentPrimary)
                }
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    // Explicit style: implicit `.percent` is ambiguous in
                    // Charts' generic context.
                    AxisMarks(format: FloatingPointFormatStyle<Double>.Percent().precision(.fractionLength(0)))
                }
                .frame(height: 140)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
