# 光影形象馆微信小程序交接文档

本文档面向后续接手分析和维护的同事，说明 `aiidphoto-uniapp` 微信小程序与 `backend` 后端在当前已上线版本中的职责边界、核心链路和注意事项。

## 当前状态

- 小程序已完成上线，项目目录为 `aiidphoto-uniapp`。
- 小程序后端复用仓库根目录下的 `backend`，与原 iOS 项目共享同一套后端服务。
- 当前线上后端域名为 `https://aiphoto-cn.foyli.cloud`。
- 当前分支用于保存本轮小程序上线改造和后端适配结果：`ai_profile_liu`。
- 本轮提交范围包含 `aiidphoto-uniapp` 与 `backend`，不包含本地构建产物、服务器密钥、证书、`.env`、微信开发者工具私有配置和 IDE 临时目录。

## 整体架构

```text
微信小程序 aiidphoto-uniapp
  ├─ 微信登录 / OpenID 获取
  ├─ 生成次数查询与扣减
  ├─ 图片上传与 AI 生成
  ├─ 虚拟支付购买生成次数
  ├─ 结果保存、历史记录、打印排版
  └─ 隐私政策、用户协议、AI 内容标识提示

backend
  ├─ 微信登录与 session token
  ├─ 生成次数与订单状态存储
  ├─ 微信虚拟支付签名、查单、补发
  ├─ HivisionIDPhotos 图像处理调用
  ├─ 阿里云百炼 / 通义万相图像编辑调用
  ├─ AIGC 隐式标识写入与导出日志
  └─ 公网法律页面与健康检查
```

小程序不直接保存或暴露后端密钥、微信支付密钥、虚拟支付 AppKey、商户私钥或第三方 AI 服务密钥。所有敏感配置应只存在于后端环境变量、服务器证书目录或微信后台。

## 小程序目录说明

- `api/config.js`：统一配置后端域名和接口路径，默认连接线上后端。
- `api/request.js`：统一请求封装，会自动带上微信登录 token。
- `api/gemini.js`：AI 生成接口、AIGC 导出确认和导出日志上报。
- `api/payment.js`：生成次数查询、购买入口开关和支付模块选择。
- `api/paymentVirtual.js`：微信小程序虚拟支付调起与订单轮询。
- `api/printLayout.js`：打印排版参数和 Canvas 绘制逻辑。
- `pages/index`：首页、首次隐私提示、新用户权益展示。
- `pages/creation`：照片选择、规格选择、AI 自定义、生成流程。
- `pages/result`：生成结果、原图/效果图对比、保存和打印入口。
- `pages/subscription`：生成次数购买页。
- `pages/privacy` 与 `pages/terms`：小程序内隐私政策和用户协议。
- `components/ComparisonSlider.vue`：结果页图片对比滑块，已将滑动区域与页面滚动隔离。
- `utils/aigcMetadata.js`：给导出的 JPEG 图片补充 AIGC XMP 隐式标识。
- `scripts/sync-wechat-output.mjs`：构建后同步产物到常用调试目录，避免开发者工具加载旧包。
- `docs/production-readiness.md`：上线检查记录。
- `docs/wechat-admin-privacy-guide.md`：微信后台隐私指引和第三方共享清单填写参考。

## 后端目录说明

- `src/index.ts`：Express 应用入口，挂载健康检查、法律页面、鉴权、支付、微信登录和生成接口。
- `src/config.ts`：环境变量读取与生产配置校验。
- `src/middleware/apiKey.ts`：客户端鉴权，支持小程序微信登录 token 与 App API Key。
- `src/routes/wechat.ts`：小程序微信登录、token 校验和用户信息接口。
- `src/routes/payment.ts`：生成次数查询、普通支付保留接口、虚拟支付下单、查单和权益补发。
- `src/routes/gemini.ts`：图像生成主链路、生成次数扣减/恢复、AIGC 导出日志。
- `src/services/paymentStore.ts`：用户权益和订单状态文件存储。
- `src/services/wechatAuthService.ts`：微信 `code2session` 登录、OpenID 映射、session token 生成。
- `src/services/wechatVirtualPayService.ts`：微信虚拟支付参数签名、查单、发货通知。
- `src/services/wechatPayService.ts`：普通微信支付服务，当前正式小程序主要使用虚拟支付。
- `src/services/aigcLabelService.ts`：JPEG/PNG AIGC 隐式标识写入和导出日志记录。
- `public/legal/`：线上法律页面，包括隐私政策、服务条款、数据删除、支持和第三方清单。

## 核心业务链路

### 1. 首次使用与免费次数

1. 新设备首次打开小程序，首页展示个人信息保护提示。
2. 用户同意前，小程序不会触发微信登录、获取 OpenID 或查询生成次数。
3. 用户同意后调用微信登录接口。
4. 后端通过 OpenID 生成内部 `userId`。
5. 若该 `userId` 首次建档，服务端赠送 3 次基础生成机会。
6. 同一微信用户更换设备不会重复领取免费次数。

### 2. 图片生成

1. 用户在制作页选择或拍摄照片。
2. 小程序选择证件照规格和可选 AI 自定义效果。
3. 生成前查询剩余次数。
4. 后端按免费/付费权益预扣生成次数。
5. 后端调用 HivisionIDPhotos 和阿里云百炼等图像处理服务。
6. 生成成功后写入 AIGC 隐式标识并返回图片。
7. 若生成失败，后端恢复本次预扣次数。
8. 小程序展示结果并允许用户主动保存。

### 3. 虚拟支付

1. 小程序购买页请求后端创建虚拟支付订单。
2. 后端生成 `signData`、`paySig` 和用户态 `signature`。
3. 小程序调用 `wx.requestVirtualPayment`。
4. 支付完成后小程序轮询订单状态。
5. 后端查单确认已支付后增加生成次数。
6. 如果用户支付后关闭小程序，再次查询权益时，后端会尝试核对最近待处理订单并补发权益。

### 4. 结果保存与 AIGC 标识

1. 结果页会显示“AI生成/编辑”标识。
2. 后端返回的 JPEG/PNG 包含 AIGC 隐式标识。
3. 打印排版经 Canvas 重新生成图片时，小程序会再次写入必要的 AIGC 元数据。
4. 用户导出无显式水印图片前，小程序会弹窗说明并上报导出日志。

## 构建与调试

```powershell
cd D:\liu\Desktop\yufeicode\ai_profile\aiidphoto-uniapp
npm install
npm run build:mp-weixin
```

正式构建产物：

```text
D:\liu\Desktop\yufeicode\ai_profile\aiidphoto-uniapp\dist\build\mp-weixin
```

同步调试产物：

```text
D:\liu\Desktop\yufeicode\ai_profile\aiidphoto-uniapp\unpackage\dist\dev\mp-weixin
```

说明：微信开发者工具历史项目中可能打开过 `unpackage/dist/dev/mp-weixin`。为避免“源码已改但真机仍加载旧包”，`build:mp-weixin` 会自动同步最新产物到该目录。正式上传仍建议选择 `dist/build/mp-weixin`。

后端构建：

```powershell
cd D:\liu\Desktop\yufeicode\ai_profile\backend
npm install
npm run build
```

## 环境变量说明

以下只列变量用途，不在仓库中保存真实值：

- `APP_API_KEY`：iOS 或其他可信客户端调用后端时使用的 App API Key。
- `REQUIRE_APP_KEY`：是否要求 App API Key。
- `WECHAT_APP_ID` / `WECHAT_APP_SECRET`：小程序微信登录和接口调用。
- `SESSION_TOKEN_SECRET`：后端签发小程序 session token。
- `WECHAT_VIRTUAL_PAY_ENABLED`：是否启用小程序虚拟支付。
- `WECHAT_VIRTUAL_OFFER_ID`：微信虚拟支付基础配置中的 OfferID。
- `WECHAT_VIRTUAL_SANDBOX_APP_KEY`：虚拟支付沙箱 AppKey。
- `WECHAT_VIRTUAL_PRODUCTION_APP_KEY`：虚拟支付现网 AppKey。
- `WECHAT_VIRTUAL_ENV`：虚拟支付环境，正式环境为 0，沙箱环境为 1。
- `WECHAT_VIRTUAL_PRODUCT_ID`：微信后台道具 ID。
- `WECHAT_VIRTUAL_PRODUCT_PRICE`：道具价格，单位为分。
- `PAYMENT_DATA_PATH`：订单与权益文件存储路径。
- `HIVISION_URL`：HivisionIDPhotos 服务地址。
- `BAILIAN_API_KEY`：阿里云百炼 / 通义万相 API Key。
- `WECHAT_MCH_ID`、`WECHAT_SERIAL_NO`、`WECHAT_API_V3_KEY`、`WECHAT_KEY_PATH` 等：普通微信支付相关配置，当前小程序正式购买链路主要使用虚拟支付。

## 与 iOS 共用后端的注意点

- 小程序与 iOS 共用同一个 `backend`，修改鉴权、生成、支付或法律页面时需确认不会破坏 iOS 现有接口。
- `apiKeyAuth` 同时兼容小程序 Bearer token 和原 App API Key。
- 小程序微信登录会创建基于 OpenID 的用户权益；iOS 侧如不使用 OpenID，应继续沿用原有 App API Key 或其既有用户标识方案。
- 图像生成接口中增加了生成次数扣减和 AIGC 标识逻辑，若 iOS 调用同一路由，需要确认是否也接受该权益约束。
- 支付模块同时存在普通微信支付和小程序虚拟支付代码，后续清理时不要误删仍被 iOS 或其他客户端使用的接口。

## 已知风险与后续维护建议

- HivisionIDPhotos 当前涉及中国大陆以外云区域处理，应持续关注隐私合规要求；如条件允许，建议迁移到中国大陆云区域。
- 当前 `paymentStore` 使用文件存储，适合轻量上线；后续用户量增长后建议迁移到数据库，并增加订单幂等、审计和备份策略。
- 微信虚拟支付、苹果 IAP、道具后台配置均依赖微信平台状态，排查支付问题时需同时看客户端能力、后端签名参数、微信后台道具状态和订单查询结果。
- 结果页图片对比滑块已从滚动容器中拆出；若后续改版结果页，需要保留横向滑动与纵向滚动的手势隔离。
- 不要提交 `dist/`、`unpackage/`、`.env`、证书、私钥、AppKey、服务器密码或微信开发者工具私有配置。

## 常用排查入口

- 首页/首次授权：`pages/index/index.vue`
- 制作页生成流程：`pages/creation/creation.vue`
- 结果页保存与对比：`pages/result/result.vue`
- 小程序支付入口：`api/payment.js`、`api/paymentVirtual.js`、`pages/subscription/subscription.vue`
- 后端微信登录：`backend/src/routes/wechat.ts`、`backend/src/services/wechatAuthService.ts`
- 后端虚拟支付：`backend/src/routes/payment.ts`、`backend/src/services/wechatVirtualPayService.ts`
- 后端生成主链路：`backend/src/routes/gemini.ts`
- AIGC 标识：`backend/src/services/aigcLabelService.ts`、`utils/aigcMetadata.js`
- 微信后台隐私填写参考：`docs/wechat-admin-privacy-guide.md`
