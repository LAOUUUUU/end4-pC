import SwiftUI

/// Material-style button, ported from the shell's `RippleButton`: a ripple flash on press, a tint on hover,
/// corners that tighten while pressed, and an accent fill when toggled on.
struct RippleButtonStyle: ButtonStyle {
    var radius: CGFloat = 14
    var toggled = false
    var accent: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        RippleBody(configuration: configuration, radius: radius, toggled: toggled, accent: accent)
    }

    private struct RippleBody: View {
        let configuration: ButtonStyle.Configuration
        let radius: CGFloat
        let toggled: Bool
        let accent: Color
        @State private var hovered = false

        var body: some View {
            let pressed = configuration.isPressed
            let corner = pressed ? radius * 0.6 : radius
            configuration.label
                .background(
                    RoundedRectangle(cornerRadius: corner)
                        .fill(toggled ? accent.opacity(0.35) : .clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .fill(.white.opacity(hovered ? 0.08 : 0))
                )
                .overlay(
                    // The ripple: a flash that spreads from the press and fades on release.
                    Circle()
                        .fill(.white.opacity(pressed ? 0.14 : 0))
                        .scaleEffect(pressed ? 3 : 0.01)
                        .clipShape(RoundedRectangle(cornerRadius: corner))
                )
                .clipShape(RoundedRectangle(cornerRadius: corner))
                .scaleEffect(pressed ? 0.97 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pressed)
                .animation(.easeOut(duration: 0.6), value: pressed)
                .animation(.easeOut(duration: 0.2), value: hovered)
                .onHover { hovered = $0 }
        }
    }
}
