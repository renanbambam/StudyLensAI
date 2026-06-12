import SwiftUI

struct DeckDetailView: View {

    @State private var viewModel: DeckDetailViewModel
    @State private var studyMode: StudyMode?
    private let dependencies: AppDependencies

    init(deck: Deck, dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: DeckDetailViewModel(
            deck: deck,
            flashcardRepository: dependencies.flashcardRepository,
            aiService: dependencies.aiService,
            exportService: dependencies.exportService
        ))
    }

    var body: some View {
        List {
            if let deck = viewModel.deck {
                Section {
                    studyButtons(deck: deck)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                }
            }

            Section("Cards (\(viewModel.cards.count))") {
                ForEach(viewModel.cards) { card in
                    FlashcardRow(card: card)
                        .contentShape(Rectangle())
                        .onTapGesture { viewModel.editingCard = card }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteCard(card) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                Task { await viewModel.improveCard(card) }
                            } label: {
                                Label("Improve", systemImage: "sparkles")
                            }
                            .tint(Color.accentPrimary)
                        }
                }
            }
        }
        .navigationTitle(viewModel.deck?.title ?? "Deck")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(DeckExportFormat.allCases, id: \.self) { format in
                        Button {
                            viewModel.export(format: format)
                        } label: {
                            Label("Export as \(format.label)", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(viewModel.cards.isEmpty)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.isAddingCard = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $viewModel.exportedFile) { file in
            ShareSheet(url: file.url)
        }
        .sheet(isPresented: $viewModel.isAddingCard) {
            CardEditorSheet(title: "New Card") { front, back in
                Task { await viewModel.addCard(front: front, back: back) }
            }
        }
        .sheet(item: $viewModel.editingCard) { card in
            CardEditorSheet(title: "Edit Card", front: card.front, back: card.back) { front, back in
                Task { await viewModel.updateCard(card, front: front, back: back) }
            }
        }
        .navigationDestination(item: $studyMode) { mode in
            if let deck = viewModel.deck {
                StudySessionView(deck: deck, mode: mode, dependencies: dependencies)
            }
        }
        .overlay {
            if viewModel.isImproving {
                LoadingOverlay(message: "Improving card…")
            }
        }
        .onAppear { viewModel.refreshCards() }
    }

    private func studyButtons(deck: Deck) -> some View {
        VStack(spacing: 8) {
            PrimaryButton(
                title: deck.dueCount > 0 ? "Study \(deck.dueCount) Due Cards" : "No Cards Due",
                systemImage: "play.fill",
                isDisabled: deck.dueCount == 0
            ) {
                studyMode = .allDue
            }
            HStack(spacing: 8) {
                Button("Full Deck") { studyMode = .fullDeck }
                    .buttonStyle(.bordered)
                    .disabled(deck.totalCards == 0)
                Button("Weak Cards") { studyMode = .weakCards }
                    .buttonStyle(.bordered)
                    .disabled(!deck.cardList.contains(where: \.isWeak))
            }
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

private struct CardEditorSheet: View {
    let title: String
    var front: String = ""
    var back: String = ""
    let onSave: (String, String) -> Void

    @State private var frontText = ""
    @State private var backText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Front (question / term)") {
                    TextField("Front", text: $frontText, axis: .vertical)
                }
                Section("Back (answer / definition)") {
                    TextField("Back", text: $backText, axis: .vertical)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            frontText.trimmingCharacters(in: .whitespacesAndNewlines),
                            backText.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        dismiss()
                    }
                    .disabled(
                        frontText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || backText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            }
            .onAppear {
                frontText = front
                backText = back
            }
        }
    }
}
