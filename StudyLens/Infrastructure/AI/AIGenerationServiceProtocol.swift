import Foundation

/// An AI-generated flashcard candidate, editable before being saved as a Flashcard.
struct FlashcardDraft: Identifiable, Equatable {
    let id: UUID
    var front: String
    var back: String
    var hint: String?
    var difficulty: String    // "easy" | "medium" | "hard"

    init(front: String, back: String, hint: String? = nil, difficulty: String = "medium") {
        self.id = UUID()
        self.front = front
        self.back = back
        self.hint = hint
        self.difficulty = difficulty
    }
}

extension FlashcardDraft: Decodable {
    private enum CodingKeys: String, CodingKey {
        case front, back, hint, difficulty
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.front = try container.decode(String.self, forKey: .front)
        self.back = try container.decode(String.self, forKey: .back)
        self.hint = try container.decodeIfPresent(String.self, forKey: .hint)
        self.difficulty = try container.decodeIfPresent(String.self, forKey: .difficulty) ?? "medium"
    }
}

/// AI flashcard generation boundary (implemented by ClaudeAIService).
protocol AIGenerationServiceProtocol {
    func generateFlashcards(from rawText: String, subject: String) async throws -> [FlashcardDraft]
    func improveCard(front: String, back: String) async throws -> FlashcardDraft
}
