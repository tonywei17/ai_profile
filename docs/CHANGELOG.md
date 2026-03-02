# Changelog

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
