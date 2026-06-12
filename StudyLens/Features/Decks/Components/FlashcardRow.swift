import SwiftUI

struct FlashcardRow: View {
    let card: Flashcard

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(card.front)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
            Text(card.back)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack(spacing: 8) {
                if card.isDue {
                    Label("Due", systemImage: "clock.fill")
                        .font(.badge)
                        .foregroundStyle(Color.accentWarning)
                } else {
                    Label(card.nextReviewDate.formatted(date: .abbreviated, time: .omitted),
                          systemImage: "calendar")
                        .font(.badge)
                        .foregroundStyle(.secondary)
                }
                if card.isWeak {
                    Label("Weak", systemImage: "exclamationmark.triangle.fill")
                        .font(.badge)
                        .foregroundStyle(Color.accentDanger)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
