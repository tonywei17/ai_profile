# CN iOS 上线状态报告

> 日期：2026-05-24
> 结论：BLOCKED

## 摘要

CN 版 iOS 工程可以构建，阿里云 ECS 上的后端进程在线，正式域名 DNS 与 HTTPS 已完成，iOS 配置已切到阿里云域名，本地最新后端代码也已部署到阿里云并完成服务器端构建，生产 App Key 强制校验已启用，法务网页已部署在同一域名 `/legal/` 下。产品已从订阅/广告模型调整为 StoreKit 消耗型成片制作包：首发优惠价 ¥3.80/张，常规目标价 ¥9.90/张，每包 3 次生成机会。App Store Connect 已创建消耗型商品并保存中国大陆首发价格，但当前仍不能推荐上线，主要阻断点是真机端到端回归尚未完成、ICP/App 备案信息需要确认、内购审核截图缺失，以及成本模型需要重算。

## 已验证

| 项目 | 结果 | 证据 |
|------|------|------|
| 后端本地构建 | PASS | `cd backend && npm run build` |
| Info.plist 语法 | PASS | `plutil -lint ios/AIIDPhoto/Info.plist` |
| iOS Release 模拟器构建 | PASS | `xcodebuildmcp simulator build --configuration Release` |
| iOS Release 设备构建 | PASS | `xcodebuildmcp device build --configuration Release` |
| iOS 后端域名配置 | PASS | `BACKEND_BASE_URL=https://aiphoto-cn.foyli.cloud` |
| 阿里云 ECS 后端进程 | PASS | PM2 `aiidphoto-backend` online，Nginx Host 转发 `/health` 返回 `{"status":"ok"}` |
| 阿里云正式域名 | PASS | DNS A 记录解析到 ECS，HTTPS `/health` 返回 `{"status":"ok"}` |
| HTTP 跳转 HTTPS | PASS | `http://aiphoto-cn.foyli.cloud/health` 返回 301 到 HTTPS |
| 阿里云后端代码同步 | PASS | 服务器 `backend/src` 与本地最新版本哈希一致，服务器端 `npm run build` 通过，PM2 已重启 |
| 生产 App Key 强制校验 | PASS | PM2 环境 `REQUIRE_APP_KEY=true`；无 Key 生成请求返回 401，携带 iOS Key 进入参数校验 |
| 法务网页 | PASS | `https://aiphoto-cn.foyli.cloud/legal/`、隐私政策、服务条款、支持页、个人信息清单、第三方服务清单均返回 200 |

## 当前阻断

| 优先级 | 阻断项 | 影响 |
|--------|--------|------|
| P0 | ICP/App 备案信息待确认 | 中国大陆 App Store 合规信息仍需官方备案号 |
| P1 | 成本模型待重算 | 旧 GCP/Gemini 成本模型已作废，不能指导按张价格、3次生成次数和投放预算 |
| P1 | 内购审核材料缺失 | `com.yufeicn.aiidphoto.photo_task_3` 已创建并配置中国大陆首发价，但仍需上传新的内购审核截图，并随新版本提交 |
| P1 | App Store 版本元数据仍是旧模型 | 当前被拒版本页面仍包含旧 Pro、广告、订阅和每日免费次数描述，提交前必须改为消耗型成片制作包 |
| P1 | 真机端到端回归未完成 | 还未覆盖真实生成、StoreKit 消耗型购买、生成次数扣减、保存相册和权限弹窗 |

## 环境与构建证据

| 项目 | 结果 |
|------|------|
| Xcode | 26.5 (17F42) |
| XcodeBuildMCP | 2.5.2 |
| Maestro | 2.5.1 |
| Simulator | iPhone 17 Pro, iOS 26.5 available |
| Simulator build log | `~/Library/Developer/XcodeBuildMCP/workspaces/ai_profile_cn-619097338ec9/logs/build_sim_2026-05-24T09-34-20-199Z_pid60540_192d4645.log` |
| Device build log | `~/Library/Developer/XcodeBuildMCP/workspaces/ai_profile_cn-619097338ec9/logs/build_device_2026-05-24T09-34-29-625Z_pid60797_d09b6015.log` |

Build warnings were limited to App Intents metadata extraction being skipped because the app has no AppIntents framework dependency.

## Security / Cost / Performance

- Security: provider keys remain server-side; production now enforces `X-App-Key` on generation requests. This is still a light client gate, not a substitute for account/device-level abuse protection.
- Cost: daily budget controls exist, but the cost model must be recalculated against Hivision + Bailian before scaling traffic.
- Performance: backend `/health` is fast through HTTPS; real image generation latency still needs a small-image smoke test and true-device UX timing.

## 建议上线顺序

1. 确认中国大陆 App Store 需要填写的 ICP/App 备案号，不要在页面或 App Store Connect 中使用占位值。
2. 清理 App Store 1.0 版本页旧 Pro/广告/订阅/免费次数文案，改为消耗型成片制作包。
3. 补新的 App Store Connect 内购审核截图，并把 `com.yufeicn.aiidphoto.photo_task_3` 随新版 App 提交；旧 Pro 订阅商品不要再走审核。
4. 用阿里云域名做真机端到端生成、StoreKit 购买、次数扣减、保存相册、权限弹窗回归。
5. 用上线首周真实账单重算单张成片毛利和 `DAILY_BUDGET`。

## 预估进度

| 模块 | 完成度 |
|------|--------|
| iOS 工程构建与基础功能 | 约 85% |
| 阿里云后端基础运行 | 约 70% |
| 阿里云正式切流 | 约 90% |
| 法律/隐私合规 | 约 85%，待备案号和正式法务审阅 |
| 上架门禁整体 | 约 85%，当前不可上线 |

## 当前可继续做的修复

- 清理 iOS 26 / iOS 17 deprecation warning，降低后续升级风险。
- 把 server 端推荐码、预算、生成日志持久化，避免 PM2 重启丢状态。
- 加一个最小 smoke test：`/health`、无 key 拒绝、有 key 允许、真实小图生成返回 base64。
- 把 App Store 审核视频和真机回归证据补齐。
