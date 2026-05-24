# 20260524_001 iOS Pricing Pivot QA

## Verdict
- Status: BLOCKED
- Build/version: AIIDPhoto Release simulator build, 2026-05-24
- Device/simulator: iPhone 17 Pro, iOS 26.5 simulator available
- Tester: Codex

## Findings
| Severity | Area | Issue | Evidence | Recommendation |
|---|---|---|---|---|
| P1 | App Store Connect | Consumable IAP still lacks the new review screenshot and has not been submitted with the app version | `com.yufeicn.aiidphoto.photo_task_3` was created in App Store Connect with China Mainland availability and launch price `¥3.80`; status remains metadata-blocked until screenshot is uploaded | Add the correct in-app purchase review screenshot, attach the IAP to the app version, and avoid the old Pro subscription product |
| P1 | App Store version metadata | Current rejected 1.0 version page still contains old Pro, ad, subscription, and free daily generation copy | App Store Connect version page description/review notes still reference Pro membership, Google AdMob, StoreKit subscriptions, and 10 free generations/day | Rewrite version metadata before any updated review submission |
| P1 | End-to-end QA | Real purchase, generation, attempt deduction, save, and print layout were not run on a device | Only compile and static checks completed | Run sandbox purchase and real image generation before release |
| P2 | Warnings | Existing iOS deprecation warnings remain | Full Release simulator build reported 9 warnings before incremental rebuild | Clean up in a follow-up; not a current compile blocker |

## Executed Checks
| Check | Result | Evidence |
|---|---|---|
| `xcodebuild -version` | PASS | Xcode 26.5, build 17F42 |
| `xcodebuildmcp --version` | PASS | 2.5.2 |
| `maestro --version` | PASS | 2.5.1 |
| Available simulators | PASS | iPhone 17 Pro iOS 26.5 listed |
| iOS Release simulator build | PASS | `xcodebuildmcp simulator build --project-path ./AIIDPhoto.xcodeproj --scheme AIIDPhoto --simulator-name "iPhone 17 Pro" --configuration Release --derived-data-path ./build/DerivedDataRelease --use-latest-os` |
| Info.plist syntax | PASS | `plutil -lint ios/AIIDPhoto/Info.plist` |
| StoreKit config JSON | PASS | `jq empty ios/AIIDPhoto/Configuration/Products.storekit` |
| Price copy sync | PASS | Old launch-price references were removed from iOS and release docs; StoreKit local price is `3.80` |
| Backend TypeScript build | PASS | `cd backend && npm run build` |
| App Store asset script parse | PASS | `node --check docs/13-appstore-assets/capture.mjs` |
| App Store Connect IAP setup | PARTIAL | Created consumable `com.yufeicn.aiidphoto.photo_task_3`, Apple ID `6772723761`, China Mainland availability, Simplified Chinese localization, and launch price `¥3.80`; review screenshot still missing |

## Security / Cost / Performance
- Security: AI provider keys remain server-side; the product pivot does not add client-side provider secrets.
- Cost: the new 3-attempt paid task reduces unbounded usage risk, but profitability still depends on real Hivision/Bailian cost per successful result.
- Performance: no runtime profiling was performed in this pass.

## Artifacts
- Build log: `~/Library/Developer/XcodeBuildMCP/workspaces/ai_profile_cn-619097338ec9/logs/build_sim_2026-05-24T11-49-56-935Z_pid15315_23b2ccf8.log`

## Release Decision
BLOCKED until the new IAP review screenshot is uploaded, the IAP is attached to the app version, and a true sandbox/device end-to-end purchase + generation regression passes.
