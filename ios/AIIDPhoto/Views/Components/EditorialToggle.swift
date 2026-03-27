import SwiftUI

/// Square toggle switch matching the editorial design language.
struct EditorialToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Rectangle()
                .stroke(Color.inkBlack, lineWidth: 1)
                .frame(width: 36, height: 20)
                .background(isOn ? Color.paperTan : Color(.systemBackground))

            Rectangle()
                .fill(Color.inkBlack)
                .frame(width: 14, height: 14)
                .padding(2)
        }
        .frame(minWidth: 44, minHeight: 44) // iOS HIG minimum tap target
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.2), value: isOn)
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            isOn.toggle()
        }
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}
