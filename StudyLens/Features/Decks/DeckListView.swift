import SwiftUI

struct DeckListView: View {

    @State private var viewModel: DeckListViewModel
    @State private var showCreateDeck = false
    @State private var studyDeck: Deck?
    @Environment(\.scenePhase) private var scenePhase
    private let dependencies: AppDependencies
    @Bindable private var router: AppRouter

    init(dependencies: AppDependencies, router: AppRouter) {
        self.dependencies = dependencies
        self.router = router
        _viewModel = State(initialValue: DeckListViewModel(
            deckRepository: dependencies.deckRepository
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.filteredDecks.isEmpty {
                    emptyState
                } else {
                    deckList
                }
            }
            .navigationTitle("My Decks")
            .searchable(text: $viewModel.searchQuery, prompt: "Search decks")
            .toolbar { toolbarContent }
            .sheet(isPresented: $showCreateDeck) {
                CreateDeckView { title, subject, colorHex in
                    Task { await viewModel.createDeck(title: title, subject: subject, colorHex: colorHex) }
                }
            }
            .navigationDestination(for: Deck.self) { deck in
                DeckDetailView(deck: deck, dependencies: dependencies)
            }
            .navigationDestination(item: $studyDeck) { deck in
                StudySessionView(deck: deck, mode: .allDue, dependencies: dependencies)
            }
            .task {
                await viewModel.loadDecks()
                consumePendingIntent()
            }
            .refreshable { await viewModel.loadDecks() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { consumePendingIntent() }
            }
            .onChange(of: router.pendingStudyDeckId) { _, deckId in
                guard let deckId else { return }
                router.pendingStudyDeckId = nil
                Task {
                    await viewModel.loadDecks()
                    studyDeck = viewModel.deck(with: deckId)
                }
            }
        }
    }

    /// Routes a "Start studying [deck]" Siri intent to the matching deck.
    private func consumePendingIntent() {
        guard let name = router.consumePendingIntentDeckName() else { return }
        studyDeck = viewModel.decks.first {
            $0.title.localizedCaseInsensitiveCompare(name) == .orderedSame
        } ?? viewModel.decks.first {
            $0.title.localizedCaseInsensitiveContains(name)
        }
    }

    private var deckList: some View {
        List {
            ForEach(viewModel.filteredDecks) { deck in
                NavigationLink(value: deck) {
                    DeckCard(deck: deck)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { await viewModel.deleteDeck(deck) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button {
                        Task { await viewModel.archiveDeck(deck) }
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .tint(.orange)
                }
                .swipeActions(edge: .leading) {
                    if deck.dueCount > 0 {
                        Button {
                            studyDeck = deck
                        } label: {
                            Label("Study", systemImage: "play.fill")
                        }
                        .tint(Color.accentPrimary)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No decks yet",
            systemImage: "rectangle.stack.badge.plus",
            description: Text("Scan your notes or create a deck manually to get started.")
        )
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Picker("Sort", selection: $viewModel.sortOption) {
                    ForEach(DeckSortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                Picker("Subject", selection: $viewModel.selectedSubject) {
                    Text("All Subjects").tag(String?.none)
                    ForEach(viewModel.subjects, id: \.self) { subject in
                        Text(subject).tag(String?.some(subject))
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showCreateDeck = true
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}
