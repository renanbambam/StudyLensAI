import SwiftUI

struct FlashcardFlipView: View {
    let front: String
    let back: String
    let hint: String?
    let isFlipped: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            face(text: front, label: "Question", hint: hint)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            face(text: back, label: "Answer", hint: nil)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .animation(.spring(duration: 0.45), value: isFlipped)
        .onTapGesture(perform: onTap)
        .accessibilityLabel(isFlipped ? "Answer: \(back)" : "Question: \(front). Tap to flip.")
    }

    private func face(text: String, label: String, hint: String?) -> some View {
        VStack(spacing: 16) {
            Text(label.uppercased())
                .font(.statLabel)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.cardFront)
                .multilineTextAlignment(.center)
            if let hint, !hint.isEmpty {
                Label(hint, systemImage: "lightbulb")
                    .font(.footnote)
                    .foregroundStyle(Color.accentWarning)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 280)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}
