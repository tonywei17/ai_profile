import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var langManager: LanguageManager
    @EnvironmentObject var subscription: SubscriptionManager
    @EnvironmentObject var usage: UsageManager
    @Environment(\.dismiss) private var dismiss

    @State private var showSubscriptionSheet = false

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground.gradient.ignoresSafeArea()

                List {
                    // MARK: Subscription
                    Section {
                        subscriptionStatusRow
                        if subscription.isSubscribed {
                            manageSubscriptionRow
                        } else {
                            upgradeRow
                        }
                        restoreRow
                    } header: {
                        sectionHeader(icon: "crown.fill", title: sectionTitle("Membership", "会员", "会員", "멤버십"))
                    }
                    .listRowBackground(Color.primary.opacity(0.06))

                    // MARK: Appearance
                    Section {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Button {
                                langManager.appearance = mode
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: mode.icon)
                                        .foregroundStyle(Color.accentColor)
                                        .frame(width: 20)
                                    Text(mode.displayName(language: lang))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if langManager.appearance == mode {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                            .font(.callout.bold())
                                    }
                                }
                            }
                        }
                    } header: {
                        sectionHeader(icon: "paintbrush.fill", title: sectionTitle("Appearance", "外观", "外観", "외관"))
                    }
                    .listRowBackground(Color.primary.opacity(0.06))

                    // MARK: Language
                    Section {
                        langRow(.system)
                        langRow(.chineseSimplified)
                        langRow(.english)
                        langRow(.japanese)
                        langRow(.korean)
                    } header: {
                        sectionHeader(icon: "globe", title: sectionTitle("Language", "语言", "言語", "언어"))
                    } footer: {
                        Text(footerNote).font(.caption)
                    }
                    .listRowBackground(Color.primary.opacity(0.06))

                    // MARK: Region
                    Section {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundStyle(Color.accentColor)
                            Text(regionLabel)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(Locale.current.region?.identifier ?? "—")
                                .foregroundStyle(.secondary)
                                .font(.callout.monospacedDigit())
                        }
                    } header: {
                        sectionHeader(icon: "map", title: sectionTitle("Region / Spec Order", "地区 / 规格排序", "地域 / 規格順序", "지역 / 규격 순서"))
                    } footer: {
                        Text(regionFooter).font(.caption)
                    }
                    .listRowBackground(Color.primary.opacity(0.06))

                    // MARK: App Info
                    Section {
                        infoRow(icon: "info.circle.fill", color: .blue,
                                label: versionLabel, value: appVersion)
                    } header: {
                        sectionHeader(icon: "info.circle", title: sectionTitle("App", "应用", "アプリ", "앱"))
                    }
                    .listRowBackground(Color.primary.opacity(0.06))

                    // MARK: Legal
                    Section {
                        Link(destination: LegalURLs.privacyPolicy) {
                            legalRow(icon: "hand.raised.fill", color: .teal, title: privacyLabel)
                        }
                        Link(destination: LegalURLs.termsOfService) {
                            legalRow(icon: "doc.text.fill", color: .orange, title: termsLabel)
                        }
                    } header: {
                        sectionHeader(icon: "lock.shield", title: sectionTitle("Legal", "法律", "法的情報", "법적 정보"))
                    }
                    .listRowBackground(Color.primary.opacity(0.06))
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.large)
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
    }

    // MARK: - Subscription Rows

    private var subscriptionStatusRow: some View {
        HStack(spacing: 12) {
            Image(systemName: subscription.isSubscribed ? "checkmark.seal.fill" : "crown")
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background((subscription.isSubscribed ? Color.orange : Color.gray).gradient)
                .clipShape(RoundedRectangle(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.isSubscribed ? subscribedLabel : notSubscribedLabel)
                    .font(.callout)
                if subscription.isSubscribed, let exp = subscription.expirationDate {
                    Text(expiryText(exp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if subscription.isSubscribed {
                    Text(todayRemainingText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(freeUserDesc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    private var upgradeRow: some View {
        Button {
            showSubscriptionSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.blue.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                Text(upgradeLabel)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showSubscriptionSheet) {
            SubscriptionSheetView()
                .environmentObject(subscription)
                .environmentObject(langManager)
                .presentationDetents([.large])
        }
    }

    private var manageSubscriptionRow: some View {
        Button {
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.purple.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                Text(manageLabel)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var restoreRow: some View {
        Button {
            Task { await subscription.restore() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.clockwise")
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.teal.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                Text(restoreLabel)
                    .foregroundStyle(.primary)
                Spacer()
                if subscription.isRestoring {
                    ProgressView().scaleEffect(0.8)
                }
            }
        }
        .disabled(subscription.isRestoring)
    }

    // MARK: - Row Builders

    private func langRow(_ option: AppLanguage) -> some View {
        Button {
            withAnimation { langManager.language = option }
        } label: {
            HStack(spacing: 12) {
                Text(option.flag).font(.title3)
                Text(option.displayName).foregroundStyle(.primary)
                Spacer()
                if langManager.language == option {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .font(.callout.bold())
                }
            }
        }
    }

    private func infoRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 7))
            Text(label)
            Spacer()
            Text(value).foregroundStyle(.secondary).font(.callout)
        }
    }

    private func legalRow(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 7))
            Text(title).foregroundStyle(.primary)
            Spacer()
            Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.secondary)
        }
    }

    private func sectionHeader(icon: String, title: String) -> some View {
        Label(title, systemImage: icon)
            .font(.footnote.bold())
            .foregroundStyle(.secondary)
            .textCase(nil)
    }

    // MARK: - Localization Helpers

    private var lang: String { langManager.effectiveCode }

    private func sectionTitle(_ en: String, _ zh: String, _ ja: String, _ ko: String) -> String {
        switch lang {
        case "zh": return zh
        case "ja": return ja
        case "ko": return ko
        default:   return en
        }
    }

    // MARK: - Localized Strings

    private var navTitle:     String { sectionTitle("Settings", "设置", "設定", "설정") }
    private var footerNote:   String {
        sectionTitle(
            "App display language. Spec ordering is always based on device region.",
            "应用界面语言。规格排序始终根据设备地区自动调整。",
            "アプリの表示言語。規格の並び順はデバイスの地域設定に従います。",
            "앱 표시 언어입니다. 규격 순서는 기기 지역 설정을 따릅니다."
        )
    }
    private var regionLabel:  String { sectionTitle("Device Region", "设备地区", "デバイス地域", "기기 지역") }
    private var regionFooter: String {
        sectionTitle(
            "ID photo formats are sorted by your device region. To change, go to iOS Settings → General → Language & Region.",
            "证件照规格按设备地区自动排序。在 iOS 设置 → 通用 → 语言与地区 中更改。",
            "規格の並び順はデバイスの地域設定で変わります。iOS設定 → 一般 → 言語と地域 で変更できます。",
            "규격 순서는 기기 지역에 따라 정렬됩니다. iOS 설정 → 일반 → 언어 및 지역에서 변경하세요."
        )
    }
    private var versionLabel:      String { sectionTitle("Version", "版本", "バージョン", "버전") }
    private var privacyLabel:      String { sectionTitle("Privacy Policy", "隐私政策", "プライバシーポリシー", "개인정보 처리방침") }
    private var termsLabel:        String { sectionTitle("Terms of Service", "服务条款", "利用規約", "이용약관") }
    private var subscribedLabel:   String { sectionTitle("Pro Member", "专业会员", "プロ会員", "프로 회원") }
    private var notSubscribedLabel:String { sectionTitle("Free Plan", "免费版", "無料プラン", "무료 플랜") }
    private var upgradeLabel:      String { sectionTitle("Upgrade to Pro", "升级为会员", "プロにアップグレード", "프로로 업그레이드") }
    private var manageLabel:       String { sectionTitle("Manage Subscription", "管理订阅", "サブスクリプション管理", "구독 관리") }
    private var restoreLabel:      String { sectionTitle("Restore Purchases", "恢复购买", "購入を復元", "구매 복원") }
    private var freeUserDesc:      String { sectionTitle("First gen free, then watch a 30s ad", "首次免费，此后需观看30秒广告", "初回無料、次回から30秒広告視聴", "첫 생성 무료, 이후 30초 광고") }
    private var todayRemainingText: String {
        let n = usage.subscriberUsesLeft
        return sectionTitle("Today's remaining: \(n)", "今日剩余：\(n) 次", "本日残り：\(n)回", "오늘 남은 횟수: \(n)회")
    }
    private func expiryText(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        let ds = fmt.string(from: date)
        return sectionTitle("Renews \(ds)", "续期日期：\(ds)", "更新日：\(ds)", "갱신일: \(ds)")
    }
}

// MARK: - Legal URLs

private enum LegalURLs {
    static let privacyPolicy  = URL(string: "https://example.com/privacy")!
    static let termsOfService = URL(string: "https://example.com/terms")!
}
