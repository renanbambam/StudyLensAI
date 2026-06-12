import XCTest
@testable import StudyLens

final class ClaudeAIServiceTests: XCTestCase {

    private var service: ClaudeAIService!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        service = ClaudeAIService(
            session: URLSession(configuration: config),
            keyProvider: FakeKeyProvider(key: "test-key")
        )
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        service = nil
        super.tearDown()
    }

    // MARK: - Success

    func testGenerateFlashcardsParsesValidResponse() async throws {
        let cardsJSON = #"[{"front":"What is a cell?","back":"Basic unit of life","hint":null,"difficulty":"easy"}]"#
        MockURLProtocol.respond(status: 200, body: Self.apiBody(text: cardsJSON))

        let drafts = try await service.generateFlashcards(from: "notes", subject: "Biology")

        XCTAssertEqual(drafts.count, 1)
        XCTAssertEqual(drafts[0].front, "What is a cell?")
        XCTAssertNil(drafts[0].hint)
        XCTAssertEqual(drafts[0].difficulty, "easy")
    }

    func testGenerateFlashcardsStripsMarkdownFences() async throws {
        let fenced = "```json\n[{\"front\":\"F\",\"back\":\"B\",\"hint\":\"H\",\"difficulty\":\"hard\"}]\n```"
        MockURLProtocol.respond(status: 200, body: Self.apiBody(text: fenced))

        let drafts = try await service.generateFlashcards(from: "notes", subject: "Math")

        XCTAssertEqual(drafts.count, 1)
        XCTAssertEqual(drafts[0].hint, "H")
    }

    func testImproveCardParsesSingleObject() async throws {
        let cardJSON = #"{"front":"Better front","back":"Better back","hint":null,"difficulty":"medium"}"#
        MockURLProtocol.respond(status: 200, body: Self.apiBody(text: cardJSON))

        let draft = try await service.improveCard(front: "old", back: "old")

        XCTAssertEqual(draft.front, "Better front")
    }

    func testRequestCarriesRequiredHeaders() async throws {
        let cardsJSON = "[]"
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return (200, Self.apiBody(text: cardsJSON))
        }

        _ = try? await service.generateFlashcards(from: "notes", subject: "Biology")

        let request = try XCTUnwrap(capturedRequest)
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-api-key"), "test-key")
        XCTAssertEqual(request.value(forHTTPHeaderField: "anthropic-version"), "2023-06-01")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.httpMethod, "POST")
    }

    // MARK: - Failures

    func testMissingAPIKeyThrows() async {
        let noKeyService = ClaudeAIService(keyProvider: FakeKeyProvider(key: nil))
        await assertThrows(StudyLensError.missingAPIKey) {
            _ = try await noKeyService.generateFlashcards(from: "x", subject: "y")
        }
    }

    func testHTTPErrorThrowsNetworkFailure() async {
        MockURLProtocol.respond(status: 429, body: #"{"error":{"type":"rate_limit_error","message":"slow down"}}"#)
        await assertThrows(StudyLensError.networkFailure(statusCode: 429)) {
            _ = try await self.service.generateFlashcards(from: "x", subject: "y")
        }
    }

    func testMalformedJSONThrowsInvalidAIResponse() async {
        MockURLProtocol.respond(status: 200, body: Self.apiBody(text: "not json at all"))
        await assertThrows(StudyLensError.invalidAIResponse) {
            _ = try await self.service.generateFlashcards(from: "x", subject: "y")
        }
    }

    // MARK: - Fence stripping (pure)

    func testStripMarkdownFencesLeavesPlainTextAlone() {
        XCTAssertEqual(ClaudeAIService.stripMarkdownFences("[1,2]"), "[1,2]")
    }

    func testStripMarkdownFencesRemovesFencedBlock() {
        XCTAssertEqual(ClaudeAIService.stripMarkdownFences("```json\n[1]\n```"), "[1]")
        XCTAssertEqual(ClaudeAIService.stripMarkdownFences("```\n{}\n```"), "{}")
    }

    // MARK: - Helpers

    /// Wraps text in the Anthropic Messages API response envelope.
    private static func apiBody(text: String) -> String {
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        return #"{"content":[{"type":"text","text":""# + escaped + #""}],"stop_reason":"end_turn"}"#
    }

    private func assertThrows(
        _ expected: StudyLensError,
        _ operation: () async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await operation()
            XCTFail("Expected \(expected) to be thrown", file: file, line: line)
        } catch let error as StudyLensError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Unexpected error type: \(error)", file: file, line: line)
        }
    }
}

// MARK: - Test doubles

private struct FakeKeyProvider: APIKeyProviding {
    let key: String?
    func readAPIKey() -> String? { key }
}

/// Intercepts URLSession traffic so no real network calls happen in tests.
final class MockURLProtocol: URLProtocol {

    static var requestHandler: ((URLRequest) -> (Int, String))?

    static func respond(status: Int, body: String) {
        requestHandler = { _ in (status, body) }
    }

    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        let (status, body) = handler(request)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
