import SwiftUI

struct HeatmapView: View {
    let data: [Date: Int]

    private let weeks = 12
    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity — last \(weeks) weeks")
                .font(.statLabel)
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 3) {
                ForEach(0..<weeks, id: \.self) { week in
                    VStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { day in
                            cell(for: date(week: week, day: day))
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    /// Date for a cell, with week 0 = oldest; the grid ends today.
    private func date(week: Int, day: Int) -> Date {
        let today = calendar.startOfDay(for: .now)
        let daysBack = (weeks - 1 - week) * 7 + (6 - day)
        return calendar.date(byAdding: .day, value: -daysBack, to: today) ?? today
    }

    @ViewBuilder
    private func cell(for date: Date) -> some View {
        let count = data[calendar.startOfDay(for: date)] ?? 0
        RoundedRectangle(cornerRadius: 2)
            .fill(color(for: count))
            .frame(width: 14, height: 14)
    }

    private func color(for count: Int) -> Color {
        switch count {
        case 0: Color(.tertiarySystemFill)
        case 1: Color.accentSuccess.opacity(0.35)
        case 2: Color.accentSuccess.opacity(0.65)
        default: Color.accentSuccess
        }
    }
}
