import SwiftUI

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
                        sectionHeader(icon: "crown.fill", title: sectionTitle("Membership", "会员", "会員", "멤버십", vi: "Thành viên", id: "Keanggotaan", pt: "Assinatura"))
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
                        sectionHeader(icon: "paintbrush.fill", title: sectionTitle("Appearance", "外观", "外観", "외관", vi: "Giao diện", id: "Tampilan", pt: "Aparência"))
                    }
                    .listRowBackground(Color.primary.opacity(0.06))

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
                        sectionHeader(icon: "map", title: sectionTitle("Region / Spec Order", "地区 / 规格排序", "地域 / 規格順序", "지역 / 규격 순서", vi: "Vùng / Thứ tự quy cách", id: "Wilayah / Urutan Spek", pt: "Região / Ordem de Formato"))
                    } footer: {
                        Text(regionFooter).font(.caption)
                    }
                    .listRowBackground(Color.primary.opacity(0.06))

                    // MARK: App Info
                    Section {
                        infoRow(icon: "info.circle.fill", color: .blue,
                                label: versionLabel, value: appVersion)
                    } header: {
                        sectionHeader(icon: "info.circle", title: sectionTitle("App", "应用", "アプリ", "앱", vi: "Ứng dụng", id: "Aplikasi", pt: "Aplicativo"))
                    }
                    .listRowBackground(Color.primary.opacity(0.06))

                    // MARK: Referral
                    Section {
                        // Share referral code
                        Button { shareReferralCode() } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.2.fill")
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Color.green.gradient)
                                    .clipShape(RoundedRectangle(cornerRadius: 7))
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

                        // Bonus remaining
                        if referralManager.bonusGenerations > 0 {
                            HStack(spacing: 12) {
                                Image(systemName: "gift.fill")
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Color.purple.gradient)
                                    .clipShape(RoundedRectangle(cornerRadius: 7))
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
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.orange.gradient)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
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
                    } header: {
                        sectionHeader(icon: "gift", title: sectionTitle("Invite Friends", "邀请好友", "友達を招待", "친구 초대", vi: "Mời bạn bè", id: "Undang Teman", pt: "Convidar Amigos"))
                    } footer: {
                        Text(referralFooter).font(.caption)
                    }
                    .listRowBackground(Color.primary.opacity(0.06))

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
    private var freeUserDesc:      String { sectionTitle("First gen free, then watch a 30s ad", "首次免费，此后需观看30秒广告", "初回無料、次回から30秒広告視聴", "첫 생성 무료, 이후 30초 광고", vi: "Lần đầu miễn phí, sau đó xem QC 30 giây", id: "Pertama gratis, lalu tonton iklan 30 detik", pt: "1ª grátis, depois assista anúncio de 30s") }
    private var todayRemainingText: String {
        let n = usage.subscriberUsesLeft
        return sectionTitle("Today's remaining: \(n)", "今日剩余：\(n) 次", "本日残り：\(n)回", "오늘 남은 횟수: \(n)회", vi: "Còn lại hôm nay: \(n)", id: "Sisa hari ini: \(n)", pt: "Restantes hoje: \(n)")
    }
    private func expiryText(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        let ds = fmt.string(from: date)
        return sectionTitle("Renews \(ds)", "续期日期：\(ds)", "更新日：\(ds)", "갱신일: \(ds)", vi: "Gia hạn \(ds)", id: "Perpanjang \(ds)", pt: "Renova \(ds)")
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
        guard let code = referralManager.referralCode else { return }
        let message = sectionTitle(
            "用我的邀请码 \(code) 下载 AI ID Photo，我们都能获得 3 次免费 Pro 生成！",
            "Use my referral code \(code) on AI ID Photo — we both get 3 free Pro generations!",
            "AI証明写真アプリで招待コード \(code) を使うと、お互いに3回無料Pro生成がもらえます！",
            "AI 증명사진 앱에서 추천 코드 \(code) 을 사용하면 서로 3회 Pro 생성을 받아요!",
            vi: "Dùng mã giới thiệu \(code) trên AI ID Photo — cả hai nhận 3 lần Pro miễn phí!",
            id: "Gunakan kode referral \(code) di AI ID Photo — kita berdua dapat 3 kali gratis!",
            pt: "Use o código \(code) no AI ID Photo — nós dois ganhamos 3 gerações Pro grátis!"
        )
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

    private static func legalLang(_ code: String) -> String {
        ["zh", "ja", "ko", "vi", "id", "pt"].contains(code) ? code : "en"
    }
}
