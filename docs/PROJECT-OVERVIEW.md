# AIIDPhoto CN — 项目概览

## 产品定位

光影形象馆是一款面向中国大陆市场的 AI 证件照 / 职业形象照 iOS App。用户上传自拍或生活照后，App 通过后端流水线生成标准证件照，支持中国常用规格、背景色、美颜/换装、打印排版和生成历史。

## 技术栈

| 层次 | 技术 | 说明 |
|------|------|------|
| iOS App | SwiftUI + Swift 5.9 | 当前 target 为 iOS 26，iPhone + iPad |
| 主证件照处理 | HivisionIDPhotos | 人脸检测、抠图、按目标像素裁切、背景填色 |
| 外观编辑 | 阿里云百炼 / Qwen Image Edit / Wanx | 美颜、换装、发型、表情等二阶段或 fallback 编辑 |
| CN 后端代理 | 阿里云 ECS + Nginx + PM2 + Node.js | 进程名 `aiidphoto-backend`，监听 `127.0.0.1:9528` |
| 仍在使用的外部服务 | Hivision Cloud Run endpoint | 阿里云后端当前通过 `HIVISION_URL` 调用该服务 |
| 密钥管理 | PM2 环境变量 / 服务器配置 | 客户端不保存百炼 Key；App 仅带 `X-App-Key` |
| 付费 | StoreKit 2 | 消耗型成片制作包，购买后发放 3 次生成机会 |

## 商业模式

```text
成片制作包: 首发优惠价 ¥3.8/张，常规目标价 ¥9.9/张
生成权益: 每个制作包含 3 次 AI 生成机会，成功生成扣 1 次
交付内容: 用户选择最满意结果后下载高清电子照和打印排版图
推荐奖励: 邀请好友后可获得奖励生成次数，用于体验或转化
```

## 项目状态

- [x] Phase 1 — 基础功能 + 安全修复（2026-03-01）
- [x] Phase 2 — 核心体验增强：规格体系、自定义尺寸、排版打印、美颜/服装、前后对比、7 语言 i18n、iPad 适配、法律文档
- [x] Phase 3 — 产品优化 + 增长引擎：Onboarding、评分引导、Analytics、社交分享、生成历史、推荐邀请
- [x] CN 改造 — Bundle ID、App 名、中文截图、Hivision/阿里云百炼链路、中国规格与打印排版
- [ ] 上线收口 — ICP/App 备案信息、App Store 审核视频、真机回归、最小自动化测试

## 当前线上后端核对（2026-05-24）

| 项目 | 实测结果 |
|------|----------|
| 服务器 | 阿里云 ECS，广州区域，Ubuntu 22.04 |
| 部署目录 | `/opt/aiidphoto-backend` |
| PM2 进程 | `aiidphoto-backend`，`dist/index.js`，Node 20.19.6，online |
| 本机端口 | `127.0.0.1:9528` |
| Nginx 配置 | `/etc/nginx/sites-available/aiphoto-cn.foyli.cloud` |
| Nginx 转发 | `aiphoto-cn.foyli.cloud` → `http://127.0.0.1:9528` |
| 公网 DNS | `aiphoto-cn.foyli.cloud` A 记录解析到 ECS 公网 IP |
| HTTPS | Let's Encrypt 证书已配置，`https://aiphoto-cn.foyli.cloud/health` 返回 `{"status":"ok"}` |
| 代码版本 | 已同步本地最新 `backend/src` 并在服务器构建、重启 PM2 |
| App Key 强制校验 | 已启用，缺失 `X-App-Key` 的生成请求返回 401 |

注意：当前仓库 `project.yml` / `Info.plist` 已切到 HTTPS 阿里云域名。上线前仍需做真机端到端生成、StoreKit 消耗型购买、生成次数扣减、保存相册和权限弹窗回归。

## 关键文件

| 文件 | 用途 |
|------|------|
| `project.yml` | XcodeGen 项目配置、Info.plist 生成源 |
| `ios/AIIDPhoto/Config.swift` | 后端 URL 与 `X-App-Key` 读取 |
| `ios/AIIDPhoto/Views/PhotoCreationView.swift` | 当前制作页主流程 |
| `ios/AIIDPhoto/Models/IDPhotoSpec.swift` | 中国证件照规格定义 |
| `ios/AIIDPhoto/Models/PhotoOptions.swift` | 表情、美颜、服装、发型、背景等选项 |
| `ios/AIIDPhoto/Services/GeminiService.swift` | iOS 端后端调用服务（历史命名） |
| `backend/src/routes/gemini.ts` | 后端生成接口（历史命名） |
| `backend/src/routes/referral.ts` | 推荐邀请 API |

## 发布关注点

- 上线前需要补齐真机端到端生成、StoreKit 消耗型购买、生成次数扣减、保存相册和权限弹窗回归。
- 法务页已部署在 `https://aiphoto-cn.foyli.cloud/legal/`；中国大陆 App Store 备案号仍需确认后填写。
