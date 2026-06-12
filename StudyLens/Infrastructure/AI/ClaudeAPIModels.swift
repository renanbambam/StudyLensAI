import Foundation

// Codable models for the Anthropic Messages API (POST /v1/messages).

struct ClaudeMessage: Encodable {
    let role: String
    let content: String
}

struct ClaudeFlashcardRequest: Encodable {
    let model: String
    let maxTokens: Int
    let system: String
    let messages: [ClaudeMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case messages
    }
}

struct ClaudeMessagesResponse: Decodable {
    struct ContentBlock: Decodable {
        let type: String
        let text: String?
    }

    let content: [ContentBlock]
    let stopReason: String?

    enum CodingKeys: String, CodingKey {
        case content
        case stopReason = "stop_reason"
    }

    /// Concatenated text of all text blocks in the response.
    var fullText: String {
        content.compactMap { $0.type == "text" ? $0.text : nil }.joined()
    }
}

struct ClaudeAPIErrorResponse: Decodable {
    struct APIError: Decodable {
        let type: String
        let message: String
    }

    let error: APIError
}
