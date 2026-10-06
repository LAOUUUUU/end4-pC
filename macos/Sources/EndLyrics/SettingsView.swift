import AppKit
import Appearance
import SwiftUI
import UniformTypeIdentifiers

/// Settings as a page inside the full-screen menu: visualizer, colours, lyrics, the background and the player.
struct SettingsView: View {
    @ObservedObject var theme: ThemeModel
    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            section("Player") {
                Picker("Follow", selection: binding(\.player)) {
                    Text("Spotify").tag(PlayerChoice.spotify)
                    Text("Apple Music").tag(PlayerChoice.appleMusic)
                    Text("Whichever is playing").tag(PlayerChoice.automatic)
                }
                .pickerStyle(.segmented)
            }

            section("Visualizer") {
                Picker("Style", selection: binding(\.style)) {
                    ForEach(VisualizerStyle.allCases, id: \.self) { style in
                        Text(Self.name(style)).tag(style)
                    }
                }
                .pickerStyle(.menu)
                Picker("Bars", selection: binding(\.barCount)) {
                    ForEach(AppSettings.barCountChoices, id: \.self) { count in
                        Text("\(count)").tag(count)
                    }
                }
                .pickerStyle(.segmented)
                Toggle("Show peak caps", isOn: binding(\.showPeakCaps))
            }

            section("Colours") {
                Picker("Take colours from", selection: binding(\.colorSource)) {
                    Text("Album cover").tag(ColorSource.album)
                    Text("A solid colour").tag(ColorSource.solid)
                }
                .pickerStyle(.segmented)
                HStack(spacing: 10) {
                    ForEach(ColorPreset.all, id: \.name) { preset in
                        Button {
                            var settings = theme.settings
                            preset.apply(to: &settings)
                            theme.settings = settings
                        } label: {
                            Circle()
                                .fill(Color(rgb: preset.accent))
                                .frame(width: 22, height: 22)
                                .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .help(preset.name)
                    }
                }
                ColorPicker("Solid colour", selection: solidColor)
                    .disabled(theme.settings.colorSource == .album)
                Text("Album colours come from the cover of the track that is playing.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }

            section("Notifications and startup") {
                Toggle("Notify when the track changes", isOn: binding(\.notifyOnTrackChange))
                Toggle("Open the main menu when EndLyrics starts", isOn: binding(\.openMainMenuAtLaunch))
                Toggle("Open EndLyrics at login", isOn: Binding(
                    get: { launchAtLogin },
                    set: { value in
                        do {
                            try LaunchAtLogin.set(value)
                        } catch {
                            NSSound.beep()
                        }
                        launchAtLogin = LaunchAtLogin.isEnabled
                    }
                ))
            }

            section("Lyrics") {
                slider("Timing offset", value: binding(\.lyricOffset), range: AppSettings.offsetRange, step: 0.25,
                       label: String(format: "%+.2f s", theme.settings.lyricOffset))
                slider("Lyric size", value: binding(\.lyricScale), range: AppSettings.lyricScaleRange, step: 0.05,
                       label: String(format: "%.0f%%", theme.settings.lyricScale * 100))
                Toggle("Click a line to jump there", isOn: binding(\.clickToSeek))
                Toggle("Compact: only the current line", isOn: binding(\.compactMode))
            }

            section("Lyric panel") {
                Toggle("Show the visualizer", isOn: binding(\.panelShowsVisualizer))
                Toggle("Show progress, volume and controls", isOn: binding(\.panelShowsControls))
                Text("Drag the panel's edges to resize it. It remembers its size and place.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }

            section("Background") {
                slider("Cover blur", value: binding(\.backgroundBlur), range: AppSettings.blurRange, step: 2,
                       label: "\(Int(theme.settings.backgroundBlur)) pt")
                HStack {
                    Button("Choose image…", action: chooseBackgroundImage)
                    if theme.settings.backgroundImagePath != nil {
                        Button("Use the cover") { theme.settings.backgroundImagePath = nil }
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
            }
        }
        .foregroundStyle(.white)
        .tint(theme.accent)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
            VStack(alignment: .leading, spacing: 10, content: content)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.1)))
        }
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.system(size: 12))
                Spacer()
                Text(label).font(.system(size: 11, design: .monospaced)).foregroundStyle(.white.opacity(0.6))
            }
            Slider(value: value, in: range, step: step)
        }
    }

    private static func name(_ style: VisualizerStyle) -> String {
        switch style {
        case .bars: return "Bars"
        case .mirror: return "Mirror"
        case .dots: return "Dots"
        case .wave: return "Wave"
        case .radial: return "Radial"
        case .blocks: return "LED blocks"
        }
    }

    /// Opens a file picker for an image and uses it as the background.
    private func chooseBackgroundImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        theme.settings.backgroundImagePath = url.path
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding(
            get: { theme.settings[keyPath: keyPath] },
            set: { theme.settings[keyPath: keyPath] = $0 }
        )
    }

    private var solidColor: Binding<Color> {
        Binding(
            get: { Color(rgb: theme.settings.solidColor) },
            set: { theme.settings.solidColor = RGB(color: $0) }
        )
    }
}
