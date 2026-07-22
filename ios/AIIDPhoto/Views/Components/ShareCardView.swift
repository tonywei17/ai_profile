import SwiftUI

/// Post-generation share prompt. Shares plain text only (App Store link + referral code) —
/// intentionally never attaches the user's photo, to avoid accidentally sharing a portrait.
struct ShareCardView: View {
    @EnvironmentObject var langManager: LanguageManager
    @Environment(\.dismiss) private var dismiss

    let referralCode: String?
    let shareText: String

    private var lang: String { langManager.effectiveCode }

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground.gradient.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.treeGreen)

                    VStack(spacing: 8) {
                        Text(titleLabel)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        Text(subtitleLabel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)

                    if let code = referralCode {
                        codeCard(code)
                    }

                    Spacer()

                    Button {
                        AnalyticsManager.shared.track(AnalyticsManager.Event.referralShareTapped)
                        presentShareSheet()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text(shareButtonLabel)
                        }
                        .font(.headline)
                        .foregroundStyle(Color.inkFillForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.inkFill)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, 24)

                    Button(dismissLabel) { dismiss() }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)
                }
                .padding(.vertical, 32)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .task {
            AnalyticsManager.shared.track(AnalyticsManager.Event.referralShareShown)
        }
    }

    private func codeCard(_ code: String) -> some View {
        VStack(spacing: 4) {
            Text(codeLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(code)
                .font(.title.monospaced().bold())
                .tracking(2)
                .onTapGesture {
                    UIPasteboard.general.string = code
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func presentShareSheet() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.keyWindow?.rootViewController else { return }
        let ac = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        if let popover = ac.popoverPresentationController {
            popover.sourceView = root.view
            popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
        }
        root.present(ac, animated: true)
    }

    // MARK: - Localized Strings

    private func l(_ zh: String, _ en: String, _ ja: String, _ ko: String,
                   vi: String? = nil, id: String? = nil, pt: String? = nil) -> String {
        switch lang {
        case "zh": return zh
        case "ja": return ja
        case "ko": return ko
        case "vi": return vi ?? en
        case "id": return id ?? en
        case "pt": return pt ?? en
        default:   return en
        }
    }

    private var titleLabel: String {
        l("证件照生成成功！", "Photo Ready!", "写真が完成しました！", "사진 생성 완료!",
          vi: "Ảnh đã sẵn sàng!", id: "Foto Siap!", pt: "Foto Pronta!")
    }
    private var subtitleLabel: String {
        l("分享给朋友，一起用 AI 生成证件照",
          "Share with friends so they can try AI ID Photo too",
          "友達にシェアして、AI証明写真を試してもらいましょう",
          "친구에게 공유하고 AI 증명사진을 함께 사용해 보세요",
          vi: "Chia sẻ cho bạn bè cùng trải nghiệm AI ID Photo",
          id: "Bagikan ke teman agar mereka juga bisa coba AI ID Photo",
          pt: "Compartilhe com amigos para eles também usarem o AI ID Photo")
    }
    private var codeLabel: String {
        l("我的推荐码", "My Referral Code", "紹介コード", "내 추천 코드",
          vi: "Mã giới thiệu của tôi", id: "Kode Referral Saya", pt: "Meu Código de Indicação")
    }
    private var shareButtonLabel: String {
        l("分享给朋友", "Share with Friends", "友達にシェア", "친구에게 공유",
          vi: "Chia sẻ với bạn bè", id: "Bagikan ke Teman", pt: "Compartilhar com Amigos")
    }
    private var dismissLabel: String {
        l("暂不分享", "Not Now", "今はしない", "나중에",
          vi: "Để sau", id: "Nanti Saja", pt: "Agora Não")
    }
}
