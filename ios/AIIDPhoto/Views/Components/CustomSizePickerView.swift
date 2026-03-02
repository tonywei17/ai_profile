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
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .purple],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                Text(title)
                    .font(.callout.bold())
                Spacer()
                Text(customSize.sizeLabel)
                    .font(.callout.monospacedDigit().bold())
                    .foregroundStyle(.blue)
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
                Stepper("", value: $customSize.widthMM,
                        in: CustomSizeSpec.minWidth...CustomSizeSpec.maxWidth,
                        step: 1)
                .labelsHidden()
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
                Stepper("", value: $customSize.heightMM,
                        in: CustomSizeSpec.minHeight...CustomSizeSpec.maxHeight,
                        step: 1)
                .labelsHidden()
            }

            // Range hint
            Text(rangeHint)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    // MARK: - Localized Strings

    private func l(_ zh: String, _ en: String, _ ja: String, _ ko: String) -> String {
        switch language {
        case "zh": return zh
        case "ja": return ja
        case "ko": return ko
        default:   return en
        }
    }

    private var title: String {
        l("自定义尺寸", "Custom Size", "カスタムサイズ", "사용자 정의 크기")
    }
    private var widthLabel: String {
        l("宽度", "Width", "幅", "너비")
    }
    private var heightLabel: String {
        l("高度", "Height", "高さ", "높이")
    }
    private var rangeHint: String {
        l("范围：宽 \(Int(CustomSizeSpec.minWidth))–\(Int(CustomSizeSpec.maxWidth))mm，高 \(Int(CustomSizeSpec.minHeight))–\(Int(CustomSizeSpec.maxHeight))mm",
          "Range: W \(Int(CustomSizeSpec.minWidth))–\(Int(CustomSizeSpec.maxWidth))mm, H \(Int(CustomSizeSpec.minHeight))–\(Int(CustomSizeSpec.maxHeight))mm",
          "範囲：幅 \(Int(CustomSizeSpec.minWidth))–\(Int(CustomSizeSpec.maxWidth))mm、高さ \(Int(CustomSizeSpec.minHeight))–\(Int(CustomSizeSpec.maxHeight))mm",
          "범위: 너비 \(Int(CustomSizeSpec.minWidth))–\(Int(CustomSizeSpec.maxWidth))mm, 높이 \(Int(CustomSizeSpec.minHeight))–\(Int(CustomSizeSpec.maxHeight))mm")
    }
}
