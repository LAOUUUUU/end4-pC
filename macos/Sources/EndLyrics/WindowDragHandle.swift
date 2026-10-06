import AppKit
import SwiftUI

/// Lets the user drag the panel from any empty part of it. SwiftUI's own gestures keep their areas,
/// and this fills the rest, so the window moves wherever it is not a control.
struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> DragView {
        DragView()
    }

    func updateNSView(_ nsView: DragView, context: Context) {}

    final class DragView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }

        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}
