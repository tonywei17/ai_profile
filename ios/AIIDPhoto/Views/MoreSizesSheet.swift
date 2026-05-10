import SwiftUI

// MARK: - Category Definition

private struct SpecCategory {
    let name: String
    let icon: String
    let specs: [IDPhotoSpec]
}

private let allCategories: [SpecCategory] = [
    SpecCategory(name: "全部",   icon: "square.grid.2x2.fill",        specs: IDPhotoSpec.allCases),
    SpecCategory(name: "身份证件", icon: "creditcard.fill",             specs: [.chinaID, .oneInch, .twoInch, .standardPortrait, .socialSecurity]),
    SpecCategory(name: "护照签证", icon: "airplane.departure",          specs: [.chinaPassport, .oneInchLarge]),
    SpecCategory(name: "驾驶出行", icon: "car.fill",                    specs: [.driverLicense]),
    SpecCategory(name: "学历教育", icon: "graduationcap.fill",           specs: [.studentID, .ncreExam]),
    SpecCategory(name: "求职简历", icon: "doc.text.image.fill",          specs: [.resume]),
    SpecCategory(name: "婚育登记", icon: "heart.fill",                   specs: [.chinaMarriage]),
    SpecCategory(name: "商务形象", icon: "person.crop.rectangle.stack",  specs: [.halfBody, .fullBody]),
]

// MARK: - Sheet View

struct MoreSizesSheet: View {
    @Binding var selectedSpec: IDPhotoSpec
    var isSubscribed: Bool
    var onLockedTap: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategoryIndex = 0
    @Namespace private var categoryNS

    private var filteredSpecs: [IDPhotoSpec] {
        allCategories[selectedCategoryIndex].specs
    }

    var body: some View {
        VStack(spacing: 0) {
            handle
            titleBar
            categoryTabs
            Divider()
            specGrid
        }
        .background(Color(.systemBackground))
    }

    // MARK: Handle & Title

    private var handle: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color(.systemGray4))
            .frame(width: 36, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 4)
    }

    private var titleBar: some View {
        HStack {
            Text("全部规格")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.inkBlack)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(.systemGray3))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    // MARK: Category Tabs

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(allCategories.indices, id: \.self) { i in
                    categoryChip(index: i)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    private func categoryChip(index: Int) -> some View {
        let cat = allCategories[index]
        let isSelected = selectedCategoryIndex == index
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategoryIndex = index
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: cat.icon)
                    .font(.system(size: 11))
                Text(cat.name)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? .white : Color.inkBlack)
            .padding(.horizontal, 13)
            .padding(.vertical, 7)
            .background(
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(Color.skyBlue)
                            .matchedGeometryEffect(id: "chip", in: categoryNS)
                    } else {
                        Capsule()
                            .fill(Color(.systemGray6))
                    }
                }
            )
        }
        .animation(.easeInOut(duration: 0.2), value: selectedCategoryIndex)
    }

    // MARK: Spec Grid

    private var specGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(filteredSpecs) { spec in
                    specCard(spec)
                }
            }
            .padding(16)
            .padding(.bottom, 20)
        }
    }

    private func specCard(_ spec: IDPhotoSpec) -> some View {
        let isSelected = selectedSpec == spec
        let isLocked = spec.isPro && !isSubscribed
        let (wMM, hMM) = spec.photoSizeMM
        let aspect = wMM / hMM

        return Button {
            if isLocked {
                onLockedTap()
            } else {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedSpec = spec
                }
                dismiss()
            }
        } label: {
            VStack(spacing: 10) {
                // Aspect-ratio preview
                ZStack(alignment: .topTrailing) {
                    GeometryReader { geo in
                        let maxH: CGFloat = 70
                        let previewW = min(geo.size.width, maxH * CGFloat(aspect))
                        let previewH = previewW / CGFloat(aspect)

                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(
                                    isSelected
                                        ? Color.skyBlue.opacity(0.15)
                                        : (isLocked ? Color(.systemGray6).opacity(0.6) : Color(.systemGray6))
                                )

                            if isLocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color(.systemGray3))
                            } else if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color.skyBlue.opacity(0.6))
                            }
                        }
                        .frame(width: previewW, height: previewH)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(
                                    isSelected ? Color.skyBlue.opacity(0.5) : Color(.systemGray4),
                                    lineWidth: 1
                                )
                        )
                        .position(x: geo.size.width / 2, y: maxH / 2)
                    }
                    .frame(height: 70)

                    // PRO badge
                    if spec.isPro {
                        Text("PRO")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.promoOrange)
                            .clipShape(Capsule())
                            .padding(6)
                    }
                }

                // Name & size
                VStack(spacing: 3) {
                    Text(spec.displayName(language: "zh"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isLocked ? Color(.systemGray3) : (isSelected ? Color.skyBlue : Color.inkBlack))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(spec.sizeLabel)
                        .font(.system(size: 11))
                        .foregroundStyle(isLocked ? Color(.systemGray4) : Color.branchGray)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.skyBlue.opacity(0.06) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? Color.skyBlue : Color(.systemGray5),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
        }
    }
}
