import AppKit
import SwiftUI

/// A window that closes on Escape, so the full-screen menu can be left with the keyboard.
final class EscapableWindow: NSWindow {
    /// Called when the window closes, however it closes.
    var onClose: (() -> Void)?

    override func cancelOperation(_ sender: Any?) {
        close()
    }

    override func close() {
        super.close()
        onClose?()
    }
}

/// Which page the full-screen menu shows.
enum FullscreenPage: Equatable {
    case home
    case settings
    case ai
}

/// Holds the page, so Settings can be opened straight into the full-screen window.
final class FullscreenNavigator: ObservableObject {
    @Published var page: FullscreenPage = .home
}

/// Opens the full-screen main menu as a real macOS full-screen window in its own Space.
@MainActor
final class FullscreenMenuController {
    private var window: NSWindow?
    let navigator = FullscreenNavigator()
    /// Called with true when the menu opens and false when it closes. The app uses it to hide the lyric panel.
    var onVisibilityChange: ((Bool) -> Void)?
    private let model: LyricsModel
    private let theme: ThemeModel
    private let visualizer: VisualizerModel
    private let hub: WidgetHub
    private let chat: AIChatModel
    private let actions: MainMenuController

    init(model: LyricsModel, theme: ThemeModel, visualizer: VisualizerModel, hub: WidgetHub, chat: AIChatModel, actions: MainMenuController) {
        self.model = model
        self.theme = theme
        self.visualizer = visualizer
        self.hub = hub
        self.chat = chat
        self.actions = actions
    }

    func show(page: FullscreenPage = .home) {
        navigator.page = page
        if let window {
            window.makeKeyAndOrderFront(nil)
            onVisibilityChange?(true)
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
            chat: chat,
            navigator: navigator,
            actions: actions,
            close: { [weak window] in window?.close() }
        ))
        window.onClose = { [weak self] in self?.onVisibilityChange?(false) }
        // The menu is "shown" only while it is the key window and on a visible Space. Otherwise the panel returns.
        for name in [NSWindow.didBecomeKeyNotification, NSWindow.didResignKeyNotification, NSWindow.didChangeOcclusionStateNotification] {
            NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak self, weak window] _ in
                MainActor.assumeIsolated {
                    guard let window else { return }
                    self?.onVisibilityChange?(window.isKeyWindow && window.occlusionState.contains(.visible))
                }
            }
        }
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.toggleFullScreen(nil)
        self.window = window
        onVisibilityChange?(true)
    }
}
