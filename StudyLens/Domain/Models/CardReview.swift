import Foundation
import SwiftData

/// Individual card rating recorded within a study session.
@Model
final class CardReview {
    var id: UUID = UUID()
    var flashcard: Flashcard?
    var session: StudySession?
    var ratingValue: Int = ReviewRating.good.rawValue
    var reviewedAt: Date = Date.now
    var responseTimeSeconds: Double = 0

    init(flashcard: Flashcard?, session: StudySession?, rating: ReviewRating, responseTimeSeconds: Double) {
        self.id = UUID()
        self.flashcard = flashcard
        self.session = session
        self.ratingValue = rating.rawValue
        self.reviewedAt = .now
        self.responseTimeSeconds = responseTimeSeconds
    }

    /// Typed accessor; raw Int is what SwiftData/CloudKit persists.
    var rating: ReviewRating {
        get { ReviewRating(rawValue: ratingValue) ?? .good }
        set { ratingValue = newValue.rawValue }
    }
}
