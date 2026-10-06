import AppKit
import SwiftUI

/// Owns the floating lyrics panel and the menu-bar item. Runs as an accessory app: no Dock icon.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = LyricsModel()
    private var panel: NSPanel?
    private var statusItem: NSStatusItem?
    private var toggleItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        makePanel()
        makeStatusItem()
        model.start()
    }

    private func makePanel() {
        let content = NSHostingView(rootView: LyricsView(model: model))
        let panel = NSPanel(
            contentRect: NSRect(x: 80, y: 120, width: 360, height: 240),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentView = content
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.orderFrontRegardless()
        self.panel = panel
    }

    private func makeStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "♪"

        let menu = NSMenu()
        let toggle = NSMenuItem(title: "Hide Lyrics", action: #selector(togglePanel), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit EndLyrics", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        item.menu = menu
        statusItem = item
        toggleItem = toggle
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
}

// Top-level code runs on the main thread, which is the main actor.
MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
