import AppKit
import SwiftUI

/// A window that closes on Escape, so the full-screen menu can be left with the keyboard.
final class EscapableWindow: NSWindow {
    override func cancelOperation(_ sender: Any?) {
        close()
    }
}

/// Opens the full-screen main menu as a real macOS full-screen window in its own Space.
@MainActor
final class FullscreenMenuController {
    private var window: NSWindow?
    private let model: LyricsModel
    private let theme: ThemeModel
    private let visualizer: VisualizerModel
    private let hub: WidgetHub
    private let actions: MainMenuController

    init(model: LyricsModel, theme: ThemeModel, visualizer: VisualizerModel, hub: WidgetHub, actions: MainMenuController) {
        self.model = model
        self.theme = theme
        self.visualizer = visualizer
        self.hub = hub
        self.actions = actions
    }

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let window = EscapableWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = .black
        window.collectionBehavior = [.fullScreenPrimary]
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: FullscreenMenuView(
            model: model,
            theme: theme,
            visualizer: visualizer,
            hub: hub,
            actions: actions,
            close: { [weak window] in window?.close() }
        ))
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.toggleFullScreen(nil)
        self.window = window
    }
}
