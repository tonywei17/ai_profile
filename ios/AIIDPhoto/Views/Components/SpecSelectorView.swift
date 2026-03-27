import SwiftUI

struct SpecSelectorView: View {
    @Binding var selected: IDPhotoSpec
    @Binding var isCustomSize: Bool
    let specs: [IDPhotoSpec]
    let language: String
    let isSubscribed: Bool
    let onLockedTap: () -> Void

    @State private var showAll = false

    private var displayedSpecs: [IDPhotoSpec] {
        showAll ? specs : Array(specs.prefix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section label
            Text(sectionLabel)
                .font(.system(size: 11, weight: .regular))
                .tracking(1.5)
                .textCase(.uppercase)
                .foregroundStyle(Color.branchGray)

            VStack(spacing: 0) {
                specGrid

                // Show more / less
                if specs.count > 4 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { showAll.toggle() }
                    } label: {
                        HStack(spacing: 6) {
                            Text(showAll ? collapseText : expandText)
                                .font(.system(size: 12, weight: .medium))
                            Image(systemName: showAll ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(Color.inkBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(alignment: .top) {
                            Color.inkBlack.frame(height: 1)
                        }
                    }
                }

                // Custom size row (show when expanded)
                if showAll {
                    customSizeRow
                }
            }
            .overlay(Rectangle().stroke(Color.inkBlack, lineWidth: 1))
        }
    }

    // MARK: - Spec Grid

    private var specGrid: some View {
        let cols = [GridItem(.flexible(), spacing: 0), GridItem(.flexible(), spacing: 0)]

        return LazyVGrid(columns: cols, spacing: 0) {
            ForEach(Array(displayedSpecs.enumerated()), id: \.element.id) { index, spec in
                let isActive = selected == spec && !isCustomSize
                let locked = spec.isPro && !isSubscribed

                Button {
                    if locked { onLockedTap() }
                    else {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isCustomSize = false
                            selected = spec
                        }
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(spec.displayName(language: language))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.inkBlack)
                            if locked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.branchGray)
                            }
                        }
                        Text(spec.sizeLabel)
                            .font(.system(size: 13, weight: .light))
                            .tracking(0.5)
                            .foregroundStyle(isActive ? Color.inkBlack : Color.branchGray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .frame(minHeight: 80)
                    .background(isActive ? Color.paperTan : Color(.systemBackground))
                    .overlay(alignment: .trailing) {
                        if index % 2 == 0 {
                            Color.inkBlack.frame(width: 1)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        let totalRows = (displayedSpecs.count + 1) / 2
                        let currentRow = index / 2
                        if currentRow < totalRows - 1 {
                            Color.inkBlack.frame(height: 1)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Custom Size Row

    private var customSizeRow: some View {
        Button {
            if !isSubscribed { onLockedTap() }
            else {
                withAnimation(.easeInOut(duration: 0.15)) { isCustomSize = true }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(customLabel)
                            .font(.system(size: 14, weight: .medium))
                        if !isSubscribed {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.branchGray)
                        }
                    }
                    Text("PRO")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(Color.branchGray)
                }
                Spacer()
            }
            .padding(16)
            .background(isCustomSize ? Color.paperTan : Color(.systemBackground))
            .overlay(alignment: .top) {
                Color.inkBlack.frame(height: 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Localized Strings

    private var sectionLabel: String {
        l("01. 格式", "01. Format", "01. Format", "01. 포맷",
          vi: "01. Định dạng", id: "01. Format", pt: "01. Formato")
    }

    private var expandText: String {
        l("显示更多", "Show More", "すべて表示", "더 보기",
          vi: "Xem thêm", id: "Lihat Semua", pt: "Ver Mais")
    }

    private var collapseText: String {
        l("收起", "Show Less", "閉じる", "접기",
          vi: "Thu gọn", id: "Tutup", pt: "Fechar")
    }

    private var customLabel: String {
        l("自定义尺寸", "Custom Size", "カスタムサイズ", "사용자 정의",
          vi: "Tùy chỉnh", id: "Kustom", pt: "Personalizado")
    }

    private func l(_ zh: String, _ en: String, _ ja: String, _ ko: String,
                   vi: String? = nil, id: String? = nil, pt: String? = nil) -> String {
        switch language {
        case "zh": return zh
        case "ja": return ja
        case "ko": return ko
        case "vi": return vi ?? en
        case "id": return id ?? en
        case "pt": return pt ?? en
        default:   return en
        }
    }
}
