import Appearance
import Combine
import Foundation
import SwiftUI

/// Holds the user's settings (saved in UserDefaults) and the colours taken from the current cover art.
@MainActor
final class ThemeModel: ObservableObject {
    private static let defaultsKey = "io.github.endlyrics.settings"
    private static let fallbackAccent = RGB(red: 0.2, green: 0.9, blue: 1.0)

    @Published var settings: AppSettings {
        didSet { save() }
    }
    /// Up to three colours from the current cover art, most prominent first.
    @Published private(set) var palette: [RGB] = []
    /// Cover art of the current track, for the blurred background. Never shown without attribution.
    @Published private(set) var artworkURL: URL?

    private var artworkSubscription: AnyCancellable?

    init() {
        settings = Self.load()
    }

    /// Colours for the window background, top to bottom, following the cover's palette.
    var backgroundColors: [Color] {
        let source = palette.isEmpty ? [Self.fallbackAccent] : palette
        return source.map { Color(rgb: $0).opacity(0.35) } + [.black.opacity(0.55)]
    }

    /// The colour used for the bars and the sung words.
    var accent: Color {
        Color(rgb: accentRGB)
    }

    private var accentRGB: RGB {
        switch settings.colorSource {
        case .album: return DominantColors.accent(from: palette) ?? Self.fallbackAccent
        case .solid: return settings.solidColor
        }
    }

    /// Reloads the palette whenever the cover art URL changes.
    func follow(_ artwork: Published<URL?>.Publisher) {
        artworkSubscription = artwork.removeDuplicates().sink { [weak self] url in
            Task { [weak self] in
                self?.artworkURL = url
                guard let url else {
                    withAnimation(.easeInOut(duration: 0.8)) { self?.palette = [] }
                    return
                }
                let colors = await ArtworkPalette.colors(from: url)
                // Fade between covers rather than snapping to the new colours.
                withAnimation(.easeInOut(duration: 0.8)) { self?.palette = colors }
            }
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }

    private static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let saved = try? JSONDecoder().decode(AppSettings.self, from: data)
        else { return AppSettings() }
        return saved.normalized()
    }
}

extension Color {
    init(rgb: RGB) {
        self.init(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }
}

extension RGB {
    /// Converts a SwiftUI colour from the colour picker. Falls back to white if it has no RGB form.
    init(color: Color) {
        let converted = NSColor(color).usingColorSpace(.sRGB) ?? NSColor.white
        self.init(red: Double(converted.redComponent), green: Double(converted.greenComponent), blue: Double(converted.blueComponent))
    }
}
