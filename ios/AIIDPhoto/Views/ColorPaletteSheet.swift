import SwiftUI

struct ColorPaletteSheet: View {
    var initialColor: Color
    var onConfirm: (Color) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var currentColor: Color

    // 30 swatches: 6 columns × 5 rows
    private let palette: [Color] = [
        // Row 1 — Neutrals
        Color(white: 1.00), Color(white: 0.96), Color(white: 0.91),
        Color(white: 0.81), Color(white: 0.63), Color(white: 0.38),
        // Row 2 — Blues (证件照蓝)
        Color(red: 0.83, green: 0.91, blue: 0.97),
        Color(red: 0.66, green: 0.83, blue: 0.94),
        Color(red: 0.44, green: 0.71, blue: 0.91),
        Color(red: 0.26, green: 0.56, blue: 0.86),
        Color(red: 0.14, green: 0.38, blue: 0.78),
        Color(red: 0.10, green: 0.25, blue: 0.56),
        // Row 3 — Reds (婚姻/党员)
        Color(red: 1.00, green: 0.83, blue: 0.83),
        Color(red: 1.00, green: 0.60, blue: 0.60),
        Color(red: 0.91, green: 0.19, blue: 0.19),
        Color(red: 0.75, green: 0.00, blue: 0.00),
        Color(red: 0.55, green: 0.00, blue: 0.00),
        Color(red: 0.83, green: 0.19, blue: 0.42),
        // Row 4 — Greens & Warm
        Color(red: 0.85, green: 0.96, blue: 0.83),
        Color(red: 0.49, green: 0.77, blue: 0.43),
        Color(red: 0.16, green: 0.50, blue: 0.25),
        Color(red: 1.00, green: 0.94, blue: 0.83),
        Color(red: 0.94, green: 0.75, blue: 0.50),
        Color(red: 0.91, green: 0.63, blue: 0.25),
        // Row 5 — Pastels & Specials
        Color(red: 0.91, green: 0.88, blue: 0.97),
        Color(red: 0.61, green: 0.44, blue: 0.83),
        Color(red: 0.31, green: 0.25, blue: 0.66),
        Color(red: 0.72, green: 0.82, blue: 0.94),
        Color(red: 0.83, green: 0.94, blue: 0.91),
        Color(red: 0.96, green: 0.90, blue: 0.82),
    ]

    init(initialColor: Color, onConfirm: @escaping (Color) -> Void) {
        self.initialColor = initialColor
        self.onConfirm = onConfirm
        _currentColor = State(initialValue: initialColor)
    }

    var body: some View {
        VStack(spacing: 0) {
            handle
            titleBar

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6),
                spacing: 10
            ) {
                ForEach(palette.indices, id: \.self) { i in
                    swatch(at: i)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)

            Divider()

            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "eyedropper.halffull")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.skyBlue)
                    Text("更多颜色")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.inkBlack)
                }
                Spacer()
                ColorPicker("", selection: $currentColor, supportsOpacity: false)
                    .labelsHidden()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Button {
                onConfirm(currentColor)
                dismiss()
            } label: {
                HStack(spacing: 10) {
                    Circle()
                        .fill(currentColor)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().strokeBorder(Color(.systemGray5), lineWidth: 0.5))
                    Text("使用此颜色")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.skyBlue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Subviews

    private var handle: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color(.systemGray4))
            .frame(width: 36, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 4)
    }

    private var titleBar: some View {
        HStack {
            Text("自定义底色")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.inkBlack)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(.systemGray3))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private func swatch(at index: Int) -> some View {
        let color = palette[index]
        let isSelected = isColorMatch(currentColor, color)
        let dark = luminance(of: color) < 0.55

        return Button { currentColor = color } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                isSelected ? Color.skyBlue : Color(.systemGray4),
                                lineWidth: isSelected ? 2.5 : 0.5
                            )
                    )
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(dark ? .white : Color.skyBlue)
                }
            }
        }
    }

    // MARK: - Helpers

    private func isColorMatch(_ a: Color, _ b: Color) -> Bool {
        let ua = UIColor(a), ub = UIColor(b)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0
        ua.getRed(&r1, green: &g1, blue: &b1, alpha: nil)
        ub.getRed(&r2, green: &g2, blue: &b2, alpha: nil)
        return sqrt(pow(r1-r2, 2) + pow(g1-g2, 2) + pow(b1-b2, 2)) < 0.02
    }

    private func luminance(of color: Color) -> Double {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: nil)
        return Double(0.299 * r + 0.587 * g + 0.114 * b)
    }
}
