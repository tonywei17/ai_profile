# Changelog

## [1.1.1] — 2026-04-07

### 新增
- 多层模型 Fallback 架构：Gemini → OpenRouter(SM) → OpenRouter(ENV)
- OpenRouter API 密钥集成（GCP Secret Manager）
- 后端响应新增 `provider` 字段，标明实际使用的模型提供商

### 修复
- **[重大]** OpenRouter fallback 未生成证件照，仅返回原图/文本分析
  - 根因：缺少 `modalities: ["text", "image"]` 参数 + prompt 未明确图片编辑意图
  - 修复：添加 system prompt、包装 prompt、请求图片输出模态

### 优化
- Pro 用户日生成上限从 20 次降至 10 次（防止重度用户亏损）
- 免费用户仅走 Gemini 直连，不触发高成本 OpenRouter fallback
- Pro/Free 统一使用 `gemini-2.5-flash-image` 模型，降低 API 成本
- 移除 OpenAI fallback（单次成本过高，不适合当前收入规模）

---

## [0.4.0] — 2026-03-02

### 新增
- 新用户引导 Onboarding（4 页 TabView，Glass UI，7 语言）
- App Store 评分引导（第 3 次生成成功后触发，按版本去重）
- 轻量级 Analytics Manager（11 事件，本地 JSON 持久化，无 SDK 依赖）
- 社交分享功能（UIActivityViewController，免费用户水印，Pro 无水印）
- 生成历史画廊（LazyVGrid，Documents 目录存储，50 条自动清理）
- 推荐邀请机制（后端邀请码 API + iOS 客户端，兑换得 3 次 Pro 生成）
- 法律文档静态托管（Cloud Run express.static，7 语言 × 2 文档）
- 后端推荐 API（`/api/referral/register` + `/api/referral/redeem`）

### 修复
- 设置页 & 订阅页法律文档 URL 从 `example.com` 占位符替换为真实后端 URL
- Cloud Run 部署失败：Compute SA 缺少 `artifactregistry.writer` 权限

### 改进
- ContentView 集成：历史按钮、分享按钮、Analytics 埋点、推荐次数消耗
- SettingsView 新增邀请好友区块（邀请码展示、分享、兑换输入框）
- Dockerfile 新增 `COPY public/` 打包静态资源

---

## [0.3.0] — 2026-03-02

### 新增
- 证件照规格体系（`IDPhotoSpec`）：10+ 规格覆盖日/中/韩/美，含尺寸、背景色、AI prompt
- 日本在留カード规格（30×40mm）
- Pro 自定义尺寸（宽 20~60mm，高 20~80mm，Stepper 控件）
- 排版打印功能（L判/2L判，300 DPI 渲染，裁切线）
- 美颜等级（自然/清透/精致）& 服装风格选项（正装/商务/学生等）
- 前后对比滑块（`ComparisonSliderView`）
- 多语言支持（中/英/日/韩）+ `LanguageManager`
- 设置页面（`SettingsView`）：语言切换、隐私政策
- StoreKit 测试配置（`Products.storekit`）
- Plus Jakarta Sans 自定义字体

### 改进
- Pro 订阅门控：规格卡片锁定图标 + 订阅弹窗触发
- `SubscriptionSheetView` 全面重构：功能列表、价格、合规链接
- iOS 26 Liquid Glass UI 全面升级（`.glassEffect()` 修饰符）
- iPad 适配：移除双栏布局，统一单栏 + maxWidth 居中
- `ScrollView` 阴影裁切修复（`.scrollClipDisabled(true)`）
- `PrintLayoutInfo` 支持自定义尺寸（`photoSizeMM` tuple 接口）

---

## [0.2.0] — 2026-03-01

### 新增
- GCP Cloud Run 后端代理服务（`backend/`），隐藏 Gemini API Key
- API Key 存储到 GCP Secret Manager
- Firebase 接入（项目 `ai-id-photo-prod`）
- 项目级 CLAUDE.md 和 Skills 配置（`swift-conventions`、`build`、`swift-review`、`xcode-fix`、`deploy-backend`）
- 隐私政策 / 服务条款链接（`SubscriptionSheetView`）
- 完整文档体系（`docs/`）

### 修复
- `SubscriptionManager.updateEntitlements()` 无限循环 Bug — 拆分为独立 Task
- `GeminiError` 实现 `LocalizedError`，用户可读错误信息
- JSON 解析从 `JSONSerialization` 改为 `Codable` 模型

### 改进
- `Config.swift` 新增 `backendBaseURL`，优先使用后端代理
- `GeminiService` 支持双模式：后端代理 / 直连 Gemini（开发用）
- 所有占位符添加 TODO/FIXME 标注
- `project.yml` Bundle ID 更新为 `com.nexus.aiidphoto`

---

## [0.1.0] — 2026-02-28

### 新增
- SwiftUI 项目初始化（Glass UI 风格）
- Gemini API 图像生成（image-to-image）
- 提示词输入框
- AdMob Banner + Rewarded 广告（模拟器 stub）
- StoreKit 2 订阅框架
- 每日使用量限制（免费 1 次，会员 20 次/天）
- XcodeGen 项目配置（`project.yml`）
