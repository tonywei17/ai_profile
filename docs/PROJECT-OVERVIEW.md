# AIIDPhoto — 项目概览

## 产品定位

AI 证件照生成器 iOS App，用户上传生活照，通过 Gemini AI 生成标准证件照，支持多种规格和背景色（规划中）。

## 技术栈

| 层次 | 技术 | 说明 |
|------|------|------|
| iOS App | SwiftUI + Swift 5.9 | 最低 iOS 16，iPhone + iPad |
| AI 服务 | Google Gemini API | 图像到图像生成 |
| 后端代理 | GCP Cloud Run + Node.js | 隐藏 API Key，速率限制 |
| 密钥管理 | GCP Secret Manager | API Key 安全存储 |
| 订阅 | StoreKit 2 | 自动续期订阅 |
| 广告 | Google AdMob | Banner + Rewarded |
| Firebase | Firebase（已接入） | 未来扩展 Auth/Analytics |

## 商业模式

```
免费用户:  首次生成免费 → 后续每次观看激励广告 → 购买会员
付费会员:  无广告 + 每天 20 次生成（$1.99/月 或 $12.99/年）
推荐奖励:  邀请好友双方各得 3 次 Pro 品质生成
```

## 项目状态

- [x] Phase 1 — 基础功能 + 安全修复（2026-03-01）
- [x] Phase 2 — 核心体验增强（2026-03-02 上午）：规格体系、自定义尺寸、排版打印、美颜/服装、前后对比、7 语言 i18n、iPad 适配、Liquid Glass UI、法律文档
- [x] Phase 3 — 产品优化 + 增长引擎（2026-03-02 下午）：Onboarding 引导、评分引导、Analytics、社交分享、生成历史、推荐邀请、法律 URL 修复、Cloud Run 部署
- [ ] Phase 4 — 上架打磨（ViewModel 抽取、图片裁剪、App Store 截图自动化、推荐持久化）

## 关键文件

| 文件 | 用途 |
|------|------|
| `project.yml` | XcodeGen 项目配置 |
| `ios/AIIDPhoto/Config.swift` | Info.plist 配置读取 |
| `ios/AIIDPhoto/ContentView.swift` | 主界面（规格选择、生成、对比、打印） |
| `ios/AIIDPhoto/Models/IDPhotoSpec.swift` | 证件照规格定义 + 自定义尺寸 |
| `ios/AIIDPhoto/Models/PrintLayout.swift` | 排版打印布局计算 |
| `ios/AIIDPhoto/Services/GeminiService.swift` | AI 图像生成服务 |
| `ios/AIIDPhoto/Services/PrintLayoutService.swift` | 300 DPI 排版渲染引擎 |
| `ios/AIIDPhoto/Managers/SubscriptionManager.swift` | StoreKit 2 订阅 |
| `ios/AIIDPhoto/Managers/LanguageManager.swift` | 7 语言切换管理 |
| `ios/AIIDPhoto/Managers/AnalyticsManager.swift` | 轻量级事件追踪 |
| `ios/AIIDPhoto/Managers/HistoryManager.swift` | 生成历史记录管理 |
| `ios/AIIDPhoto/Managers/ReferralManager.swift` | 推荐邀请管理 |
| `ios/AIIDPhoto/Views/OnboardingView.swift` | 新用户引导（4 页） |
| `ios/AIIDPhoto/Views/HistoryView.swift` | 生成历史画廊 |
| `backend/src/routes/gemini.ts` | 后端 Gemini 代理路由 |
| `backend/src/routes/referral.ts` | 推荐邀请 API |

## 相关链接

- GCP Project: `ai-id-photo-prod`
- Cloud Run: `https://aiidphoto-backend-616059029156.asia-northeast1.run.app`
- Firebase Console: `https://console.firebase.google.com/project/ai-id-photo-prod`
- GitHub: `https://github.com/tonywei17/ai_profile`
