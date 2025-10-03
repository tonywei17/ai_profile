import SwiftUI
import PhotosUI

struct ContentView: View {
    @EnvironmentObject var subscription: SubscriptionManager
    @EnvironmentObject var usage: UsageManager
    @EnvironmentObject var adManager: AdManager

    @State private var selectedItem: PhotosPickerItem?
    @State private var inputImage: UIImage?
    @State private var outputImage: UIImage?

    @State private var isGenerating = false
    @State private var showSubscriptionSheet = false
    @State private var showCamera = false
    @State private var errorMessage: String?
    @State private var prompt: String = "生成证件照：浅色纯色背景，35x45mm，正脸居中，头肩框图，光照均匀，自然风格。"

    var body: some View {
        ZStack {
            GlassBackground.gradient
                .ignoresSafeArea()

            VStack(spacing: 16) {
                header

                glassCard

                generateSection

                if !subscription.isSubscribed {
                    AdBannerViewWrapper()
                        .frame(height: 50)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showSubscriptionSheet) {
            SubscriptionSheetView().environmentObject(subscription)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $inputImage)
                .ignoresSafeArea()
        }
        .alert("错误", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AI证件照")
                    .font(.largeTitle.bold())
                Text(subscription.isSubscribed ? "会员：每天可用20次" : usage.freeTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showSubscriptionSheet = true
            } label: {
                Label("会员", systemImage: "crown.fill")
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
    }

    private var glassCard: some View {
        VStack(spacing: 12) {
            if let image = inputImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay { RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.15)) }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.square")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)
                        Text("请选择一张生活照或自拍")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 220)
            }
            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("相册选择", systemImage: "photo")
                        .buttonStyle()
                }
                .onChange(of: selectedItem) { newItem in
                    Task { await loadSelectedImage(newItem) }
                }

                Button {
                    showCamera = true
                } label: {
                    Label("打开相机", systemImage: "camera")
                        .buttonStyle()
                }
            }

            if let result = outputImage {
                Divider().padding(.top, 8)
                VStack(alignment: .leading, spacing: 8) {
                    Text("生成的证件照：")
                        .font(.headline)
                    Image(uiImage: result)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay { RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.15)) }
                    HStack {
                        Button {
                            UIImageWriteToSavedPhotosAlbum(result, nil, nil, nil)
                        } label: {
                            Label("保存到相册", systemImage: "square.and.arrow.down")
                                .buttonStyle()
                        }
                        Spacer()
                        Button {
                            outputImage = nil
                        } label: {
                            Label("重新生成", systemImage: "gobackward")
                                .buttonStyle(style: .secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(GlassBackground.thin)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.15)) }
    }

    private var generateSection: some View {
        VStack(spacing: 8) {
            TextField("输入生成指令（可选）", text: $prompt)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 0)

            Button {
                Task { await generateTapped() }
            } label: {
                if isGenerating {
                    ProgressView().tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    Text("生成证件照")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(inputImage == nil ? Color.gray.opacity(0.4) : Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
            }
            .disabled(isGenerating || inputImage == nil)

            if !subscription.isSubscribed {
                Text("非会员：首次免费，再次需观看30秒广告")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("今日剩余次数：\(usage.subscriberUsesLeft)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func generateTapped() async {
        guard let input = inputImage else { return }

        let decision = usage.canGenerate(isSubscribed: subscription.isSubscribed)
        switch decision {
        case .allowed:
            await performGenerate(input: input)
        case .requireRewardedAd:
            await presentRewardedThenGenerate(input: input)
        case .reachedLimit:
            errorMessage = "已达到今日上限，请明天再试或开通会员。"
        }
    }

    private func presentRewardedThenGenerate(input: UIImage) async {
        await adManager.loadRewarded()
        let rewarded = await adManager.showRewarded()
        if rewarded {
            usage.markUsed(isSubscribed: false)
            await performGenerate(input: input)
        } else {
            errorMessage = "未完成广告观看，无法继续生成。"
        }
    }

    private func performGenerate(input: UIImage) async {
        isGenerating = true
        defer { isGenerating = false }
        do {
            let result = try await GeminiService.shared.generateIDPhoto(from: input, prompt: prompt)
            self.outputImage = result
            usage.markUsed(isSubscribed: subscription.isSubscribed)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadSelectedImage(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let ui = UIImage(data: data) {
            await MainActor.run { inputImage = ui }
        }
    }
}

private extension View {
    func buttonStyle(style: ButtonVisualStyle = .primary) -> some View {
        modifier(GlassButtonStyle(style: style))
    }
}

enum ButtonVisualStyle { case primary, secondary }

struct GlassButtonStyle: ViewModifier {
    let style: ButtonVisualStyle
    func body(content: Content) -> some View {
        content
            .font(.callout.bold())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(foreground)
    }
    private var background: AnyShapeStyle {
        switch style {
        case .primary: AnyShapeStyle(Color.accentColor)
        case .secondary: AnyShapeStyle(.ultraThinMaterial)
        }
    }
    private var foreground: Color {
        switch style {
        case .primary: .white
        case .secondary: .primary
        }
    }
}

struct AdBannerViewWrapper: View {
    var body: some View {
        #if canImport(GoogleMobileAds)
        AdBannerView()
        #else
        Color.clear
        #endif
    }
}
