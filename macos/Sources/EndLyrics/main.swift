import AppKit
import Appearance
import Combine
import SwiftUI

/// Switches between the standard panel and the Now Playing layout.
struct PanelRoot: View {
    @ObservedObject var model: LyricsModel
    @ObservedObject var visualizer: VisualizerModel
    @ObservedObject var theme: ThemeModel

    var body: some View {
        Group {
            if model.expanded {
                NowPlayingView(model: model, visualizer: visualizer, theme: theme)
            } else {
                LyricsView(model: model, visualizer: visualizer, theme: theme)
            }
        }
        .padding(0)
        .frame(width: model.expanded ? 420 : 360, height: model.expanded ? 560 : 330, alignment: .topLeading)
        .animation(.easeInOut(duration: 0.3), value: model.expanded)
    }
}

/// Owns the floating lyrics panel, the settings window, and the menu-bar item. Runs as an accessory app: no Dock icon.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = LyricsModel()
    private let visualizer = VisualizerModel()
    private let theme = ThemeModel()
    private let widgets = WidgetHub()
    private var panel: NSPanel?
    private var statusItem: NSStatusItem?
    private var toggleItem: NSMenuItem?
    private var offsetSubscription: AnyCancellable?
    private var expandSubscription: AnyCancellable?
    private var mainMenu: MainMenuController?
    private var quickMenu: NSMenu?
    private var fullscreenMenu: FullscreenMenuController?
    private var playerSubscription: AnyCancellable?
    private var sourceSubscription: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Regular, not accessory, so the main menu bar appears when the app is active.
        NSApp.setActivationPolicy(.regular)
        makePanel()
        makeStatusItem()
        visualizer.follow(model.$isPlaying)
        playerSubscription = theme.$settings
            .map(\.player)
            .removeDuplicates()
            .sink { [weak self] choice in self?.model.router.choice = choice }
        sourceSubscription = model.$source
            .removeDuplicates()
            .sink { [weak self] source in self?.visualizer.setBundlePrefix(source.bundlePrefix) }
        theme.follow(model.$artworkURL)
        offsetSubscription = theme.$settings
            .map(\.lyricOffset)
            .removeDuplicates()
            .sink { [weak self] offset in self?.model.offsetSeconds = offset }
        let menu = MainMenuController(
            model: model,
            theme: theme,
            togglePanel: { [weak self] in self?.togglePanel() }
        )
        menu.install()
        mainMenu = menu
        widgets.countdown.onFinish = { [weak self] in
            guard let self, self.widgets.countdown.pausesMusic, self.model.isPlaying else { return }
            self.model.togglePlayPause()
        }
        let fullscreen = FullscreenMenuController(model: model, theme: theme, visualizer: visualizer, hub: widgets, actions: menu)
        fullscreenMenu = fullscreen
        menu.openFullscreen = { fullscreen.show() }
        menu.openSettings = { fullscreen.show(page: .settings) }
        let notifier = TrackNotifier()
        var lastAnnounced: String?
        model.onTrackChanged = { [weak self] id, title, artist in
            guard let self else { return }
            let enabled = self.theme.settings.notifyOnTrackChange
            if TrackAnnouncer.shouldAnnounce(previous: lastAnnounced, next: id, enabled: enabled) {
                notifier.post(title: title, artist: artist)
            }
            lastAnnounced = id
        }
        model.start()
        expandSubscription = model.$expanded.dropFirst().sink { [weak self] expanded in
            self?.resizePanel(expanded: expanded)
        }
    }

    /// Grows or shrinks the panel around its top-left corner, animated, so the drag position stays put.
    private func resizePanel(expanded: Bool) {
        guard let panel else { return }
        let size = NSSize(width: expanded ? 420 : 360, height: expanded ? 560 : 330)
        var frame = panel.frame
        frame.origin.y += frame.height - size.height
        frame.size = size
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            panel.animator().setFrame(frame, display: true)
        }
    }

    private func makePanel() {
        let content = NSHostingView(rootView: PanelRoot(model: model, visualizer: visualizer, theme: theme))
        // The window keeps the size we give it. Content changes must not resize it, or dragging stutters.
        content.sizingOptions = []
        // Top-left of the main screen, just below the menu bar, so it is easy to find.
        let area = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let size = NSSize(width: 360, height: 330)
        let origin = NSPoint(x: area.minX + 24, y: area.maxY - size.height - 24)
        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentView = content
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        content.wantsLayer = true
        content.layer?.cornerRadius = 14
        content.layer?.masksToBounds = true
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.orderFrontRegardless()
        self.panel = panel
    }

    private func makeStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "♪"
        // Left click opens the themed main menu; right click opens the plain menu.
        item.button?.target = self
        item.button?.action = #selector(statusItemClicked(_:))
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        let menu = NSMenu()
        let toggle = NSMenuItem(title: "Hide Lyrics", action: #selector(togglePanel), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)
        let settings = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit EndLyrics", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        quickMenu = menu
        statusItem = item
        toggleItem = toggle
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp, let quickMenu, let statusItem {
            statusItem.popUpMenu(quickMenu)
            return
        }
        fullscreenMenu?.show()
    }

    @objc private func togglePanel() {
        guard let panel else { return }
        if panel.isVisible {
            panel.orderOut(nil)
            toggleItem?.title = "Show Lyrics"
        } else {
            panel.orderFrontRegardless()
            toggleItem?.title = "Hide Lyrics"
        }
    }

    @objc private func showSettings() {
        fullscreenMenu?.show(page: .settings)
    }
}

if CommandLine.arguments.contains("--audio-check") {
    AudioCheck.run()
}
if CommandLine.arguments.contains("--palette-check") {
    PaletteCheck.run()
}

// Top-level code runs on the main thread, which is the main actor.
MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
