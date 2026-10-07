import Foundation

/// One turn of a chat with Claude.
public struct ChatMessage: Equatable, Sendable {
    public enum Role: String, Sendable {
        case user
        case assistant
    }

    public let role: Role
    public let text: String

    public init(role: Role, text: String) {
        self.role = role
        self.text = text
    }
}

/// Builds the request body for POST https://api.anthropic.com/v1/messages.
public enum AnthropicRequestBuilder {
    public static func body(model: String, maxTokens: Int, messages: [ChatMessage]) -> [String: Any] {
        [
            "model": model,
            "max_tokens": maxTokens,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.text] },
        ]
    }
}

public enum AnthropicResponseError: Error, Equatable {
    /// The API's own error message (from an `{"type":"error", ...}` response).
    case apiError(String)
    /// A successful response with no text content block.
    case noTextInResponse
    /// Not valid JSON, or not the shape the Messages API returns.
    case malformed
}

/// Reads the text out of a Messages API response.
public enum AnthropicResponseParser {
    public static func text(from data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AnthropicResponseError.malformed
        }
        if (json["type"] as? String) == "error" {
            let message = (json["error"] as? [String: Any])?["message"] as? String
            throw AnthropicResponseError.apiError(message ?? "unknown error")
        }
        guard let content = json["content"] as? [[String: Any]] else {
            throw AnthropicResponseError.malformed
        }
        let texts = content.compactMap { block -> String? in
            guard (block["type"] as? String) == "text" else { return nil }
            return block["text"] as? String
        }
        guard !texts.isEmpty else { throw AnthropicResponseError.noTextInResponse }
        return texts.joined()
    }
}
