import SwiftUI

struct DeckCard: View {
    let deck: Deck

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: deck.colorHex))
                .frame(width: 6)

            VStack(alignment: .leading, spacing: 6) {
                Text(deck.title)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    SubjectBadge(subject: deck.subject, colorHex: deck.colorHex)
                    Text("\(deck.totalCards) cards")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if deck.dueCount > 0 {
                Text("\(deck.dueCount) due")
                    .font(.badge)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentDanger.opacity(0.15))
                    .foregroundStyle(Color.accentDanger)
                    .clipShape(Capsule())
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.accentSuccess)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
