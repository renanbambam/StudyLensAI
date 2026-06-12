import SwiftUI

/// First-launch prompt for the Claude API key, stored in Keychain only
/// (behavior specified in the architecture document's Quick Start).
struct APIKeySetupView: View {

    let keychain: KeychainHelper

    @State private var apiKey = ""
    @State private var saveFailed = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("sk-ant-…", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Claude API Key")
                } footer: {
                    Text(
                        "Required for AI flashcard generation. Stored securely in the Keychain"
                            + " — never leaves this device except to call the Claude API."
                    )
                }

                if saveFailed {
                    Text("Could not save the key. Please try again.")
                        .foregroundStyle(Color.accentDanger)
                }

                PrimaryButton(
                    title: "Save Key",
                    systemImage: "key.fill",
                    isDisabled: apiKey.trimmingCharacters(in: .whitespaces).isEmpty
                ) {
                    save()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            .navigationTitle("Welcome to StudyLens")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Later") { dismiss() }
                }
            }
        }
    }

    private func save() {
        do {
            try keychain.saveAPIKey(apiKey.trimmingCharacters(in: .whitespaces))
            dismiss()
        } catch {
            saveFailed = true
        }
    }
}
