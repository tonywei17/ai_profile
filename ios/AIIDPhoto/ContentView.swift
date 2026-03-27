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

    private var sheetColorScheme: ColorScheme {
        langManager.appearance.colorScheme ?? colorScheme
    }

    private var sortedSpecs: [IDPhotoSpec] { IDPhotoSpec.sorted(for: Locale.current) }
    private var lang: String { langManager.effectiveCode }

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
    @State private var lastGenerateTime: Date?

    // Photo picker states (replacing Menu-based approach)
    @State private var showPhotoPicker = false
    @State private var showPhotoSourceDialog = false
    @State private var showPhotoChangeDialog = false

    @AppStorage("successfulGenerations") private var successfulGenerations: Int = 0
    @AppStorage("lastReviewPromptVersion") private var lastReviewPromptVersion: String = ""
    @AppStorage("hasGivenAIConsent") private var hasGivenAIConsent: Bool = false
    @AppStorage("printLayoutEnabled") private var printLayoutEnabled: Bool = true

    @State private var showAIConsent = false
    @State private var pendingGenerateAfterConsent = false

    // Processing toggle bindings
    private var beautyBinding: Binding<Bool> {
        Binding(
            get: { photoOptions.beauty != .natural },
            set: { newValue in
                if newValue {
                    if BeautyLevel.lightEnhance.isPro && !subscription.isSubscribed {
                        showSubscriptionSheet = true
                    } else {
                        photoOptions.beauty = .lightEnhance
                    }
                } else {
                    photoOptions.beauty = .natural
                }
            }
        )
    }

    private var outfitBinding: Binding<Bool> {
        Binding(
            get: { photoOptions.attire != .keepOriginal },
            set: { newValue in
                if newValue {
                    if Attire.darkSuit.isPro && !subscription.isSubscribed {
                        showSubscriptionSheet = true
                    } else {
                        photoOptions.attire = .darkSuit
                        photoOptions.background = .pureWhite
                    }
                } else {
                    photoOptions.attire = .keepOriginal
                    photoOptions.background = .specDefault
                }
            }
        )
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                topToolbar
                heroSection

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 32) {
                            SpecSelectorView(
                                selected: $selectedSpec,
                                isCustomSize: $isCustomSize,
                                specs: sortedSpecs,
                                language: lang,
                                isSubscribed: subscription.isSubscribed,
                                onLockedTap: { showSubscriptionSheet = true }
                            )

                            if isCustomSize {
                                CustomSizePickerView(customSize: $customSize, language: lang)
                            }

                            processingSection
                                .opacity(inputImage == nil ? 0.4 : 1.0)
                                .allowsHitTesting(inputImage != nil)
                            outputSection
                                .opacity(inputImage == nil ? 0.4 : 1.0)
                                .allowsHitTesting(inputImage != nil)

                            if outputImage != nil {
                                resultCard.id("resultCard")
                            }

                            if !subscription.isSubscribed {
                                AdBannerViewWrapper().frame(height: 50)
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: sizeClass == .regular ? 600 : .infinity)
                        .frame(maxWidth: .infinity)
                    }
                    .onChange(of: outputImage) { newValue in
                        if newValue != nil {
                            withAnimation { proxy.scrollTo("resultCard", anchor: .top) }
                        }
                    }
                }

                bottomBar
            }
        }
        .onChange(of: selectedItem) { newItem in
            outputImage = nil
            Task { await loadSelectedImage(newItem) }
        }
        // PhotosPicker modifier (triggered by state, NOT inside Menu)
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
        // Photo source dialogs
        .confirmationDialog(uploadActionLabel, isPresented: $showPhotoSourceDialog) {
            Button(albumLabel) { showPhotoPicker = true }
            Button(cameraLabel) { showCamera = true }
        }
        .confirmationDialog("", isPresented: $showPhotoChangeDialog) {
            Button(albumLabel) { showPhotoPicker = true }
            Button(cameraLabel) { showCamera = true }
            Button(retakeLabel, role: .destructive) {
                withAnimation {
                    selectedItem = nil
                    inputImage = nil
                    outputImage = nil
                }
            }
        }
        // Print layout sheet (moved to body level)
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

    // MARK: - Top Toolbar

    private var topToolbar: some View {
        HStack {
            Spacer()
            HStack(spacing: 12) {
                Button { showHistory = true } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.inkBlack)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(Text("History"))
                Button { showSettingsSheet = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.inkBlack)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(Text("Settings"))
                Button { showSubscriptionSheet = true } label: {
                    Text(subscription.isSubscribed ? subscribedLabel : "PRO")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(subscription.isSubscribed ? Color.inkFillForeground : Color.inkBlack)
                        .padding(.horizontal, 10)
                        .frame(height: 44)
                        .background(subscription.isSubscribed ? Color.inkFill : Color.clear)
                        .overlay(Rectangle().stroke(Color.inkBlack, lineWidth: 1))
                }
                .accessibilityLabel(Text("Subscription"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
        .background(Color(.systemBackground))
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack {
            HStack(spacing: 0) {
                Color.paperTan
                Color(.systemBackground)
            }

            GeometryReader { geo in
                Text("ID PHOTO MAKER")
                    .font(.system(size: 12, weight: .regular))
                    .fontWidth(.condensed)
                    .tracking(4)
                    .foregroundStyle(Color.branchGray)
                    .fixedSize()
                    .rotationEffect(.degrees(-90))
                    .position(x: 20, y: geo.size.height / 2)
            }
            .allowsHitTesting(false)

            if let image = inputImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 160)
                    .clipShape(Rectangle())
                    .overlay(Rectangle().stroke(Color.inkBlack, lineWidth: 1))
                    .overlay(alignment: .bottomTrailing) {
                        Button { showPhotoChangeDialog = true } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.inkFillForeground)
                                .padding(8)
                                .background(Color.inkFill.opacity(0.7))
                        }
                        .frame(minWidth: 44, minHeight: 44, alignment: .bottomTrailing)
                        .padding(4)
                    }
            } else {
                Button { showPhotoSourceDialog = true } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            Rectangle()
                                .stroke(Color.inkBlack, lineWidth: 1)
                                .frame(width: 64, height: 64)
                                .background(Color(.systemBackground))
                            Text("+")
                                .font(.system(size: 24, weight: .light))
                                .foregroundStyle(Color.inkBlack)
                        }
                        Text(uploadActionLabel)
                            .font(.system(size: 12, weight: .medium))
                            .tracking(0.5)
                            .foregroundStyle(Color.inkBlack)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemBackground))
                    }
                }
            }
        }
        .frame(height: max(UIScreen.main.bounds.height * 0.22, 180))
        .clipped()
        .overlay(alignment: .bottom) {
            Color.inkBlack.frame(height: 1)
        }
    }

    // MARK: - Processing Section

    private var processingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(processingSectionLabel)
                .font(.system(size: 11, weight: .regular))
                .tracking(1.5)
                .textCase(.uppercase)
                .foregroundStyle(Color.branchGray)

            VStack(spacing: 0) {
                featureToggleRow(
                    title: beautyToggleTitle,
                    description: beautyToggleDesc,
                    isOn: beautyBinding
                )
                Color.inkBlack.frame(height: 1)
                featureToggleRow(
                    title: outfitToggleTitle,
                    description: outfitToggleDesc,
                    isOn: outfitBinding
                )
            }
            .overlay(alignment: .top) { Color.inkBlack.frame(height: 1) }
            .overlay(alignment: .bottom) { Color.inkBlack.frame(height: 1) }
        }
    }

    private func featureToggleRow(title: String, description: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.inkBlack)
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.branchGray)
            }
            Spacer()
            EditorialToggle(isOn: isOn)
        }
        .padding(.vertical, 16)
    }

    // MARK: - Output Section

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(outputSectionLabel)
                .font(.system(size: 11, weight: .regular))
                .tracking(1.5)
                .textCase(.uppercase)
                .foregroundStyle(Color.branchGray)

            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Rectangle()
                            .stroke(Color.inkBlack, lineWidth: 1)
                            .frame(width: 24, height: 24)
                        Text("P")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.inkBlack)
                    }
                    Text(printToggleLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.inkBlack)
                }
                Spacer()
                EditorialToggle(isOn: $printLayoutEnabled)
            }
            .padding(16)
            .overlay(Rectangle().stroke(Color.inkBlack, lineWidth: 1))
        }
    }

    // MARK: - Result Card

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(comparisonTitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.inkBlack)

            if let before = inputImage, let result = outputImage {
                ComparisonSliderView(before: before, after: result, language: lang)
                    .aspectRatio(result.size.width / result.size.height, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 400)

                // Save & Share buttons
                HStack(spacing: 0) {
                    Button {
                        guard let img = outputImage else { return }
                        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                        showSavedToastBriefly()
                        AnalyticsManager.shared.track(AnalyticsManager.Event.photoSaved)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 13))
                            Text(saveLabel)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(Color.inkFillForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.inkFill)
                    }

                    Button { sharePhoto() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 13))
                            Text(shareLabel)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(Color.inkBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(Rectangle().stroke(Color.inkBlack, lineWidth: 1))
                    }
                }
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Color.inkBlack.frame(height: 1)

            if outputImage != nil {
                // Post-generation: Reset + Print Layout
                HStack(spacing: 0) {
                    // Reset (outline, subtle)
                    Button {
                        withAnimation { outputImage = nil }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 13))
                            Text(resetLabel)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(Color.inkBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .overlay(Rectangle().stroke(Color.inkBlack, lineWidth: 1))
                    }

                    // Print Layout (filled, Pro)
                    Button {
                        if subscription.isSubscribed {
                            showPrintLayout = true
                        } else {
                            showSubscriptionSheet = true
                            AnalyticsManager.shared.track(AnalyticsManager.Event.paywallShown, properties: ["trigger": "printLayout"])
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text("P")
                                .font(.system(size: 11, weight: .bold))
                            Text(printBottomLabel)
                                .font(.system(size: 14, weight: .medium))
                            if !subscription.isSubscribed {
                                Text("PRO")
                                    .font(.system(size: 9, weight: .bold))
                                    .tracking(0.5)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .overlay(Rectangle().stroke(Color.inkFillForeground.opacity(0.5), lineWidth: 1))
                            }
                        }
                        .foregroundStyle(Color.inkFillForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.inkFill)
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
            } else {
                // Pre-generation: Generate button + usage hint
                VStack(spacing: 8) {
                    Button {
                        Task { await generateTapped() }
                    } label: {
                        HStack(spacing: 8) {
                            if isGenerating {
                                GeneratingLabel(language: lang)
                            } else {
                                Circle()
                                    .fill(Color.treeGreen)
                                    .frame(width: 6, height: 6)
                                Text(generateLabel)
                            }
                        }
                        .font(.system(size: 15, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(inputImage == nil ? Color.inkFillForeground.opacity(0.4) : Color.inkFillForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(inputImage == nil ? Color.inkFill.opacity(0.3) : Color.inkFill)
                    }
                    .disabled(isGenerating || inputImage == nil)

                    // Usage hint
                    if !subscription.isSubscribed {
                        Text(freeUsageNote)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.branchGray)
                    } else {
                        Text(remainingCountText)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.branchGray)
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
            }
        }
    }

    // MARK: - Toast

    private var savedToast: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
            Text(savedMessage)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(Color.inkFillForeground)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.inkFill)
        .padding(.bottom, 100)
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
            return l("生成自定义 \(size) 证件照", "Generate \(size) ID Photo", "カスタム \(size) 写真を生成", "사용자 정의 \(size) 사진 생성",
                     vi: "Tạo ảnh thẻ \(size)", id: "Buat Foto ID \(size)", pt: "Gerar Foto \(size)")
        }
        let specName = selectedSpec.displayName(language: lang)
        return l("生成\(specName)证件照", "Generate \(specName) Photo", "\(specName)写真を生成", "\(specName) 사진 생성",
                 vi: "Tạo ảnh \(specName)", id: "Buat Foto \(specName)", pt: "Gerar Foto \(specName)")
    }
    private var freeSubtitle:    String { l("首次免费", "First gen free", "初回無料", "첫 생성 무료", vi: "Lần đầu miễn phí", id: "Pertama gratis", pt: "1ª vez grátis") }
    private var freeUsageNote: String {
        let left = usage.freeUsesRemaining
        switch lang {
        case "zh": return "今日剩余 \(left)/\(UsageManager.freeDailyLimit) 次 · \(left == UsageManager.freeDailyLimit ? "首次免费" : "需观看广告")"
        case "ja": return "本日残り \(left)/\(UsageManager.freeDailyLimit)回 · \(left == UsageManager.freeDailyLimit ? "初回無料" : "広告視聴が必要")"
        case "ko": return "오늘 남은 \(left)/\(UsageManager.freeDailyLimit)회 · \(left == UsageManager.freeDailyLimit ? "첫 생성 무료" : "광고 시청 필요")"
        case "vi": return "Còn \(left)/\(UsageManager.freeDailyLimit) lần · \(left == UsageManager.freeDailyLimit ? "Lần đầu miễn phí" : "Cần xem QC")"
        case "id": return "Sisa \(left)/\(UsageManager.freeDailyLimit) · \(left == UsageManager.freeDailyLimit ? "Pertama gratis" : "Perlu tonton iklan")"
        case "pt": return "Restam \(left)/\(UsageManager.freeDailyLimit) · \(left == UsageManager.freeDailyLimit ? "1ª grátis" : "Requer anúncio")"
        default:   return "\(left)/\(UsageManager.freeDailyLimit) left today · \(left == UsageManager.freeDailyLimit ? "First gen free" : "Ad required")"
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

    // Editorial strings
    private var uploadActionLabel:      String { l("撮影 / 選択", "Take / Select", "撮影 / 選択", "촬영 / 선택", vi: "Chụp / Chọn", id: "Ambil / Pilih", pt: "Tirar / Selecionar") }
    private var processingSectionLabel: String { l("02. 处理", "02. Processing", "02. Processing", "02. 처리", vi: "02. Xử lý", id: "02. Processing", pt: "02. Processamento") }
    private var outputSectionLabel:     String { l("03. 输出", "03. Output", "03. Output", "03. 출력", vi: "03. Đầu ra", id: "03. Output", pt: "03. Saída") }
    private var beautyToggleTitle:      String { l("AI 美颜补正", "AI Beauty", "AI 美顔補正", "AI 뷰티 보정", vi: "AI Làm đẹp", id: "AI Kecantikan", pt: "AI Beleza") }
    private var beautyToggleDesc:       String { l("自然肌肤修正与面部倾斜调整", "Natural skin correction & face alignment", "自然な肌補正と顔の傾き調整", "자연스러운 피부 보정과 얼굴 기울기 조정", vi: "Chỉnh sửa da tự nhiên", id: "Koreksi kulit alami", pt: "Correção natural da pele") }
    private var outfitToggleTitle:      String { l("服装・背景替换", "Outfit & Background", "服装・背景置換", "복장·배경 교체", vi: "Trang phục & Nền", id: "Pakaian & Latar", pt: "Traje & Fundo") }
    private var outfitToggleDesc:       String { l("自动换装西装与白底背景", "Auto suit change & white background", "スーツへの自動着せ替えと白背景化", "자동 정장 착용 및 흰색 배경", vi: "Tự động đổi vest & nền trắng", id: "Otomatis ganti jas & latar putih", pt: "Traje automático & fundo branco") }
    private var printToggleLabel:       String { l("便利店排版打印", "Convenience Store Print", "コンビニプリント対応排版", "편의점 인쇄 레이아웃", vi: "In tại cửa hàng", id: "Layout Cetak", pt: "Layout de Impressão") }
    private var resetLabel:             String { l("重置", "Reset", "リセット", "리셋", vi: "Đặt lại", id: "Reset", pt: "Redefinir") }
    private var printBottomLabel:       String { l("便利店打印", "Print Layout", "コンビニプリント", "편의점 인쇄", vi: "In ảnh", id: "Cetak", pt: "Imprimir") }

    // MARK: - Actions

    private func generateTapped() async {
        guard let input = inputImage, !isGenerating else { return }
        if let last = lastGenerateTime, Date().timeIntervalSince(last) < 1.0 { return }

        if !hasGivenAIConsent {
            pendingGenerateAfterConsent = true
            showAIConsent = true
            return
        }
        if !subscription.isSubscribed && photoOptions.hasProSelection {
            photoOptions = .defaults
        }
        let decision = usage.canGenerate(isSubscribed: subscription.isSubscribed)
        switch decision {
        case .allowed:
            await performGenerate(input: input)
        case .requireRewardedAd:
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
        lastGenerateTime = Date()
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

            historyManager.addRecord(
                image: result,
                specRawValue: isCustomSize ? "custom" : selectedSpec.rawValue,
                sizeLabel: isCustomSize ? customSize.sizeLabel : selectedSpec.sizeLabel,
                isCustomSize: isCustomSize
            )

            let specName = isCustomSize ? "custom" : selectedSpec.rawValue
            AnalyticsManager.shared.track(AnalyticsManager.Event.generationSuccess, properties: ["spec": specName])

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


// MARK: - Generating Label

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
