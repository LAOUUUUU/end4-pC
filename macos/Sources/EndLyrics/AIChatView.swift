import AIChatKit
import Appearance
import SwiftUI

/// A chat page for the full-screen menu. Uses the user's own Anthropic API key, stored in Keychain.
struct AIChatView: View {
    @ObservedObject var chat: AIChatModel
    @ObservedObject var theme: ThemeModel
    let openSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ask Claude").font(.system(size: 16, weight: .bold))
                Spacer()
                if !chat.messages.isEmpty {
                    Button("Clear", action: chat.clear)
                        .buttonStyle(RippleButtonStyle(radius: 8))
                        .font(.system(size: 11))
                }
            }

            if chat.hasKey {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(chat.messages.enumerated()), id: \.offset) { index, message in
                                bubble(message).id(index)
                            }
                            if chat.isSending {
                                ProgressView().controlSize(.small)
                            }
                            if let error = chat.errorMessage {
                                Text(error)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.red.opacity(0.9))
                            }
                        }
                        .onChange(of: chat.messages.count) { _, _ in
                            withAnimation { proxy.scrollTo(chat.messages.count - 1, anchor: .bottom) }
                        }
                    }
                    .frame(maxHeight: .infinity)
                }

                HStack(spacing: 8) {
                    TextField("Message Claude…", text: $chat.draft, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.08)))
                        .onSubmit { chat.send(model: theme.settings.aiModel) }
                    Button {
                        chat.send(model: theme.settings.aiModel)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill").font(.system(size: 22))
                    }
                    .buttonStyle(RippleButtonStyle(radius: 14, toggled: true, accent: theme.accent))
                    .disabled(chat.draft.trimmingCharacters(in: .whitespaces).isEmpty || chat.isSending)
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Add your Anthropic API key in Settings to chat with Claude.")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                    Button("Open Settings", action: openSettings)
                        .buttonStyle(RippleButtonStyle(radius: 8, toggled: true, accent: theme.accent))
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }
                Spacer()
            }
        }
    }

    private func bubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == .assistant { Spacer(minLength: 40) }
            Text(message.text)
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(message.role == .user ? theme.accent.opacity(0.35) : .white.opacity(0.1))
                )
            if message.role == .user { Spacer(minLength: 40) }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
}
