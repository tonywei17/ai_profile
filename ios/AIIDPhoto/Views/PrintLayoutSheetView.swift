import SwiftUI

struct PrintLayoutSheetView: View {
    let image: UIImage
    let photoSizeMM: (width: Double, height: Double)
    let sizeLabel: String
    let isSubscribed: Bool
    let onLockedTap: () -> Void

    @EnvironmentObject var langManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedPaper: PrintPaperSize = .lSize
    @State private var showGuides = true
    @State private var renderedImage: UIImage?
    @State private var showSavedToast = false

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

    private var layout: PrintLayoutInfo {
        PrintLayoutInfo.calculate(photoSizeMM: photoSizeMM, paperSize: selectedPaper)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            GlassBackground.gradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection
                    previewCard
                    paperPicker
                    infoSection
                    saveButton
                    instructionSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 52)
                .padding(.bottom, 32)
            }

            // Close
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.callout.bold())
                    .padding(10)
            }
            .glassEffect(.regular.interactive(), in: .circle)
            .padding(16)
        }
        .overlay(alignment: .bottom) {
            if showSavedToast { savedToast }
        }
        .task { renderPreview() }
        .onChange(of: selectedPaper) { _ in renderPreview() }
        .onChange(of: showGuides) { _ in renderPreview() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "printer.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(sheetTitle)
                .font(lang == "en"
                      ? .custom("PlusJakartaSans-Bold", size: 24)
                      : .system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(GlassBackground.titleGradient(for: colorScheme))

            Text(sheetSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Preview

    private var previewCard: some View {
        VStack(spacing: 12) {
            if let img = renderedImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(
                        CGFloat(selectedPaper.widthPx) / CGFloat(selectedPaper.heightPx),
                        contentMode: .fit
                    )
                    .frame(maxHeight: 360)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            } else {
                ProgressView()
                    .frame(height: 200)
            }

            HStack(spacing: 16) {
                Label(
                    "\(layout.totalCount)\(photoCountUnit)",
                    systemImage: "square.grid.2x2"
                )
                .font(.callout.bold())

                Text("•").foregroundStyle(.secondary)

                Text(sizeLabel)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text("•").foregroundStyle(.secondary)

                Text("300 DPI")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    // MARK: - Paper Size Picker

    private var paperPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(paperSizeLabel)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(PrintPaperSize.allCases) { size in
                    let isSelected = selectedPaper == size
                    let info = PrintLayoutInfo.calculate(photoSizeMM: photoSizeMM, paperSize: size)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPaper = size
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(size.displayName(language: lang))
                                .font(.callout.bold())
                                .foregroundStyle(isSelected ? .white : .primary)
                            Text(size.sizeLabel)
                                .font(.caption)
                                .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                            Text("\(info.totalCount)\(photoCountUnit)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    isSelected ? Color.white.opacity(0.25) : Color.blue
                                )
                                .clipShape(Capsule())
                            Text(size.priceHint(language: lang))
                                .font(.caption2)
                                .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .glassEffect(
                        isSelected ? .regular.tint(.blue) : .regular,
                        in: .rect(cornerRadius: 14)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(isSelected ? Color.blue.opacity(0.6) : .clear, lineWidth: 2)
                    )
                }
            }
        }
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $showGuides) {
                HStack(spacing: 10) {
                    Image(systemName: "scissors")
                        .foregroundStyle(.orange)
                    Text(guidesLabel)
                        .font(.callout)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().padding(.leading, 46)

            HStack(spacing: 10) {
                Image(systemName: "building.2.fill")
                    .foregroundStyle(.green)
                Text(compatLabel)
                    .font(.callout)
                Spacer()
                Text("7-11 · Lawson · FamilyMart")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    // MARK: - Save

    private var saveButton: some View {
        Group {
            if isSubscribed {
                Button {
                    guard let img = renderedImage else { return }
                    UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                    showSavedToastBriefly()
                } label: {
                    Label(saveLayoutLabel, systemImage: "square.and.arrow.down")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(.white)
                }
                .glassEffect(.regular.tint(.blue).interactive(), in: .rect(cornerRadius: 16))
            } else {
                Button { onLockedTap() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                        Text(unlockLabel)
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(.white)
                }
                .glassEffect(.regular.tint(.orange).interactive(), in: .rect(cornerRadius: 16))
            }
        }
    }

    // MARK: - Instructions

    private var instructionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(howToTitle)
                .font(.callout.bold())

            ForEach(Array(howToSteps.enumerated()), id: \.offset) { idx, step in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(idx + 1).")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 16, alignment: .trailing)
                    Text(step)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    // MARK: - Toast

    private var savedToast: some View {
        Label(savedLabel, systemImage: "checkmark.circle.fill")
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .glassEffect(.regular.tint(.green), in: .capsule)
            .padding(.bottom, 48)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Helpers

    private func renderPreview() {
        renderedImage = PrintLayoutService.shared.renderLayout(
            image: image,
            photoSizeMM: photoSizeMM,
            paperSize: selectedPaper,
            showGuides: showGuides
        )
    }

    private func showSavedToastBriefly() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring()) { showSavedToast = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut) { showSavedToast = false }
        }
    }

    // MARK: - Localized Strings

    private var sheetTitle: String {
        l("便利店排版打印", "Konbini Print Layout", "コンビニプリント", "편의점 인쇄 레이아웃",
          vi: "In ảnh tại cửa hàng", id: "Cetak di Konbini", pt: "Layout p/ Impressão")
    }
    private var sheetSubtitle: String {
        l("一键生成排版照片，直接到便利店打印",
          "Export a print-ready layout for convenience store printing",
          "コンビニで印刷できるレイアウト写真を一発生成",
          "편의점에서 바로 인쇄할 수 있는 레이아웃 생성",
          vi: "Tạo bố cục in ảnh, in tại cửa hàng tiện lợi",
          id: "Ekspor layout siap cetak untuk toko serba ada",
          pt: "Exporte um layout pronto para impressão em lojas")
    }
    private var paperSizeLabel: String {
        l("用纸尺寸", "Paper Size", "用紙サイズ", "용지 크기",
          vi: "Khổ giấy", id: "Ukuran Kertas", pt: "Tamanho do Papel")
    }
    private var photoCountUnit: String {
        l("张", " photos", "枚", "장",
          vi: " ảnh", id: " foto", pt: " fotos")
    }
    private var guidesLabel: String {
        l("裁剪参考线", "Cutting Guides", "カットガイド", "재단 가이드",
          vi: "Đường cắt", id: "Panduan Potong", pt: "Guias de Corte")
    }
    private var compatLabel: String {
        l("便利店兼容", "Konbini Compatible", "コンビニ対応", "편의점 호환",
          vi: "Tương thích cửa hàng", id: "Kompatibel Konbini", pt: "Compatível com Lojas")
    }
    private var saveLayoutLabel: String {
        l("保存排版照片", "Save Print Layout", "レイアウト写真を保存", "레이아웃 사진 저장",
          vi: "Lưu ảnh bố cục", id: "Simpan Layout Cetak", pt: "Salvar Layout")
    }
    private var unlockLabel: String {
        l("解锁排版打印", "Unlock Print Layout", "コンビニプリントを解除", "인쇄 레이아웃 잠금 해제",
          vi: "Mở khóa in ảnh", id: "Buka Layout Cetak", pt: "Desbloquear Impressão")
    }
    private var savedLabel: String {
        l("已保存到相册", "Saved to Photos", "写真を保存しました", "사진 저장 완료",
          vi: "Đã lưu vào Ảnh", id: "Tersimpan ke Foto", pt: "Salvo em Fotos")
    }
    private var howToTitle: String {
        l("使用方法", "How to Print", "印刷手順", "인쇄 방법",
          vi: "Hướng dẫn in", id: "Cara Cetak", pt: "Como Imprimir")
    }
    private var howToSteps: [String] {
        [
            l("保存排版照片到相册",
              "Save the layout image to Photos",
              "レイアウト写真をカメラロールに保存",
              "레이아웃 사진을 사진 앱에 저장",
              vi: "Lưu ảnh bố cục vào album",
              id: "Simpan foto layout ke Galeri",
              pt: "Salve a imagem de layout em Fotos"),
            l("将照片传输到便利店多功能复合机（USB、Wi-Fi或LINE等）",
              "Transfer the image to the konbini multi-function printer (USB, Wi-Fi, or LINE)",
              "USBやWi-Fi、LINEなどでコンビニのマルチコピー機に転送",
              "USB, Wi-Fi 또는 LINE으로 편의점 복합기에 전송",
              vi: "Chuyển ảnh sang máy in cửa hàng (USB, Wi-Fi hoặc LINE)",
              id: "Transfer gambar ke printer konbini (USB, Wi-Fi, atau LINE)",
              pt: "Transfira a imagem para a impressora (USB, Wi-Fi ou LINE)"),
            l("选择\"照片打印\" → L判或2L判",
              "Select \"Photo Print\" → L or 2L size",
              "「写真プリント」→ L判または2L判を選択",
              "\"사진 인쇄\" → L 또는 2L 사이즈 선택",
              vi: "Chọn \"In ảnh\" → L hoặc 2L",
              id: "Pilih \"Cetak Foto\" → ukuran L atau 2L",
              pt: "Selecione \"Imprimir Foto\" → tamanho L ou 2L"),
            l("打印后沿参考线裁剪即可使用",
              "Cut along the guide lines after printing",
              "印刷後、ガイドラインに沿って切り取り",
              "인쇄 후 가이드라인을 따라 자르기",
              vi: "Cắt theo đường hướng dẫn sau khi in",
              id: "Potong sesuai garis panduan setelah dicetak",
              pt: "Corte ao longo das linhas guia após imprimir"),
        ]
    }
}
