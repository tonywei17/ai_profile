import SwiftUI

enum GlassBackground {
    static var gradient: some View {
        LinearGradient(colors: [
            Color.blue.opacity(0.3),
            Color.purple.opacity(0.25),
            Color.indigo.opacity(0.3)
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var thin: some ShapeStyle {
        .ultraThinMaterial
    }
}
