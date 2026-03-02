import SwiftUI

enum GlassBackground {
    /// Adaptive blurred gradient background — responds to color scheme.
    static var gradient: some View {
        AdaptiveGradientBackground()
    }

    /// Brand typography gradient — adaptive for light/dark.
    static func titleGradient(for colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.55, green: 0.70, blue: 1.0),
                    Color(red: 0.70, green: 0.78, blue: 1.0),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.26, green: 0.46, blue: 0.86),
                    Color(red: 0.44, green: 0.52, blue: 0.90),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static var thin: some ShapeStyle {
        .ultraThinMaterial
    }
}

// MARK: - Adaptive Gradient Background

private struct AdaptiveGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                if colorScheme == .dark {
                    darkVariant(w: w, h: h)
                } else {
                    lightVariant(w: w, h: h)
                }
            }
            .clipped()
        }
    }

    @ViewBuilder
    private func lightVariant(w: CGFloat, h: CGFloat) -> some View {
        Color(red: 0.94, green: 0.93, blue: 0.99)

        Ellipse()
            .fill(Color(red: 0.48, green: 0.76, blue: 0.95).opacity(0.80))
            .frame(width: w * 0.90, height: h * 0.52)
            .blur(radius: w * 0.20)
            .offset(x: -w * 0.24, y: -h * 0.20)

        Ellipse()
            .fill(Color(red: 0.96, green: 0.66, blue: 0.85).opacity(0.72))
            .frame(width: w * 0.78, height: h * 0.48)
            .blur(radius: w * 0.18)
            .offset(x: w * 0.26, y: -h * 0.16)

        Ellipse()
            .fill(Color(red: 0.60, green: 0.67, blue: 0.93).opacity(0.68))
            .frame(width: w * 0.82, height: h * 0.44)
            .blur(radius: w * 0.20)
            .offset(x: -w * 0.20, y: h * 0.30)

        Ellipse()
            .fill(Color(red: 0.82, green: 0.75, blue: 0.95).opacity(0.55))
            .frame(width: w * 0.65, height: h * 0.40)
            .blur(radius: w * 0.16)
            .offset(x: w * 0.22, y: h * 0.26)
    }

    @ViewBuilder
    private func darkVariant(w: CGFloat, h: CGFloat) -> some View {
        Color(red: 0.06, green: 0.06, blue: 0.10)

        Ellipse()
            .fill(Color(red: 0.12, green: 0.25, blue: 0.42).opacity(0.70))
            .frame(width: w * 0.90, height: h * 0.52)
            .blur(radius: w * 0.22)
            .offset(x: -w * 0.24, y: -h * 0.20)

        Ellipse()
            .fill(Color(red: 0.38, green: 0.16, blue: 0.32).opacity(0.55))
            .frame(width: w * 0.78, height: h * 0.48)
            .blur(radius: w * 0.20)
            .offset(x: w * 0.26, y: -h * 0.16)

        Ellipse()
            .fill(Color(red: 0.16, green: 0.20, blue: 0.40).opacity(0.55))
            .frame(width: w * 0.82, height: h * 0.44)
            .blur(radius: w * 0.22)
            .offset(x: -w * 0.20, y: h * 0.30)

        Ellipse()
            .fill(Color(red: 0.24, green: 0.18, blue: 0.38).opacity(0.45))
            .frame(width: w * 0.65, height: h * 0.40)
            .blur(radius: w * 0.18)
            .offset(x: w * 0.22, y: h * 0.26)
    }
}
