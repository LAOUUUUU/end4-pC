import Appearance
import AudioVisualizer
import SwiftUI

/// The visualizer in the style the settings choose: bars, mirror, dots, wave, radial, or LED blocks.
struct VisualizerView: View {
    @ObservedObject var model: VisualizerModel
    @ObservedObject var theme: ThemeModel
    var height: CGFloat = 36

    var body: some View {
        let settings = theme.settings
        let levels = BandResampler.resample(model.bands, to: settings.barCount)
        let peaks = BandResampler.resample(model.peaks, to: settings.barCount)
        Group {
            switch settings.style {
            case .bars:
                BarsCanvas(levels: levels, peaks: peaks, showCaps: settings.showPeakCaps, accent: theme.accent, height: height, mirror: false)
            case .mirror:
                BarsCanvas(levels: levels, peaks: peaks, showCaps: settings.showPeakCaps, accent: theme.accent, height: height, mirror: true)
            case .dots:
                DotsCanvas(levels: levels, accent: theme.accent, rows: 8)
            case .wave:
                WaveCanvas(levels: VisualizerGeometry.smooth(levels), accent: theme.accent)
            case .radial:
                RadialCanvas(levels: levels, accent: theme.accent)
            case .blocks:
                DotsCanvas(levels: levels, accent: theme.accent, rows: 12, square: true)
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }
}

/// Rising bars, optionally mirrored, with falling peak caps.
private struct BarsCanvas: View {
    let levels: [Float]
    let peaks: [Float]
    let showCaps: Bool
    let accent: Color
    let height: CGFloat
    let mirror: Bool

    var body: some View {
        let row = mirror ? BandLayout.mirrored(levels) : levels
        let caps = mirror ? BandLayout.mirrored(peaks) : peaks
        Canvas { context, size in
            guard !row.isEmpty else { return }
            let gap: CGFloat = 3
            let width = max(2, (size.width - gap * CGFloat(row.count - 1)) / CGFloat(row.count))
            for (i, level) in row.enumerated() {
                let x = CGFloat(i) * (width + gap)
                let barHeight = max(3, CGFloat(level) * size.height)
                let bar = CGRect(x: x, y: size.height - barHeight, width: width, height: barHeight)
                context.fill(Path(roundedRect: bar, cornerRadius: width / 2), with: .color(accent.opacity(0.9)))
                if showCaps {
                    let cap = CGFloat(caps[i]) * size.height
                    context.fill(Path(CGRect(x: x, y: size.height - cap - 2, width: width, height: 2)), with: .color(.white))
                }
            }
        }
    }
}

/// Columns of dots (or squares), lit up to each band's level.
private struct DotsCanvas: View {
    let levels: [Float]
    let accent: Color
    let rows: Int
    var square = false

    var body: some View {
        Canvas { context, size in
            guard !levels.isEmpty else { return }
            let gap: CGFloat = 3
            let columnWidth = (size.width - gap * CGFloat(levels.count - 1)) / CGFloat(levels.count)
            let cell = min(columnWidth, (size.height - gap * CGFloat(rows - 1)) / CGFloat(rows))
            for (column, level) in levels.enumerated() {
                let lit = VisualizerGeometry.litDots(level: level, rows: rows)
                let x = CGFloat(column) * (columnWidth + gap) + (columnWidth - cell) / 2
                for row in 0..<rows {
                    let y = size.height - CGFloat(row + 1) * (cell + gap) + gap
                    let rect = CGRect(x: x, y: y, width: cell, height: cell)
                    let path = square ? Path(rect) : Path(ellipseIn: rect)
                    let color: Color = row < lit ? accent : .white.opacity(0.12)
                    context.fill(path, with: .color(color))
                }
            }
        }
    }
}

/// A smooth line through the band levels, with a soft fill underneath.
private struct WaveCanvas: View {
    let levels: [Float]
    let accent: Color

    var body: some View {
        Canvas { context, size in
            guard levels.count > 1 else { return }
            let step = size.width / CGFloat(levels.count - 1)
            let points = levels.enumerated().map { i, level in
                CGPoint(x: CGFloat(i) * step, y: size.height * (1 - CGFloat(level)))
            }
            var line = Path()
            line.move(to: points[0])
            for i in 1..<points.count {
                let mid = CGPoint(x: (points[i - 1].x + points[i].x) / 2, y: (points[i - 1].y + points[i].y) / 2)
                line.addQuadCurve(to: mid, control: points[i - 1])
            }
            line.addLine(to: points[points.count - 1])

            var fill = line
            fill.addLine(to: CGPoint(x: size.width, y: size.height))
            fill.addLine(to: CGPoint(x: 0, y: size.height))
            fill.closeSubpath()
            context.fill(fill, with: .color(accent.opacity(0.18)))
            context.stroke(line, with: .color(accent), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

/// Bars around a circle, each one longer when its band is louder.
private struct RadialCanvas: View {
    let levels: [Float]
    let accent: Color

    var body: some View {
        Canvas { context, size in
            guard !levels.isEmpty else { return }
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let inner = min(size.width, size.height) * 0.22
            let outer = min(size.width, size.height) / 2
            for (i, level) in levels.enumerated() {
                let angle = VisualizerGeometry.radialAngle(index: i, count: levels.count) - .pi / 2
                let length = inner + CGFloat(level) * (outer - inner)
                var line = Path()
                line.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
                line.addLine(to: CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length))
                context.stroke(line, with: .color(accent), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
        }
    }
}
