import SwiftUI

struct CreateDeckView: View {

    let onCreate: (String, String, String) -> Void

    @State private var title = ""
    @State private var subject = ""
    @State private var colorHex = DeckPalette.hexValues[0]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Deck") {
                    TextField("Title", text: $title)
                    TextField("Subject (e.g. Biology)", text: $subject)
                }

                Section("Color") {
                    HStack(spacing: 12) {
                        ForEach(DeckPalette.hexValues, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 28, height: 28)
                                .overlay {
                                    if hex == colorHex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { colorHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(
                            title.trimmingCharacters(in: .whitespaces),
                            subject.trimmingCharacters(in: .whitespaces),
                            colorHex
                        )
                        dismiss()
                    }
                    .disabled(
                        title.trimmingCharacters(in: .whitespaces).isEmpty
                            || subject.trimmingCharacters(in: .whitespaces).isEmpty
                    )
                }
            }
        }
    }
}
