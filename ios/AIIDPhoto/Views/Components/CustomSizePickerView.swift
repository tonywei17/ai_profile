import SwiftUI

struct CustomSizePickerView: View {
    @Binding var customSize: CustomSizeSpec
    let language: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "ruler.fill")
                    .foregroundStyle(Color.inkBlack)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text(customSize.sizeLabel)
                    .font(.system(size: 14, weight: .bold).monospacedDigit())
                    .foregroundStyle(Color.inkBlack)
            }

            Divider()

            // Width stepper
            HStack {
                Text(widthLabel)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(customSize.widthMM)) mm")
                    .font(.callout.monospacedDigit())
                    .frame(width: 60, alignment: .trailing)
                Stepper(widthLabel, value: $customSize.widthMM,
                        in: CustomSizeSpec.minWidth...CustomSizeSpec.maxWidth,
                        step: 1)
                .labelsHidden()
                .accessibilityLabel(widthLabel)
                .accessibilityValue(Text("\(Int(customSize.widthMM)) mm"))
            }

            // Height stepper
            HStack {
                Text(heightLabel)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(customSize.heightMM)) mm")
                    .font(.callout.monospacedDigit())
                    .frame(width: 60, alignment: .trailing)
                Stepper(heightLabel, value: $customSize.heightMM,
                        in: CustomSizeSpec.minHeight...CustomSizeSpec.maxHeight,
                        step: 1)
                .labelsHidden()
                .accessibilityLabel(heightLabel)
                .accessibilityValue(Text("\(Int(customSize.heightMM)) mm"))
            }

            // Range hint
            Text(rangeHint)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .overlay(Rectangle().stroke(Color.inkBlack, lineWidth: 1))
    }

    // MARK: - Localized Strings

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

    private var title: String {
        l("自定义尺寸", "Custom Size", "カスタムサイズ", "사용자 정의 크기",
          vi: "Kích thước tùy chỉnh", id: "Ukuran Kustom", pt: "Tamanho Personalizado")
    }
    private var widthLabel: String {
        l("宽度", "Width", "幅", "너비",
          vi: "Chiều rộng", id: "Lebar", pt: "Largura")
    }
    private var heightLabel: String {
        l("高度", "Height", "高さ", "높이",
          vi: "Chiều cao", id: "Tinggi", pt: "Altura")
    }
    private var rangeHint: String {
        let minW = Int(CustomSizeSpec.minWidth)
        let maxW = Int(CustomSizeSpec.maxWidth)
        let minH = Int(CustomSizeSpec.minHeight)
        let maxH = Int(CustomSizeSpec.maxHeight)
        return l("范围：宽 \(minW)–\(maxW)mm，高 \(minH)–\(maxH)mm",
          "Range: W \(minW)–\(maxW)mm, H \(minH)–\(maxH)mm",
          "範囲：幅 \(minW)–\(maxW)mm、高さ \(minH)–\(maxH)mm",
          "범위: 너비 \(minW)–\(maxW)mm, 높이 \(minH)–\(maxH)mm",
          vi: "Phạm vi: R \(minW)–\(maxW)mm, C \(minH)–\(maxH)mm",
          id: "Rentang: L \(minW)–\(maxW)mm, T \(minH)–\(maxH)mm",
          pt: "Faixa: L \(minW)–\(maxW)mm, A \(minH)–\(maxH)mm")
    }
}
