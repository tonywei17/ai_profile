# AIIDPhoto (SwiftUI)

A minimal SwiftUI app scaffold for AI-generated ID photos:
- Upload from Photos or take a selfie.
- Send to Gemini ("nanobanana" API endpoint) to generate an ID photo.
- Monetization: Free + Subscription. Non-subscribers: 1st use free, subsequent uses require rewarded video ads. Subscribers: no ads, 20/day limit.
- Glass (frosted) UI style.

## Requirements
- Xcode 15+ (Swift 5.9+), iOS 16+ target recommended.
- AdMob SDK (via SPM) if showing ads.
- StoreKit 2 (built-in).
- A Gemini-compatible HTTP endpoint that accepts JSON { image: base64, ... } and returns { image: base64 }.

## Setup Steps

1. Create Xcode Project
- App name: AIIDPhoto (or any).
- Interface: SwiftUI. Language: Swift.
- Add the files from `ios/AIIDPhoto/` into your project.

2. Info.plist Keys
Add the following (String) keys:
- `GEMINI_ENDPOINT` = https://your-proxy.example.com/gemini/nanobanana
- `GEMINI_API_KEY` = <your_api_key>
- `GADApplicationIdentifier` = <your_admob_app_id>

And usage descriptions:
- `NSCameraUsageDescription` = We need camera access for selfies.
- `NSPhotoLibraryAddUsageDescription` = Save generated photos.
- `NSPhotoLibraryUsageDescription` = Pick existing photos.

3. AdMob via Swift Package Manager
- File > Add Packages…
- Search: `https://github.com/googleads/swift-package-manager-google-mobile-ads`
- Add GoogleMobileAds.xcframework to the app target.
- Replace Ad unit IDs in `AdManager.swift` with your production IDs.
- Initialize GMA in `AppDelegate` or SwiftUI `@main` using `GADMobileAds.sharedInstance().start(completionHandler: nil)` (you can add an `UIApplicationDelegateAdaptor` if needed).

4. StoreKit 2 Subscription
- Create auto-renewable subscription in App Store Connect with product ID `com.yourcompany.aiidphoto.premium` (or update `SubscriptionManager.productID`).
- Add an entitlement to your subscription group.
- Test in Sandbox. `SubscriptionManager` observes `Transaction.updates` and sets `isSubscribed`.

5. Gemini (Nanobanana) Endpoint
- `GeminiService` expects a POST JSON `{ image: base64, style: "id_photo", size: "35x45mm" }` and a response `{ image: base64 }`.
- Auth: Bearer token in `Authorization` header using `GEMINI_API_KEY`.
- If your schema differs, adjust request/parse code in `GeminiService.swift`.

6. Usage & Ads Logic
- Free users: first use allowed, subsequent uses call rewarded ad before generation.
- Subscribers: ad-free; daily cap 20 resets at local day boundary.
- Note: Rewarded ad duration is controlled by the ad network; you cannot force a 30s minimum display duration. Gate by reward callback instead per AdMob policy.

7. Glass UI
- `GlassBackground` and button modifiers provide frosted/blurred visuals.

## Testing Checklist
- Free path: first generation succeeds without ad; second triggers rewarded ad; reward continues flow.
- Subscriber path: purchase/restore sets `isSubscribed`; no ads; counter decreases and resets daily.
- API path: mock your endpoint to return a valid base64 image.

## Notes
- Replace placeholder IDs and endpoints.
- For production, add error handling, retries, background task handling, analytics, and privacy disclosures.
