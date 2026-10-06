import Appearance
import SwiftUI

/// The settings page: visualizer look, colour source, and lyric behaviour.
struct SettingsView: View {
    @ObservedObject var theme: ThemeModel

    var body: some View {
        Form {
            Section("Visualizer") {
                Picker("Style", selection: binding(\.style)) {
                    Text("Bars").tag(VisualizerStyle.bars)
                    Text("Mirror").tag(VisualizerStyle.mirror)
                }
                .pickerStyle(.segmented)
                Picker("Bars", selection: binding(\.barCount)) {
                    ForEach(AppSettings.barCountChoices, id: \.self) { count in
                        Text("\(count)").tag(count)
                    }
                }
                .pickerStyle(.segmented)
                Toggle("Show peak caps", isOn: binding(\.showPeakCaps))
            }

            Section("Colours") {
                Picker("Take colours from", selection: binding(\.colorSource)) {
                    Text("Album cover").tag(ColorSource.album)
                    Text("A solid colour").tag(ColorSource.solid)
                }
                ColorPicker("Solid colour", selection: solidColor)
                    .disabled(theme.settings.colorSource == .album)
                Text("Album colours come from the cover of the track that is playing.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Lyrics") {
                VStack(alignment: .leading) {
                    Text("Timing offset: \(theme.settings.lyricOffset, specifier: "%+.2f") s")
                    Slider(value: binding(\.lyricOffset), in: AppSettings.offsetRange, step: 0.25)
                }
                Toggle("Click a line to jump there", isOn: binding(\.clickToSeek))
                Toggle("Compact: only the current line", isOn: binding(\.compactMode))
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 520)
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
