import SwiftUI

struct SubscriptionSheetView: View {
    @EnvironmentObject var subscription: SubscriptionManager
    @EnvironmentObject var langManager: LanguageManager
    @Environment(\.dismiss) private var dismiss

    private var lang: String { langManager.effectiveCode }

    private func l(_ zh: String, _ en: String, _ ja: String, _ ko: String,
                   vi: String? = nil, id: String? = nil, pt: String? = nil) -> String {
        switch lang {
        case "zh": return zh
        case "ja": return ja
        case "ko": return ko
        case "vi": return vi ?? en
        case "id": return id ?? en
        case "pt": return pt ?? en
        default: return en
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    heroBannerSection
                    offerSummarySection
                    valueStatsSection
                    includedSection
                    usageStatusSection
                }
                .padding(.bottom, 18)
            }
            Divider()
            purchaseFooter
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.92))
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text(l("关闭", "Close", "閉じる", "닫기")))
            .padding(.top, 12)
            .padding(.trailing, 12)
        }
        .alert(errorAlertTitle, isPresented: Binding(
            get: { subscription.purchaseError != nil },
            set: { if !$0 { subscription.purchaseError = nil } }
        )) {
            Button(okLabel, role: .cancel) {}
        } message: {
            Text(subscription.purchaseError ?? "")
        }
    }

    private var heroBannerSection: some View {
        ZStack(alignment: .trailing) {
            LinearGradient(
                colors: [Color.skyBlue, Color.skyBlueMid],
                startPoint: .leading,
                endPoint: .trailing
            )

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(discountBadge)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.18))
                        .clipShape(Capsule())

                    Text(heroTitle)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text(heroSubtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.84))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    HStack(spacing: 8) {
                        Text(displayPriceText)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.promoOrange)
                        Text(perPhotoLabel)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                        Text(originalPriceLabel)
                            .font(.system(size: 11))
                            .strikethrough(color: .white.opacity(0.6))
                            .foregroundStyle(.white.opacity(0.62))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.18))
                    .clipShape(Capsule())
                }
                .padding(.leading, 20)
                .padding(.vertical, 22)
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Rectangle().fill(.white.opacity(0.10))
                    Image(systemName: "person.crop.rectangle.badge.plus")
                        .font(.system(size: 58, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.38))
                }
                .frame(width: 126)
            }
        }
        .frame(height: 210)
    }

    private var offerSummarySection: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(displayPriceText)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(Color.skyBlue)
                Text(perPhotoLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.branchGray)
                Spacer()
                Text(noSubscriptionLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.branchGray)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(.systemBackground))
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.treeGreen)
                Text(priceExplainLabel)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkBlack)
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemGray6).opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }

    private var valueStatsSection: some View {
        HStack(spacing: 0) {
            valueStat(highlight: "3次", label: attemptsTitle, desc: attemptsShortDesc)
            Rectangle().fill(Color(.systemGray4)).frame(width: 1, height: 44)
            valueStat(highlight: "高清", label: downloadTitle, desc: downloadShortDesc)
            Rectangle().fill(Color(.systemGray4)).frame(width: 1, height: 44)
            valueStat(highlight: "排版", label: printTitle, desc: printShortDesc)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemGray6).opacity(0.6))
    }

    private func valueStat(highlight: String, label: String, desc: String) -> some View {
        VStack(spacing: 4) {
            Text(highlight)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.skyBlue)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.inkBlack)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(desc)
                .font(.system(size: 10))
                .foregroundStyle(Color.branchGray)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
    }

    private var includedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(includedSectionTitle)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.inkBlack)

            VStack(spacing: 10) {
                featureRow(icon: "sparkles", title: attemptsTitle, desc: attemptsDesc)
                featureRow(icon: "photo.fill", title: bestPickTitle, desc: bestPickDesc)
                featureRow(icon: "square.and.arrow.down", title: downloadTitle, desc: downloadDesc)
                featureRow(icon: "printer.fill", title: printTitle, desc: printDesc)
                featureRow(icon: "shield.checkerboard", title: privacyTitle, desc: privacyDesc)
            }
        }
        .padding(.horizontal, 16)
    }

    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.skyBlue.opacity(0.10))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.skyBlue)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.inkBlack)
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.branchGray)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color.treeGreen)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }

    private var usageStatusSection: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(subscription.generationAttemptsLeft > 0 ? Color.treeGreen.opacity(0.12) : Color.skyBlue.opacity(0.10))
                    .frame(width: 46, height: 46)
                Image(systemName: subscription.generationAttemptsLeft > 0 ? "bolt.fill" : "cart.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(subscription.generationAttemptsLeft > 0 ? Color.treeGreen : Color.skyBlue)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(remainingTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.inkBlack)
                Text(remainingDesc)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.branchGray)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.systemGray6).opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }

    private var ctaButton: some View {
        Button {
            Task { await subscription.purchasePhotoTask() }
        } label: {
            Group {
                if subscription.isPurchasing {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.1)
                        .padding(.vertical, 6)
                } else {
                    VStack(spacing: 4) {
                        Text(ctaTitle)
                            .font(.system(size: 16, weight: .semibold))
                        Text(ctaSubtitle)
                            .font(.system(size: 11))
                            .opacity(0.85)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
        }
        .disabled(subscription.isPurchasing)
        .background(
            LinearGradient(
                colors: [Color.skyBlue, Color.skyBlueMid],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 26))
    }

    private var purchaseFooter: some View {
        VStack(spacing: 9) {
            ctaButton
            footerSection
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(Color(.systemBackground))
    }

    private var footerSection: some View {
        VStack(spacing: 10) {
            Text(legalNote)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            LegalLinksView()
        }
    }

    private var heroTitle: String {
        l("一张成片，三次生成", "One Final Photo, 3 Attempts", "1枚完成、3回生成", "완성본 1장, 생성 3회")
    }
    private var heroSubtitle: String {
        l("先买一个制作包，最多生成3次，选最满意的照片下载高清电子照和打印排版。",
          "Buy one photo task, generate up to 3 times, then download the best HD result and print layout.",
          "1回分を購入し、最大3回生成。ベストな写真をHD保存と印刷レイアウトで出力。",
          "1회 제작권으로 최대 3회 생성하고 가장 좋은 결과를 저장합니다.")
    }
    private var discountBadge: String { l("限时优惠", "Launch Offer", "期間限定", "한정 할인") }
    private var noSubscriptionLabel: String { l("非订阅 · 不自动续费", "No subscription", "サブスクなし", "구독 없음") }
    private var perPhotoLabel: String { l("/ 张", "/ photo", "/ 枚", "/ 장") }
    private var originalPriceLabel: String { l("原价 ¥9.90", "Was ¥9.90", "通常 ¥9.90", "정가 ¥9.90") }
    private var displayPriceText: String {
        if lang == "zh" { return "¥3.80" }
        return subscription.photoTaskDisplayPrice ?? "¥3.80"
    }
    private var priceExplainLabel: String {
        l("优惠价按张购买，包含3次生成机会。", "Includes 3 generation attempts for this photo.", "この写真に3回分の生成が含まれます。", "이 사진에 생성 3회가 포함됩니다.")
    }

    private var includedSectionTitle: String { l("制作包包含", "Included", "含まれる内容", "포함 항목") }
    private var attemptsTitle: String { l("3次AI生成机会", "3 AI Attempts", "AI生成3回", "AI 생성 3회") }
    private var attemptsDesc: String { l("表情、底色、服装不满意可以再来", "Regenerate when expression, background, or attire is off.", "表情・背景・服装を調整して再生成できます。", "표정, 배경, 복장을 다시 조정할 수 있습니다.") }
    private var attemptsShortDesc: String { l("选最满意", "Pick best", "選べる", "선택 가능") }
    private var bestPickTitle: String { l("选择最适合的照片", "Pick the Best Result", "ベストを選択", "최고 결과 선택") }
    private var bestPickDesc: String { l("生成记录会保留，可回看对比", "Previous results stay in history for comparison.", "履歴から比較できます。", "기록에서 비교할 수 있습니다.") }
    private var downloadTitle: String { l("高清电子照下载", "HD Export", "HD保存", "HD 저장") }
    private var downloadDesc: String { l("保存到相册，可用于线上报名上传", "Save to Photos for online applications.", "オンライン申請に使えます。", "온라인 신청에 사용할 수 있습니다.") }
    private var downloadShortDesc: String { l("可直接上传", "Ready upload", "保存可能", "저장 가능") }
    private var printTitle: String { l("打印店排版", "Print Layout", "印刷レイアウト", "인쇄 레이아웃") }
    private var printDesc: String { l("6寸/5寸排版图一起包含，不再单独收费", "6R/5R print layouts are included.", "印刷用レイアウト込み。", "인쇄 레이아웃 포함.") }
    private var printShortDesc: String { l("到店即打", "Print ready", "印刷用", "인쇄용") }
    private var privacyTitle: String { l("隐私保护", "Privacy Protected", "プライバシー保護", "개인정보 보호") }
    private var privacyDesc: String { l("照片处理仅用于本次制作", "Photos are processed only for this task.", "写真は今回の制作のみに使われます。", "사진은 이번 제작에만 사용됩니다.") }

    private var remainingTitle: String {
        subscription.generationAttemptsLeft > 0
            ? l("当前剩余 \(subscription.generationAttemptsLeft) 次生成", "\(subscription.generationAttemptsLeft) attempts left", "残り\(subscription.generationAttemptsLeft)回", "\(subscription.generationAttemptsLeft)회 남음")
            : l("购买后立即开始制作", "Start after purchase", "購入後すぐ開始", "구매 후 바로 시작")
    }
    private var remainingDesc: String {
        subscription.generationAttemptsLeft > 0
            ? l("继续生成不会再弹出购买页。", "You can continue without another purchase prompt.", "追加購入なしで続けられます。", "추가 구매 없이 계속할 수 있습니다.")
            : l("建议先确定用途和底色，再开始3次生成。", "Pick the target format and background before using attempts.", "用途と背景を決めてから生成してください。", "용도와 배경을 정한 후 생성하세요.")
    }

    private var ctaTitle: String { l("购买制作包", "Buy Photo Task", "制作分を購入", "제작권 구매") }
    private var ctaSubtitle: String { l("¥3.80 优惠价 · 原价 ¥9.90/张", "Launch offer ¥3.80 · Regular ¥9.90/photo", "特価 ¥3.80 · 通常 ¥9.90/枚", "할인가 ¥3.80 · 정가 ¥9.90/장") }
    private var legalNote: String {
        l("本商品为消耗型购买，不是订阅，不会自动续费；购买由 Apple 处理，退款按 App Store 规则执行。",
          "This is a consumable purchase, not a subscription. It does not auto-renew.",
          "これは消耗型購入で、サブスクリプションではありません。自動更新されません。",
          "소모성 구매이며 구독이 아니므로 자동 갱신되지 않습니다.")
    }
    private var errorAlertTitle: String { l("购买失败", "Purchase Failed", "購入に失敗しました", "구매 실패") }
    private var okLabel: String { l("好的", "OK", "OK", "확인") }
}

// MARK: - Legal Links

private enum LegalURLs {
    static let baseURL = "https://aiphoto-cn.foyli.cloud/legal"

    static func privacyPolicy(lang: String) -> URL {
        URL(string: "\(baseURL)/privacy/\(legalLang(lang)).html")!
    }

    static func termsOfService(lang: String) -> URL {
        URL(string: "\(baseURL)/terms/\(legalLang(lang)).html")!
    }

    private static func legalLang(_ code: String) -> String {
        if code.hasPrefix("zh") { return "zh" }
        if code.hasPrefix("ja") { return "ja" }
        if code.hasPrefix("ko") { return "ko" }
        if code.hasPrefix("vi") { return "vi" }
        if code.hasPrefix("id") { return "id" }
        if code.hasPrefix("pt") { return "pt" }
        return "en"
    }
}

struct LegalLinksView: View {
    @EnvironmentObject var langManager: LanguageManager

    private var lang: String { langManager.effectiveCode }

    private var privacyLabel: String {
        switch lang {
        case "zh": return "隐私政策"
        case "ja": return "プライバシーポリシー"
        case "ko": return "개인정보 처리방침"
        case "vi": return "Chính sách Bảo mật"
        case "id": return "Kebijakan Privasi"
        case "pt": return "Política de Privacidade"
        default: return "Privacy Policy"
        }
    }

    private var termsLabel: String {
        switch lang {
        case "zh": return "服务条款"
        case "ja": return "利用規約"
        case "ko": return "이용약관"
        case "vi": return "Điều khoản Dịch vụ"
        case "id": return "Ketentuan Layanan"
        case "pt": return "Termos de Serviço"
        default: return "Terms of Service"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            Link(privacyLabel, destination: LegalURLs.privacyPolicy(lang: lang))
            Text("·").foregroundStyle(.secondary)
            Link(termsLabel, destination: LegalURLs.termsOfService(lang: lang))
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}
