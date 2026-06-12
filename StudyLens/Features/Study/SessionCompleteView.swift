import SwiftUI

struct SessionCompleteView: View {
    let stats: SessionStats?
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentSuccess)

            Text("Session Complete!")
                .font(.screenTitle)

            if let stats {
                HStack(spacing: 24) {
                    statBlock(value: "\(stats.cardsStudied)", label: "Studied")
                    statBlock(
                        value: stats.retentionRate.formatted(.percent.precision(.fractionLength(0))),
                        label: "Retention"
                    )
                    statBlock(
                        value: Duration.seconds(stats.durationSeconds)
                            .formatted(.time(pattern: .minuteSecond)),
                        label: "Time"
                    )
                }
            } else {
                Text("Nothing to study right now — all caught up!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            PrimaryButton(title: "Done", systemImage: "checkmark") {
                onDone()
            }
            .padding(.horizontal, 32)
        }
        .padding()
        .navigationBarBackButtonHidden()
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.statValue)
                .foregroundStyle(Color.accentPrimary)
            Text(label)
                .font(.statLabel)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 72)
    }
}
