import SwiftUI

struct ProOptionsView: View {
    @Binding var options: PhotoOptions
    let isSubscribed: Bool
    let language: String
    let onLockedTap: () -> Void

    @AppStorage("proOptionsExpanded") private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            // Header — inside the card's padding context
            headerButton
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, isExpanded ? 10 : 14)

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    categoryRow(title: beautyTitle) {
                        ForEach(BeautyLevel.allCases) { item in
                            OptionChip(
                                label: item.displayName(language: language),
                                icon: item.icon,
                                isSelected: options.beauty == item,
                                isLocked: item.isPro && !isSubscribed
                            ) { select(pro: item.isPro) { options.beauty = item } }
                        }
                    }
                    categoryRow(title: attireTitle) {
                        ForEach(Attire.allCases) { item in
                            OptionChip(
                                label: item.displayName(language: language),
                                icon: item.icon,
                                isSelected: options.attire == item,
                                isLocked: item.isPro && !isSubscribed
                            ) { select(pro: item.isPro) { options.attire = item } }
                        }
                    }
                    categoryRow(title: hairTitle) {
                        ForEach(HairGrooming.allCases) { item in
                            OptionChip(
                                label: item.displayName(language: language),
                                icon: item.icon,
                                isSelected: options.hair == item,
                                isLocked: item.isPro && !isSubscribed
                            ) { select(pro: item.isPro) { options.hair = item } }
                        }
                    }
                    categoryRow(title: backgroundTitle) {
                        ForEach(BackgroundColorOption.allCases) { item in
                            BackgroundChip(
                                label: item.displayName(language: language),
                                swatchColor: item.swatchColor,
                                isSelected: options.background == item,
                                isLocked: item.isPro && !isSubscribed
                            ) { select(pro: item.isPro) { options.background = item } }
                        }
                    }
                    categoryRow(title: accessoriesTitle) {
                        ForEach(AccessoriesCleanup.allCases) { item in
                            OptionChip(
                                label: item.displayName(language: language),
                                icon: item.icon,
                                isSelected: options.accessories == item,
                                isLocked: item.isPro && !isSubscribed
                            ) { select(pro: item.isPro) { options.accessories = item } }
                        }
                    }
                }
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    // MARK: - Header

    private var headerButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        LinearGradient(colors: [.yellow, .orange],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                Text(sectionTitle)
                    .font(.callout.weight(.semibold))
                if !isSubscribed {
                    Text("PRO")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(colors: [.orange, .pink],
                                           startPoint: .leading,
                                           endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
            }
        }
    }

    // MARK: - Helpers

    private func select(pro: Bool, action: () -> Void) {
        if pro && !isSubscribed {
            onLockedTap()
        } else {
            withAnimation(.easeInOut(duration: 0.2)) { action() }
        }
    }

    // MARK: - Category Row

    private func categoryRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.leading, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    content()
                }
                .padding(.vertical, 2)
            }
            .contentMargins(.leading, 16, for: .scrollContent)
            .contentMargins(.trailing, 8, for: .scrollContent)
        }
    }

    // MARK: - Localized Strings

    private var sectionTitle:      String { l("AI 自定义", "AI Customize", "AI カスタマイズ", "AI 커스터마이즈",
                                              vi: "AI Tùy chỉnh", id: "AI Kustomisasi", pt: "AI Personalizar") }
    private var beautyTitle:       String { l("美颜",      "Beauty",       "美肌",           "뷰티",
                                              vi: "Làm đẹp", id: "Kecantikan", pt: "Beleza") }
    private var attireTitle:       String { l("服装",      "Attire",       "服装",           "복장",
                                              vi: "Trang phục", id: "Pakaian", pt: "Traje") }
    private var hairTitle:         String { l("发型",      "Hair",         "髪型",           "헤어",
                                              vi: "Tóc", id: "Rambut", pt: "Cabelo") }
    private var backgroundTitle:   String { l("背景色",    "Background",   "背景色",         "배경색",
                                              vi: "Nền", id: "Latar", pt: "Fundo") }
    private var accessoriesTitle:  String { l("配饰",      "Accessories",  "アクセサリー",   "액세서리",
                                              vi: "Phụ kiện", id: "Aksesori", pt: "Acessórios") }

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

// MARK: - Option Chip

private struct OptionChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(.caption.bold())
                    .lineLimit(1)
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .opacity(isLocked ? 0.55 : 1.0)
        }
        .glassEffect(
            isSelected ? .regular.tint(.blue) : .regular,
            in: .capsule
        )
    }
}

// MARK: - Background Color Chip

private struct BackgroundChip: View {
    let label: String
    let swatchColor: Color?
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let color = swatchColor {
                    Circle()
                        .fill(color)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle().strokeBorder(.primary.opacity(0.2), lineWidth: 0.5)
                        )
                } else {
                    Image(systemName: "rectangle.dashed")
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(label)
                    .font(.caption.bold())
                    .lineLimit(1)
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .opacity(isLocked ? 0.55 : 1.0)
        }
        .glassEffect(
            isSelected ? .regular.tint(.blue) : .regular,
            in: .capsule
        )
    }
}
