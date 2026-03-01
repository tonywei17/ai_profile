# 系统架构设计

## 整体架构

```
┌─────────────────────────────────────────────┐
│                iOS App (SwiftUI)            │
│                                             │
│  ContentView → GeminiService → Config       │
│       ↓              ↓                      │
│  SubscriptionManager  UsageManager          │
│  AdManager            (UserDefaults)        │
└──────────────┬──────────────────────────────┘
               │ HTTPS POST /api/gemini/generate
               ▼
┌─────────────────────────────────────────────┐
│          GCP Cloud Run (Tokyo)              │
│                                             │
│  Express + TypeScript                       │
│  ├── Rate Limiting (10 req/min/IP)          │
│  └── /api/gemini/generate                   │
│         ↓ x-goog-api-key (from Secret Mgr)  │
└──────────────┬──────────────────────────────┘
               │ HTTPS POST
               ▼
┌─────────────────────────────────────────────┐
│           Google Gemini API                 │
│  gemini-2.5-flash-image (image-to-image)    │
└─────────────────────────────────────────────┘
```

## iOS 架构：MVVM

```
┌──────────────┐    ┌────────────────────┐    ┌──────────────┐
│    View       │ ←→ │    Manager/VM      │ ←→ │   Service    │
│ ContentView   │    │ SubscriptionMgr    │    │ GeminiService│
│ SubScriptionV │    │ UsageManager       │    │              │
│ SubscSheet    │    │ AdManager          │    │              │
└──────────────┘    └────────────────────┘    └──────────────┘
       ↕                     ↕
  @EnvironmentObject    @MainActor
  @StateObject          ObservableObject
```

### 数据流

1. 用户选择照片 → `inputImage: UIImage?`（`@State`）
2. 点击生成 → `ContentView.generateTapped()`
3. 检查使用权限 → `UsageManager.canGenerate()`
4. 需要广告 → `AdManager.loadRewarded()` + `showRewarded()`
5. 调用 API → `GeminiService.generateIDPhoto(from:prompt:)`
6. 优先后端代理 → `Config.backendBaseURL` → Cloud Run
7. 返回 `UIImage` → `outputImage`（`@State`）展示

## 后端架构

```
backend/
├── src/
│   ├── index.ts          # Express app，50MB body limit
│   ├── config.ts         # 环境变量读取
│   ├── routes/
│   │   └── gemini.ts     # POST /api/gemini/generate
│   └── middleware/
│       └── rateLimit.ts  # 内存 IP 限速（10次/分钟）
└── Dockerfile            # node:22-slim 多阶段构建
```

**请求/响应格式：**

```typescript
// Request
{ image: string, prompt: string }  // image: base64 JPEG

// Response (success)
{ image: string }  // image: base64

// Response (error)
{ error: string }
```

## GCP 基础设施

| 服务 | 配置 |
|------|------|
| Cloud Run | `asia-northeast1`，512Mi，CPU 1，最大 10 实例 |
| Secret Manager | `GEMINI_API_KEY`，Cloud Run SA 只读权限 |
| Artifact Registry | `cloud-run-source-deploy` 仓库 |
| Firebase | 已接入，待使用 Auth/Analytics |

## 安全设计

1. **API Key 隔离**：Gemini API Key 仅存于 Secret Manager，Cloud Run 运行时注入为环境变量，客户端不持有
2. **速率限制**：后端 10 次/分钟/IP，防止滥用
3. **客户端限制**：免费用户首次免费 + 看广告，会员 20 次/天（UserDefaults，可被绕过，作为 UX 层）
4. **HTTPS 全程**：iOS → Cloud Run → Gemini 全链路加密

## 已知技术债

| 问题 | 优先级 | 说明 |
|------|--------|------|
| UsageManager 可绕过 | 中 | 卸载重装=重置，应迁移到 Keychain 或服务端 |
| 后端无身份验证 | 中 | 任意请求可调用，未来加 Firebase Auth |
| 内存速率限制 | 低 | 重启后重置，未来改 Redis 或 Firestore |
