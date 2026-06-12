import SwiftUI

struct StatsView: View {

    @State private var viewModel: StatsViewModel

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: StatsViewModel(
            progressService: dependencies.progressService,
            sessionRepository: dependencies.sessionRepository,
            deckRepository: dependencies.deckRepository
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        StreakBadge(streak: viewModel.streak)
                        totalsCard
                    }
                    RetentionChart(sessions: viewModel.recentSessions)
                    HeatmapView(data: viewModel.heatmapData)
                    DueBySubjectChart(data: viewModel.dueCountBySubject)
                }
                .padding()
            }
            .navigationTitle("Progress")
            .task { await viewModel.loadStats() }
            .refreshable { await viewModel.loadStats() }
        }
    }

    private var totalsCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "rectangle.stack.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.accentPrimary)
            Text("\(viewModel.totalCardsStudied)")
                .font(.statValue)
            Text("cards studied")
                .font(.statLabel)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
