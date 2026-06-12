import SwiftUI
import UIKit

struct RatingButtons: View {
    let onRate: (ReviewRating) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ReviewRating.allCases, id: \.self) { rating in
                Button {
                    playHaptic(for: rating)
                    onRate(rating)
                } label: {
                    Text(rating.label)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .background(color(for: rating).opacity(0.15))
                .foregroundStyle(color(for: rating))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    /// Distinct haptic per outcome: error for a blackout, warning for hard,
    /// success for good/easy.
    private func playHaptic(for rating: ReviewRating) {
        let generator = UINotificationFeedbackGenerator()
        switch rating {
        case .again: generator.notificationOccurred(.error)
        case .hard: generator.notificationOccurred(.warning)
        case .good, .easy: generator.notificationOccurred(.success)
        }
    }

    private func color(for rating: ReviewRating) -> Color {
        switch rating {
        case .again: .accentDanger
        case .hard: .accentWarning
        case .good: .accentPrimary
        case .easy: .accentSuccess
        }
    }
}
