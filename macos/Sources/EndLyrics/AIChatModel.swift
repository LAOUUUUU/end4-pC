import AIChatKit
import Foundation

/// A chat with Claude, using the user's own Anthropic API key. Nothing is sent unless a key is set.
@MainActor
final class AIChatModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isSending = false
    @Published private(set) var errorMessage: String?
    @Published var draft = ""

    var hasKey: Bool { KeychainStore.read()?.isEmpty == false }

    func send(model: String) {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let key = KeychainStore.read(), !key.isEmpty else { return }

        let userMessage = ChatMessage(role: .user, text: text)
        messages.append(userMessage)
        draft = ""
        errorMessage = nil
        isSending = true

        let history = messages
        Task {
            do {
                let reply = try await Self.request(apiKey: key, model: model, messages: history)
                messages.append(ChatMessage(role: .assistant, text: reply))
            } catch AnthropicResponseError.apiError(let message) {
                errorMessage = message
            } catch {
                errorMessage = "Couldn't reach Claude: \(error.localizedDescription)"
            }
            isSending = false
        }
    }

    func clear() {
        messages = []
        errorMessage = nil
    }

    private static func request(apiKey: String, model: String, messages: [ChatMessage]) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = AnthropicRequestBuilder.body(model: model, maxTokens: 1024, messages: messages)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, _) = try await URLSession.shared.data(for: request)
        return try AnthropicResponseParser.text(from: data)
    }
}
