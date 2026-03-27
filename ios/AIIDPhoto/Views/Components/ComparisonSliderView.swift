import SwiftUI

/// 原图 vs AI生成 左右拖动对比视图
struct ComparisonSliderView: View {
    let before: UIImage
    let after: UIImage
    var language: String = "en"

    @State private var progress: CGFloat = 0.5

    var body: some View {
        GeometryReader { geo in
            let dividerX = geo.size.width * progress

            ZStack(alignment: .leading) {
                // After (AI生成) — 底层满铺
                Image(uiImage: after)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                // Before (原图) — 左侧裁剪显示
                Image(uiImage: before)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: dividerX)
                    }

                // 标签层
                labelOverlay(dividerX: dividerX, width: geo.size.width)

                // 分割线
                Rectangle()
                    .fill(.white.opacity(0.9))
                    .frame(width: 2)
                    .allowsHitTesting(false)
                    .offset(x: dividerX - 1)

                // 拖动手柄
                dragHandle
                    .offset(x: dividerX - 22)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        let new = val.location.x / geo.size.width
                        withAnimation(.interactiveSpring()) {
                            progress = max(0.04, min(0.96, new))
                        }
                    }
            )
        }
        .drawingGroup()
        .clipShape(Rectangle())
        .overlay {
            Rectangle().stroke(Color.inkBlack, lineWidth: 1)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func labelOverlay(dividerX: CGFloat, width: CGFloat) -> some View {
        VStack {
            HStack {
                pillLabel(beforeLabel)
                    .opacity(progress > 0.12 ? 1 : 0)
                Spacer()
                pillLabel(afterLabel)
                    .opacity(progress < 0.88 ? 1 : 0)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .animation(.easeInOut(duration: 0.15), value: progress)
            Spacer()
        }
        .frame(width: width)
    }

    private func pillLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .tracking(0.5)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.inkBlack.opacity(0.6))
    }

    private var beforeLabel: String {
        switch language {
        case "zh": return "原图"
        case "ja": return "元画像"
        case "ko": return "원본"
        case "vi": return "Gốc"
        case "id": return "Asli"
        case "pt": return "Original"
        default:   return "Original"
        }
    }

    private var afterLabel: String {
        switch language {
        case "zh": return "AI 生成"
        case "ja": return "AI 生成"
        case "ko": return "AI 생성"
        case "vi": return "AI tạo"
        case "id": return "AI Dibuat"
        case "pt": return "AI Gerado"
        default:   return "AI Generated"
        }
    }

    private var dragHandle: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 44, height: 44)
                .shadow(color: .black.opacity(0.22), radius: 6, y: 2)

            HStack(spacing: 3) {
                Image(systemName: "chevron.left")
                Image(systemName: "chevron.right")
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.gray)
        }
    }
}
