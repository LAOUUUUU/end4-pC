import SwiftUI
import Translation

/// An on-device translation of one lyric line, shown under it. macOS 15+; the caller checks availability.
/// All translation runs on the device; Apple's note is that it may log the app and the language pair,
/// never the text itself.
@available(macOS 15.0, *)
struct TranslatedLine: View {
    let text: String
    /// BCP-47 code, or nil for the device's language.
    let targetCode: String?
    @State private var translated: String?

    var body: some View {
        Group {
            if let translated, !translated.isEmpty, translated.caseInsensitiveCompare(text) != .orderedSame {
                Text(translated)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(2)
                    .transition(.opacity)
            }
        }
        .id(text)
        .translationTask(source: nil, target: targetCode.map { Locale.Language(identifier: $0) }) { session in
            guard !text.isEmpty, text != "♪" else {
                translated = nil
                return
            }
            do {
                let response = try await session.translate(text)
                translated = response.targetText
            } catch {
                translated = nil
            }
        }
    }
}
