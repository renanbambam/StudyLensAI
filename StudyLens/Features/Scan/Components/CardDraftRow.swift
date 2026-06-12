import SwiftUI

struct CardDraftRow: View {
    @Binding var draft: FlashcardDraft
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(draft.difficulty.capitalized)
                    .font(.badge)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(difficultyColor.opacity(0.15))
                    .foregroundStyle(difficultyColor)
                    .clipShape(Capsule())
                Spacer()
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                }
            }

            TextField("Front", text: $draft.front, axis: .vertical)
                .font(.subheadline.weight(.semibold))

            Divider()

            TextField("Back", text: $draft.back, axis: .vertical)
                .font(.subheadline)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var difficultyColor: Color {
        switch draft.difficulty {
        case "easy": .accentSuccess
        case "hard": .accentDanger
        default: .accentWarning
        }
    }
}
