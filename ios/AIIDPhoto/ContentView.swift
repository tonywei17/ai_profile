import SwiftUI
import PhotosUI
import StoreKit

struct ContentView: View {
    @EnvironmentObject var subscription: SubscriptionManager
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

    // Usage limit alert
    @State private var showLimitAlert = false
    @State private var limitAlertMessage = ""

    @AppStorage("successfulGenerations") private var successfulGenerations: Int = 0
    @AppStorage("lastReviewPromptVersion") private var lastReviewPromptVersion: String = ""
    @AppStorage("hasGivenAIConsent") private var hasGivenAIConsent: Bool = false

    @State private var showAIConsent = false
    @State private var pendingGenerateAfterConsent = false
    private let includedFeatureAccess = true

    @State private var navigateToCreation = false

    var body: some View {
        NavigationStack {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                if inputImage == nil {
                    homeHeader

                    ScrollView {
                        VStack(spacing: 0) {
                            heroBannerSection
                            serviceCategoriesSection
                            trustStatsSection
                            Divider().padding(.horizontal, 16)
                            showcaseSection
                        }
                        .padding(.bottom, 24)
                    }

                    homeBottomBar
                } else {
                    generationHeader
                    heroSection

                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 32) {
                                SpecSelectorView(
                                    selected: $selectedSpec,
                                    isCustomSize: $isCustomSize,
                                    specs: sortedSpecs,
                                    language: lang,
                                    isSubscribed: includedFeatureAccess,
                                    onLockedTap: { showSubscriptionSheet = true }
                                )

                                if isCustomSize {
                                    CustomSizePickerView(customSize: $customSize, language: lang)
                                }

                                ProOptionsView(
                                    options: $photoOptions,
                                    isSubscribed: includedFeatureAccess,
                                    language: lang,
                                    onLockedTap: { showSubscriptionSheet = true }
                                )
                                .opacity(inputImage == nil ? 0.4 : 1.0)
                                .allowsHitTesting(inputImage != nil)

                                if outputImage != nil {
                                    resultCard.id("resultCard")
                                }

                            }
                            .padding(24)
                            .frame(maxWidth: sizeClass == .regular ? 600 : .infinity)
                            .frame(maxWidth: .infinity)
                        }
                        .onChange(of: outputImage) { _, newValue in
                            if newValue != nil {
                                withAnimation { proxy.scrollTo("resultCard", anchor: .top) }
                            }
                        }
                    }

                    bottomBar
                }
            }
        }
        .onChange(of: selectedItem) { _, newItem in
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
                    isSubscribed: includedFeatureAccess,
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
        .alert(limitAlertTitle, isPresented: $showLimitAlert) {
            Button(upgradeLabel) { showSubscriptionSheet = true }
            Button(okLabel, role: .cancel) {}
        } message: {
            Text(limitAlertMessage)
        }
        .onChange(of: selectedSpec) { _, _ in
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
        .navigationDestination(isPresented: $navigateToCreation) {
            PhotoCreationView()
                .environmentObject(subscription)
                .environmentObject(langManager)
                .environmentObject(historyManager)
                .environmentObject(referralManager)
        }
        } // NavigationStack
    }

    // MARK: - Home Page Header

    private var homeHeader: some View {
        HStack(spacing: 10) {
            Image("AppLogo")
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 1) {
                Text("光影形象馆")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.inkBlack)
                Text("AI职业形象照与证件照助手")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.branchGray)
            }

            Spacer()

            HStack(spacing: 0) {
                Button { showHistory = true } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.inkBlack)
                        .frame(width: 40, height: 40)
                }
                .accessibilityLabel(Text(historyNavLabel))
                Button { showSettingsSheet = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.inkBlack)
                        .frame(width: 40, height: 40)
                }
                .accessibilityLabel(Text(settingsNavLabel))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) { Color(.systemGray5).frame(height: 0.5) }
    }

    // MARK: - Generation Flow Header

    private var generationHeader: some View {
        HStack {
            Button { withAnimation { inputImage = nil; outputImage = nil } } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.inkBlack)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text(backNavLabel))

            Text("光影形象馆")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.inkBlack)

            Spacer()

            HStack(spacing: 8) {
                Button { showHistory = true } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.inkBlack)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(Text(historyNavLabel))
                Button { showSubscriptionSheet = true } label: {
                    Text(subscription.generationAttemptsLeft > 0 ? subscribedLabel : buyTaskLabel)
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(subscription.generationAttemptsLeft > 0 ? Color.inkFillForeground : Color.inkBlack)
                        .padding(.horizontal, 10)
                        .frame(height: 36)
                        .background(subscription.generationAttemptsLeft > 0 ? Color.inkFill : Color.clear)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.inkBlack, lineWidth: 1))
                }
                .accessibilityLabel(Text(photoTaskNavLabel))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) { Color(.systemGray5).frame(height: 0.5) }
    }

    // MARK: - Hero Banner (Home Page)

    private var heroBannerSection: some View {
        ZStack(alignment: .trailing) {
            Image("HomeHeroPortrait")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .clipped()

            LinearGradient(
                colors: [Color.skyBlue.opacity(0.28), Color.skyBlue.opacity(0.10), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("AI职业形象照")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                    Text("简历照 · 证件照")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.92))
                    Text("更专业 · 更自然 · 更出色")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.75))

                    Spacer()

                    HStack(spacing: 6) {
                        Text("限时优惠")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white)
                        Text("3.80元/张")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.promoOrange)
                        Text("原价9.90元")
                            .font(.system(size: 10))
                            .strikethrough(color: .white.opacity(0.6))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.18))
                    .clipShape(Capsule())
                }
                .padding(.leading, 20)
                .padding(.vertical, 22)
                .frame(maxWidth: 245, alignment: .leading)

                Spacer()
            }
        }
        .frame(height: 190)
        .overlay(alignment: .topTrailing) {
            aiGeneratedBadge
                .padding(.top, 12)
                .padding(.trailing, 18)
        }
    }

    // MARK: - Service Categories

    private struct CategoryItem {
        let icon: String
        let title: String
        let subtitle: String
    }

    private let categories: [CategoryItem] = [
        CategoryItem(icon: "person.crop.rectangle.fill", title: "身份证件照",  subtitle: "1寸·白底·通用"),
        CategoryItem(icon: "airplane.departure",          title: "护照签证照",  subtitle: "33×48mm·白底"),
        CategoryItem(icon: "car.fill",                    title: "驾驶证照",    subtitle: "22×32mm·白底"),
        CategoryItem(icon: "doc.text.image.fill",         title: "简历形象照",  subtitle: "25×35mm·蓝/白底"),
        CategoryItem(icon: "graduationcap.fill",          title: "学籍报名照",  subtitle: "35×45mm·蓝底"),
        CategoryItem(icon: "person.circle.fill",          title: "社交头像",    subtitle: "方形·自定义"),
    ]

    private var serviceCategoriesSection: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(categories, id: \.title) { item in
                categoryButton(icon: item.icon, title: item.title, subtitle: item.subtitle)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }

    private func categoryButton(icon: String, title: String, subtitle: String) -> some View {
        Button { navigateToCreation = true } label: {
            VStack(spacing: 7) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.skyBlue.opacity(0.10))
                        .frame(width: 54, height: 54)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(Color.skyBlue)
                }
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.inkBlack)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundStyle(Color.branchGray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Trust Stats

    private var trustStatsSection: some View {
        HStack(spacing: 0) {
            statItem(highlight: "120万+", label: "用户", desc: "已服务")
            Rectangle().fill(Color(.systemGray4)).frame(width: 1, height: 36)
            statItem(highlight: "3次", label: "可重修", desc: "选最满意结果")
            Rectangle().fill(Color(.systemGray4)).frame(width: 1, height: 36)
            statItem(highlight: "隐私", label: "安全保护", desc: "照片仅自己可见")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemGray6).opacity(0.6))
    }

    private func statItem(highlight: String, label: String, desc: String) -> some View {
        VStack(spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(highlight)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.skyBlue)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkBlack)
            }
            Text(desc)
                .font(.system(size: 10))
                .foregroundStyle(Color.branchGray)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Effects Showcase

    private var showcaseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("真实效果展示")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.inkBlack)
                Spacer()
            }

            HStack(spacing: 12) {
                showcaseCard(imageName: "ShowcaseMaleComparison", label: "证件照优化")
                showcaseCard(imageName: "ShowcaseFemaleComparison", label: "职业形象照")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private func showcaseCard(imageName: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 110)
                    .clipped()

                aiGeneratedBadge
                    .padding(6)
            }
            .frame(height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray5), lineWidth: 1))

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.branchGray)
        }
        .frame(maxWidth: .infinity)
    }

    private var aiGeneratedBadge: some View {
        Text("AI生成")
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(.white.opacity(0.84))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.20))
            .clipShape(Capsule())
    }

    // MARK: - Home Bottom Bar

    private var homeBottomBar: some View {
        VStack(spacing: 0) {
            Color(.systemGray5).frame(height: 0.5)
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.promoOrange)
                        Text("限时优惠")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.branchGray)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("3.80")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.skyBlue)
                        Text("元/张")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.inkBlack)
                        Text("原价9.90元")
                            .font(.system(size: 11))
                            .strikethrough(color: Color.branchGray)
                            .foregroundStyle(Color.branchGray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)

                Button { navigateToCreation = true } label: {
                    HStack(spacing: 6) {
                        Text("立即制作")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.skyBlue, Color.skyBlueMid],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                }
                .layoutPriority(1)
                .padding(.trailing, 8)
            }
            .padding(.horizontal, 32)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .background(Color(.systemBackground))
        }
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
        .frame(height: 190)
        .clipped()
        .overlay(alignment: .bottom) {
            Color.inkBlack.frame(height: 1)
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

            Group {
                if outputImage != nil {
                    postGenerationBar
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    preGenerationBar
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: outputImage != nil)
        }
    }

    private var postGenerationBar: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) { outputImage = nil }
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

            Button {
                showPrintLayout = true
            } label: {
                HStack(spacing: 6) {
                    Text("P")
                        .font(.system(size: 11, weight: .bold))
                    Text(printBottomLabel)
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(Color.inkFillForeground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.inkFill)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
    }

    private var preGenerationBar: some View {
        VStack(spacing: 8) {
            Button {
                Task { await generateTapped() }
            } label: {
                HStack(spacing: 8) {
                    if isGenerating {
                        GeneratingLabel(language: lang)
                    } else {
                        Circle()
                            .fill(inputImage == nil ? Color.branchGray : Color.treeGreen)
                            .frame(width: 6, height: 6)
                        Text(generateLabel)
                    }
                }
                .font(.system(size: 15, weight: .medium))
                .tracking(1)
                .foregroundStyle(inputImage == nil ? Color.branchGray : Color.inkFillForeground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(inputImage == nil ? Color(.systemGray5) : Color.inkFill)
            }
            .disabled(isGenerating || inputImage == nil)

            Text(taskUsageNote)
                .font(.system(size: 11))
                .foregroundStyle(Color.branchGray)
        }
        .padding(16)
        .background(Color(.systemBackground))
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

    private var appTitle:        String { l("光影形象馆", "AI ID Photo", "AI証明写真", "AI 증명사진", vi: "AI Ảnh Thẻ", id: "AI Foto ID", pt: "AI Foto Documento") }
    private var memberSubtitle:  String { l("制作包：3次生成 · 高清下载 · 含排版打印", "Photo task: 3 attempts · HD export · Print layout", "制作分：3回生成・HD保存・印刷込み", "제작권: 3회 생성 · HD 저장 · 인쇄 포함", vi: "Gói ảnh: 3 lần · HD · In ảnh", id: "Paket foto: 3 kali · HD · Cetak", pt: "Pacote: 3 tentativas · HD · Impressão") }
    private var memberLabel:     String { l("制作包", "Photo Task", "制作分", "제작권", vi: "Gói ảnh", id: "Paket foto", pt: "Pacote") }
    private var subscribedLabel: String { l("剩\(subscription.generationAttemptsLeft)次", "\(subscription.generationAttemptsLeft) left", "残\(subscription.generationAttemptsLeft)", "\(subscription.generationAttemptsLeft)회", vi: "Còn \(subscription.generationAttemptsLeft)", id: "Sisa \(subscription.generationAttemptsLeft)", pt: "\(subscription.generationAttemptsLeft) restam") }
    private var buyTaskLabel:    String { l("购买", "Buy", "購入", "구매", vi: "Mua", id: "Beli", pt: "Comprar") }
    private var historyNavLabel: String { l("历史记录", "History", "履歴", "기록", vi: "Lịch sử", id: "Riwayat", pt: "Histórico") }
    private var settingsNavLabel: String { l("设置", "Settings", "設定", "설정", vi: "Cài đặt", id: "Pengaturan", pt: "Configurações") }
    private var backNavLabel: String { l("返回首页", "Back to home", "ホームへ戻る", "홈으로 돌아가기", vi: "Về trang chính", id: "Kembali ke beranda", pt: "Voltar ao início") }
    private var photoTaskNavLabel: String {
        subscription.generationAttemptsLeft > 0
            ? l("制作包剩余 \(subscription.generationAttemptsLeft) 次", "\(subscription.generationAttemptsLeft) photo task attempts left", "制作分 残り\(subscription.generationAttemptsLeft)回", "제작권 \(subscription.generationAttemptsLeft)회 남음")
            : l("购买制作包", "Buy photo task", "制作分を購入", "제작권 구매", vi: "Mua gói ảnh", id: "Beli paket foto", pt: "Comprar pacote")
    }
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
    private var freeSubtitle:    String { l("限时优惠", "Launch offer", "限定特価", "한정 할인", vi: "Ưu đãi", id: "Promo", pt: "Oferta") }
    private var taskUsageNote: String {
        let left = subscription.generationAttemptsLeft
        if left > 0 {
            return l("本制作包剩余 \(left) 次生成 · 选最满意的照片下载",
                     "\(left) attempts left · Pick the best result to download",
                     "残り\(left)回 · ベストな写真を保存",
                     "\(left)회 남음 · 가장 좋은 사진을 저장")
        }
        let bonus = referralManager.bonusGenerations
        if bonus > 0 {
            return l("奖励生成剩余 \(bonus) 次 · 可先体验后购买制作包",
                     "\(bonus) bonus attempts left · Try before buying a task",
                     "ボーナス残り\(bonus)回",
                     "보너스 \(bonus)회 남음")
        }
        return l("限时 ¥3.80/张，原价 ¥9.90 · 含3次生成和排版下载",
                 "Launch offer ¥3.80/photo · Includes 3 attempts and print layout",
                 "特価 ¥3.80/枚 · 3回生成と印刷レイアウト込み",
                 "할인가 ¥3.80/장 · 생성 3회와 인쇄 포함")
    }
    private var remainingCountText: String {
        switch lang {
        case "zh": return "剩余生成次数：\(subscription.generationAttemptsLeft)"
        case "ja": return "残り：\(subscription.generationAttemptsLeft)回"
        case "ko": return "남은 횟수: \(subscription.generationAttemptsLeft)회"
        case "vi": return "Còn lại: \(subscription.generationAttemptsLeft)"
        case "id": return "Sisa: \(subscription.generationAttemptsLeft)"
        case "pt": return "Restantes: \(subscription.generationAttemptsLeft)"
        default:   return "Attempts left: \(subscription.generationAttemptsLeft)"
        }
    }
    private var comparisonTitle: String { l("效果对比", "Before & After", "効果比較", "전후 비교", vi: "Trước & Sau", id: "Sebelum & Sesudah", pt: "Antes & Depois") }
    private var saveLabel:       String { l("保存到相册", "Save to Photos", "写真を保存", "사진 저장", vi: "Lưu vào Ảnh", id: "Simpan ke Foto", pt: "Salvar em Fotos") }
    private var shareLabel:      String { l("分享", "Share", "共有", "공유", vi: "Chia sẻ", id: "Bagikan", pt: "Compartilhar") }
    private var regenerateLabel: String { l("重新生成", "Regenerate", "再生成", "재생성", vi: "Tạo lại", id: "Buat Ulang", pt: "Regerar") }
    private var retakeLabel:     String { l("换一张照片", "Try Another Photo", "別の写真で試す", "다른 사진으로", vi: "Thử ảnh khác", id: "Coba Foto Lain", pt: "Outra Foto") }
    private var savedMessage:    String { l("已保存到相册", "Saved to Photos", "写真を保存しました", "사진 저장 완료", vi: "Đã lưu vào Ảnh", id: "Tersimpan ke Foto", pt: "Salvo em Fotos") }
    private var printLayoutLabel: String { l("打印店排版", "Print Shop Layout", "プリントレイアウト", "인쇄 레이아웃") }
    private var printLayoutDesc:  String { l("生成排版照片，到打印店直接打印", "Print-ready layout for any photo print shop", "プリント用レイアウトを生成", "인쇄용 레이아웃 생성") }
    private var errorTitle:      String { l("错误", "Error", "エラー", "오류", vi: "Lỗi", id: "Kesalahan", pt: "Erro") }
    private var okLabel:         String { l("好的", "OK", "OK", "확인", vi: "OK", id: "OK", pt: "OK") }

    // Editorial strings
    private var uploadActionLabel:      String { l("撮影 / 選択", "Take / Select", "撮影 / 選択", "촬영 / 선택", vi: "Chụp / Chọn", id: "Ambil / Pilih", pt: "Tirar / Selecionar") }
    private var resetLabel:             String { l("重置", "Reset", "リセット", "리셋", vi: "Đặt lại", id: "Reset", pt: "Redefinir") }
    private var limitAlertTitle:        String { l("次数已用完", "Limit Reached", "回数上限に達しました", "횟수 초과", vi: "Đã hết lượt", id: "Batas Tercapai", pt: "Limite Atingido") }
    private var limitReachedMessage:    String { l("本制作包的生成次数已用完。购买后可再获得3次生成机会，并继续下载高清照片和排版图。", "This photo task is out of attempts. Buy another task for 3 more generations.", "この制作分の生成回数を使い切りました。追加購入で3回生成できます。", "이번 제작권의 생성 횟수를 모두 사용했습니다. 추가 구매로 3회 더 생성할 수 있습니다.", vi: "Đã hết lượt. Mua thêm để có 3 lần tạo ảnh.", id: "Percobaan habis. Beli lagi untuk 3 kali.", pt: "Tentativas esgotadas. Compre outro pacote para mais 3.") }
    private var subscriberLimitMessage: String { limitReachedMessage }
    private var upgradeLabel:           String { l("购买制作包", "Buy Task", "購入", "구매", vi: "Mua", id: "Beli", pt: "Comprar") }
    private var printBottomLabel:       String { l("打印店打印", "Print", "プリント", "인쇄") }

    // MARK: - Actions

    private func generateTapped() async {
        guard let input = inputImage, !isGenerating else { return }
        if let last = lastGenerateTime, Date().timeIntervalSince(last) < 1.0 { return }

        if !hasGivenAIConsent {
            pendingGenerateAfterConsent = true
            showAIConsent = true
            return
        }
        let usesReferralBonus = !subscription.canGenerate() && referralManager.bonusGenerations > 0
        guard subscription.canGenerate() || usesReferralBonus else {
            limitAlertMessage = subscriberLimitMessage
            showLimitAlert = true
            AnalyticsManager.shared.track(AnalyticsManager.Event.paywallShown, properties: ["trigger": "noGenerationAttempts"])
            return
        }

        await performGenerate(input: input, usesReferralBonus: usesReferralBonus)
    }

    private func performGenerate(input: UIImage, usesReferralBonus: Bool = false) async {
        lastGenerateTime = Date()
        isGenerating = true
        defer { isGenerating = false }
        do {
            let basePrompt = isCustomSize ? customSize.prompt : selectedSpec.prompt
            let finalPrompt = basePrompt + photoOptions.buildPromptSuffix()
            let tier: GeminiService.OutputTier = .pro
            let px = isCustomSize ? customSize.pixelSize : selectedSpec.pixelSize
            let bgHex = isCustomSize ? customSize.backgroundColorHex : selectedSpec.backgroundColorHex
            let specInfo = GeminiService.SpecInfo(widthPx: px.width, heightPx: px.height, bgColorHex: bgHex)
            let result = try await GeminiService.shared.generateIDPhoto(
                from: input,
                prompt: finalPrompt,
                tier: tier,
                specInfo: specInfo
            )
            self.outputImage = result
            if usesReferralBonus {
                _ = referralManager.useBonusGeneration()
            } else {
                subscription.consumeGenerationAttempt()
            }
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
        let items: [Any] = [img]

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
