import SwiftUI
import SwiftData

@main
struct StudyLensApp: App {

    private let container: ModelContainer
    private let dependencies: AppDependencies
    @State private var router = AppRouter()
    @State private var showAPIKeySetup = false

    init() {
        do {
            let container = try PersistenceController.makeContainer()
            self.container = container
            self.dependencies = AppDependencies(modelContext: container.mainContext)
        } catch {
            // Without a working store the app cannot function; crash early
            // with a clear message rather than limping along.
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies, router: router)
                .onOpenURL { router.handle(url: $0) }
                .onAppear {
                    showAPIKeySetup = dependencies.keychain.readAPIKey() == nil
                    dependencies.refreshWidgetSnapshot()
                }
                .sheet(isPresented: $showAPIKeySetup) {
                    APIKeySetupView(keychain: dependencies.keychain)
                }
        }
        .modelContainer(container)
    }
}

struct RootView: View {
    let dependencies: AppDependencies
    @Bindable var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            DeckListView(dependencies: dependencies, router: router)
                .tabItem { Label("Decks", systemImage: "rectangle.stack") }
                .tag(AppTab.decks)

            ScanView(dependencies: dependencies)
                .tabItem { Label("Scan", systemImage: "doc.viewfinder") }
                .tag(AppTab.scan)

            StatsView(dependencies: dependencies)
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }
                .tag(AppTab.stats)
        }
    }
}
