import AppKit
import Appearance
import LyricsCore
import SpotifyKit
import SwiftUI

/// The app's main menu bar: Playback, View, Lyrics, Window and Help.
/// Every item is a thin call into the same models the window uses.
@MainActor
final class MainMenuController: NSObject {
    let model: LyricsModel
    let theme: ThemeModel
    private let togglePanel: () -> Void
    /// Opens the full-screen main menu. Set by the app delegate.
    var openFullscreen: (() -> Void)?

    init(model: LyricsModel, theme: ThemeModel, togglePanel: @escaping () -> Void) {
        self.model = model
        self.theme = theme
        self.togglePanel = togglePanel
    }

    func install() {
        let main = NSMenu()
        main.addItem(submenu(title: "EndLyrics", items: [
            item("About EndLyrics", #selector(about)),
            .separator(),
            item("Settings…", #selector(settings), key: ","),
            .separator(),
            item("Hide EndLyrics", #selector(NSApplication.hide(_:)), key: "h", target: NSApp),
            item("Quit EndLyrics", #selector(NSApplication.terminate(_:)), key: "q", target: NSApp),
        ]))
        main.addItem(submenu(title: "Playback", items: [
            item("Play / Pause", #selector(playPause), key: " "),
            item("Next Track", #selector(next), key: functionKey(NSRightArrowFunctionKey), modifiers: .command),
            item("Previous Track", #selector(previous), key: functionKey(NSLeftArrowFunctionKey), modifiers: .command),
            .separator(),
            item("Volume Up", #selector(volumeUp), key: functionKey(NSUpArrowFunctionKey), modifiers: .command),
            item("Volume Down", #selector(volumeDown), key: functionKey(NSDownArrowFunctionKey), modifiers: .command),
            .separator(),
            item("Toggle Shuffle", #selector(toggleShuffle), key: "s", modifiers: [.command, .shift]),
            item("Toggle Repeat", #selector(toggleRepeat), key: "r", modifiers: [.command, .shift]),
        ]))
        main.addItem(submenu(title: "View", items: [
            item("Full-Screen Main Menu", #selector(fullscreenMenu), key: "m", modifiers: [.command, .shift]),
            item("Show / Hide Lyrics Window", #selector(toggleWindow), key: "l"),
            item("Now Playing Layout", #selector(toggleNowPlaying), key: "e"),
            item("Compact Mode", #selector(toggleCompact), key: "c", modifiers: [.command, .shift]),
            item("Mirror Visualizer", #selector(toggleMirror), key: "m", modifiers: [.command, .option]),
        ]))
        main.addItem(submenu(title: "Lyrics", items: [
            item("Save as .lrc…", #selector(saveLRC), key: "s"),
            item("Save as .txt…", #selector(saveTXT), key: "s", modifiers: [.command, .option]),
            item("Millisecond Timestamps in .lrc", #selector(toggleMilliseconds)),
            .separator(),
            item("Timing Later (+0.25 s)", #selector(offsetLater), key: "]"),
            item("Timing Earlier (−0.25 s)", #selector(offsetEarlier), key: "["),
            item("Reset Timing", #selector(offsetReset), key: "0"),
            .separator(),
            item("Click a Line to Jump", #selector(toggleClickToSeek)),
            item("Copy Current Lyric", #selector(copyCurrentLyric), key: "c", modifiers: [.command, .option]),
        ]))
        main.addItem(submenu(title: "Window", items: [
            item("Minimize", #selector(minimize), key: "m"),
            item("Close Window", #selector(closeWindow), key: "w"),
        ], isWindowMenu: true))
        main.addItem(submenu(title: "Help", items: [
            item("Lyric Sources", #selector(showSources)),
            item("Permissions Help", #selector(showPermissions)),
            .separator(),
            item("Project on GitHub", #selector(openProject)),
        ]))
        NSApp.mainMenu = main
    }

    // MARK: - Items

    private func submenu(title: String, items: [NSMenuItem], isWindowMenu: Bool = false) -> NSMenuItem {
        let parent = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let menu = NSMenu(title: title)
        items.forEach { menu.addItem($0) }
        parent.submenu = menu
        if isWindowMenu { NSApp.windowsMenu = menu }
        return parent
    }

    /// The character AppKit uses as the key equivalent for an arrow or function key.
    private func functionKey(_ code: Int) -> String {
        String(Character(UnicodeScalar(UInt32(code))!))
    }

    private func item(
        _ title: String,
        _ action: Selector,
        key: String = "",
        modifiers: NSEvent.ModifierFlags = [],
        target: AnyObject? = nil
    ) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: key)
        menuItem.keyEquivalentModifierMask = modifiers
        menuItem.target = target ?? self
        return menuItem
    }

    // MARK: - Playback

    @objc func playPause() { model.togglePlayPause() }
    @objc func next() { model.command(.next) }
    @objc func previous() { model.command(.previous) }
    @objc func volumeUp() { model.setVolume(min(100, model.volume + 10)) }
    @objc func volumeDown() { model.setVolume(max(0, model.volume - 10)) }
    @objc func toggleShuffle() { model.toggleShuffle() }
    @objc func toggleRepeat() { model.toggleRepeat() }

    // MARK: - View

    @objc func toggleWindow() { togglePanel() }
    @objc func fullscreenMenu() { openFullscreen?() }
    @objc func toggleNowPlaying() { model.expanded.toggle() }
    @objc func toggleCompact() { theme.settings.compactMode.toggle() }
    @objc func toggleMirror() {
        theme.settings.style = theme.settings.style == .mirror ? .bars : .mirror
    }

    // MARK: - Lyrics

    @objc func saveLRC() { save(extension: "lrc") }
    @objc func saveTXT() { save(extension: "txt") }
    @objc func toggleMilliseconds() { millisecondTimestamps.toggle() }
    @objc func offsetLater() { theme.settings.lyricOffset = min(3, theme.settings.lyricOffset + 0.25) }
    @objc func offsetEarlier() { theme.settings.lyricOffset = max(-3, theme.settings.lyricOffset - 0.25) }
    @objc func offsetReset() { theme.settings.lyricOffset = 0 }
    @objc func toggleClickToSeek() { theme.settings.clickToSeek.toggle() }

    var millisecondTimestamps = false

    private func save(extension ext: String) {
        let lines = model.loadedLines
        guard !lines.isEmpty else {
            alert("No lyrics to save", "Play a track with synced lyrics first.")
            return
        }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = LyricsExport.fileName(
            title: model.trackTitle ?? "Untitled",
            artist: model.trackArtist ?? "Unknown",
            extension: ext
        )
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let text = ext == "lrc"
            ? LyricsExport.lrc(lines, title: model.trackTitle, artist: model.trackArtist, millisecondPrecision: millisecondTimestamps)
            : LyricsExport.txt(lines)
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            alert("Couldn't save the lyrics", error.localizedDescription)
        }
    }

    // MARK: - Window and help

    @objc func about() { NSApp.orderFrontStandardAboutPanel(nil) }
    /// Opens Settings as a page in the full-screen menu. Set by the app delegate.
    var openSettings: (() -> Void)?

    @objc func settings() { openSettings?() }

    @objc func copyCurrentLyric() {
        let line = model.currentLineText
        guard !line.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(line, forType: .string)
    }
    @objc func minimize() { NSApp.keyWindow?.miniaturize(nil) }
    @objc func closeWindow() { NSApp.keyWindow?.performClose(nil) }

    @objc func showSources() {
        alert("Lyric sources", "LRCLIB is tried first (free, public, documented). NetEase Cloud Music is used when LRCLIB has nothing. NetEase's API is unofficial and can change without notice.")
    }

    @objc func showPermissions() {
        alert("Permissions", "Automation: allow EndLyrics to control Spotify (System Settings > Privacy & Security > Automation).\nSystem Audio Recording: needed for the visualizer (Privacy & Security > Screen & System Audio Recording).")
    }

    @objc func openProject() {
        if let url = URL(string: "https://github.com/LAOUUUUU/end4-pC") {
            NSWorkspace.shared.open(url)
        }
    }

    private func alert(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }
}
