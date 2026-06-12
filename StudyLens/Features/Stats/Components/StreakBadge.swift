import SwiftUI

struct StreakBadge: View {
    let streak: Int

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: streak > 0 ? "flame.fill" : "flame")
                .font(.system(size: 40))
                .foregroundStyle(streak > 0 ? Color.accentWarning : .secondary)
            Text("\(streak)")
                .font(.statValue)
            Text(streak == 1 ? "day streak" : "days streak")
                .font(.statLabel)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
