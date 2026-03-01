---
name: swift-conventions
description: Swift and iOS development conventions for this project. Use when writing, reviewing, or refactoring Swift code, creating new SwiftUI views, or working with iOS frameworks like StoreKit, URLSession, or UIKit bridges.
user-invocable: false
---

# Swift & iOS Conventions

## Architecture: MVVM

- **View**: SwiftUI views — layout and presentation only, no business logic
- **ViewModel**: `@MainActor final class XxxViewModel: ObservableObject` — owns state and logic
- **Model**: Plain `struct` types conforming to `Codable` where applicable
- **Service**: Singleton or injected networking/persistence layer

```swift
// ViewModel pattern
@MainActor
final class PhotoViewModel: ObservableObject {
    @Published private(set) var state: ViewState = .idle
    private let service: GeminiService

    init(service: GeminiService = .shared) {
        self.service = service
    }
}
```

## SwiftUI Patterns

- Use `@StateObject` for view-owned state, `@EnvironmentObject` for app-wide dependencies
- Extract sub-views as `private var` computed properties when `body` exceeds ~40 lines
- Use `task { }` modifier for async work on appear
- Prefer `.sheet(item:)` over `.sheet(isPresented:)` when passing data
- Use `ViewModifier` for reusable styling (e.g., glass button style)
- Always handle loading / error / empty states in views

## Error Handling

All custom error types must conform to `LocalizedError`:

```swift
enum GeminiError: LocalizedError {
    case invalidConfig
    case networkError(underlying: Error)
    case decodeFailed

    var errorDescription: String? {
        switch self {
        case .invalidConfig: return "API 配置无效，请检查设置"
        case .networkError(let e): return "网络请求失败：\(e.localizedDescription)"
        case .decodeFailed: return "无法解析服务器返回的数据"
        }
    }
}
```

## Networking

- Use `Codable` structs for request/response models — avoid raw `JSONSerialization`
- Use `JSONEncoder`/`JSONDecoder` with explicit coding strategies
- Handle HTTP status codes explicitly (not just != 200)
- Timeout: 60 seconds for image generation requests

```swift
struct GeminiRequest: Encodable {
    let contents: [Content]
}

struct GeminiResponse: Decodable {
    let candidates: [Candidate]
}
```

## StoreKit 2

- Use `Transaction.currentEntitlements` on launch for initial state
- Listen to `Transaction.updates` in a separate `Task` for real-time updates
- Always call `transaction.finish()` after processing
- Test with StoreKit Configuration file in Xcode

## Conditional Compilation

Use `#if canImport(...)` for optional frameworks (e.g., GoogleMobileAds):

```swift
#if canImport(GoogleMobileAds)
import GoogleMobileAds
// AdMob code
#endif
```

## Security

- NEVER store API keys in client-side code or Info.plist for production
- Use Keychain for sensitive persistent data, not UserDefaults
- Validate all server responses before using

## File Naming

- One primary type per file, file name matches type: `GeminiService.swift`
- ViewModels: `XxxViewModel.swift`
- Views: `XxxView.swift`
- Managers: `XxxManager.swift`
- Group by feature in folders: `Views/`, `Managers/`, `Services/`, `Models/`

## iOS Target

- Deployment target: iOS 16.0
- iPhone only (`TARGETED_DEVICE_FAMILY: "1"`)
- Portrait orientation only
- Swift 5.9+
