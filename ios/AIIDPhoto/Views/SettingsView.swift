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
            VStack(spacing: 0) {
                settingsHeader

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        settingsHero
                        photoTaskPanel
                        appearancePanel
                        languagePanel
                        referralPanel
                        servicePanel
                        legalPanel
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .background(Color(.systemBackground).ignoresSafeArea())
        }
        .sheet(isPresented: $showSubscriptionSheet) {
            SubscriptionSheetView()
                .environmentObject(subscription)
                .environmentObject(langManager)
                .presentationDetents([.large])
        }
        .alert(
            sectionTitle("Success!", "兑换成功！", "成功！", "성공!",
                         vi: "Thành công!", id: "Berhasil!", pt: "Sucesso!"),
            isPresented: $showRedeemSuccess
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(sectionTitle(
                "You got 3 bonus generations!",
                "获得 3 次奖励生成机会！",
                "3回のボーナス生成を獲得しました！",
                "보너스 생성 3회를 받았습니다!",
                vi: "Bạn nhận được 3 lần tạo ảnh thưởng!",
                id: "Anda mendapat 3 bonus generasi!",
                pt: "Você ganhou 3 gerações bônus!"
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

    // MARK: - Modern Settings Layout

    private var settingsHeader: some View {
        HStack(spacing: 10) {
            Text(navTitle)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.inkBlack)

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.branchGray)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text(sectionTitle("Close", "关闭", "閉じる", "닫기")))
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 10)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) { Color(.systemGray5).frame(height: 0.5) }
    }

    private var settingsHero: some View {
        ZStack(alignment: .trailing) {
            LinearGradient(
                colors: [Color.skyBlue, Color.skyBlueMid],
                startPoint: .leading,
                endPoint: .trailing
            )

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Text("光影形象馆")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Text(subscriptionStatusLabel)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(subscription.generationAttemptsLeft > 0 ? todayRemainingText : freeUserDesc)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(2)

                    Spacer()

                    Text("3次生成 · 高清下载 · 打印排版")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.18))
                        .clipShape(Capsule())
                }
                .padding(.leading, 18)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Rectangle().fill(.white.opacity(0.10))
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.white.opacity(0.36))
                }
                .frame(width: 116)
            }
        }
        .frame(height: 176)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var photoTaskPanel: some View {
        settingsSection(icon: "cart.fill", title: sectionTitle("Photo Task", "制作包", "制作分", "제작권", vi: "Gói ảnh", id: "Paket foto", pt: "Pacote")) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    iconTile(subscriptionStatusIcon, color: subscription.generationAttemptsLeft > 0 ? Color.treeGreen : Color.skyBlue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(subscriptionStatusLabel)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.inkBlack)
                        Text(subscription.generationAttemptsLeft > 0 ? todayRemainingText : freeUserDesc)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.branchGray)
                    }
                    Spacer()
                    Text("\(subscription.generationAttemptsLeft)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.skyBlue)
                        .monospacedDigit()
                }

                Button { showSubscriptionSheet = true } label: {
                    HStack(spacing: 6) {
                        Text(upgradeLabel)
                            .font(.system(size: 15, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [Color.skyBlue, Color.skyBlueMid],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                }
            }
        }
    }

    private var appearancePanel: some View {
        settingsSection(icon: "paintbrush.fill", title: sectionTitle("Appearance", "外观", "外観", "외관", vi: "Giao diện", id: "Tampilan", pt: "Aparência")) {
            VStack(spacing: 10) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    optionRow(
                        icon: mode.icon,
                        title: mode.displayName(language: lang),
                        selected: langManager.appearance == mode
                    ) {
                        withAnimation { langManager.appearance = mode }
                    }
                }
            }
        }
    }

    private var languagePanel: some View {
        settingsSection(icon: "globe", title: sectionTitle("Language", "语言", "言語", "언어", vi: "Ngôn ngữ", id: "Bahasa", pt: "Idioma")) {
            VStack(spacing: 10) {
                languageOption(.system)
                languageOption(.chineseSimplified)
                languageOption(.english)
                Text(footerNote)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.branchGray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var referralPanel: some View {
        settingsSection(icon: "gift.fill", title: inviteLabel) {
            VStack(spacing: 10) {
                Button { shareReferralCode() } label: {
                    actionRow(
                        icon: "person.2.fill",
                        title: inviteLabel,
                        subtitle: referralManager.referralCode.map { "\(codeLabel): \($0)" },
                        trailingIcon: "square.and.arrow.up"
                    )
                }

                if referralManager.bonusGenerations > 0 {
                    infoLine(icon: "sparkles", title: bonusLabel, value: "\(referralManager.bonusGenerations)")
                }

                HStack(spacing: 10) {
                    iconTile("ticket.fill", color: Color.skyBlue)
                    TextField(redeemPlaceholder, text: $redeemCodeInput)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.system(size: 14))
                    Button {
                        Task { await redeemCode() }
                    } label: {
                        if isRedeeming {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Text(redeemLabel)
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(redeemCodeInput.count < 4 ? Color(.systemGray3) : Color.skyBlue)
                    .clipShape(Capsule())
                    .disabled(redeemCodeInput.count < 4 || isRedeeming)
                }
                .padding(12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray5), lineWidth: 1))

                Text(referralFooter)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.branchGray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var servicePanel: some View {
        settingsSection(icon: "map.fill", title: sectionTitle("Service", "服务", "サービス", "서비스")) {
            VStack(spacing: 10) {
                infoLine(icon: "location.fill", title: regionLabel, value: lang == "zh" ? "中国大陆 CN" : "China CN")
                infoLine(icon: "info.circle.fill", title: versionLabel, value: appVersion)
            }
        }
    }

    private var legalPanel: some View {
        settingsSection(icon: "lock.shield.fill", title: sectionTitle("Legal", "法律", "法的情報", "법적 정보", vi: "Pháp lý", id: "Hukum", pt: "Legal")) {
            VStack(spacing: 10) {
                Link(destination: LegalURLs.privacyPolicy(lang: lang)) {
                    actionRow(icon: "hand.raised.fill", title: privacyLabel, subtitle: nil, trailingIcon: "arrow.up.right")
                }
                Link(destination: LegalURLs.termsOfService(lang: lang)) {
                    actionRow(icon: "doc.text.fill", title: termsLabel, subtitle: nil, trailingIcon: "arrow.up.right")
                }
            }
        }
    }

    private func settingsSection<Content: View>(icon: String, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.skyBlue)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.inkBlack)
            }
            content()
        }
        .padding(14)
        .background(Color(.systemGray6).opacity(0.62))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func optionRow(icon: String, title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                iconTile(icon, color: selected ? Color.skyBlue : Color.branchGray)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.inkBlack)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.skyBlue)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? Color.skyBlue.opacity(0.35) : Color(.systemGray5), lineWidth: 1))
        }
    }

    private func languageOption(_ option: AppLanguage) -> some View {
        Button {
            withAnimation { langManager.language = option }
        } label: {
            HStack(spacing: 12) {
                Text(option.flag)
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(Color.skyBlue.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text(option.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.inkBlack)
                Spacer()
                if langManager.language == option {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.skyBlue)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(langManager.language == option ? Color.skyBlue.opacity(0.35) : Color(.systemGray5), lineWidth: 1))
        }
    }

    private func actionRow(icon: String, title: String, subtitle: String?, trailingIcon: String) -> some View {
        HStack(spacing: 12) {
            iconTile(icon, color: Color.skyBlue)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.inkBlack)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.branchGray)
                }
            }
            Spacer()
            Image(systemName: trailingIcon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.branchGray)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray5), lineWidth: 1))
    }

    private func infoLine(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            iconTile(icon, color: Color.skyBlue)
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.inkBlack)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.branchGray)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray5), lineWidth: 1))
    }

    private func iconTile(_ icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.10))
                .frame(width: 44, height: 44)
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    // MARK: - Photo Task Rows

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
                if subscription.generationAttemptsLeft > 0 {
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
        subscription.generationAttemptsLeft > 0 ? "checkmark.seal.fill" : "cart"
    }

    private var subscriptionStatusColor: Color {
        subscription.generationAttemptsLeft > 0 ? .orange : .gray
    }

    private var subscriptionStatusLabel: String {
        subscription.generationAttemptsLeft > 0 ? subscribedLabel : notSubscribedLabel
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
            "App display language.",
            "应用界面语言。",
            "アプリの表示言語。",
            "앱 표시 언어입니다."
        )
    }
    private var regionLabel:  String { sectionTitle("Region", "服务地区", "地域", "지역") }
    private var versionLabel:      String { sectionTitle("Version", "版本", "バージョン", "버전", vi: "Phiên bản", id: "Versi", pt: "Versão") }
    private var privacyLabel:      String { sectionTitle("Privacy Policy", "隐私政策", "プライバシーポリシー", "개인정보 처리방침", vi: "Chính sách Bảo mật", id: "Kebijakan Privasi", pt: "Política de Privacidade") }
    private var termsLabel:        String { sectionTitle("Terms of Service", "服务条款", "利用規約", "이용약관", vi: "Điều khoản Dịch vụ", id: "Ketentuan Layanan", pt: "Termos de Serviço") }
    private var subscribedLabel:   String { sectionTitle("Photo Task Active", "制作包可用", "制作分あり", "제작권 사용 가능", vi: "Gói ảnh khả dụng", id: "Paket aktif", pt: "Pacote ativo") }
    private var notSubscribedLabel:String { sectionTitle("No Photo Task", "暂无制作包", "制作分なし", "제작권 없음", vi: "Chưa có gói ảnh", id: "Belum ada paket", pt: "Sem pacote") }
    private var upgradeLabel:      String { sectionTitle("Buy Photo Task", "购买制作包", "制作分を購入", "제작권 구매", vi: "Mua gói ảnh", id: "Beli paket foto", pt: "Comprar pacote") }
    private var manageLabel:       String { sectionTitle("Purchase History", "购买记录", "購入履歴", "구매 내역", vi: "Lịch sử mua", id: "Riwayat pembelian", pt: "Histórico") }
    private var restoreLabel:      String { sectionTitle("Sync Purchases", "同步购买", "購入を同期", "구매 동기화", vi: "Đồng bộ mua hàng", id: "Sinkronkan pembelian", pt: "Sincronizar compras") }
    private var freeUserDesc:      String { sectionTitle("Buy once for 3 AI attempts", "购买后获得 3 次 AI 生成机会", "購入後AI生成3回", "구매 후 AI 생성 3회", vi: "Mua một lần có 3 lượt", id: "Beli sekali untuk 3 kali", pt: "Compre para 3 tentativas") }
    private var todayRemainingText: String {
        let n = subscription.generationAttemptsLeft
        return sectionTitle("Attempts left: \(n)", "剩余生成：\(n) 次", "残り：\(n)回", "남은 횟수: \(n)회", vi: "Còn lại: \(n)", id: "Sisa: \(n)", pt: "Restantes: \(n)")
    }
    private var cancelledLabel: String {
        sectionTitle("Photo Task Used", "制作包已用完", "制作分を使用済み", "제작권 사용 완료",
                     vi: "Đã dùng hết gói", id: "Paket habis", pt: "Pacote usado")
    }
    private var resubscribeLabel: String {
        sectionTitle("Buy Another Task", "再买一个制作包", "もう一度購入", "제작권 추가 구매",
                     vi: "Mua thêm gói", id: "Beli lagi", pt: "Comprar outro")
    }
    private var resubscribeDesc: String {
        sectionTitle("Get 3 more attempts", "再获得 3 次生成机会", "さらに3回生成", "생성 3회 추가",
                     vi: "Thêm 3 lượt", id: "Tambah 3 kali", pt: "Mais 3 tentativas")
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

    // MARK: - Referral Strings & Actions

    private var inviteLabel:       String { sectionTitle("Invite Friends", "邀请好友", "友達を招待", "친구 초대", vi: "Mời bạn bè", id: "Undang Teman", pt: "Convidar Amigos") }
    private var codeLabel:         String { sectionTitle("Code", "邀请码", "コード", "코드", vi: "Mã", id: "Kode", pt: "Código") }
    private var bonusLabel:        String { sectionTitle("Bonus Generations", "奖励次数", "ボーナス回数", "보너스 횟수", vi: "Lượt thưởng", id: "Bonus", pt: "Gerações Bônus") }
    private var redeemPlaceholder: String { sectionTitle("Enter code", "输入邀请码", "コードを入力", "코드 입력", vi: "Nhập mã", id: "Masukkan kode", pt: "Inserir código") }
    private var redeemLabel:       String { sectionTitle("Redeem", "兑换", "引き換え", "사용", vi: "Đổi", id: "Tukar", pt: "Resgatar") }
    private var referralFooter:    String {
        sectionTitle(
            "Share your code with friends. You both get 3 bonus generations when they redeem it.",
            "分享邀请码给朋友，双方各得 3 次奖励生成机会。",
            "友達にコードをシェア。引き換えると双方に3回のボーナス生成が付与されます。",
            "친구에게 코드를 공유하세요. 사용 시 양쪽 모두 보너스 생성 3회를 받습니다.",
            vi: "Chia sẻ mã cho bạn bè. Cả hai nhận 3 lần tạo ảnh thưởng.",
            id: "Bagikan kode ke teman. Keduanya dapat 3 bonus generasi.",
            pt: "Compartilhe seu código. Ambos ganham 3 gerações bônus."
        )
    }

    private func shareReferralCode() {
        guard let code = referralManager.referralCode else { return }
        let message = sectionTitle(
            "用我的邀请码 \(code) 下载 AI ID Photo，我们都能获得 3 次奖励生成机会！",
            "Use my referral code \(code) on AI ID Photo — we both get 3 bonus generations!",
            "AI証明写真アプリで招待コード \(code) を使うと、お互いに3回のボーナス生成がもらえます！",
            "AI 증명사진 앱에서 추천 코드 \(code) 을 사용하면 서로 보너스 생성 3회를 받아요!",
            vi: "Dùng mã giới thiệu \(code) trên AI ID Photo — cả hai nhận 3 lần tạo ảnh thưởng!",
            id: "Gunakan kode referral \(code) di AI ID Photo — kita berdua dapat 3 bonus generasi!",
            pt: "Use o código \(code) no AI ID Photo — nós dois ganhamos 3 gerações bônus!"
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
    static let baseURL = "https://aiphoto-cn.foyli.cloud/legal"

    static func privacyPolicy(lang: String) -> URL {
        URL(string: "\(baseURL)/privacy/\(legalLang(lang)).html")!
    }
    static func termsOfService(lang: String) -> URL {
        URL(string: "\(baseURL)/terms/\(legalLang(lang)).html")!
    }

    private static func legalLang(_ code: String) -> String {
        // CN release legal pages are maintained in Simplified Chinese.
        return "zh"
    }
}
