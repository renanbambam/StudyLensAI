import SwiftUI

/// Hex palette offered when creating a deck. Plain strings (no SwiftUI import)
/// so ViewModels can use it without depending on the UI layer.
enum DeckPalette {
    static let hexValues: [String] = [
        "#4F46E5", "#16A34A", "#D97706", "#DC2626",
        "#0891B2", "#9333EA", "#DB2777", "#65A30D"
    ]

    static var random: String { hexValues.randomElement() ?? "#4F46E5" }
}

extension Color {

    static let accentPrimary = Color(hex: "#4F46E5")
    static let accentSuccess = Color(hex: "#16A34A")
    static let accentWarning = Color(hex: "#D97706")
    static let accentDanger = Color(hex: "#DC2626")

    /// Creates a Color from a "#RRGGBB" hex string; falls back to indigo.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        guard cleaned.count == 6, Scanner(string: cleaned).scanHexInt64(&value) else {
            self = .indigo
            return
        }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
