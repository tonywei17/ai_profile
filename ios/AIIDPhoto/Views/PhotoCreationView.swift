import SwiftUI
import PhotosUI

struct PhotoCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscription: SubscriptionManager
    @EnvironmentObject var langManager: LanguageManager
    @EnvironmentObject var historyManager: HistoryManager
    @EnvironmentObject var referralManager: ReferralManager

    @State private var selectedItem: PhotosPickerItem?
    @State private var inputImage: UIImage?
    @State private var outputImage: UIImage?
    @State private var selectedSpec: IDPhotoSpec = .oneInch
    @State private var photoOptions = PhotoOptions.defaults
    @State private var isGenerating = false
    @State private var currentStep = 1
    @State private var showPhotoPicker = false
    @State private var showPhotoSourceDialog = false
    @State private var showCamera = false
    @State private var showMoreSizes = false
    @State private var showSubscriptionSheet = false
    @State private var errorMessage: String?
    @State private var lastError: GeminiError?
    @State private var showSavedToast = false
    @State private var customBgColor: Color = Color(red: 0.83, green: 0.91, blue: 0.97)
    @State private var isCustomBgActive = false
    @State private var showColorPicker = false
    @State private var showPrintLayout = false
    @State private var showCameraDeniedAlert = false

    private let featuredSpecs: [IDPhotoSpec] = [.oneInch, .twoInch, .resume, .chinaPassport, .twoInchSmall]
    private let backgroundOptions: [BackgroundColorOption] = [.specDefault, .pureWhite, .red, .lightBlue, .lightGray]
    private let includedFeatureAccess = true

    private let steps = ["上传照片", "选择场景", "AI优化", "下载保存"]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                progressStepsView
                    .overlay(alignment: .bottom) { Color(.systemGray5).frame(height: 0.5) }

                ScrollView {
                    VStack(spacing: 0) {
                        if currentStep <= 2 {
                            uploadSection
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                            sectionDivider
                            aiFeatureSection
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                            sectionDivider
                            specSection
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                            sectionDivider
                            expressionSection
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                            sectionDivider
                            beautySection
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                            sectionDivider
                            attireSection
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                            sectionDivider
                            hairSection
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                            sectionDivider
                            backgroundSection
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                        } else if currentStep == 3 {
                            generatingView
                        } else {
                            resultView
                        }
                    }
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 110)
                }
            }

            generateBarView
        }
        .navigationTitle("制作形象照")
        .navigationBarTitleDisplayMode(.inline)
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
        .confirmationDialog("", isPresented: $showPhotoSourceDialog) {
            Button("从相册选择") { showPhotoPicker = true }
            Button("拍摄照片") { handleCameraTap() }
        }
        .alert("相机权限未开启", isPresented: $showCameraDeniedAlert) {
            Button("去设置开启") { PermissionManager.openSettings() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("请在「设置 → 光影形象馆 → 相机」中开启权限后再试。")
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $inputImage).ignoresSafeArea()
        }
        .sheet(isPresented: $showMoreSizes) {
            MoreSizesSheet(
                selectedSpec: $selectedSpec,
                isSubscribed: includedFeatureAccess,
                onLockedTap: {
                    showMoreSizes = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showSubscriptionSheet = true
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showColorPicker) {
            ColorPaletteSheet(initialColor: customBgColor) { color in
                customBgColor = color
                isCustomBgActive = true
                photoOptions.background = .specDefault
            }
            .presentationDetents([.fraction(0.65), .large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showSubscriptionSheet) {
            SubscriptionSheetView()
                .environmentObject(subscription)
                .environmentObject(langManager)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showPrintLayout) {
            if let output = outputImage {
                PrintLayoutSheetView(
                    image: output,
                    photoSizeMM: selectedSpec.photoSizeMM,
                    sizeLabel: selectedSpec.sizeLabel,
                    isSubscribed: includedFeatureAccess,
                    onLockedTap: {
                        showPrintLayout = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showSubscriptionSheet = true
                        }
                    }
                )
                .environmentObject(langManager)
                .environmentObject(subscription)
                .presentationDetents([.large])
            }
        }
        .onChange(of: selectedItem) { _, item in
            Task { await loadImage(item) }
        }
        .onChange(of: inputImage) { _, img in
            if img != nil, currentStep == 1 { currentStep = 2 }
        }
        .alert("生成失败", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil; lastError = nil } }
        )) {
            if lastError?.isRetryable ?? true {
                Button("重试") {
                    errorMessage = nil
                    let err = lastError
                    lastError = nil
                    Task {
                        // 给短暂延迟让 alert 完全消失
                        try? await Task.sleep(for: .milliseconds(200))
                        await generate()
                    }
                    _ = err
                }
            }
            Button("好的", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .overlay(alignment: .bottom) {
            if showSavedToast { savedToast }
        }
    }

    // MARK: - Progress Steps

    private var progressStepsView: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, title in
                VStack(spacing: 5) {
                    ZStack {
                        Circle()
                            .fill(index + 1 <= currentStep ? Color.skyBlue : Color(.systemGray5))
                            .frame(width: 28, height: 28)
                        if index + 1 < currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(index + 1 == currentStep ? .white : Color(.systemGray3))
                        }
                    }
                    Text(title)
                        .font(.system(size: 10))
                        .foregroundStyle(index + 1 <= currentStep ? Color.skyBlue : Color(.systemGray3))
                }

                if index < steps.count - 1 {
                    Rectangle()
                        .fill(index + 1 < currentStep ? Color.skyBlue : Color(.systemGray5))
                        .frame(height: 1.5)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 18)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
    }

    // MARK: - Upload Section

    private var uploadSection: some View {
        VStack(spacing: 0) {
            if let image = inputImage {
                ZStack(alignment: .bottomTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(maxWidth: .infinity)

                    Button { showPhotoSourceDialog = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11, weight: .medium))
                            Text("更换照片")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.skyBlue.opacity(0.85))
                        .clipShape(Capsule())
                    }
                    .padding(10)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.skyBlue.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                        .background(Color.skyBlue.opacity(0.02).clipShape(RoundedRectangle(cornerRadius: 12)))
                )
            } else {
                Button { showPhotoSourceDialog = true } label: {
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.skyBlue.opacity(0.10))
                                .frame(width: 70, height: 70)
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(Color.skyBlue)
                        }
                        VStack(spacing: 6) {
                            Text("点击上传照片")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.inkBlack)
                            Text("支持 JPG/PNG 格式，大小不超过 20MB")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.branchGray)
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.skyBlueMid)
                                Text("建议正面、光线充足、无遮挡")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.branchGray)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.skyBlue.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                            .background(Color.skyBlue.opacity(0.03).clipShape(RoundedRectangle(cornerRadius: 12)))
                    )
                }
            }
        }
    }

    // MARK: - AI Feature Section (informational tags only)

    private let aiFeatures: [(icon: String, label: String)] = [
        ("person.crop.circle.badge.checkmark", "智能抠图"),
        ("paintpalette.fill",                   "自动换底色"),
        ("crop",                                "尺寸适配"),
        ("sparkles",                            "AI 美颜优化"),
        ("shield.checkerboard",                 "隐私保护"),
    ]

    private var aiFeatureSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.skyBlue)
                Text("AI 将自动处理以下项目")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.inkBlack)
            }

            // Flowing tag layout
            FlowTagLayout(spacing: 8) {
                ForEach(aiFeatures, id: \.label) { feature in
                    HStack(spacing: 5) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.skyBlue)
                        Text(feature.label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.skyBlue)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.skyBlue.opacity(0.08))
                            .overlay(Capsule().strokeBorder(Color.skyBlue.opacity(0.2), lineWidth: 1))
                    )
                }
            }
        }
    }

    // MARK: - Spec Section

    private var specSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Text("选择规格")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.inkBlack)
                Text("热门")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.promoRed)
                    .clipShape(Capsule())
            }

            let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(featuredSpecs) { spec in
                    specButton(spec: spec)
                }
                moreSpecsButton
            }
        }
    }

    private func specButton(spec: IDPhotoSpec) -> some View {
        let isSelected = selectedSpec == spec
        return Button { selectedSpec = spec } label: {
            VStack(spacing: 3) {
                Text(spec.displayName(language: "zh"))
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.skyBlue : Color.inkBlack)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text(spec.sizeLabel)
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? Color.skyBlueMid : Color.branchGray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.skyBlue.opacity(0.06) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected ? Color.skyBlue : Color(.systemGray4),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
    }

    private var moreSpecsButton: some View {
        Button { showMoreSizes = true } label: {
            HStack(spacing: 4) {
                Text("更多尺寸")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.skyBlue)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.skyBlue)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.skyBlue.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.skyBlue.opacity(0.35), lineWidth: 1)
            )
        }
    }

    // MARK: - Expression Section

    private var expressionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("表情")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.inkBlack)

            HStack(spacing: 8) {
                ForEach(ExpressionStyle.allCases) { style in
                    expressionButton(style: style)
                }
            }
        }
    }

    private func expressionButton(style: ExpressionStyle) -> some View {
        let isSelected = photoOptions.expression == style
        return Button {
            photoOptions.expression = style
        } label: {
            VStack(spacing: 7) {
                Image(systemName: style.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color.skyBlue : Color(.systemGray3))
                Text(style.displayName(language: "zh"))
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.skyBlue : Color.inkBlack)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.skyBlue.opacity(0.06) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected ? Color.skyBlue : Color(.systemGray4),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
    }

    // MARK: - Beauty Section

    private var beautySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("美颜强度")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.inkBlack)

            HStack(spacing: 8) {
                ForEach(BeautyLevel.allCases) { level in
                    beautyButton(level: level)
                }
            }
        }
    }

    private func beautyButton(level: BeautyLevel) -> some View {
        let isSelected = photoOptions.beauty == level
        return Button {
            photoOptions.beauty = level
        } label: {
            VStack(spacing: 7) {
                Image(systemName: level.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color.skyBlue : Color(.systemGray3))
                HStack(spacing: 3) {
                    Text(level.displayName(language: "zh"))
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.skyBlue : Color.inkBlack)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.skyBlue.opacity(0.06) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected ? Color.skyBlue : Color(.systemGray4),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
    }

    // MARK: - Attire Section

    private var attireSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("选择服装")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.inkBlack)

            let cols = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(Attire.allCases) { attire in
                    attireButton(attire: attire)
                }
            }
        }
    }

    private func attireButton(attire: Attire) -> some View {
        let isSelected = photoOptions.attire == attire
        return Button {
            photoOptions.attire = attire
        } label: {
            HStack(spacing: 8) {
                Image(systemName: attire.icon)
                    .font(.system(size: 15))
                    .foregroundStyle(isSelected ? Color.skyBlue : Color.branchGray)
                    .frame(width: 20)
                HStack(spacing: 4) {
                    Text(attire.displayName(language: "zh"))
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.skyBlue : Color.inkBlack)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.skyBlue)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.skyBlue.opacity(0.06) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected ? Color.skyBlue : Color(.systemGray4),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
    }

    // MARK: - Hair Section

    private var hairSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("发型整理")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.inkBlack)

            HStack(spacing: 8) {
                ForEach(HairGrooming.allCases) { hair in
                    hairButton(hair: hair)
                }
            }
        }
    }

    private func hairButton(hair: HairGrooming) -> some View {
        let isSelected = photoOptions.hair == hair
        return Button {
            photoOptions.hair = hair
        } label: {
            HStack(spacing: 8) {
                Image(systemName: hair.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? Color.skyBlue : Color.branchGray)
                HStack(spacing: 4) {
                    Text(hair.displayName(language: "zh"))
                        .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.skyBlue : Color.inkBlack)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.skyBlue)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.skyBlue.opacity(0.06) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected ? Color.skyBlue : Color(.systemGray4),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
    }

    // MARK: - Background Section

    private var backgroundSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("选择底色")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.inkBlack)

            HStack(spacing: 12) {
                ForEach(backgroundOptions) { option in
                    backgroundCircle(option)
                }
                Button { showColorPicker = true } label: {
                    ZStack {
                        Circle()
                            .fill(isCustomBgActive ? customBgColor : Color(.systemGray6))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle().strokeBorder(
                                    isCustomBgActive ? Color.skyBlue : Color(.systemGray4),
                                    lineWidth: isCustomBgActive ? 2.5 : 1
                                )
                            )
                        if isCustomBgActive {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(bgLuminance(customBgColor) < 0.55 ? .white : Color.skyBlue)
                        } else {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.branchGray)
                        }
                    }
                }
            }
        }
    }

    private func backgroundCircle(_ option: BackgroundColorOption) -> some View {
        let isSelected = photoOptions.background == option && !isCustomBgActive
        let color: Color = {
            switch option {
            case .specDefault: return Color(red: 0.26, green: 0.55, blue: 0.86)
            case .pureWhite:   return .white
            case .red:         return Color(red: 0.81, green: 0.19, blue: 0.19)
            case .lightBlue:   return Color(red: 0.83, green: 0.91, blue: 0.97)
            case .lightGray:   return Color(red: 0.91, green: 0.91, blue: 0.91)
            }
        }()
        return Button {
            photoOptions.background = option
            isCustomBgActive = false
        } label: {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle().strokeBorder(
                            isSelected ? Color.skyBlue : Color(.systemGray4),
                            lineWidth: isSelected ? 2.5 : 1
                        )
                    )
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(option == .pureWhite ? Color.skyBlue : .white)
                }
            }
        }
    }

    // MARK: - Generating View

    private var generatingView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)

            ZStack {
                Circle()
                    .fill(Color.skyBlue.opacity(0.08))
                    .frame(width: 100, height: 100)
                ProgressView()
                    .scaleEffect(1.6)
                    .tint(Color.skyBlue)
            }

            VStack(spacing: 8) {
                Text("AI 正在生成中…")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.inkBlack)
                Text("预计 1-2 分钟，请耐心等候")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.branchGray)
            }

            VStack(alignment: .leading, spacing: 10) {
                generatingStep(icon: "person.crop.circle.badge.checkmark", text: "智能识别人像主体")
                generatingStep(icon: "paintpalette.fill",                   text: "自动去除背景并替换底色")
                generatingStep(icon: "crop",                                text: "精确裁切至目标尺寸")
                generatingStep(icon: "sparkles",                            text: "AI 美颜自然优化")
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray6).opacity(0.8))
            )
            .padding(.horizontal, 24)
        }
    }

    private func generatingStep(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.skyBlue)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Color.inkBlack)
            Spacer()
            ProgressView()
                .scaleEffect(0.7)
                .tint(Color.skyBlueMid)
        }
    }

    // MARK: - Result View

    private var resultView: some View {
        VStack(spacing: 20) {
            if let output = outputImage, let input = inputImage {
                VStack(spacing: 4) {
                    Text("生成成功")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.inkBlack)
                    Text("满意后可下载，不满意可重新生成")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.branchGray)
                }
                .padding(.top, 20)

                ComparisonSliderView(before: input, after: output, language: "zh")
                    .aspectRatio(output.size.width / output.size.height, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 380)
                    .padding(.horizontal, 16)

                // 主操作行：重新生成 + 保存到相册
                HStack(spacing: 12) {
                    Button {
                        withAnimation {
                            outputImage = nil
                            currentStep = 2
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 13))
                            Text("重新生成")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(Color.skyBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.skyBlue, lineWidth: 1.5)
                        )
                    }

                    Button {
                        UIImageWriteToSavedPhotosAlbum(output, nil, nil, nil)
                        showSavedToastBriefly()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 13))
                            Text("保存到相册")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [Color.skyBlue, Color.skyBlueMid],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 16)

                // 打印排版入口
                Button { showPrintLayout = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "printer.fill")
                            .font(.system(size: 14))
                        Text("打印排版")
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                        Text("自动生成打印店可用的排版图")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.branchGray)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.branchGray)
                    }
                    .foregroundStyle(Color.inkBlack)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 16)

                Button { sharePhoto() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                        Text("分享照片")
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                    }
                    .foregroundStyle(Color.skyBlue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .background(Color.skyBlue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Generate Bar

    @ViewBuilder
    private var generateBarView: some View {
        if currentStep <= 2 {
            VStack(spacing: 0) {
                Color(.systemGray5).frame(height: 0.5)
                VStack(spacing: 6) {
                    Button {
                        guard inputImage != nil else { showPhotoSourceDialog = true; return }
                        Task { await generate() }
                    } label: {
                        Text(generateButtonTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: inputImage == nil
                                        ? [Color(.systemGray3), Color(.systemGray3)]
                                        : [Color.skyBlue, Color.skyBlueMid],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isGenerating)

                    Text(generateBarFootnote)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.branchGray)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
            }
        }
    }

    private var generateButtonTitle: String {
        guard inputImage != nil else { return "上传照片后生成" }
        let left = subscription.generationAttemptsLeft
        if left > 0 { return "开始生成（剩余\(left)次）" }
        let bonus = referralManager.bonusGenerations
        return bonus > 0 ? "开始生成（奖励\(bonus)次）" : "购买后生成（3次机会）"
    }

    private var generateBarFootnote: String {
        let left = subscription.generationAttemptsLeft
        if left > 0 {
            return "本制作包剩余 \(left) 次，可选择最满意照片下载"
        }
        let bonus = referralManager.bonusGenerations
        return bonus > 0
            ? "奖励生成剩余 \(bonus) 次，可先体验后购买制作包"
            : "限时3.80元/张，原价9.90元，含3次生成和排版下载"
    }

    // MARK: - Toast

    private var savedToast: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
            Text("已保存到相册")
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.skyBlue)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .padding(.bottom, 120)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Section Divider

    private var sectionDivider: some View {
        Color(.systemGray6)
            .frame(height: 8)
    }

    // MARK: - Color Helpers

    private func colorToHex(_ color: Color) -> String {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: nil)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    private func bgLuminance(_ color: Color) -> Double {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: nil)
        return Double(0.299 * r + 0.587 * g + 0.114 * b)
    }

    // MARK: - Actions

    private func handleCameraTap() {
        PermissionManager.requestCameraAccess { status in
            switch status {
            case .authorized:
                showCamera = true
            case .denied, .restricted:
                showCameraDeniedAlert = true
            case .notDetermined:
                break // 系统弹窗会在 requestAccess 内处理
            }
        }
    }

    private func loadImage(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let ui = UIImage(data: data) {
            await MainActor.run { inputImage = ui }
        }
    }

    private func generate() async {
        guard let input = inputImage, !isGenerating else { return }

        let usesReferralBonus = !subscription.canGenerate() && referralManager.bonusGenerations > 0
        guard subscription.canGenerate() || usesReferralBonus else {
            showSubscriptionSheet = true
            return
        }

        isGenerating = true
        withAnimation { currentStep = 3 }
        defer { isGenerating = false }
        do {
            var finalPrompt = selectedSpec.prompt + photoOptions.buildPromptSuffix()
            if isCustomBgActive {
                finalPrompt += "将照片背景替换为纯色 \(colorToHex(customBgColor))，覆盖之前的底色设定。"
            }
            let tier: GeminiService.OutputTier = .pro
            let px = selectedSpec.pixelSize
            // Effective bg hex: custom > preset override > spec default
            let bgHex: String
            if isCustomBgActive {
                bgHex = String(colorToHex(customBgColor).dropFirst()) // strip "#"
            } else {
                bgHex = photoOptions.background.bgColorHex ?? selectedSpec.backgroundColorHex
            }
            // 始终传 specInfo，让 Hivision 做高质量抠图+裁切+底色（第一阶段）。
            // 若有外观编辑选项，cosmeticPrompt 会触发后端第二阶段（Qwen/Bailian）叠加处理。
            let specInfo = GeminiService.SpecInfo(widthPx: px.width, heightPx: px.height, bgColorHex: bgHex)
            let cosmeticPrompt = photoOptions.buildCosmeticPrompt()
            let result = try await GeminiService.shared.generateIDPhoto(
                from: input,
                prompt: finalPrompt,
                tier: tier,
                specInfo: specInfo,
                cosmeticPrompt: cosmeticPrompt
            )
            outputImage = result
            if usesReferralBonus {
                _ = referralManager.useBonusGeneration()
            } else {
                subscription.consumeGenerationAttempt()
            }
            historyManager.addRecord(
                image: result,
                specRawValue: selectedSpec.rawValue,
                sizeLabel: selectedSpec.sizeLabel,
                isCustomSize: false
            )
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation { currentStep = 4 }
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            if let ge = error as? GeminiError {
                lastError = ge
                errorMessage = ge.errorDescription
            } else {
                lastError = nil
                errorMessage = error.localizedDescription
            }
            withAnimation { currentStep = 2 }
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
