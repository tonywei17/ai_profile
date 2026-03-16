import SwiftUI
import PhotosUI
import StoreKit

struct ContentView: View {
    @EnvironmentObject var subscription: SubscriptionManager
    @EnvironmentObject var usage: UsageManager
    @EnvironmentObject var adManager: AdManager
    @EnvironmentObject var langManager: LanguageManager
    @EnvironmentObject var historyManager: HistoryManager
    @EnvironmentObject var referralManager: ReferralManager

    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.colorScheme) private var colorScheme

    /// Resolved color scheme for sheets: never nil.
    /// When "Follow System", uses the environment's actual colorScheme (set by the system).
    private var sheetColorScheme: ColorScheme {
        langManager.appearance.colorScheme ?? colorScheme
    }

    // Locale-sorted spec list — computed once per locale
    private var sortedSpecs: [IDPhotoSpec] { IDPhotoSpec.sorted(for: Locale.current) }
    private var lang: String { langManager.effectiveCode }

    /// English uses Plus Jakarta Sans; CJK falls back to system rounded for cultural fit.
    private var titleFont: Font {
        lang == "en"
            ? .custom("PlusJakartaSans-SemiBold", size: 34)
            : .system(size: 34, weight: .semibold, design: .rounded)
    }

    @State private var selectedItem: PhotosPickerItem?
    @State private var inputImage: UIImage?
    @State private var outputImage: UIImage?
    @State private var selectedSpec: IDPhotoSpec = IDPhotoSpec.defaultSpec(for: Locale.current)

    @State private var photoOptions = PhotoOptions.defaults
    @State private var isGenerating = false
    @State private var showSubscriptionSheet = false
    @State private var showSettingsSheet = false
    @State private var showCamera = false
    @State private var errorMessage: String?
    @State private var showSavedToast = false
    @State private var showPrintLayout = false
    @State private var isCustomSize = false
    @State private var customSize = CustomSizeSpec()
    @State private var showHistory = false

    // Review prompt tracking
    @AppStorage("successfulGenerations") private var successfulGenerations: Int = 0
    @AppStorage("lastReviewPromptVersion") private var lastReviewPromptVersion: String = ""

    // AI data sharing consent
    @AppStorage("hasGivenAIConsent") private var hasGivenAIConsent: Bool = false
    @State private var showAIConsent = false
    @State private var pendingGenerateAfterConsent = false

    var body: some View {
        ZStack {
            GlassBackground.gradient.ignoresSafeArea()
            mainLayout
        }
        .sheet(isPresented: $showSubscriptionSheet) {
            SubscriptionSheetView()
                .environmentObject(subscription)
                .environmentObject(langManager)
                .presentationDetents([.large])
                .preferredColorScheme(sheetColorScheme)
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView()
                .environmentObject(langManager)
                .environmentObject(subscription)
                .environmentObject(usage)
                .environmentObject(referralManager)
                .presentationDetents([.large])
                .preferredColorScheme(sheetColorScheme)
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $inputImage).ignoresSafeArea()
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
                .environmentObject(langManager)
                .environmentObject(historyManager)
                .presentationDetents([.large])
                .preferredColorScheme(sheetColorScheme)
        }
        .alert(errorTitle, isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(okLabel, role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .onChange(of: selectedSpec) { _ in
            photoOptions.background = .specDefault
            isCustomSize = false
        }
        .overlay(alignment: .bottom) {
            if showSavedToast { savedToast }
        }
        .fullScreenCover(isPresented: $showAIConsent) {
            AIConsentView(
                onAgree: {
                    hasGivenAIConsent = true
                    showAIConsent = false
                    if pendingGenerateAfterConsent {
                        pendingGenerateAfterConsent = false
                        Task { await generateTapped() }
                    }
                },
                onDecline: {
                    showAIConsent = false
                    pendingGenerateAfterConsent = false
                }
            )
            .environmentObject(langManager)
            .preferredColorScheme(sheetColorScheme)
        }
    }

    // MARK: - iPhone Layout

    private var mainLayout: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    headerView
                    SpecSelectorView(
                        selected: $selectedSpec,
                        isCustomSize: $isCustomSize,
                        specs: sortedSpecs,
                        language: lang,
                        isSubscribed: subscription.isSubscribed,
                        onLockedTap: { showSubscriptionSheet = true }
                    )
                    .padding(.horizontal, -16)
                    if isCustomSize {
                        CustomSizePickerView(customSize: $customSize, language: lang)
                    }
                    uploadCard
                    ProOptionsView(
                        options: $photoOptions,
                        isSubscribed: subscription.isSubscribed,
                        language: lang,
                        onLockedTap: { showSubscriptionSheet = true }
                    )
                    generateButton
                    usageInfoText
                    if outputImage != nil {
                        resultCard
                            .id("resultCard")
                    }
                    if !subscription.isSubscribed {
                        AdBannerViewWrapper().frame(height: 50)
                    }
                }
                .padding()
                .frame(maxWidth: sizeClass == .regular ? 600 : .infinity)
                .frame(maxWidth: .infinity) // center on wide screens
            }
            .onChange(of: outputImage) { newValue in
                if newValue != nil {
                    withAnimation {
                        proxy.scrollTo("resultCard", anchor: .top)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomToolbar
        }
    }

    // MARK: - Shared Subviews

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(appTitle)
                .font(titleFont)
                .foregroundStyle(GlassBackground.titleGradient(for: colorScheme))
            Text(subscription.isSubscribed ? memberSubtitle : freeSubtitle)
                .font(.subheadline.weight(.light))
                .italic()
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bottomToolbar: some View {
        HStack {
            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    // Settings
                    Button { showSettingsSheet = true } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .padding(16)
                    }
                    .glassEffect(.regular.interactive(), in: .circle)

                    // History
                    Button { showHistory = true } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3)
                            .padding(16)
                    }
                    .glassEffect(.regular.interactive(), in: .circle)

                    // Subscription
                    Button { showSubscriptionSheet = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.title3)
                                .foregroundStyle(
                                    LinearGradient(colors: [.yellow, .orange],
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing)
                                )
                            Text(subscription.isSubscribed ? subscribedLabel : memberLabel)
                                .font(.body.bold())
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .glassEffect(.regular.interactive(), in: .capsule)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    private var uploadCard: some View {
        VStack(spacing: 12) {
            if let image = inputImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                UploadPlaceholder(hint: uploadHint)
            }

            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label(albumLabel, systemImage: "photo.on.rectangle")
                            .font(.callout.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(.white)
                    }
                    .glassEffect(.regular.tint(.blue).interactive(), in: .rect(cornerRadius: 12))
                    .onChange(of: selectedItem) { newItem in
                        outputImage = nil
                        Task { await loadSelectedImage(newItem) }
                    }

                    Button { showCamera = true } label: {
                        Label(cameraLabel, systemImage: "camera.fill")
                            .font(.callout.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
                }
            }
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var generateButton: some View {
        Button {
            Task { await generateTapped() }
        } label: {
            Group {
                if isGenerating {
                    GeneratingLabel(language: lang)
                } else {
                    Label(generateLabel, systemImage: "wand.and.stars")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(inputImage == nil ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.white))
        }
        .glassEffect(
            inputImage == nil ? .regular : .regular.tint(.blue).interactive(),
            in: .rect(cornerRadius: 16)
        )
        .disabled(isGenerating || inputImage == nil)
    }

    private var usageInfoText: some View {
        Group {
            if !subscription.isSubscribed {
                Text(freeUsageNote)
            } else {
                Text(remainingCountText)
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(comparisonTitle).font(.headline)

            if let before = inputImage, let result = outputImage {
                ComparisonSliderView(before: before, after: result)
                    .aspectRatio(result.size.width / result.size.height, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 400)

                resultActions
                retakeButton
                printLayoutButton
            }
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var resultActions: some View {
        VStack(spacing: 10) {
            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    Button {
                        guard let img = outputImage else { return }
                        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                        showSavedToastBriefly()
                        AnalyticsManager.shared.track(AnalyticsManager.Event.photoSaved)
                    } label: {
                        Label(saveLabel, systemImage: "square.and.arrow.down")
                            .font(.callout.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(.white)
                    }
                    .glassEffect(.regular.tint(.blue).interactive(), in: .rect(cornerRadius: 12))

                    Button { sharePhoto() } label: {
                        Label(shareLabel, systemImage: "square.and.arrow.up")
                            .font(.callout.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
                }
            }

            Button { outputImage = nil } label: {
                Label(regenerateLabel, systemImage: "arrow.counterclockwise")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 2)
        }
    }

    private var retakeButton: some View {
        Button {
            withAnimation {
                selectedItem = nil
                inputImage = nil
                outputImage = nil
            }
        } label: {
            Label(retakeLabel, systemImage: "photo.badge.plus")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    private var printLayoutButton: some View {
        Button { showPrintLayout = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "printer.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .purple],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(printLayoutLabel)
                            .font(.callout.bold())
                        if !subscription.isSubscribed {
                            Text("PRO")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.orange.gradient)
                                .clipShape(Capsule())
                        }
                    }
                    Text(printLayoutDesc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 14))
        .sheet(isPresented: $showPrintLayout) {
            if let result = outputImage {
                PrintLayoutSheetView(
                    image: result,
                    photoSizeMM: isCustomSize ? customSize.photoSizeMM : selectedSpec.photoSizeMM,
                    sizeLabel: isCustomSize ? customSize.sizeLabel : selectedSpec.sizeLabel,
                    isSubscribed: subscription.isSubscribed,
                    onLockedTap: {
                        showPrintLayout = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            showSubscriptionSheet = true
                        }
                    }
                )
                .environmentObject(langManager)
                .environmentObject(subscription)
                .presentationDetents([.large])
                .preferredColorScheme(sheetColorScheme)
            }
        }
    }

    private var savedToast: some View {
        Label(savedMessage, systemImage: "checkmark.circle.fill")
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .glassEffect(.regular.tint(.green), in: .capsule)
            .padding(.bottom, 48)
            .transition(.move(edge: .bottom).combined(with: .opacity))
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

    private var appTitle:        String { l("AI证件照", "AI ID Photo", "AI証明写真", "AI 증명사진", vi: "AI Ảnh Thẻ", id: "AI Foto ID", pt: "AI Foto Documento") }
    private var memberSubtitle:  String { l("会员：无限生成 · 无广告 · 含排版打印", "Member: Unlimited · No Ads · Print Layout", "会員：無制限生成・広告なし・プリント込み", "회원: 무제한 · 광고 없음 · 인쇄 포함", vi: "Thành viên: Không giới hạn · Không QC · In ảnh", id: "Member: Tanpa batas · Tanpa iklan · Cetak", pt: "Membro: Ilimitado · Sem anúncios · Impressão") }
    private var memberLabel:     String { l("会员", "Member", "会員", "회원", vi: "Thành viên", id: "Member", pt: "Membro") }
    private var subscribedLabel: String { l("已订阅", "Subscribed", "購読中", "구독중", vi: "Đã đăng ký", id: "Berlangganan", pt: "Assinante") }
    private var uploadHint:      String { l("上传一张正面清晰的生活照", "Upload a clear front-facing photo", "正面の鮮明な写真をアップロード", "정면이 선명한 사진을 업로드하세요", vi: "Tải lên ảnh chính diện rõ nét", id: "Unggah foto wajah depan yang jelas", pt: "Envie uma foto frontal nítida") }
    private var albumLabel:      String { l("从相册选择", "Photo Library", "フォトライブラリ", "사진 보관함", vi: "Thư viện ảnh", id: "Galeri Foto", pt: "Biblioteca") }
    private var cameraLabel:     String { l("拍摄照片", "Take Photo", "カメラで撮影", "사진 촬영", vi: "Chụp ảnh", id: "Ambil Foto", pt: "Tirar Foto") }
    private var generateLabel:   String {
        if isCustomSize {
            let size = customSize.sizeLabel
            return l("生成自定义 \(size)", "Generate Custom \(size)", "カスタム \(size) を生成", "사용자 정의 \(size) 생성",
                     vi: "Tạo tùy chỉnh \(size)", id: "Buat Kustom \(size)", pt: "Gerar Personalizado \(size)")
        }
        let specName = selectedSpec.displayName(language: lang)
        return l("生成\(specName)", "Generate \(specName)", "\(specName)を生成", "\(specName) 생성",
                 vi: "Tạo \(specName)", id: "Buat \(specName)", pt: "Gerar \(specName)")
    }
    private var freeSubtitle:    String { l("首次免费", "First gen free", "初回無料", "첫 생성 무료", vi: "Lần đầu miễn phí", id: "Pertama gratis", pt: "1ª vez grátis") }
    private var freeUsageNote: String {
        let left = usage.freeUsesRemaining
        switch lang {
        case "zh": return "今日剩余 \(left)/\(UsageManager.freeDailyLimit) 次 · 需观看广告"
        case "ja": return "本日残り \(left)/\(UsageManager.freeDailyLimit)回 · 広告視聴が必要"
        case "ko": return "오늘 남은 \(left)/\(UsageManager.freeDailyLimit)회 · 광고 시청 필요"
        case "vi": return "Còn \(left)/\(UsageManager.freeDailyLimit) lần · Cần xem QC"
        case "id": return "Sisa \(left)/\(UsageManager.freeDailyLimit) · Perlu tonton iklan"
        case "pt": return "Restam \(left)/\(UsageManager.freeDailyLimit) · Requer anúncio"
        default:   return "\(left)/\(UsageManager.freeDailyLimit) left today · Ad required"
        }
    }
    private var remainingCountText: String {
        switch lang {
        case "zh": return "今日剩余次数：\(usage.subscriberUsesLeft)"
        case "ja": return "本日残り：\(usage.subscriberUsesLeft)回"
        case "ko": return "오늘 남은 횟수: \(usage.subscriberUsesLeft)회"
        case "vi": return "Còn lại hôm nay: \(usage.subscriberUsesLeft)"
        case "id": return "Sisa hari ini: \(usage.subscriberUsesLeft)"
        case "pt": return "Restantes hoje: \(usage.subscriberUsesLeft)"
        default:   return "Today's remaining: \(usage.subscriberUsesLeft)"
        }
    }
    private var comparisonTitle: String { l("效果对比", "Before & After", "効果比較", "전후 비교", vi: "Trước & Sau", id: "Sebelum & Sesudah", pt: "Antes & Depois") }
    private var saveLabel:       String { l("保存到相册", "Save to Photos", "写真を保存", "사진 저장", vi: "Lưu vào Ảnh", id: "Simpan ke Foto", pt: "Salvar em Fotos") }
    private var shareLabel:      String { l("分享", "Share", "共有", "공유", vi: "Chia sẻ", id: "Bagikan", pt: "Compartilhar") }
    private var regenerateLabel: String { l("重新生成", "Regenerate", "再生成", "재생성", vi: "Tạo lại", id: "Buat Ulang", pt: "Regerar") }
    private var retakeLabel:     String { l("换一张照片", "Try Another Photo", "別の写真で試す", "다른 사진으로", vi: "Thử ảnh khác", id: "Coba Foto Lain", pt: "Outra Foto") }
    private var savedMessage:    String { l("已保存到相册", "Saved to Photos", "写真を保存しました", "사진 저장 완료", vi: "Đã lưu vào Ảnh", id: "Tersimpan ke Foto", pt: "Salvo em Fotos") }
    private var printLayoutLabel: String { l("便利店排版打印", "Konbini Print Layout", "コンビニプリント", "편의점 인쇄 레이아웃", vi: "In ảnh tại cửa hàng", id: "Layout Cetak Konbini", pt: "Layout p/ Impressão") }
    private var printLayoutDesc:  String { l("生成排版照片，到便利店直接打印", "Print-ready layout for convenience stores", "プリント用レイアウトを生成、コンビニで印刷", "편의점에서 바로 인쇄할 수 있는 레이아웃", vi: "Tạo bố cục, in tại cửa hàng tiện lợi", id: "Layout siap cetak untuk toko serba ada", pt: "Layout pronto para lojas de conveniência") }
    private var errorTitle:      String { l("错误", "Error", "エラー", "오류", vi: "Lỗi", id: "Kesalahan", pt: "Erro") }
    private var okLabel:         String { l("好的", "OK", "OK", "확인", vi: "OK", id: "OK", pt: "OK") }

    // MARK: - Actions

    private func generateTapped() async {
        guard let input = inputImage else { return }

        // Show AI consent dialog on first generation
        if !hasGivenAIConsent {
            pendingGenerateAfterConsent = true
            showAIConsent = true
            return
        }
        // Defense: reset pro options if free user somehow selected them
        if !subscription.isSubscribed && photoOptions.hasProSelection {
            photoOptions = .defaults
        }
        let decision = usage.canGenerate(isSubscribed: subscription.isSubscribed)
        switch decision {
        case .allowed:
            await performGenerate(input: input)
        case .requireRewardedAd:
            // Use referral bonus before requiring ad
            if referralManager.useBonusGeneration() {
                await performGenerate(input: input)
                return
            }
            await presentRewardedThenGenerate(input: input)
        case .reachedDailyLimit:
            showSubscriptionSheet = true
            AnalyticsManager.shared.track(AnalyticsManager.Event.paywallShown, properties: ["trigger": "reachedDailyLimit"])
        case .reachedLimit:
            showSubscriptionSheet = true
            AnalyticsManager.shared.track(AnalyticsManager.Event.paywallShown, properties: ["trigger": "reachedLimit"])
        }
    }

    private func presentRewardedThenGenerate(input: UIImage) async {
        await adManager.loadRewarded()
        let rewarded = await adManager.showRewarded()
        if rewarded {
            AnalyticsManager.shared.track(AnalyticsManager.Event.adWatched)
            usage.markUsed(isSubscribed: false)
            await performGenerate(input: input)
        } else {
            errorMessage = l("未完成广告观看，无法继续生成。",
                             "Ad not completed. Generation cancelled.",
                             "広告が完了しませんでした。生成をキャンセルしました。",
                             "광고가 완료되지 않았습니다. 생성이 취소되었습니다.",
                             vi: "Chưa xem xong quảng cáo. Đã hủy tạo ảnh.",
                             id: "Iklan belum selesai. Pembuatan dibatalkan.",
                             pt: "Anúncio não concluído. Geração cancelada.")
        }
    }

    private func performGenerate(input: UIImage) async {
        isGenerating = true
        defer { isGenerating = false }
        do {
            let basePrompt = isCustomSize ? customSize.prompt : selectedSpec.prompt
            let finalPrompt = basePrompt + photoOptions.buildPromptSuffix()
            let tier: GeminiService.OutputTier = subscription.isSubscribed ? .pro : .free
            let result = try await GeminiService.shared.generateIDPhoto(
                from: input,
                prompt: finalPrompt,
                tier: tier
            )
            self.outputImage = result
            usage.markUsed(isSubscribed: subscription.isSubscribed)
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            // Save to history
            historyManager.addRecord(
                image: result,
                specRawValue: isCustomSize ? "custom" : selectedSpec.rawValue,
                sizeLabel: isCustomSize ? customSize.sizeLabel : selectedSpec.sizeLabel,
                isCustomSize: isCustomSize
            )

            let specName = isCustomSize ? "custom" : selectedSpec.rawValue
            AnalyticsManager.shared.track(AnalyticsManager.Event.generationSuccess, properties: ["spec": specName])

            // Request App Store review after 3rd success, once per version
            successfulGenerations += 1
            if successfulGenerations >= 3 {
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                if lastReviewPromptVersion != currentVersion {
                    lastReviewPromptVersion = currentVersion
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        if let scene = UIApplication.shared.connectedScenes
                            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                            AppStore.requestReview(in: scene)
                        }
                    }
                }
            }
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            errorMessage = error.localizedDescription
            AnalyticsManager.shared.track(AnalyticsManager.Event.generationFailed)
        }
    }

    private func loadSelectedImage(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let ui = UIImage(data: data) {
            await MainActor.run { inputImage = ui }
        }
    }

    private func sharePhoto() {
        guard let img = outputImage else { return }
        let shareImage = subscription.isSubscribed ? img : addWatermark(to: img)
        let items: [Any] = [shareImage]

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.keyWindow?.rootViewController {
            let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
            if let popover = ac.popoverPresentationController {
                popover.sourceView = root.view
                popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
            }
            root.present(ac, animated: true)
        }
        AnalyticsManager.shared.track(AnalyticsManager.Event.photoShared)
    }

    private func addWatermark(to image: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(at: .zero)
            let text = "AI ID Photo"
            let fontSize = max(image.size.width * 0.035, 14)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.5),
            ]
            let textSize = text.size(withAttributes: attrs)
            let point = CGPoint(
                x: image.size.width - textSize.width - 16,
                y: image.size.height - textSize.height - 16
            )
            text.draw(at: point, withAttributes: attrs)
        }
    }

    private func showSavedToastBriefly() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring()) { showSavedToast = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut) { showSavedToast = false }
        }
    }
}


// MARK: - Generating Label (cycling status messages)

private struct GeneratingLabel: View {
    let language: String

    private var messages: [String] {
        switch language {
        case "ja": return ["写真を解析中…", "顔を処理中…", "証明写真を生成中…", "もうすぐ完成…"]
        case "ko": return ["사진 분석 중…", "얼굴 처리 중…", "증명사진 생성 중…", "거의 완료…"]
        case "zh": return ["AI 正在分析照片…", "AI 正在处理人像…", "AI 正在生成证件照…", "即将完成，请稍候…"]
        case "vi": return ["Đang phân tích ảnh…", "Đang xử lý khuôn mặt…", "Đang tạo ảnh thẻ…", "Sắp hoàn thành…"]
        case "id": return ["Menganalisis foto…", "Memproses wajah…", "Membuat foto ID…", "Hampir selesai…"]
        case "pt": return ["Analisando foto…", "Processando rosto…", "Gerando foto documento…", "Quase pronto…"]
        default:   return ["Analyzing photo…", "Processing face…", "Generating ID photo…", "Almost done…"]
        }
    }

    @State private var index = 0

    var body: some View {
        HStack(spacing: 10) {
            ProgressView().tint(.white)
            Text(messages[index])
                .id(index)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal:   .move(edge: .top).combined(with: .opacity)
                ))
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.easeInOut(duration: 0.35)) {
                    index = (index + 1) % messages.count
                }
            }
        }
    }
}

// MARK: - Upload Placeholder

private struct UploadPlaceholder: View {
    let hint: String
    @State private var pulsing = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.rectangle.badge.plus")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(.secondary.opacity(pulsing ? 0.7 : 0.45))
                .scaleEffect(pulsing ? 1.07 : 1.0)
                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulsing)
            Text(hint)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [8, 5]))
                .foregroundStyle(.secondary.opacity(0.25))
        }
        .onAppear { pulsing = true }
    }
}

// MARK: - Ad Banner Wrapper

struct AdBannerViewWrapper: View {
    var body: some View {
        #if canImport(GoogleMobileAds)
        AdBannerView()
        #else
        Color.clear
        #endif
    }
}
