import Foundation

/// Model note: the architecture pinned `claude-sonnet-4-20250514`, which
/// Anthropic deprecated (retirement 2026-06-15); `claude-sonnet-4-6` is the
/// documented drop-in replacement.
final class ClaudeAIService: AIGenerationServiceProtocol {

    static let model = "claude-sonnet-4-6"
    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let apiVersion = "2023-06-01"
    private static let maxTokens = 2000

    private let session: URLSession
    private let keyProvider: APIKeyProviding
    private let analytics: StudyAnalytics

    init(
        session: URLSession = .shared,
        keyProvider: APIKeyProviding = KeychainHelper(),
        analytics: StudyAnalytics = StudyAnalytics()
    ) {
        self.session = session
        self.keyProvider = keyProvider
        self.analytics = analytics
    }

    func generateFlashcards(from rawText: String, subject: String) async throws -> [FlashcardDraft] {
        let userContent = "Subject: \(subject)\n\nRaw notes from OCR:\n\(rawText)"
        let text = try await sendMessage(system: Prompts.flashcardGenerationV1, userContent: userContent)
        let drafts: [FlashcardDraft] = try Self.decodeJSON(from: text)
        analytics.track("ai_generation_succeeded", metadata: ["cards": "\(drafts.count)"])
        return drafts
    }

    func improveCard(front: String, back: String) async throws -> FlashcardDraft {
        let userContent = "Front: \(front)\nBack: \(back)"
        let text = try await sendMessage(system: Prompts.cardImprovementV1, userContent: userContent)
        return try Self.decodeJSON(from: text)
    }

    private func sendMessage(system: String, userContent: String) async throws -> String {
        guard let apiKey = keyProvider.readAPIKey(), !apiKey.isEmpty else {
            throw StudyLensError.missingAPIKey
        }

        let body = ClaudeFlashcardRequest(
            model: Self.model,
            maxTokens: Self.maxTokens,
            system: system,
            messages: [ClaudeMessage(role: "user", content: userContent)]
        )

        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Self.apiVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw StudyLensError.networkFailure(statusCode: -1)
        }
        guard (200..<300).contains(http.statusCode) else {
            if let apiError = try? JSONDecoder().decode(ClaudeAPIErrorResponse.self, from: data) {
                analytics.track("ai_request_failed", metadata: ["type": apiError.error.type])
            }
            throw StudyLensError.networkFailure(statusCode: http.statusCode)
        }

        let decoded = try JSONDecoder().decode(ClaudeMessagesResponse.self, from: data)
        let text = decoded.fullText
        guard !text.isEmpty else { throw StudyLensError.invalidAIResponse }
        return text
    }

    /// Decodes a value from model output, tolerating accidental markdown fences.
    static func decodeJSON<T: Decodable>(from text: String) throws -> T {
        let cleaned = stripMarkdownFences(text)
        guard let data = cleaned.data(using: .utf8),
              let value = try? JSONDecoder().decode(T.self, from: data) else {
            throw StudyLensError.invalidAIResponse
        }
        return value
    }

    /// Removes ```json ... ``` fences the model may add despite instructions.
    static func stripMarkdownFences(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasPrefix("```") {
            var lines = result.components(separatedBy: .newlines)
            lines.removeFirst()
            if let last = lines.last, last.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                lines.removeLast()
            }
            result = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return result
    }
}
