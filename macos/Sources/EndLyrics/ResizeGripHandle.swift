import AppKit
import SwiftUI

/// A visible grip you can drag to resize the panel, since its borderless edges give no hint
/// that they are draggable. Drags the window's bottom-right corner; the top-left stays put.
struct ResizeGripHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> GripView {
        GripView()
    }

    func updateNSView(_ nsView: GripView, context: Context) {}

    final class GripView: NSView {
        private var startFrame: NSRect = .zero
        private var startPoint: NSPoint = .zero

        override func mouseDown(with event: NSEvent) {
            guard let window else { return }
            startFrame = window.frame
            startPoint = NSEvent.mouseLocation
        }

        override func mouseDragged(with event: NSEvent) {
            guard let window else { return }
            let current = NSEvent.mouseLocation
            let dx = current.x - startPoint.x
            let dy = current.y - startPoint.y
            let width = min(max(startFrame.width + dx, window.minSize.width), window.maxSize.width)
            let height = min(max(startFrame.height - dy, window.minSize.height), window.maxSize.height)
            var frame = startFrame
            frame.size = NSSize(width: width, height: height)
            frame.origin.y = startFrame.origin.y + (startFrame.height - height)
            window.setFrame(frame, display: true)
        }
    }
}

/// The grip's icon: three short diagonal strokes, the classic resize-corner mark.
struct ResizeGripIcon: View {
    var body: some View {
        Canvas { context, size in
            let color = Color.white.opacity(0.5)
            for i in 0..<3 {
                let offset = CGFloat(i) * 4.5 + 3
                var path = Path()
                path.move(to: CGPoint(x: size.width - 1, y: size.height - offset))
                path.addLine(to: CGPoint(x: size.width - offset, y: size.height - 1))
                context.stroke(path, with: .color(color), lineWidth: 1.2)
            }
        }
        .frame(width: 14, height: 14)
    }
}
