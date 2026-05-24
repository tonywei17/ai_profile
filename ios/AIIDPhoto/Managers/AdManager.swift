import SwiftUI

@MainActor
final class AdManager: ObservableObject {
    func loadRewarded() async {}

    func showRewarded() async -> Bool {
        false
    }
}
