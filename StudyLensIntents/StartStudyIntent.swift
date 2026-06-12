import AppIntents

/// "Start studying [deck name]" via Siri / Shortcuts.
///
/// Compiled into the main app target (Apple's guidance for intents that open
/// the app). The deck name is matched case-insensitively when the app routes.
struct StartStudyIntent: AppIntent {

    static let title: LocalizedStringResource = "Start Studying"
    static let description = IntentDescription("Starts a study session for one of your decks.")
    static let openAppWhenRun = true

    @Parameter(title: "Deck name")
    var deckName: String

    @MainActor
    func perform() async throws -> some IntentResult {
        // Hand off to the app via App Group defaults; the app resolves the
        // deck by name on activation and routes to the study session.
        UserDefaults(suiteName: WidgetDataStore.appGroupId)?
            .set(deckName, forKey: "intent.pendingDeckName")
        return .result()
    }
}

struct StudyLensShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // Phrase parameters must be AppEnum/AppEntity-backed; a String
        // parameter in a phrase crashes shortcut registration at launch.
        // Siri asks for the deck name via the parameter dialog instead.
        AppShortcut(
            intent: StartStudyIntent(),
            phrases: [
                "Start studying in \(.applicationName)"
            ],
            shortTitle: "Start Studying",
            systemImageName: "rectangle.stack.fill"
        )
    }
}
