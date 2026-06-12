import SwiftUI

struct SessionProgressBar: View {
    let progress: Double
    let cardsRemaining: Int

    var body: some View {
        VStack(spacing: 4) {
            ProgressView(value: progress)
                .tint(Color.accentPrimary)
            Text("\(cardsRemaining) cards remaining")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
