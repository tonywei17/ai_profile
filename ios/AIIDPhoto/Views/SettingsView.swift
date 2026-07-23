import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var langManager: LanguageManager
    @EnvironmentObject var subscription: SubscriptionManager
    @EnvironmentObject var usage: UsageManager
    @EnvironmentObject var referralManager: ReferralManager
    @Environment(\.dismiss) private var dismiss

    @State private var showSubscriptionSheet = false
    @State private var redeemCodeInput = ""
    @State private var isRedeeming = false
    @State private var showRedeemSuccess = false
    @State private var claimToastMessage: String?

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                List {
                    // MARK: Subscription
                    Section {
                        subscriptionStatusRow
                        if subscription.isSubscribed {
                            manageSubscriptionRow
                            if !subscription.willAutoRenew {
                                resubscribeHintRow
                            }
                        } else {
                            upgradeRow
                        }
                        restoreRow
                    } header: {
                        sectionHeader(icon: "crown.fill", title: sectionTitle("Membership", "会员", "会員", "멤버십", vi: "Thành viên", id: "Keanggotaan", pt: "Assinatura"))
                    }
                    .listRowBackground(Color(.secondarySystemGroupedBackground))

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
                        sectionHeader(icon: "paintbrush.fill", title: sectionTitle("Appearance", "外观", "外観", "외관", vi: "Giao diện", id: "Tampilan", pt: "Aparência"))
                    }
                    .listRowBackground(Color(.secondarySystemGroupedBackground))

                    // MARK: Language
                    Section {
                        langRow(.system)
                        langRow(.chineseSimplified)
                        langRow(.english)
                        langRow(.japanese)
                        langRow(.korean)
                        langRow(.vietnamese)
                        langRow(.indonesian)
                        langRow(.portuguese)
                    } header: {
                        sectionHeader(icon: "globe", title: sectionTitle("Language", "语言", "言語", "언어", vi: "Ngôn ngữ", id: "Bahasa", pt: "Idioma"))
                    } footer: {
                        Text(footerNote).font(.caption)
                    }
                    .listRowBackground(Color(.secondarySystemGroupedBackground))

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
                        sectionHeader(icon: "map", title: sectionTitle("Region / Spec Order", "地区 / 规格排序", "地域 / 規格順序", "지역 / 규격 순서", vi: "Vùng / Thứ tự quy cách", id: "Wilayah / Urutan Spek", pt: "Região / Ordem de Formato"))
                    } footer: {
                        Text(regionFooter).font(.caption)
                    }
                    .listRowBackground(Color(.secondarySystemGroupedBackground))

                    // MARK: App Info
                    Section {
                        infoRow(icon: "info.circle.fill", color: .blue,
                                label: versionLabel, value: appVersion)
                    } header: {
                        sectionHeader(icon: "info.circle", title: sectionTitle("App", "应用", "アプリ", "앱", vi: "Ứng dụng", id: "Aplikasi", pt: "Aplicativo"))
                    }
                    .listRowBackground(Color(.secondarySystemGroupedBackground))

                    // MARK: Referral
                    Section {
                        // Share referral code
                        Button { shareReferralCode() } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.2.fill")
                                    .foregroundStyle(Color.inkBlack)
                                    .frame(width: 28, height: 28)
                                    .overlay(Rectangle().stroke(Color.inkBorder, lineWidth: 1))
                                    .clipShape(Rectangle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(inviteLabel).foregroundStyle(.primary)
                                    if let code = referralManager.referralCode {
                                        Text("\(codeLabel): \(code)")
                                            .font(.caption.monospaced())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "square.and.arrow.up").font(.caption).foregroundStyle(.secondary)
                            }
                        }

                        // Invited count + trial progress
                        referralProgressRow

                        // Promo Pro trial expiry (once granted)
                        if let until = subscription.promoPremiumUntil, until > Date() {
                            promoActiveRow(until: until)
                        }

                        // Bonus remaining
                        if referralManager.bonusGenerations > 0 {
                            HStack(spacing: 12) {
                                Image(systemName: "gift.fill")
                                    .foregroundStyle(Color.inkBlack)
                                    .frame(width: 28, height: 28)
                                    .overlay(Rectangle().stroke(Color.inkBorder, lineWidth: 1))
                                    .clipShape(Rectangle())
                                Text(bonusLabel)
                                Spacer()
                                Text("\(referralManager.bonusGenerations)")
                                    .font(.callout.bold())
                                    .foregroundStyle(.purple)
                            }
                        }

                        // Redeem code
                        HStack(spacing: 12) {
                            Image(systemName: "ticket.fill")
                                .foregroundStyle(Color.inkBlack)
                                .frame(width: 28, height: 28)
                                .overlay(Rectangle().stroke(Color.inkBorder, lineWidth: 1))
                                .clipShape(Rectangle())
                            TextField(redeemPlaceholder, text: $redeemCodeInput)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                            Button {
                                Task { await redeemCode() }
                            } label: {
                                if isRedeeming {
                                    ProgressView().scaleEffect(0.8)
                                } else {
                                    Text(redeemLabel).font(.callout.bold())
                                }
                            }
                            .disabled(redeemCodeInput.count < 4 || isRedeeming)
                        }

                        Link(destination: LegalURLs.referralTerms(lang: lang)) {
                            legalRow(icon: "doc.plaintext.fill", color: .gray, title: referralTermsLabel)
                        }
                    } header: {
                        sectionHeader(icon: "gift", title: sectionTitle("Invite Friends", "邀请好友", "友達を招待", "친구 초대", vi: "Mời bạn bè", id: "Undang Teman", pt: "Convidar Amigos"))
                    } footer: {
                        Text(referralFooter).font(.caption)
                    }
                    .listRowBackground(Color(.secondarySystemGroupedBackground))

                    // MARK: Legal
                    Section {
                        Link(destination: LegalURLs.privacyPolicy(lang: lang)) {
                            legalRow(icon: "hand.raised.fill", color: .teal, title: privacyLabel)
                        }
                        Link(destination: LegalURLs.termsOfService(lang: lang)) {
                            legalRow(icon: "doc.text.fill", color: .orange, title: termsLabel)
                        }
                    } header: {
                        sectionHeader(icon: "lock.shield", title: sectionTitle("Legal", "法律", "法的情報", "법적 정보", vi: "Pháp lý", id: "Hukum", pt: "Legal"))
                    }
                    .listRowBackground(Color(.secondarySystemGroupedBackground))
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
        .task {
            await referralManager.refreshStatus()
            if let result = await referralManager.claimRewards(applyTrial: { subscription.grantPromoPremium(days: $0) }),
               result.grantedGenerations > 0 || result.grantedTrialDays > 0 {
                claimToastMessage = claimedMessage(generations: result.grantedGenerations, trialDays: result.grantedTrialDays)
                AnalyticsManager.shared.track(AnalyticsManager.Event.referralClaimed)
            }
        }
        .alert(
            sectionTitle("Reward Received!", "获得奖励！", "報酬を獲得！", "보상 획득!",
                         vi: "Đã nhận thưởng!", id: "Hadiah Diterima!", pt: "Recompensa Recebida!"),
            isPresented: Binding(
                get: { claimToastMessage != nil },
                set: { if !$0 { claimToastMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(claimToastMessage ?? "")
        }
        .alert(
            sectionTitle("Success!", "兑换成功！", "成功！", "성공!",
                         vi: "Thành công!", id: "Berhasil!", pt: "Sucesso!"),
            isPresented: $showRedeemSuccess
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(sectionTitle(
                "You got 3 free Pro generations!",
                "获得 3 次免费 Pro 品质生成！",
                "3回の無料Pro生成を獲得しました！",
                "3회 무료 Pro 생성을 받았습니다!",
                vi: "Bạn nhận được 3 lần tạo ảnh Pro miễn phí!",
                id: "Anda mendapat 3 generasi Pro gratis!",
                pt: "Você ganhou 3 gerações Pro grátis!"
            ))
        }
        .alert(
            sectionTitle("Error", "错误", "エラー", "오류",
                         vi: "Lỗi", id: "Kesalahan", pt: "Erro"),
            isPresented: Binding(
                get: { referralManager.redeemError != nil },
                set: { if !$0 { referralManager.redeemError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(referralManager.redeemError ?? "")
        }
    }

    // MARK: - Subscription Rows

    private var subscriptionStatusRow: some View {
        HStack(spacing: 12) {
            Image(systemName: subscriptionStatusIcon)
                .foregroundStyle(Color.inkBlack)
                .frame(width: 28, height: 28)
                .overlay(Rectangle().stroke(Color.inkBorder, lineWidth: 1))
                .clipShape(Rectangle())
            VStack(alignment: .leading, spacing: 2) {
                Text(subscriptionStatusLabel)
                    .font(.callout)
                    .foregroundStyle(.primary)
                if subscription.isSubscribed, let exp = subscription.expirationDate {
                    if subscription.willAutoRenew {
                        Text(renewsText(exp))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(expiresText(exp))
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
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

    private var subscriptionStatusIcon: String {
        if !subscription.isSubscribed { return "crown" }
        return subscription.willAutoRenew ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
    }

    private var subscriptionStatusColor: Color {
        if !subscription.isSubscribed { return .gray }
        return subscription.willAutoRenew ? .orange : .yellow
    }

    private var subscriptionStatusLabel: String {
        if !subscription.isSubscribed { return notSubscribedLabel }
        return subscription.willAutoRenew ? subscribedLabel : cancelledLabel
    }

    private var upgradeRow: some View {
        Button {
            showSubscriptionSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(Color.inkBlack)
                    .frame(width: 28, height: 28)
                    .overlay(Rectangle().stroke(Color.inkBorder, lineWidth: 1))
                    .clipShape(Rectangle())
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
            Task {
                if let scene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    do {
                        try await AppStore.showManageSubscriptions(in: scene)
                    } catch {
                        // Fallback to URL if native sheet fails
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            await UIApplication.shared.open(url)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(Color.inkBlack)
                    .frame(width: 28, height: 28)
                    .overlay(Rectangle().stroke(Color.inkBorder, lineWidth: 1))
                    .clipShape(Rectangle())
                Text(manageLabel)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var resubscribeHintRow: some View {
        Button {
            showSubscriptionSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.up.heart.fill")
                    .foregroundStyle(Color.inkBlack)
                    .frame(width: 28, height: 28)
                    .overlay(Rectangle().stroke(Color.inkBorder, lineWidth: 1))
                    .clipShape(Rectangle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(resubscribeLabel)
                        .foregroundStyle(.primary)
                    Text(resubscribeDesc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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

    private var restoreRow: some View {
        Button {
            Task { await subscription.restore() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.clockwise")
                    .foregroundStyle(Color.inkBlack)
                    .frame(width: 28, height: 28)
                    .overlay(Rectangle().stroke(Color.inkBorder, lineWidth: 1))
                    .clipShape(Rectangle())
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
                .foregroundStyle(Color.inkBlack)
                .frame(width: 28, height: 28)
                .overlay(Rectangle().stroke(Color.inkBorder, lineWidth: 1))
                .clipShape(Rectangle())
            Text(label)
            Spacer()
            Text(value).foregroundStyle(.secondary).font(.callout)
        }
    }

    private func legalRow(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.inkBlack)
                .frame(width: 28, height: 28)
                .overlay(Rectangle().stroke(Color.inkBorder, lineWidth: 1))
                .clipShape(Rectangle())
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

    private func sectionTitle(_ en: String, _ zh: String, _ ja: String, _ ko: String,
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

    // MARK: - Localized Strings

    private var navTitle:     String { sectionTitle("Settings", "设置", "設定", "설정", vi: "Cài đặt", id: "Pengaturan", pt: "Configurações") }
    private var footerNote:   String {
        sectionTitle(
            "App display language. Spec ordering is always based on device region.",
            "应用界面语言。规格排序始终根据设备地区自动调整。",
            "アプリの表示言語。規格の並び順はデバイスの地域設定に従います。",
            "앱 표시 언어입니다. 규격 순서는 기기 지역 설정을 따릅니다.",
            vi: "Ngôn ngữ hiển thị ứng dụng. Thứ tự quy cách luôn theo vùng thiết bị.",
            id: "Bahasa tampilan aplikasi. Urutan spek selalu berdasarkan wilayah perangkat.",
            pt: "Idioma do aplicativo. A ordem dos formatos segue a região do dispositivo."
        )
    }
    private var regionLabel:  String { sectionTitle("Device Region", "设备地区", "デバイス地域", "기기 지역", vi: "Vùng thiết bị", id: "Wilayah Perangkat", pt: "Região do Dispositivo") }
    private var regionFooter: String {
        sectionTitle(
            "ID photo formats are sorted by your device region. To change, go to iOS Settings → General → Language & Region.",
            "证件照规格按设备地区自动排序。在 iOS 设置 → 通用 → 语言与地区 中更改。",
            "規格の並び順はデバイスの地域設定で変わります。iOS設定 → 一般 → 言語と地域 で変更できます。",
            "규격 순서는 기기 지역에 따라 정렬됩니다. iOS 설정 → 일반 → 언어 및 지역에서 변경하세요.",
            vi: "Quy cách ảnh thẻ được sắp xếp theo vùng thiết bị. Để thay đổi, vào Cài đặt iOS → Cài đặt chung → Ngôn ngữ & Vùng.",
            id: "Format foto ID diurutkan berdasarkan wilayah perangkat. Untuk mengubah, buka Pengaturan iOS → Umum → Bahasa & Wilayah.",
            pt: "Os formatos são ordenados pela região do dispositivo. Para alterar, vá em Ajustes iOS → Geral → Idioma e Região."
        )
    }
    private var versionLabel:      String { sectionTitle("Version", "版本", "バージョン", "버전", vi: "Phiên bản", id: "Versi", pt: "Versão") }
    private var privacyLabel:      String { sectionTitle("Privacy Policy", "隐私政策", "プライバシーポリシー", "개인정보 처리방침", vi: "Chính sách Bảo mật", id: "Kebijakan Privasi", pt: "Política de Privacidade") }
    private var termsLabel:        String { sectionTitle("Terms of Service", "服务条款", "利用規約", "이용약관", vi: "Điều khoản Dịch vụ", id: "Ketentuan Layanan", pt: "Termos de Serviço") }
    private var subscribedLabel:   String { sectionTitle("Pro Member", "专业会员", "プロ会員", "프로 회원", vi: "Thành viên Pro", id: "Anggota Pro", pt: "Membro Pro") }
    private var notSubscribedLabel:String { sectionTitle("Free Plan", "免费版", "無料プラン", "무료 플랜", vi: "Gói Miễn phí", id: "Paket Gratis", pt: "Plano Gratuito") }
    private var upgradeLabel:      String { sectionTitle("Upgrade to Pro", "升级为会员", "プロにアップグレード", "프로로 업그레이드", vi: "Nâng cấp Pro", id: "Upgrade ke Pro", pt: "Assinar Pro") }
    private var manageLabel:       String { sectionTitle("Manage Subscription", "管理订阅", "サブスクリプション管理", "구독 관리", vi: "Quản lý đăng ký", id: "Kelola Langganan", pt: "Gerenciar Assinatura") }
    private var restoreLabel:      String { sectionTitle("Restore Purchases", "恢复购买", "購入を復元", "구매 복원", vi: "Khôi phục mua hàng", id: "Pulihkan Pembelian", pt: "Restaurar Compras") }
    private var freeUserDesc:      String { sectionTitle("First gen free, then watch an ad", "首次免费，此后需观看广告", "初回無料、次回から広告視聴", "첫 생성 무료, 이후 광고 시청", vi: "Lần đầu miễn phí, sau đó xem quảng cáo", id: "Pertama gratis, lalu tonton iklan", pt: "1ª grátis, depois assista um anúncio") }
    private var todayRemainingText: String {
        let n = usage.subscriberUsesLeft
        return sectionTitle("Today's remaining: \(n)", "今日剩余：\(n) 次", "本日残り：\(n)回", "오늘 남은 횟수: \(n)회", vi: "Còn lại hôm nay: \(n)", id: "Sisa hari ini: \(n)", pt: "Restantes hoje: \(n)")
    }
    private var cancelledLabel: String {
        sectionTitle("Pro (Cancelled)", "专业会员（已取消）", "プロ会員（解約済み）", "프로 회원 (취소됨)",
                     vi: "Pro (Đã hủy)", id: "Pro (Dibatalkan)", pt: "Pro (Cancelado)")
    }
    private var resubscribeLabel: String {
        sectionTitle("Resubscribe", "重新订阅", "再購読", "다시 구독",
                     vi: "Đăng ký lại", id: "Berlangganan Lagi", pt: "Reativar Assinatura")
    }
    private var resubscribeDesc: String {
        sectionTitle("Don't lose your Pro features", "保留专业功能，不要错过", "プロ機能を失わないように", "프로 기능을 잃지 마세요",
                     vi: "Đừng mất tính năng Pro", id: "Jangan kehilangan fitur Pro", pt: "Não perca seus recursos Pro")
    }
    private func renewsText(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        let ds = fmt.string(from: date)
        return sectionTitle("Renews \(ds)", "续期日期：\(ds)", "更新日：\(ds)", "갱신일: \(ds)", vi: "Gia hạn \(ds)", id: "Perpanjang \(ds)", pt: "Renova \(ds)")
    }
    private func expiresText(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        let ds = fmt.string(from: date)
        return sectionTitle("Expires \(ds)", "到期日期：\(ds)", "有効期限：\(ds)", "만료일: \(ds)", vi: "Hết hạn \(ds)", id: "Berakhir \(ds)", pt: "Expira \(ds)")
    }

    // MARK: - Referral Progress

    /// "Invited N people — M more to unlock a 3-day Pro trial" progress row.
    private var referralProgressRow: some View {
        let invited = referralManager.status?.redeemCount ?? referralManager.invitedCount
        let trialGranted = referralManager.status?.trialGranted ?? false
        let remaining = max(0, Self.trialThreshold - invited)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "person.3.fill")
                    .foregroundStyle(Color.inkBlack)
                    .frame(width: 28, height: 28)
                    .overlay(Rectangle().stroke(Color.inkBorder, lineWidth: 1))
                    .clipShape(Rectangle())
                Text(invitedCountText(invited))
                    .foregroundStyle(.primary)
                Spacer()
            }
            if !trialGranted {
                ProgressView(value: Double(min(invited, Self.trialThreshold)), total: Double(Self.trialThreshold))
                    .tint(.purple)
                Text(remaining > 0 ? trialProgressText(remaining: remaining) : trialReadyText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func promoActiveRow(until: Date) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.inkBlack)
                .frame(width: 28, height: 28)
                .overlay(Rectangle().stroke(Color.inkBorder, lineWidth: 1))
                .clipShape(Rectangle())
            VStack(alignment: .leading, spacing: 2) {
                Text(promoActiveLabel).foregroundStyle(.primary)
                Text(promoUntilText(until)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private static let trialThreshold = 3

    private func claimedMessage(generations: Int, trialDays: Int) -> String {
        if generations > 0 && trialDays > 0 {
            return sectionTitle(
                "You earned \(generations) free generations and a \(trialDays)-day Pro trial!",
                "获得 \(generations) 次免费生成和 \(trialDays) 天 Pro 体验！",
                "\(generations)回の無料生成と\(trialDays)日間のPro体験を獲得しました！",
                "\(generations)회 무료 생성과 \(trialDays)일 Pro 체험을 획득했습니다!",
                vi: "Bạn nhận được \(generations) lượt tạo miễn phí và \(trialDays) ngày dùng thử Pro!",
                id: "Anda mendapat \(generations) generasi gratis dan \(trialDays) hari trial Pro!",
                pt: "Você ganhou \(generations) gerações grátis e \(trialDays) dias de teste Pro!"
            )
        } else if trialDays > 0 {
            return sectionTitle(
                "You earned a \(trialDays)-day Pro trial!",
                "获得 \(trialDays) 天 Pro 体验！",
                "\(trialDays)日間のPro体験を獲得しました！",
                "\(trialDays)일 Pro 체험을 획득했습니다!",
                vi: "Bạn nhận được \(trialDays) ngày dùng thử Pro!",
                id: "Anda mendapat \(trialDays) hari trial Pro!",
                pt: "Você ganhou \(trialDays) dias de teste Pro!"
            )
        }
        return sectionTitle(
            "You earned \(generations) free generations!",
            "获得 \(generations) 次免费生成！",
            "\(generations)回の無料生成を獲得しました！",
            "\(generations)회 무료 생성을 획득했습니다!",
            vi: "Bạn nhận được \(generations) lượt tạo miễn phí!",
            id: "Anda mendapat \(generations) generasi gratis!",
            pt: "Você ganhou \(generations) gerações grátis!"
        )
    }

    private func invitedCountText(_ n: Int) -> String {
        sectionTitle("Invited \(n) friend\(n == 1 ? "" : "s")", "已邀请 \(n) 人", "\(n)人を招待済み", "\(n)명 초대함",
                     vi: "Đã mời \(n) người", id: "Mengundang \(n) orang", pt: "\(n) amigo(s) convidado(s)")
    }
    private func trialProgressText(remaining: Int) -> String {
        sectionTitle(
            "Invite \(remaining) more to unlock a 3-day Pro trial",
            "再邀请 \(remaining) 人即可解锁 3 天 Pro 体验",
            "あと\(remaining)人招待すると3日間のPro体験がもらえます",
            "\(remaining)명 더 초대하면 3일 Pro 체험이 열려요",
            vi: "Mời thêm \(remaining) người để mở khóa 3 ngày dùng thử Pro",
            id: "Undang \(remaining) orang lagi untuk membuka trial Pro 3 hari",
            pt: "Convide mais \(remaining) para desbloquear 3 dias de teste Pro"
        )
    }
    private var trialReadyText: String {
        sectionTitle("3-day Pro trial ready — reopen the app to claim it",
                     "3 天 Pro 体验已就绪，重新打开 App 即可领取",
                     "3日間のPro体験の準備ができました。アプリを開き直すと受け取れます",
                     "3일 Pro 체험 준비 완료 — 앱을 다시 열면 받을 수 있어요",
                     vi: "Đã sẵn sàng dùng thử Pro 3 ngày — mở lại ứng dụng để nhận",
                     id: "Trial Pro 3 hari siap — buka ulang aplikasi untuk klaim",
                     pt: "Teste Pro de 3 dias pronto — reabra o app para resgatar")
    }
    private var promoActiveLabel: String {
        sectionTitle("Pro Trial Active", "Pro 体验进行中", "Proトライアル中", "프로 체험 중",
                     vi: "Đang dùng thử Pro", id: "Trial Pro Aktif", pt: "Teste Pro Ativo")
    }
    private func promoUntilText(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        let ds = fmt.string(from: date)
        return sectionTitle("Until \(ds)", "至 \(ds)", "\(ds)まで", "\(ds)까지",
                            vi: "Đến \(ds)", id: "Hingga \(ds)", pt: "Até \(ds)")
    }
    private var referralTermsLabel: String {
        sectionTitle("Campaign Terms", "活动规则", "キャンペーン規約", "캠페인 약관",
                     vi: "Điều khoản Chương trình", id: "Ketentuan Kampanye", pt: "Termos da Campanha")
    }

    // MARK: - Referral Strings & Actions

    private var inviteLabel:       String { sectionTitle("Invite Friends", "邀请好友", "友達を招待", "친구 초대", vi: "Mời bạn bè", id: "Undang Teman", pt: "Convidar Amigos") }
    private var codeLabel:         String { sectionTitle("Code", "邀请码", "コード", "코드", vi: "Mã", id: "Kode", pt: "Código") }
    private var bonusLabel:        String { sectionTitle("Bonus Generations", "奖励次数", "ボーナス回数", "보너스 횟수", vi: "Lượt thưởng", id: "Bonus", pt: "Gerações Bônus") }
    private var redeemPlaceholder: String { sectionTitle("Enter code", "输入邀请码", "コードを入力", "코드 입력", vi: "Nhập mã", id: "Masukkan kode", pt: "Inserir código") }
    private var redeemLabel:       String { sectionTitle("Redeem", "兑换", "引き換え", "사용", vi: "Đổi", id: "Tukar", pt: "Resgatar") }
    private var referralFooter:    String {
        sectionTitle(
            "Share your code with friends. You both get 3 free Pro generations when they redeem it.",
            "分享邀请码给朋友，双方各得 3 次 Pro 品质生成。",
            "友達にコードをシェア。引き換えると双方に3回の無料Pro生成が付与されます。",
            "친구에게 코드를 공유하세요. 사용 시 양쪽 모두 3회 Pro 생성을 받습니다.",
            vi: "Chia sẻ mã cho bạn bè. Cả hai nhận 3 lần tạo ảnh Pro miễn phí.",
            id: "Bagikan kode ke teman. Keduanya dapat 3 kali generasi Pro gratis.",
            pt: "Compartilhe seu código. Ambos ganham 3 gerações Pro grátis."
        )
    }

    private func shareReferralCode() {
        guard referralManager.referralCode != nil else { return }
        let message = referralManager.shareMessage(language: AppLanguage(rawValue: lang) ?? .english)
        AnalyticsManager.shared.track(AnalyticsManager.Event.referralShareTapped, properties: ["source": "settings"])
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.keyWindow?.rootViewController {
            let ac = UIActivityViewController(activityItems: [message], applicationActivities: nil)
            if let popover = ac.popoverPresentationController {
                popover.sourceView = root.view
                popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
            }
            root.present(ac, animated: true)
        }
    }

    private func redeemCode() async {
        isRedeeming = true
        defer { isRedeeming = false }
        let success = await referralManager.redeemCode(redeemCodeInput)
        if success {
            redeemCodeInput = ""
            showRedeemSuccess = true
        }
    }
}

// MARK: - Legal URLs

private enum LegalURLs {
    static let baseURL = "https://nexus-wei.space/aiidphoto"

    static func privacyPolicy(lang: String) -> URL {
        URL(string: "\(baseURL)/privacy/\(legalLang(lang)).html")!
    }
    static func termsOfService(lang: String) -> URL {
        URL(string: "\(baseURL)/terms/\(legalLang(lang)).html")!
    }
    static func referralTerms(lang: String) -> URL {
        // Pages authored at ../nexus-wei.space/aiidphoto/referral-terms/{lang}.html (7 langs).
        // Live only after the nexus-wei-site Cloud Run service is redeployed.
        URL(string: "\(baseURL)/referral-terms/\(legalLang(lang)).html")!
    }

    private static func legalLang(_ code: String) -> String {
        ["zh", "ja", "ko", "vi", "id", "pt"].contains(code) ? code : "en"
    }
}
