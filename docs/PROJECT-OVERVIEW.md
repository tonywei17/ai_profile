# AIIDPhoto — 项目概览

## 产品定位

AI 证件照生成器 iOS App，用户上传生活照，通过 Gemini AI 生成标准证件照，支持多种规格和背景色（规划中）。

## 技术栈

| 层次 | 技术 | 说明 |
|------|------|------|
| iOS App | SwiftUI + Swift 5.9 | 最低 iOS 16，仅 iPhone |
| AI 服务 | Google Gemini API | 图像到图像生成 |
| 后端代理 | GCP Cloud Run + Node.js | 隐藏 API Key，速率限制 |
| 密钥管理 | GCP Secret Manager | API Key 安全存储 |
| 订阅 | StoreKit 2 | 自动续期订阅 |
| 广告 | Google AdMob | Banner + Rewarded |
| Firebase | Firebase（已接入） | 未来扩展 Auth/Analytics |

## 商业模式

```
免费用户:  首次生成免费 → 后续每次观看激励广告 → 购买会员
付费会员:  无广告 + 每天 20 次生成
```

## 项目状态

- [x] Phase 1 — 基础功能 + 安全修复（2026-03-01）
- [x] Phase 2 — 核心体验增强（2026-03-02）：规格体系、自定义尺寸、排版打印、美颜/服装、前后对比、多语言、iPad 适配、Liquid Glass UI
- [ ] Phase 3 — 上架打磨（ViewModel 抽取、图片裁剪、生成历史、Analytics、App Store 准备）

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
| `ios/AIIDPhoto/Managers/LanguageManager.swift` | 4 语言切换管理 |
| `backend/src/routes/gemini.ts` | 后端 Gemini 代理路由 |

## 相关链接

- GCP Project: `ai-id-photo-prod`
- Cloud Run: `https://aiidphoto-backend-616059029156.asia-northeast1.run.app`
- Firebase Console: `https://console.firebase.google.com/project/ai-id-photo-prod`
- GitHub: `https://github.com/tonywei17/ai_profile`
