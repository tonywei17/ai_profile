import SwiftUI

struct SubscriptionSheetView: View {
    @EnvironmentObject var subscription: SubscriptionManager
    @EnvironmentObject var langManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var crownPulse = false

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
        default:   return en
        }
    }

    private var heroTitleFont: Font {
        lang == "en"
            ? .custom("PlusJakartaSans-Bold", size: 28)
            : .system(size: 28, weight: .bold, design: .rounded)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            GlassBackground.gradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    heroSection
                    benefitsCard
                    planSelector
                    ctaButton
                    socialProof
                    footerSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 52)
                .padding(.bottom, 32)
            }

            // Close button
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.callout.bold())
                    .padding(10)
            }
            .glassEffect(.regular.interactive(), in: .circle)
            .padding(16)
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

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hue: 0.12, saturation: 0.9, brightness: 1.0),
                                 Color(hue: 0.07, saturation: 1.0, brightness: 0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(crownPulse ? 1.08 : 1.0)
                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: crownPulse)
                .onAppear { crownPulse = true }
                .shadow(color: .orange.opacity(0.4), radius: 16, y: 6)

            Text(heroTitle)
                .font(heroTitleFont)
                .foregroundStyle(GlassBackground.titleGradient(for: colorScheme))

            Text(heroSubtitle)
                .font(.subheadline.weight(.light))
                .italic()
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Benefits

    private var benefitsCard: some View {
        VStack(spacing: 0) {
            benefitRow(icon: "nosign",              color: .red,
                       title: l("纯净无广告体验",    "No Ads, Ever",           "広告なし",         "광고 없음",
                                vi: "Không quảng cáo", id: "Tanpa Iklan", pt: "Sem Anúncios"),
                       desc:  l("专注生成，不受打扰", "Create without interruption", "邪魔なく生成に集中", "방해 없이 생성에 집중",
                                vi: "Tạo ảnh không bị gián đoạn", id: "Buat tanpa gangguan", pt: "Crie sem interrupção"))
            Divider().padding(.leading, 56)
            benefitRow(icon: "bolt.fill",           color: .yellow,
                       title: l("每天20次随拍随用",  "20 Generations / Day",   "1日20回生成",      "하루 20회 생성",
                                vi: "20 lần/ngày", id: "20 Kali/Hari", pt: "20 Gerações/Dia"),
                       desc:  l("证件照自由，再也不用排队", "No more waiting in line", "もう列に並ばなくていい", "더 이상 줄 서지 않아도 됩니다",
                                vi: "Tự do tạo ảnh thẻ, không cần xếp hàng", id: "Tak perlu antre lagi", pt: "Sem mais filas"))
            Divider().padding(.leading, 56)
            benefitRow(icon: "doc.text.image.fill", color: .blue,
                       title: l("10种规格一键覆盖",  "10 Global Formats",      "10種類の規格対応",  "10가지 규격 지원",
                                vi: "10 quy cách toàn cầu", id: "10 Format Global", pt: "10 Formatos Globais"),
                       desc:  l("身份证、护照、签证全搞定", "ID, Passport, Visa & more", "身分証・旅券・ビザなど", "신분증・여권・비자 등",
                                vi: "Thẻ, hộ chiếu, visa và nhiều hơn", id: "KTP, Paspor, Visa & lainnya", pt: "RG, Passaporte, Visto e mais"))
            Divider().padding(.leading, 56)
            benefitRow(icon: "slider.horizontal.3", color: .indigo,
                       title: l("专业自定义选项",    "Pro Customization",      "プロカスタマイズ",  "프로 커스터마이징",
                                vi: "Tùy chỉnh Pro", id: "Kustomisasi Pro", pt: "Personalização Pro"),
                       desc:  l("美颜、换装、背景色等高级选项", "Beauty, attire, background & more", "美肌・服装・背景色など", "뷰티・복장・배경색 등",
                                vi: "Làm đẹp, trang phục, nền và hơn thế", id: "Kecantikan, pakaian, latar & lainnya", pt: "Beleza, traje, fundo e mais"))
            Divider().padding(.leading, 56)
            benefitRow(icon: "printer.fill",         color: .cyan,
                       title: l("便利店排版打印",    "Konbini Print Layout",   "コンビニプリント",     "편의점 인쇄 레이아웃",
                                vi: "In ảnh tại cửa hàng", id: "Cetak di Konbini", pt: "Impressão em Loja"),
                       desc:  l("一键排版，到便利店直接打印", "Print-ready layout for convenience stores", "レイアウト写真を一発生成、コンビニで印刷", "편의점에서 바로 인쇄 가능",
                                vi: "Tạo bố cục, in tại cửa hàng tiện lợi", id: "Layout siap cetak untuk toko serba ada", pt: "Layout pronto para lojas de conveniência"))
            Divider().padding(.leading, 56)
            benefitRow(icon: "sparkles",            color: .purple,
                       title: l("新功能优先体验",    "Priority New Features",  "新機能を優先体験",  "신기능 우선 체험",
                                vi: "Ưu tiên tính năng mới", id: "Fitur Baru Prioritas", pt: "Novidades em Primeira Mão"),
                       desc:  l("抢先享受每次重大更新", "First access to every major update", "毎回の大型アップデートを先取り", "모든 주요 업데이트를 먼저",
                                vi: "Trải nghiệm sớm mỗi cập nhật lớn", id: "Akses pertama ke setiap update besar", pt: "Primeiro acesso a cada grande atualização"))
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    private func benefitRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout.bold())
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark")
                .font(.caption.bold())
                .foregroundStyle(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Plan Selector

    private var planSelector: some View {
        VStack(spacing: 12) {
            planCard(
                plan: .annual,
                title: annualPlanTitle,
                price: subscription.annualDisplayPrice ?? "---",
                period: perYearLabel,
                badge: saveBadgeLabel,
                footnote: annualFootnote
            )
            planCard(
                plan: .monthly,
                title: monthlyPlanTitle,
                price: subscription.monthlyDisplayPrice ?? "---",
                period: perMonthLabel,
                badge: nil,
                footnote: monthlyFootnote
            )
        }
    }

    private func planCard(plan: SubscriptionPlan, title: String, price: String,
                          period: String, badge: String?, footnote: String) -> some View {
        let isSelected = subscription.selectedPlan == plan

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                subscription.selectedPlan = plan
            }
        } label: {
            HStack(spacing: 14) {
                // Radio indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .secondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.callout.bold())
                    Text(footnote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let badge {
                        Text(badge)
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange.gradient)
                            .clipShape(Capsule())
                    }
                    Text(price)
                        .font(.system(size: 20, weight: .bold))
                    Text(period)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .glassEffect(
            isSelected ? .regular.tint(.blue.opacity(0.15)) : .regular,
            in: .rect(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isSelected ? Color.blue.opacity(0.6) : Color.clear, lineWidth: 2)
        )
    }

    // MARK: - CTA

    private var ctaButton: some View {
        Button {
            Task { await subscription.purchase() }
        } label: {
            Group {
                if subscription.isPurchasing {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.1)
                        .padding(.vertical, 6)
                } else {
                    VStack(spacing: 4) {
                        Text(ctaTitleNoTrial)
                            .font(.headline)
                        Text(ctaSubtitleNoTrial)
                            .font(.caption)
                            .opacity(0.85)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
        }
        .disabled(subscription.isPurchasing)
        .glassEffect(.regular.tint(.blue).interactive(), in: .rect(cornerRadius: 16))
    }

    // MARK: - Social Proof

    private var socialProof: some View {
        HStack(spacing: 6) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption2)
                }
            }
            Text(socialProofLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 12) {
            Button { Task { await subscription.restore() } } label: {
                Text(restoreLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text(legalNote)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            LegalLinksView()
        }
    }

    // MARK: - Localized Strings

    private var heroTitle:      String { l("解锁专业版",             "Unlock Pro",                    "プロ版を解除",           "프로 잠금 해제",
                                           vi: "Mở khóa Pro", id: "Buka Pro", pt: "Desbloquear Pro") }
    private var heroSubtitle:   String { l("让每一张证件照都完美无瑕", "Perfect ID photos, every time", "すべての証明写真を完璧に", "모든 증명사진을 완벽하게",
                                           vi: "Mọi ảnh thẻ đều hoàn hảo", id: "Foto ID sempurna, setiap saat", pt: "Fotos perfeitas, sempre") }

    // Plan titles
    private var annualPlanTitle:  String { l("年付方案", "Annual Plan",  "年間プラン", "연간 플랜",
                                            vi: "Gói Năm", id: "Paket Tahunan", pt: "Plano Anual") }
    private var monthlyPlanTitle: String { l("月付方案", "Monthly Plan", "月額プラン", "월간 플랜",
                                            vi: "Gói Tháng", id: "Paket Bulanan", pt: "Plano Mensal") }

    // Period labels
    private var perYearLabel:   String { l("/ 年",  "/ yr",    "/ 年",  "/ 년",
                                          vi: "/ năm", id: "/ thn", pt: "/ ano") }
    private var perMonthLabel:  String { l("/ 月",  "/ mo",    "/ 月",  "/ 월",
                                          vi: "/ tháng", id: "/ bln", pt: "/ mês") }

    // Badge & footnotes
    private var saveBadgeLabel: String { l("省46%", "Save 46%", "46%お得", "46% 절약",
                                          vi: "Tiết kiệm 46%", id: "Hemat 46%", pt: "Economize 46%") }
    private var annualFootnote: String { l("按年计费，随时可取消",
                                           "Billed annually. Cancel anytime.",
                                           "年間課金。いつでもキャンセル可。",
                                           "연간 결제. 언제든지 취소 가능.",
                                           vi: "Thanh toán hàng năm. Hủy bất cứ lúc nào.",
                                           id: "Ditagih per tahun. Batalkan kapan saja.",
                                           pt: "Cobrado anualmente. Cancele a qualquer momento.") }
    private var monthlyFootnote: String { l("按月计费，灵活订阅",
                                            "Billed monthly. Flexible plan.",
                                            "月額課金。柔軟なプラン。",
                                            "월간 결제. 유연한 플랜.",
                                            vi: "Thanh toán hàng tháng. Linh hoạt.",
                                            id: "Ditagih per bulan. Fleksibel.",
                                            pt: "Cobrado mensalmente. Flexível.") }

    // CTA
    private var ctaTitleNoTrial:    String { l("立即订阅", "Subscribe Now", "今すぐ購読", "지금 구독",
                                               vi: "Đăng ký ngay", id: "Langganan Sekarang", pt: "Assinar Agora") }
    private var ctaSubtitleNoTrial: String {
        subscription.selectedPlan == .annual
            ? l("按年计费，随时取消",
                "Billed annually. Cancel anytime.",
                "年間課金。いつでもキャンセル可。",
                "연간 결제. 언제든지 취소 가능.",
                vi: "Thanh toán hàng năm. Hủy bất cứ lúc nào.",
                id: "Ditagih per tahun. Batalkan kapan saja.",
                pt: "Cobrado anualmente. Cancele a qualquer momento.")
            : l("按月计费，随时取消",
                "Billed monthly. Cancel anytime.",
                "月額課金。いつでもキャンセル可。",
                "월간 결제. 언제든지 취소 가능.",
                vi: "Thanh toán hàng tháng. Hủy bất cứ lúc nào.",
                id: "Ditagih per bulan. Batalkan kapan saja.",
                pt: "Cobrado mensalmente. Cancele a qualquer momento.")
    }
    private var socialProofLabel: String { l("10,000+ 用户信赖", "Trusted by 10,000+ users", "10,000人以上が信頼", "10,000명 이상이 신뢰",
                                            vi: "Được 10.000+ người tin dùng", id: "Dipercaya 10.000+ pengguna", pt: "Confiado por 10.000+ usuários") }
    private var restoreLabel:   String { l("恢复购买", "Restore Purchases", "購入を復元", "구매 복원",
                                           vi: "Khôi phục mua hàng", id: "Pulihkan Pembelian", pt: "Restaurar Compras") }
    private var legalNote:      String { l("订阅将自动续期，可随时在 iPhone 设置 › App Store 中取消。",
                                           "Subscription auto-renews. Cancel in iPhone Settings › App Store.",
                                           "サブスクリプションは自動更新されます。iPhone設定 › App Storeでキャンセル可。",
                                           "구독이 자동 갱신됩니다. iPhone 설정 › App Store에서 취소하세요.",
                                           vi: "Đăng ký tự động gia hạn. Hủy trong Cài đặt iPhone › App Store.",
                                           id: "Langganan diperpanjang otomatis. Batalkan di Pengaturan iPhone › App Store.",
                                           pt: "Assinatura renovada automaticamente. Cancele em Ajustes iPhone › App Store.") }
    private var errorAlertTitle: String { l("购买失败", "Purchase Failed", "購入に失敗しました", "구매 실패",
                                           vi: "Mua thất bại", id: "Pembelian Gagal", pt: "Compra Falhou") }
    private var okLabel:         String { l("好的", "OK", "OK", "확인",
                                           vi: "OK", id: "OK", pt: "OK") }
}

// MARK: - Legal Links

// TODO: 替换为正式的隐私政策和服务条款 URL
private enum LegalURLs {
    static let privacyPolicy  = URL(string: "https://example.com/privacy")!
    static let termsOfService = URL(string: "https://example.com/terms")!
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
        default:   return "Privacy Policy"
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
        default:   return "Terms of Service"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            Link(privacyLabel, destination: LegalURLs.privacyPolicy)
            Text("·").foregroundStyle(.secondary)
            Link(termsLabel, destination: LegalURLs.termsOfService)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}
