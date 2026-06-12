import SwiftUI

struct StudySessionView: View {

    @State private var viewModel: StudySessionViewModel
    private let deck: Deck
    private let mode: StudyMode
    @Environment(\.dismiss) private var dismiss

    init(deck: Deck, mode: StudyMode, dependencies: AppDependencies) {
        self.deck = deck
        self.mode = mode
        _viewModel = State(initialValue: StudySessionViewModel(
            srService: dependencies.spacedRepetitionService,
            sessionRepository: dependencies.sessionRepository,
            flashcardRepository: dependencies.flashcardRepository,
            onSessionEnd: { dependencies.refreshWidgetSnapshot() }
        ))
    }

    var body: some View {
        Group {
            if viewModel.sessionComplete {
                SessionCompleteView(stats: viewModel.sessionStats) {
                    dismiss()
                }
            } else if let card = viewModel.currentCard {
                studyContent(card: card)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startSession(deck: deck, mode: mode)
        }
    }

    private func studyContent(card: Flashcard) -> some View {
        VStack(spacing: 24) {
            SessionProgressBar(
                progress: viewModel.progress,
                cardsRemaining: viewModel.cardsRemaining
            )

            Spacer()

            FlashcardFlipView(
                front: card.front,
                back: card.back,
                hint: card.hint,
                isFlipped: viewModel.isFlipped
            ) {
                viewModel.flipCard()
            }

            Spacer()

            if viewModel.isFlipped {
                RatingButtons { rating in
                    Task { await viewModel.rate(rating) }
                }
            } else {
                Text("Tap the card to reveal the answer")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            }
        }
        .padding()
    }
}
