import SwiftUI

/// 原图 vs AI生成 左右拖动对比视图
struct ComparisonSliderView: View {
    let before: UIImage
    let after: UIImage

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
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.15))
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func labelOverlay(dividerX: CGFloat, width: CGFloat) -> some View {
        VStack {
            HStack {
                pillLabel("原图")
                    .opacity(progress > 0.12 ? 1 : 0)
                Spacer()
                pillLabel("AI 生成")
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
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.black.opacity(0.45), in: Capsule())
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
