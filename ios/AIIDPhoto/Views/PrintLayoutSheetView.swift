import SwiftUI

struct PrintLayoutSheetView: View {
    let image: UIImage
    let photoSizeMM: (width: Double, height: Double)
    let sizeLabel: String
    let isSubscribed: Bool
    let onLockedTap: () -> Void

    @EnvironmentObject var langManager: LanguageManager
    @EnvironmentObject var subscription: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedPaper: PrintPaperSize = .lSize
    @State private var showGuides = true
    @State private var renderedImage: UIImage?
    @State private var showSavedToast = false
    @State private var layout: PrintLayoutInfo?

    private var currentLayout: PrintLayoutInfo {
        layout ?? PrintLayoutInfo.calculate(photoSizeMM: photoSizeMM, paperSize: selectedPaper)
    }

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

    var body: some View {
        NavigationStack {
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
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showSavedToast { savedToast }
        }
        .task { updateLayout(); renderPreview() }
        .onChange(of: selectedPaper) { _ in updateLayout(); renderPreview() }
        .onChange(of: showGuides) { _ in renderPreview() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Rectangle()
                    .stroke(Color.inkBlack, lineWidth: 1)
                    .frame(width: 40, height: 40)
                Text("P")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.inkBlack)
            }

            Text(sheetTitle)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color.inkBlack)

            Text(sheetSubtitle)
                .font(.system(size: 13))
                .foregroundStyle(Color.branchGray)
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
                    .clipShape(Rectangle())
                    .overlay(Rectangle().stroke(Color.inkBlack, lineWidth: 1))
            } else {
                ProgressView()
                    .frame(height: 200)
            }

            HStack(spacing: 16) {
                Label(
                    "\(currentLayout.totalCount)\(photoCountUnit)",
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
        .overlay(Rectangle().stroke(Color.inkBlack, lineWidth: 1))
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
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.inkBlack)
                            Text(size.sizeLabel)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.branchGray)
                            Text("\(info.totalCount)\(photoCountUnit)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.inkBlack)
                            Text(size.priceHint(language: lang))
                                .font(.system(size: 11))
                                .foregroundStyle(Color.branchGray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .background(isSelected ? Color.paperTan : Color(.systemBackground))
                    .overlay(Rectangle().stroke(Color.inkBlack, lineWidth: isSelected ? 2 : 1))
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
        .overlay(Rectangle().stroke(Color.inkBlack, lineWidth: 1))
    }

    // MARK: - Save

    private var saveButton: some View {
        Group {
            if isSubscribed {
                Button {
                    savePrintLayout()
                } label: {
                    Label(saveLayoutLabel, systemImage: "square.and.arrow.down")
                        .font(.system(size: 15, weight: .medium))
                        .tracking(0.5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(.white)
                }
                .background(Color.inkBlack)
            } else if subscription.printLayoutCredits > 0 {
                Button {
                    subscription.consumePrintLayoutCredit()
                    savePrintLayout()
                } label: {
                    Label(saveWithCreditLabel, systemImage: "square.and.arrow.down")
                        .font(.system(size: 15, weight: .medium))
                        .tracking(0.5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(.white)
                }
                .background(Color.inkBlack)
            } else {
                VStack(spacing: 12) {
                    Button {
                        Task { await subscription.purchasePrintLayout() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "cart.fill")
                                .font(.body)
                            Text(singlePurchaseLabel)
                                .font(.system(size: 15, weight: .medium))
                            Spacer()
                            Text(subscription.printLayoutSingleDisplayPrice ?? "---")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                    }
                    .disabled(subscription.isPurchasing)
                    .background(Color.inkBlack)

                    Button { onLockedTap() } label: {
                        HStack(spacing: 10) {
                            Text("PRO")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(Color.inkBlack)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(subscribeHintLabel)
                                    .font(.system(size: 14, weight: .medium))
                                Text(subscribeHintDesc)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.branchGray)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.branchGray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .foregroundStyle(Color.inkBlack)
                    }
                    .overlay(Rectangle().stroke(Color.inkBlack, lineWidth: 1))
                }
            }
        }
        .alert(errorAlertTitle, isPresented: Binding(
            get: { subscription.purchaseError != nil },
            set: { if !$0 { subscription.purchaseError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(subscription.purchaseError ?? "")
        }
    }

    private func savePrintLayout() {
        guard let img = renderedImage else { return }
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
        showSavedToastBriefly()
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
        .overlay(Rectangle().stroke(Color.inkBlack, lineWidth: 1))
    }

    // MARK: - Toast

    private var savedToast: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
            Text(savedLabel)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.inkBlack)
        .padding(.bottom, 48)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Helpers

    private func updateLayout() {
        layout = PrintLayoutInfo.calculate(photoSizeMM: photoSizeMM, paperSize: selectedPaper)
    }

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
    private var saveWithCreditLabel: String {
        let c = subscription.printLayoutCredits
        return l("使用额度保存（剩余\(c)次）", "Save with Credit (\(c) left)", "クレジットで保存（残り\(c)回）", "크레딧으로 저장 (\(c)회 남음)",
                 vi: "Lưu bằng credit (\(c) còn lại)", id: "Simpan dengan kredit (\(c) sisa)", pt: "Salvar com crédito (\(c) restante)")
    }
    private var singlePurchaseLabel: String {
        l("单次购买排版", "Buy Single Print", "1回分を購入", "1회 인쇄 구매",
          vi: "Mua 1 lần in", id: "Beli 1x Cetak", pt: "Comprar 1 Impressão")
    }
    private var subscribeHintLabel: String {
        l("订阅更划算", "Subscribe & Save", "定額でもっとお得", "구독하면 더 저렴",
          vi: "Đăng ký tiết kiệm hơn", id: "Langganan Lebih Hemat", pt: "Assine e Economize")
    }
    private var subscribeHintDesc: String {
        l("同样价格享受一整月无限次排版 + 无限生成 + 无广告",
          "Same price for a full month: unlimited prints + generations + no ads",
          "同じ金額で1ヶ月間：無制限プリント＋生成＋広告なし",
          "같은 가격으로 한 달간: 무제한 인쇄 + 생성 + 광고 없음",
          vi: "Cùng giá cho 1 tháng: in không giới hạn + tạo ảnh + không QC",
          id: "Harga sama untuk sebulan: cetak + buat tanpa batas + tanpa iklan",
          pt: "Mesmo preço por 1 mês: impressão + geração ilimitada + sem anúncios")
    }
    private var errorAlertTitle: String {
        l("购买失败", "Purchase Failed", "購入に失敗しました", "구매 실패",
          vi: "Mua thất bại", id: "Pembelian Gagal", pt: "Compra Falhou")
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
