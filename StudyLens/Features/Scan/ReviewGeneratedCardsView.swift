import SwiftUI

struct ReviewGeneratedCardsView: View {

    @Bindable var viewModel: ScanViewModel
    @State private var deckTitle = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("\(viewModel.generatedDrafts.count) cards generated — edit or remove before saving.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach($viewModel.generatedDrafts) { $draft in
                    CardDraftRow(draft: $draft) {
                        viewModel.removeDraft(draft)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Review Cards")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                TextField("Deck name", text: $deckTitle)
                    .textFieldStyle(.roundedBorder)
                PrimaryButton(
                    title: "Save Deck",
                    systemImage: "tray.and.arrow.down.fill",
                    isDisabled: deckTitle.trimmingCharacters(in: .whitespaces).isEmpty
                        || viewModel.generatedDrafts.isEmpty
                ) {
                    Task {
                        await viewModel.saveDeck(
                            title: deckTitle.trimmingCharacters(in: .whitespaces),
                            subject: viewModel.lastSubject
                        )
                        dismiss()
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
        }
    }
}
