import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var langManager: LanguageManager
    @Binding var hasSeenOnboarding: Bool
    @Environment(\.colorScheme) private var colorScheme

    @State private var currentPage = 0

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

    private var titleFont: Font {
        lang == "en"
            ? .custom("PlusJakartaSans-Bold", size: 28)
            : .system(size: 28, weight: .bold, design: .rounded)
    }

    private let pages: [(icon: String, color: Color)] = [
        ("wand.and.stars", .blue),
        ("doc.text.image.fill", .purple),
        ("printer.fill", .cyan),
    ]

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(0..<3, id: \.self) { index in
                        featurePage(index: index).tag(index)
                    }
                    getStartedPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                if currentPage < 3 {
                    skipButton
                }
            }
        }
    }

    // MARK: - Feature Page

    private func featurePage(index: Int) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: pages[index].icon)
                .font(.system(size: 80, weight: .thin))
                .foregroundStyle(pages[index].color.gradient)
                .shadow(color: pages[index].color.opacity(0.3), radius: 20, y: 8)

            Text(pageTitle(index))
                .font(titleFont)
                .foregroundStyle(Color.inkBlack)

            Text(pageSubtitle(index))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Get Started Page

    private var getStartedPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 80, weight: .thin))
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .purple],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .shadow(color: .purple.opacity(0.3), radius: 20, y: 8)

            Text(readyTitle)
                .font(titleFont)
                .foregroundStyle(Color.inkBlack)

            Text(readySubtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button {
                completeOnboarding()
            } label: {
                Text(startLabel)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(.white)
            }
            .background(Color.inkBlack)
            .padding(.horizontal, 24)

            Spacer()
                .frame(height: 60)
        }
    }

    // MARK: - Skip Button

    private var skipButton: some View {
        Button {
            completeOnboarding()
        } label: {
            Text(skipLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 16)
    }

    private func completeOnboarding() {
        AnalyticsManager.shared.track(AnalyticsManager.Event.onboardingComplete)
        hasSeenOnboarding = true
    }

    // MARK: - Localized Content

    private func pageTitle(_ index: Int) -> String {
        switch index {
        case 0: return l("AI 智能证件照", "AI-Powered ID Photos", "AI証明写真", "AI 증명사진",
                         vi: "Ảnh Thẻ AI", id: "Foto ID AI", pt: "Fotos com IA")
        case 1: return l("全球多种规格", "10+ Global Formats", "世界の10種類以上の規格", "10가지+ 글로벌 규격",
                         vi: "10+ Quy cách Toàn cầu", id: "10+ Format Global", pt: "10+ Formatos Globais")
        case 2: return l("排版即刻打印", "Print-Ready Layout", "コンビニプリント対応", "편의점 인쇄 레이아웃",
                         vi: "In ảnh Sẵn sàng", id: "Siap Cetak", pt: "Pronto para Impressão")
        default: return ""
        }
    }

    private func pageSubtitle(_ index: Int) -> String {
        switch index {
        case 0: return l("上传自拍或照片，AI 自动生成标准证件照\n支持美颜、换装、调整背景",
                         "Upload a selfie and AI generates a perfect ID photo.\nBeauty, attire, and background customization included.",
                         "自撮りをアップロードするだけで\nAIが美肌・服装・背景を調整した証明写真を生成",
                         "셀카를 업로드하면 AI가 완벽한 증명사진을 생성\n뷰티, 복장, 배경 커스터마이징 포함",
                         vi: "Tải ảnh selfie lên, AI tạo ảnh thẻ hoàn hảo.\nLàm đẹp, trang phục và nền tùy chỉnh.",
                         id: "Unggah selfie, AI buat foto ID sempurna.\nKecantikan, pakaian, dan latar bisa disesuaikan.",
                         pt: "Envie uma selfie e a IA gera uma foto perfeita.\nBeleza, traje e fundo personalizáveis.")
        case 1: return l("覆盖中国、日本、韩国、美国等国家\n身份证、护照、签证、履历照片一键搞定",
                         "Covers China, Japan, Korea, US, and more.\nID card, passport, visa, resume — all in one tap.",
                         "中国・日本・韓国・米国など対応\n身分証・パスポート・ビザ・履歴書写真をワンタップで",
                         "중국, 일본, 한국, 미국 등 지원\n신분증, 여권, 비자, 이력서 사진을 한 번에",
                         vi: "Hỗ trợ Trung Quốc, Nhật, Hàn, Mỹ và hơn.\nThẻ, hộ chiếu, visa, hồ sơ — chỉ một chạm.",
                         id: "Mendukung China, Jepang, Korea, AS, dll.\nKTP, paspor, visa, resume — satu ketukan.",
                         pt: "Cobre China, Japão, Coreia, EUA e mais.\nRG, passaporte, visto, currículo — em um toque.")
        case 2: return l("自动排版为 L判/2L判 尺寸\n保存后直接到便利店打印，省时省钱",
                         "Auto-layout for L-size / 2L-size paper.\nSave and print at any convenience store.",
                         "L判・2Lサイズに自動レイアウト\n保存してコンビニで直接印刷、時間もお金も節約",
                         "L판/2L판 자동 레이아웃\n저장 후 편의점에서 바로 인쇄, 시간과 비용 절약",
                         vi: "Tự động bố trí cho khổ L / 2L.\nLưu và in tại cửa hàng tiện lợi.",
                         id: "Tata letak otomatis ukuran L / 2L.\nSimpan dan cetak di toko serba ada.",
                         pt: "Layout automático para papel L / 2L.\nSalve e imprima na loja de conveniência.")
        default: return ""
        }
    }

    private var readyTitle: String {
        l("准备好了吗？", "Ready to Start?", "準備はいいですか？", "시작할 준비가 되셨나요?",
          vi: "Sẵn sàng chưa?", id: "Siap Mulai?", pt: "Pronto para Começar?")
    }

    private var readySubtitle: String {
        l("首次生成完全免费，无需注册",
          "Your first generation is completely free. No sign-up required.",
          "初回生成は完全無料、登録不要",
          "첫 생성은 완전 무료, 가입 필요 없음",
          vi: "Lần đầu hoàn toàn miễn phí. Không cần đăng ký.",
          id: "Generasi pertama gratis. Tanpa daftar.",
          pt: "A primeira geração é grátis. Sem cadastro.")
    }

    private var startLabel: String {
        l("免费开始", "Start Free", "無料で始める", "무료로 시작",
          vi: "Bắt đầu Miễn phí", id: "Mulai Gratis", pt: "Começar Grátis")
    }

    private var skipLabel: String {
        l("跳过", "Skip", "スキップ", "건너뛰기",
          vi: "Bỏ qua", id: "Lewati", pt: "Pular")
    }
}
