# 系统架构设计

## 整体架构

```text
┌─────────────────────────────────────────────┐
│                iOS App (SwiftUI)            │
│                                             │
│  PhotoCreationView → GeminiService → Config │
│       ↓              ↓                      │
│  SubscriptionManager  ReferralManager       │
│  HistoryManager       LanguageManager       │
└──────────────┬──────────────────────────────┘
               │ HTTPS POST /api/gemini/generate
               ▼
┌─────────────────────────────────────────────┐
│       CN Backend: Alibaba Cloud ECS         │
│                                             │
│  Nginx → 127.0.0.1:9528 → Express/PM2       │
│  ├── /health                                │
│  ├── /api/gemini/generate                   │
│  ├── /api/referral/*                        │
│  └── /legal/*                               │
└──────────────┬──────────────────────────────┘
               │
       ┌───────┴─────────────────────┐
       ▼                             ▼
┌──────────────────────┐     ┌────────────────────────┐
│ HivisionIDPhotos     │     │ Alibaba Cloud Bailian   │
│ 抠图 / 裁切 / 换底色 │     │ Qwen/Wanx 图像编辑      │
└──────────────────────┘     └────────────────────────┘
```

`GeminiService.swift` 和 `backend/src/routes/gemini.ts` 是历史命名；CN 版实际不再以 Gemini 作为主图像生成服务。

## iOS 架构

```text
View
├── ContentView / PhotoCreationView
├── SubscriptionSheetView / PrintLayoutSheetView
└── SettingsView

Managers
├── SubscriptionManager   StoreKit 2 消耗型成片制作包 / 剩余生成次数
├── HistoryManager        本地生成历史
├── ReferralManager       推荐奖励
└── LanguageManager       语言选择

Services
├── GeminiService         后端生成接口客户端（历史命名）
└── PrintLayoutService    300 DPI 打印排版渲染
```

## 生成数据流

1. 用户上传照片或拍照。
2. `PhotoCreationView.generate()` 检查成片制作包剩余次数；无付费次数时可使用推荐奖励次数。
3. App 根据所选规格构造 `specWidth`、`specHeight`、`specBgColor` 和 prompt。
4. `GeminiService.generateIDPhoto(...)` 压缩图片并请求 `/api/gemini/generate`。
5. 后端优先使用 HivisionIDPhotos 生成合规证件照底图。
6. 当请求包含外观编辑选项时，本地最新代码支持在 Hivision 结果上追加 Qwen/Bailian cosmetic pass；服务器当前部署版本仍是较早 fallback 链。
7. 返回 base64 图片，App 解码成 `UIImage`，展示、保存、分享或进入打印排版；成功后扣减 1 次生成机会。

## 后端结构

```text
backend/
├── src/
│   ├── index.ts              # Express app
│   ├── config.ts             # PORT / HIVISION_URL / BAILIAN_API_KEY / APP_API_KEY / REFERRAL_HMAC_SECRET
│   ├── routes/
│   │   ├── gemini.ts         # POST /api/gemini/generate
│   │   ├── referral.ts       # 推荐码
│   │   └── tripo.ts
│   └── middleware/
│       ├── apiKey.ts         # X-App-Key
│       ├── rateLimit.ts      # 内存限速
│       └── requestLogger.ts
└── public/legal/             # 静态法律页
```

## 当前阿里云部署

| 项目 | 配置 |
|------|------|
| ECS | 阿里云广州区域，Ubuntu 22.04 |
| 目录 | `/opt/aiidphoto-backend` |
| 进程 | PM2 `aiidphoto-backend` |
| Node | 20.19.6 |
| App 端口 | `127.0.0.1:9528` |
| Nginx | `/etc/nginx/sites-available/aiphoto-cn.foyli.cloud` |
| 反代 | `location /` → `http://127.0.0.1:9528` |
| Body limit | Nginx 20MB，Express 10MB |
| Read timeout | 180s |

## 安全设计

1. **服务端 Key 隔离**：百炼 Key 只在服务器环境变量 / PM2 ecosystem 中配置，iOS 客户端不包含。
2. **App Key**：iOS 请求带 `X-App-Key`；服务器支持强制校验，但当前生产配置为过渡模式。
3. **限速**：全局内存限速 + 生成接口 3 req/min/IP。
4. **预算保护**：后端有每日生成预算计数，超过阈值返回 503。
5. **网络暴露**：Node 进程只监听本机端口，经 Nginx 对外。

## 已知技术债

| 问题 | 优先级 | 说明 |
|------|--------|------|
| App Key 只是轻量门禁 | P1 | 客户端 Key 可被逆向，上线后应补账号/设备级滥用保护 |
| 推荐码内存存储 | P2 | PM2 重启后邀请码状态丢失，应迁移到数据库 |
