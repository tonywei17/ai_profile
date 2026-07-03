# AIIDPhoto - Project Instructions

## Project Overview

SwiftUI iOS app for China-market AI ID photos and professional profile images.
- **Platform**: iOS 26+, iPhone + iPad (single-column layout)
- **Language**: Swift 5.9
- **UI Framework**: SwiftUI with glass (frosted) UI style
- **Project Generator**: XcodeGen (`project.yml`)
- **Backend**: Alibaba Cloud ECS + Nginx + PM2, HivisionIDPhotos + Alibaba Cloud Bailian/Qwen
- **Monetization**: StoreKit 2 consumable photo task, 3 AI generation attempts per purchase

## Project Structure

```
ios/AIIDPhoto/
├── AIIDPhotoApp.swift          # @main entry point
├── AppDelegate.swift           # App lifecycle hooks
├── Config.swift                # Info.plist config reader
├── ContentView.swift           # Main UI (spec selection, generate, compare, print)
├── Configuration/
│   ├── App.xcconfig            # Shared build settings, optional local secrets include
│   ├── Secrets.xcconfig.example
│   └── Products.storekit       # StoreKit testing configuration
├── Managers/
│   ├── SubscriptionManager.swift   # StoreKit 2 consumable purchase + attempts
│   ├── LanguageManager.swift       # 7-language switcher (zh/en/ja/ko/vi/id/pt)
│   ├── AnalyticsManager.swift      # Lightweight event tracking (local JSON)
│   ├── HistoryManager.swift        # Generation history (Documents dir)
│   └── ReferralManager.swift       # Referral invite system
├── Models/
│   ├── IDPhotoSpec.swift       # Photo specs (10+ presets) + CustomSizeSpec
│   ├── PhotoOptions.swift      # Beauty level & outfit style (Pro)
│   ├── PrintLayout.swift       # PrintPaperSize + PrintLayoutInfo grid calc
│   └── GenerationRecord.swift  # History record model
├── Resources/
│   ├── Fonts/                  # Plus Jakarta Sans (Bold, SemiBold)
│   └── {en,ja,ko,zh-Hans,vi,id,pt-BR}.lproj/Localizable.strings
├── Services/
│   ├── GeminiService.swift     # Historical name; backend generation API client
│   └── PrintLayoutService.swift # 300 DPI tiled print renderer
└── Views/
    ├── SubscriptionSheetView.swift
    ├── PrintLayoutSheetView.swift  # Print preview + save
    ├── SettingsView.swift          # Language, privacy, referral, version
    ├── OnboardingView.swift        # 4-page first-run onboarding
    ├── HistoryView.swift           # Generation history gallery
    └── Components/
        ├── GlassBackground.swift       # Liquid Glass backgrounds
        ├── ImagePickers.swift
        ├── ComparisonSliderView.swift  # Before/after drag slider
        ├── CustomSizePickerView.swift  # Pro custom size steppers
        ├── ProOptionsView.swift        # Beauty + outfit options
        └── SpecSelectorView.swift      # Horizontal spec card selector
```

## Build & Run

```bash
# Generate Xcode project (requires xcodegen)
xcodegen generate

# Build via command line
xcodebuild -project AIIDPhoto.xcodeproj -scheme AIIDPhoto -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run tests
xcodebuild -project AIIDPhoto.xcodeproj -scheme AIIDPhoto -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## Swift / iOS Conventions

### Architecture
- **Pattern**: SwiftUI views with focused managers/services. Follow existing local structure before adding new abstractions.
- **DI**: Use `@EnvironmentObject` for app-wide managers, `@StateObject` for view-owned state
- **Singletons**: Avoid where possible; prefer dependency injection

### Swift Style
- Use `Codable` for JSON models — avoid raw `JSONSerialization`
- Prefer `async/await` over completion handlers
- Mark all UI-bound classes with `@MainActor`
- Use `enum` namespaces for constants (e.g., `Config`)
- Error types must conform to `LocalizedError` with user-readable `errorDescription`

### SwiftUI
- Extract reusable view modifiers into `ViewModifier` structs
- Keep `body` computed property concise — extract sub-views as `private var`
- Use `task {}` modifier for async work on view appear
- Prefer `@Binding` for child views, `@State` for local state

### Naming
- Types: `PascalCase` (e.g., `GeminiService`, `SubscriptionManager`)
- Functions/properties: `camelCase` (e.g., `generateIDPhoto`, `isSubscribed`)
- Constants: `camelCase` in `enum` namespace (e.g., `Config.backendBaseURL`)
- Files: Match primary type name (e.g., `GeminiService.swift`)

### Error Handling
- Define domain-specific `Error` enums per module
- Always implement `LocalizedError` for user-facing errors
- Log errors with `print()` in debug, use `os.Logger` for production
- Show user-facing errors via `.alert()` modifier

### Localization
- All user-facing strings should use `String(localized:)` or `LocalizedStringKey`
- Keep string literals in views, extract to `.strings` files when adding i18n

## Key Dependencies

| Dependency | Purpose | Integration |
|-----------|---------|-------------|
| StoreKit 2 | Consumable photo task purchase | Built-in framework |
| HivisionIDPhotos | ID photo crop, matting, background | Server-side via backend |
| Alibaba Cloud Bailian/Qwen | Cosmetic/fallback generation | Server-side via backend |

## Backend (Alibaba Cloud ECS)

```
backend/
├── src/index.ts              # Express entry point
├── src/routes/gemini.ts      # POST /api/gemini/generate
├── src/routes/referral.ts    # POST /api/referral/register & /redeem
├── src/middleware/rateLimit.ts
├── src/config.ts
├── public/legal/             # Static legal docs (7 languages × 2 docs)
└── Dockerfile
```

- **Production domain**: `https://aiphoto-cn.foyli.cloud`
- **ECS region**: Alibaba Cloud Guangzhou
- **Process manager**: PM2 process `aiidphoto-backend`, local port `127.0.0.1:9528`
- **Reverse proxy**: Nginx + HTTPS certificate on `aiphoto-cn.foyli.cloud`
- **Provider keys**: Server-side only. Production target is Alibaba Cloud KMS Secrets Manager + ECS RAM Role. PM2 plaintext env vars are transitional only.
- **Required secrets**:
  - `APP_API_KEY` — lightweight iOS `X-App-Key` gate
  - `REFERRAL_HMAC_SECRET` — referral code HMAC signing, separate from `APP_API_KEY`
  - `BAILIAN_API_KEY` — Alibaba Cloud Bailian/Qwen provider key
  - `HIVISION_URL` — HivisionIDPhotos endpoint

### Backend Deploy Workflow

```bash
cd backend
npm install
npm run build

# Upload to ECS according to docs/07-deployment/cloud-run-deploy.md,
# then rebuild and restart PM2 on the server.
```

### Backend Development

- Edit files in `backend/src/`
- Run locally: `cd backend && npm run dev`
- Deploy to Alibaba Cloud ECS: follow `docs/07-deployment/cloud-run-deploy.md`

## iOS Configuration

Config values are read from Info.plist via `Config.swift`:
- `BACKEND_BASE_URL` — Alibaba Cloud backend URL
- `APP_API_KEY` — client calling key supplied by `$(AIIDPHOTO_APP_API_KEY)`, not committed directly

Local build secret flow:

```bash
cp ios/AIIDPhoto/Configuration/Secrets.xcconfig.example ios/AIIDPhoto/Configuration/Secrets.xcconfig
# Fill AIIDPHOTO_APP_API_KEY locally. Do not commit Secrets.xcconfig.
xcodegen generate
```

## Git Commit Convention

```
feat: new feature
fix: bug fix
docs: documentation update
style: formatting changes
refactor: code restructure
chore: maintenance
```
