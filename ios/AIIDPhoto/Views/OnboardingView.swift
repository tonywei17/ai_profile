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
        case 1: return l("覆盖中国常用规格", "Common China Formats", "中国規格対応", "중국 규격 지원")
        case 2: return l("打印店排版即刻打印", "Print-Ready Layout", "プリント用レイアウト", "인쇄 레이아웃")
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
        case 1: return l("身份证、一寸、二寸、护照、驾照、社保\n签证、简历、半身、全身照一键搞定",
                         "China ID, 1-inch, 2-inch, passport, driver license,\nresume, half/full body — all in one tap.",
                         "中国身分証・1寸・2寸・パスポート他に対応",
                         "중국 신분증·1촌·2촌·여권 등 지원")
        case 2: return l("自动排版为 5 寸 / 7 寸尺寸\n保存后到打印店直接打印，省时省钱",
                         "Auto-layout for 5R / 7R photo paper.\nSave and print at any photo print shop.",
                         "5R / 7R に自動レイアウト",
                         "5R / 7R 자동 레이아웃")
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
