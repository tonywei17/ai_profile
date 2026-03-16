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
                    comparisonBanner
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

    // MARK: - Price Comparison Banner (Loss Aversion)

    private var comparisonBanner: some View {
        VStack(spacing: 8) {
            Text(comparisonTitle)
                .font(.caption.bold())
                .foregroundStyle(.orange)

            HStack(spacing: 0) {
                // Photo studio price (crossed out)
                VStack(spacing: 4) {
                    Image(systemName: "building.2.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text(studioLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(studioPrice)
                        .font(.callout.bold())
                        .strikethrough(color: .red)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Image(systemName: "arrow.right")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)

                // Our price
                VStack(spacing: 4) {
                    Image(systemName: "iphone")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    Text("AI ID Photo")
                        .font(.caption2.bold())
                        .foregroundStyle(.blue)
                    Text(ourMonthlyPrice)
                        .font(.callout.bold())
                        .foregroundStyle(.blue)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .glassEffect(.regular.tint(.orange.opacity(0.08)), in: .rect(cornerRadius: 16))
    }

    // MARK: - Benefits

    private var benefitsCard: some View {
        VStack(spacing: 0) {
            benefitRow(icon: "infinity",               color: .blue,
                       title: benefitUnlimitedTitle,
                       desc: benefitUnlimitedDesc)
            Divider().padding(.leading, 56)
            benefitRow(icon: "nosign",                 color: .red,
                       title: benefitNoAdsTitle,
                       desc: benefitNoAdsDesc)
            Divider().padding(.leading, 56)
            benefitRow(icon: "printer.fill",           color: .cyan,
                       title: benefitPrintTitle,
                       desc: benefitPrintDesc)
            Divider().padding(.leading, 56)
            benefitRow(icon: "doc.text.image.fill",    color: .indigo,
                       title: benefitFormatsTitle,
                       desc: benefitFormatsDesc)
            Divider().padding(.leading, 56)
            benefitRow(icon: "slider.horizontal.3",    color: .purple,
                       title: benefitProTitle,
                       desc: benefitProDesc)
            Divider().padding(.leading, 56)
            benefitRow(icon: "sparkles",               color: .orange,
                       title: benefitUpdatesTitle,
                       desc: benefitUpdatesDesc)
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
                        Text(ctaTitle)
                            .font(.headline)
                        Text(ctaSubtitle)
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

    // Hero — emotional, benefit-focused
    private var heroTitle: String {
        l("告别排队，告别高价", "Pro ID Photos, Instantly", "もう写真館に行かなくていい", "사진관에 갈 필요 없어요",
          vi: "Không cần tiệm ảnh nữa", id: "Tak Perlu Studio Foto Lagi", pt: "Adeus, Estúdios Caros")
    }
    private var heroSubtitle: String {
        l("手机上3秒搞定，省时省钱", "Professional results in 3 seconds from your phone", "スマホで3秒、プロ品質の証明写真", "스마트폰에서 3초, 전문가 퀄리티",
          vi: "3 giây trên điện thoại, chất lượng chuyên nghiệp", id: "3 detik dari HP, kualitas profesional", pt: "3 segundos no celular, qualidade profissional")
    }

    // Price comparison banner
    private var comparisonTitle: String {
        l("比照相馆便宜 95%", "95% Cheaper Than Photo Studios", "写真館より95%お得", "사진관보다 95% 저렴",
          vi: "Rẻ hơn 95% so với tiệm ảnh", id: "95% Lebih Murah dari Studio", pt: "95% Mais Barato que Estúdios")
    }
    private var studioLabel: String {
        l("照相馆", "Photo Studio", "写真館", "사진관",
          vi: "Tiệm ảnh", id: "Studio Foto", pt: "Estúdio")
    }
    private var studioPrice: String {
        switch lang {
        case "ja": return "¥1,500〜3,000 JPY"
        case "ko": return "₩15,000〜35,000 KRW"
        case "zh": return "¥25〜80 CNY"
        case "vi": return "50,000〜150,000 VND"
        case "id": return "Rp25,000〜75,000 IDR"
        case "pt": return "R$20〜60 BRL"
        default:   return "$7〜17 USD"
        }
    }
    private var ourMonthlyPrice: String {
        subscription.monthlyDisplayPrice ?? "---"
    }

    // Benefits — action-oriented descriptions
    private var benefitUnlimitedTitle: String {
        l("无限次生成",  "Unlimited Generations",  "無制限生成",    "무제한 생성",
          vi: "Tạo không giới hạn", id: "Tanpa Batas", pt: "Gerações Ilimitadas")
    }
    private var benefitUnlimitedDesc: String {
        l("不满意就重新生成，直到完美为止",
          "Regenerate until it's perfect — no limits",
          "納得いくまで何度でも再生成、制限なし",
          "만족할 때까지 무제한 재생성",
          vi: "Tạo lại đến khi hoàn hảo — không giới hạn",
          id: "Ulangi sampai sempurna — tanpa batas",
          pt: "Regenere até ficar perfeito — sem limites")
    }
    private var benefitNoAdsTitle: String {
        l("无广告打扰",        "Zero Ads",               "広告完全なし",      "광고 제로",
          vi: "Không quảng cáo", id: "Tanpa Iklan", pt: "Sem Anúncios")
    }
    private var benefitNoAdsDesc: String {
        l("不用看30秒广告，一键生成",
          "Skip the 30-second ads — generate instantly",
          "30秒広告をスキップ、即座に生成",
          "30초 광고 건너뛰기, 즉시 생성",
          vi: "Bỏ qua QC 30 giây — tạo ảnh ngay",
          id: "Lewati iklan 30 detik — langsung buat",
          pt: "Pule anúncios de 30s — gere instantaneamente")
    }
    private var benefitPrintTitle: String {
        l("便利店排版打印", "Konbini Print Layout", "コンビニプリント", "편의점 인쇄 레이아웃",
          vi: "In ảnh tại cửa hàng", id: "Cetak di Konbini", pt: "Impressão em Loja")
    }
    private var benefitPrintDesc: String {
        l("300DPI排版照片，便利店直接打印",
          "300 DPI print-ready layout, print at any convenience store",
          "300DPIレイアウト写真、コンビニで即印刷",
          "300DPI 레이아웃, 편의점에서 바로 인쇄",
          vi: "Layout 300DPI, in tại cửa hàng tiện lợi",
          id: "Layout 300DPI, cetak di toko serba ada",
          pt: "Layout 300DPI, imprima em qualquer loja")
    }
    private var benefitFormatsTitle: String {
        l("10+国际规格", "10+ Global Formats", "10種類以上の国際規格", "10개 이상 국제 규격",
          vi: "10+ quy cách quốc tế", id: "10+ Format Internasional", pt: "10+ Formatos Internacionais")
    }
    private var benefitFormatsDesc: String {
        l("护照、签证、身份证等全部支持",
          "Passport, visa, national ID — all covered",
          "パスポート・ビザ・身分証すべて対応",
          "여권・비자・신분증 모두 지원",
          vi: "Hộ chiếu, visa, CCCD — tất cả đều có",
          id: "Paspor, visa, KTP — semua tersedia",
          pt: "Passaporte, visto, RG — tudo incluído")
    }
    private var benefitProTitle: String {
        l("专业自定义",      "Pro Customization",    "プロカスタマイズ",   "프로 커스터마이징",
          vi: "Tùy chỉnh Pro", id: "Kustomisasi Pro", pt: "Personalização Pro")
    }
    private var benefitProDesc: String {
        l("美颜、换装、自定义尺寸等高级选项",
          "Beauty, attire, custom size & more",
          "美肌・服装・カスタムサイズなどのプロ機能",
          "뷰티・복장・사용자 정의 크기 등 프로 기능",
          vi: "Làm đẹp, trang phục, kích thước tùy chỉnh",
          id: "Kecantikan, pakaian, ukuran kustom",
          pt: "Beleza, traje, tamanho personalizado")
    }
    private var benefitUpdatesTitle: String {
        l("新功能优先体验",  "Priority New Features", "新機能を優先体験",  "신기능 우선 체험",
          vi: "Ưu tiên tính năng mới", id: "Fitur Baru Prioritas", pt: "Novidades Primeiro")
    }
    private var benefitUpdatesDesc: String {
        l("抢先享受每次重大更新",
          "First access to every major update",
          "毎回の大型アップデートを先取り",
          "모든 주요 업데이트를 먼저 체험",
          vi: "Trải nghiệm sớm mỗi cập nhật lớn",
          id: "Akses pertama ke setiap update besar",
          pt: "Primeiro acesso a cada atualização")
    }

    // Plan titles
    private var annualPlanTitle: String {
        l("年付方案（最划算）", "Annual Plan (Best Value)", "年間プラン（最もお得）", "연간 플랜 (최고 혜택)",
          vi: "Gói Năm (Tiết kiệm nhất)", id: "Paket Tahunan (Paling Hemat)", pt: "Plano Anual (Melhor Valor)")
    }
    private var monthlyPlanTitle: String { l("月付方案", "Monthly Plan", "月額プラン", "월간 플랜",
                                            vi: "Gói Tháng", id: "Paket Bulanan", pt: "Plano Mensal") }

    // Period labels
    private var perYearLabel:  String { l("/ 年",  "/ yr",    "/ 年",  "/ 년",
                                          vi: "/ năm", id: "/ thn", pt: "/ ano") }
    private var perMonthLabel: String { l("/ 月",  "/ mo",    "/ 月",  "/ 월",
                                          vi: "/ tháng", id: "/ bln", pt: "/ mês") }

    // Badge & footnotes
    private var saveBadgeLabel: String { l("省50%", "Save 50%", "50%お得", "50% 절약",
                                          vi: "Tiết kiệm 50%", id: "Hemat 50%", pt: "Economize 50%") }
    private var annualFootnote: String {
        l("按年计费 · 相当于每月不到一杯咖啡",
          "Billed annually · Less than a coffee per month",
          "年間課金 · 月あたりコーヒー1杯以下",
          "연간 결제 · 월 커피 한 잔도 안 되는 가격",
          vi: "Thanh toán hàng năm · Rẻ hơn 1 ly cà phê/tháng",
          id: "Ditagih per tahun · Kurang dari 1 kopi/bulan",
          pt: "Cobrado anualmente · Menos que 1 café/mês")
    }
    private var monthlyFootnote: String {
        l("按月计费 · 灵活订阅，随时取消",
          "Billed monthly · Flexible, cancel anytime",
          "月額課金 · いつでもキャンセル可",
          "월간 결제 · 유연하게, 언제든 취소",
          vi: "Thanh toán hàng tháng · Linh hoạt, hủy bất cứ lúc nào",
          id: "Ditagih per bulan · Fleksibel, batalkan kapan saja",
          pt: "Cobrado mensalmente · Flexível, cancele quando quiser")
    }

    // CTA — urgency + confidence
    private var ctaTitle: String {
        l("立即解锁全部功能", "Unlock All Features Now", "今すぐ全機能を解除", "지금 모든 기능 잠금 해제",
          vi: "Mở khóa tất cả ngay", id: "Buka Semua Fitur Sekarang", pt: "Desbloquear Tudo Agora")
    }
    private var ctaSubtitle: String {
        l("随时可取消，无风险",
          "Cancel anytime — risk free",
          "いつでもキャンセル可・リスクなし",
          "언제든 취소 가능 · 위험 없음",
          vi: "Hủy bất cứ lúc nào — không rủi ro",
          id: "Batalkan kapan saja — tanpa risiko",
          pt: "Cancele a qualquer momento — sem risco")
    }

    private var socialProofLabel: String { l("10,000+ 用户信赖", "Trusted by 10,000+ users", "10,000人以上が信頼", "10,000명 이상이 신뢰",
                                            vi: "Được 10.000+ người tin dùng", id: "Dipercaya 10.000+ pengguna", pt: "Confiado por 10.000+ usuários") }
    private var restoreLabel:   String { l("恢复购买", "Restore Purchases", "購入を復元", "구매 복원",
                                           vi: "Khôi phục mua hàng", id: "Pulihkan Pembelian", pt: "Restaurar Compras") }
    private var legalNote:      String { l("订阅将自动续期，可随时在 iPhone 设置 › App Store 中取消。",
                                           "Subscription auto-renews. Cancel in iPhone Settings > App Store.",
                                           "サブスクリプションは自動更新されます。iPhone設定 > App Storeでキャンセル可。",
                                           "구독이 자동 갱신됩니다. iPhone 설정 > App Store에서 취소하세요.",
                                           vi: "Đăng ký tự động gia hạn. Hủy trong Cài đặt iPhone > App Store.",
                                           id: "Langganan diperpanjang otomatis. Batalkan di Pengaturan iPhone > App Store.",
                                           pt: "Assinatura renovada automaticamente. Cancele em Ajustes iPhone > App Store.") }
    private var errorAlertTitle: String { l("购买失败", "Purchase Failed", "購入に失敗しました", "구매 실패",
                                           vi: "Mua thất bại", id: "Pembelian Gagal", pt: "Compra Falhou") }
    private var okLabel:         String { l("好的", "OK", "OK", "확인",
                                           vi: "OK", id: "OK", pt: "OK") }
}

// MARK: - Legal Links

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
            Link(privacyLabel, destination: LegalURLs.privacyPolicy(lang: lang))
            Text("·").foregroundStyle(.secondary)
            Link(termsLabel, destination: LegalURLs.termsOfService(lang: lang))
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}
