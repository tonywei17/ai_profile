import SwiftUI

struct SubscriptionSheetView: View {
    @EnvironmentObject var subscription: SubscriptionManager

    var body: some View {
        VStack(spacing: 16) {
            Text("开通会员")
                .font(.title.bold())

            VStack(alignment: .leading, spacing: 8) {
                Label("去除所有广告", systemImage: "nosign")
                Label("每天20次生成上限", systemImage: "bolt.fill")
                Label("更快的生成速度（未来）", systemImage: "speedometer")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            if let price = subscription.displayPrice {
                Text("订阅价格：\(price)")
                    .font(.headline)
            }

            Button {
                Task { await subscription.purchase() }
            } label: {
                Text("立即订阅")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }

            Button { Task { await subscription.restore() } } label: {
                Text("恢复购买")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Spacer()

            Text("订阅自动续期，可随时在设置中取消。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(GlassBackground.gradient.ignoresSafeArea())
    }
}
