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
- [ ] Phase 2 — 核心体验增强（证件照规格、裁剪、历史记录）
- [ ] Phase 3 — 商业化打磨（多语言、Analytics、对比展示）

## 关键文件

| 文件 | 用途 |
|------|------|
| `project.yml` | XcodeGen 项目配置 |
| `ios/AIIDPhoto/Config.swift` | Info.plist 配置读取 |
| `ios/AIIDPhoto/Services/GeminiService.swift` | AI 图像生成服务 |
| `ios/AIIDPhoto/Managers/SubscriptionManager.swift` | StoreKit 2 订阅 |
| `backend/src/routes/gemini.ts` | 后端 Gemini 代理路由 |

## 相关链接

- GCP Project: `ai-id-photo-prod`
- Cloud Run: `https://aiidphoto-backend-616059029156.asia-northeast1.run.app`
- Firebase Console: `https://console.firebase.google.com/project/ai-id-photo-prod`
- GitHub: `https://github.com/tonywei17/ai_profile`
