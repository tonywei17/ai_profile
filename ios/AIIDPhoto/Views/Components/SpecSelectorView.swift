import SwiftUI

struct SpecSelectorView: View {
    @Binding var selected: IDPhotoSpec
    @Binding var isCustomSize: Bool
    /// Locale-sorted spec list (caller provides, avoids recomputing on every render)
    let specs: [IDPhotoSpec]
    /// Current language code for display names
    let language: String
    /// Whether the user has an active subscription
    let isSubscribed: Bool
    /// Called when a locked Pro spec is tapped
    let onLockedTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(sectionTitle)
                .font(.callout.weight(.semibold))
                .tracking(0.3)
                .foregroundStyle(.secondary)
                .padding(.leading, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(specs) { spec in
                        let locked = spec.isPro && !isSubscribed
                        SpecCard(
                            name: spec.displayName(language: language),
                            size: spec.sizeLabel,
                            icon: spec.icon,
                            isSelected: selected == spec && !isCustomSize,
                            isLocked: locked
                        )
                        .onTapGesture {
                            if locked {
                                onLockedTap()
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isCustomSize = false
                                    selected = spec
                                }
                            }
                        }
                    }

                    // Custom size card (Pro)
                    SpecCard(
                        name: customLabel,
                        size: "PRO",
                        icon: "ruler.fill",
                        isSelected: isCustomSize,
                        isLocked: !isSubscribed
                    )
                    .onTapGesture {
                        if !isSubscribed {
                            onLockedTap()
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isCustomSize = true
                            }
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            .scrollClipDisabled(true)
            .contentMargins(.leading, 16, for: .scrollContent)
            .contentMargins(.trailing, 4, for: .scrollContent)
        }
    }

    private var sectionTitle: String {
        switch language {
        case "ja": return "規格を選択"
        case "ko": return "규격 선택"
        case "zh": return "选择规格"
        default:   return "Select Format"
        }
    }

    private var customLabel: String {
        switch language {
        case "ja": return "カスタム"
        case "ko": return "사용자 정의"
        case "zh": return "自定义"
        default:   return "Custom"
        }
    }
}

// MARK: - Spec Card

private struct SpecCard: View {
    let name: String
    let size: String
    let icon: String
    let isSelected: Bool
    let isLocked: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(isSelected ? .white : .primary)

            Text(name)
                .font(.caption.bold())
                .foregroundStyle(isSelected ? .white : .primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)

            Text(size)
                .font(.system(size: 10))
                .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
        }
        .padding(.horizontal, 6)
        .frame(width: 88, height: 92)
        .opacity(isLocked ? 0.6 : 1.0)
        .overlay(alignment: .topTrailing) {
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(Color.orange.gradient)
                    .clipShape(Circle())
                    .offset(x: 4, y: -4)
            }
        }
        .glassEffect(isSelected ? .regular.tint(.blue) : .regular, in: .rect(cornerRadius: 14))
        .scaleEffect(isSelected ? 1.04 : 1.0)
    }
}
