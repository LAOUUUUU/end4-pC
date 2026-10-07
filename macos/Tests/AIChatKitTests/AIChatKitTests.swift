import XCTest
@testable import AIChatKit

final class AnthropicRequestBuilderTests: XCTestCase {
    func testBuildsTheDocumentedRequestShape() throws {
        let messages = [ChatMessage(role: .user, text: "hi")]

        let body = AnthropicRequestBuilder.body(model: "claude-sonnet-5-5", maxTokens: 512, messages: messages)
        let data = try JSONSerialization.data(withJSONObject: body)
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(decoded?["model"] as? String, "claude-sonnet-5-5")
        XCTAssertEqual(decoded?["max_tokens"] as? Int, 512)
        let decodedMessages = decoded?["messages"] as? [[String: String]]
        XCTAssertEqual(decodedMessages, [["role": "user", "content": "hi"]])
    }

    func testPreservesMessageOrderAndRoles() throws {
        let messages = [
            ChatMessage(role: .user, text: "a"),
            ChatMessage(role: .assistant, text: "b"),
            ChatMessage(role: .user, text: "c"),
        ]

        let body = AnthropicRequestBuilder.body(model: "m", maxTokens: 1, messages: messages)
        let decodedMessages = body["messages"] as? [[String: String]]

        XCTAssertEqual(decodedMessages?.map { $0["role"] }, ["user", "assistant", "user"])
        XCTAssertEqual(decodedMessages?.map { $0["content"] }, ["a", "b", "c"])
    }
}

final class AnthropicResponseParserTests: XCTestCase {
    func testExtractsTextFromContentBlocks() throws {
        let json = #"{"id":"msg_1","type":"message","role":"assistant","content":[{"type":"text","text":"hello there"}],"model":"claude-sonnet-5-5","stop_reason":"end_turn"}"#

        let text = try AnthropicResponseParser.text(from: Data(json.utf8))

        XCTAssertEqual(text, "hello there")
    }

    func testJoinsMultipleTextBlocks() throws {
        let json = #"{"type":"message","content":[{"type":"text","text":"a"},{"type":"text","text":"b"}]}"#

        XCTAssertEqual(try AnthropicResponseParser.text(from: Data(json.utf8)), "ab")
    }

    func testThrowsTheAPIsOwnErrorMessage() {
        let json = #"{"type":"error","error":{"type":"authentication_error","message":"invalid x-api-key"}}"#

        XCTAssertThrowsError(try AnthropicResponseParser.text(from: Data(json.utf8))) { error in
            XCTAssertEqual(error as? AnthropicResponseError, .apiError("invalid x-api-key"))
        }
    }

    func testThrowsWhenThereIsNoTextBlock() {
        let json = #"{"type":"message","content":[{"type":"tool_use","id":"x"}]}"#

        XCTAssertThrowsError(try AnthropicResponseParser.text(from: Data(json.utf8))) { error in
            XCTAssertEqual(error as? AnthropicResponseError, .noTextInResponse)
        }
    }

    func testThrowsOnInvalidJSON() {
        XCTAssertThrowsError(try AnthropicResponseParser.text(from: Data("not json".utf8))) { error in
            XCTAssertEqual(error as? AnthropicResponseError, .malformed)
        }
    }
}
