# 光影形象馆 / AIIDPhoto CN (SwiftUI)

SwiftUI iOS app for CN ID photos and professional profile images:
- Pick from Photos or take a camera image.
- Send to the backend proxy for HivisionIDPhotos processing and optional Alibaba Cloud Bailian/Qwen cosmetic edit pass.
- Monetization: one consumable photo task purchase, currently priced for a launch offer, grants 3 AI generation attempts.
- StoreKit 2 consumable purchase, Chinese ID photo specs, HD export, print layout, and iPad-friendly UI.

## Requirements
- Xcode 26.x for the current project settings.
- StoreKit 2 (built-in).
- Backend endpoint that accepts `POST /api/gemini/generate` and returns `{ image: base64 }`. The route name is historical.

## Setup Steps

1. Open Project
- Open `AIIDPhoto.xcodeproj` from the repository root.
- Current bundle ID: `com.yufeicn.aiidphoto`.
- Current display name: `光影形象馆`.

2. Info.plist / Secret Build Settings
- `BACKEND_BASE_URL` is generated from `project.yml`; CN production points to `https://aiphoto-cn.foyli.cloud`.
- `APP_API_KEY` is generated as `$(AIIDPHOTO_APP_API_KEY)` and must be supplied by CI or a local xcconfig, not committed in `Info.plist`.
- XcodeGen loads `ios/AIIDPhoto/Configuration/App.xcconfig`, which optionally includes the gitignored `Secrets.xcconfig`.
- For local release builds, copy `ios/AIIDPhoto/Configuration/Secrets.xcconfig.example` to `ios/AIIDPhoto/Configuration/Secrets.xcconfig` and fill `AIIDPHOTO_APP_API_KEY`.

And usage descriptions:
- `NSCameraUsageDescription` explains camera capture for ID/profile photos.
- `NSPhotoLibraryUsageDescription` explains choosing source photos.
- `NSPhotoLibraryAddUsageDescription` explains saving generated outputs.

3. StoreKit 2 Consumable Product
- Create a consumable in-app purchase in App Store Connect.
- Product ID: `com.yufeicn.aiidphoto.photo_task_3`.
- Display name recommendation: `AI证件照成片（3次生成）`.
- Launch offer price: `¥3.80`; regular price target: `¥9.90/张`.
- Test in Sandbox. `SubscriptionManager` observes `Transaction.updates` and grants 3 local generation attempts after a verified purchase.

4. Backend Endpoint
- `GeminiService` is a historical class name. It sends image, tier, prompt, `specInfo`, and optional `cosmeticPrompt` to the backend.
- Auth uses `X-App-Key` with `APP_API_KEY`.
- CN production backend currently runs on Alibaba Cloud ECS behind Nginx/PM2 at `https://aiphoto-cn.foyli.cloud`.
- Production provider secrets should live in Alibaba Cloud KMS Secrets Manager and be read by ECS through an instance RAM role; PM2 plaintext env vars are a transition path only.

5. Usage Logic
- One photo task grants 3 attempts.
- A successful AI generation consumes 1 attempt; failed generation should not consume an attempt.
- Downloading the HD image and print layout is included after generation.
- Referral bonuses, if enabled, are consumed only when no paid attempts are available.

6. Glass UI
- Existing SwiftUI views use the app's glass/frosted styling helpers.

## Testing Checklist
- Purchase path: buying `photo_task_3` grants 3 attempts.
- Generation path: successful generation consumes 1 attempt; failure keeps the count unchanged.
- Exhausted path: no attempts opens the purchase sheet.
- API path: backend returns a valid base64 image for a real ID photo spec.
- Permission path: camera, photo library, and save-to-library prompts show Chinese copy.

## Notes
- Replace placeholder IDs and endpoints.
- CN legal/privacy pages are hosted at `https://aiphoto-cn.foyli.cloud/legal/`; ICP/App filing information still needs confirmation before App Store submission.
