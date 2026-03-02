# AIIDPhoto - Project Instructions

## Project Overview

SwiftUI iOS app for AI-powered ID photo generation using Gemini API.
- **Platform**: iOS 16+, iPhone + iPad (single-column layout)
- **Language**: Swift 5.9
- **UI Framework**: SwiftUI with glass (frosted) UI style
- **Project Generator**: XcodeGen (`project.yml`)
- **Monetization**: StoreKit 2 subscription + AdMob rewarded ads

## Project Structure

```
ios/AIIDPhoto/
├── AIIDPhotoApp.swift          # @main entry point
├── AppDelegate.swift           # AdMob initialization
├── Config.swift                # Info.plist config reader
├── ContentView.swift           # Main UI (spec selection, generate, compare, print)
├── Configuration/
│   └── Products.storekit       # StoreKit testing configuration
├── Managers/
│   ├── SubscriptionManager.swift   # StoreKit 2
│   ├── AdManager.swift             # Google AdMob
│   ├── LanguageManager.swift       # 4-language switcher (zh/en/ja/ko)
│   └── UsageManager.swift          # Free/premium usage limits
├── Models/
│   ├── IDPhotoSpec.swift       # Photo specs (10+ presets) + CustomSizeSpec
│   ├── PhotoOptions.swift      # Beauty level & outfit style (Pro)
│   └── PrintLayout.swift       # PrintPaperSize + PrintLayoutInfo grid calc
├── Resources/
│   ├── Fonts/                  # Plus Jakarta Sans (Bold, SemiBold)
│   └── {en,ja,ko,zh-Hans}.lproj/Localizable.strings
├── Services/
│   ├── GeminiService.swift     # Gemini API client
│   └── PrintLayoutService.swift # 300 DPI tiled print renderer
└── Views/
    ├── SubscriptionSheetView.swift
    ├── PrintLayoutSheetView.swift  # Print preview + save
    ├── SettingsView.swift          # Language, privacy, version
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
xcodebuild -project AIIDPhoto.xcodeproj -scheme AIIDPhoto -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild -project AIIDPhoto.xcodeproj -scheme AIIDPhoto -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Swift / iOS Conventions

### Architecture
- **Pattern**: MVVM — Views should be thin, logic lives in ViewModels (`ObservableObject`)
- **DI**: Use `@EnvironmentObject` for app-wide managers, `@StateObject` for view-owned state
- **Singletons**: Avoid where possible; prefer dependency injection

### Swift Style
- Use `Codable` for JSON models — avoid raw `JSONSerialization`
- Prefer `async/await` over completion handlers
- Mark all UI-bound classes with `@MainActor`
- Use `enum` namespaces for constants (e.g., `Config`, `AdUnits`)
- Error types must conform to `LocalizedError` with user-readable `errorDescription`
- Use `#if canImport(GoogleMobileAds)` guards for optional SDK dependencies

### SwiftUI
- Extract reusable view modifiers into `ViewModifier` structs
- Keep `body` computed property concise — extract sub-views as `private var`
- Use `task {}` modifier for async work on view appear
- Prefer `@Binding` for child views, `@State` for local state

### Naming
- Types: `PascalCase` (e.g., `GeminiService`, `UsageManager`)
- Functions/properties: `camelCase` (e.g., `generateIDPhoto`, `isSubscribed`)
- Constants: `camelCase` in `enum` namespace (e.g., `Config.geminiAPIKey`)
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
| StoreKit 2 | Subscriptions | Built-in framework |
| GoogleMobileAds | Banner + Rewarded ads | Optional via SPM, `#if canImport` guarded |
| Gemini API | Image generation | HTTP REST via URLSession |

## Backend (GCP Cloud Run)

```
backend/
├── src/index.ts              # Express entry point
├── src/routes/gemini.ts      # POST /api/gemini/generate
├── src/middleware/rateLimit.ts
├── src/config.ts
└── Dockerfile
```

- **GCP Project**: `ai-id-photo-prod`
- **Region**: `asia-northeast1` (Tokyo)
- **Service URL**: `https://aiidphoto-backend-616059029156.asia-northeast1.run.app`
- **API Key**: Stored in Secret Manager (`GEMINI_API_KEY`), never in code

### Backend Deploy Workflow (Cloud Run — no local Docker needed)

```bash
# Deploy backend changes directly via Cloud Build
gcloud run deploy aiidphoto-backend \
  --source ./backend \
  --project=ai-id-photo-prod \
  --region=asia-northeast1 \
  --set-secrets="GEMINI_API_KEY=GEMINI_API_KEY:latest" \
  --quiet

# Or use the skill:
# /deploy-backend
```

### Backend Development

- Edit files in `backend/src/`
- Run locally: `cd backend && npm run dev`
- Deploy to Cloud Run: `/deploy-backend`

## iOS Configuration

Config values are read from Info.plist via `Config.swift`:
- `BACKEND_BASE_URL` — Cloud Run backend URL (primary, API key stored server-side)
- `GEMINI_ENDPOINT` — Direct Gemini API URL (dev/fallback only)
- `GEMINI_API_KEY` — Direct API key (dev/fallback only, leave empty in production)
- `GADApplicationIdentifier` — AdMob app ID (when using ads)

## Git Commit Convention

```
feat: new feature
fix: bug fix
docs: documentation update
style: formatting changes
refactor: code restructure
chore: maintenance
```
