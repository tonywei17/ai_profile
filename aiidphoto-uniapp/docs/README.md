# 光影形象馆微信小程序交接说明

本文档用于记录 `aiidphoto-uniapp` 微信小程序当前上线版本的关键配置、构建方式和提审注意事项，便于后续在 `ai_profile_liu` 分支继续维护。

## 项目定位

- 小程序名称：光影形象馆。
- 技术栈：uni-app + Vue 3，目标平台为微信小程序。
- 后端域名：`https://aiphoto-cn.foyli.cloud`。
- 业务功能：证件照/职业形象照生成、常用规格与自定义尺寸、AI 外观编辑、结果保存、打印排版、历史记录、生成次数购买。
- 支付模式：微信小程序虚拟支付，正式商品为 3 次 AI 生成机会，价格以微信支付/道具后台配置为准。

## 目录说明

- `api/`：后端接口封装、微信登录、生成次数、虚拟支付与 AI 生成接口。
- `pages/`：小程序页面，包含首页、制作页、结果页、历史页、设置页、购买页、隐私政策和用户协议。
- `components/`：复用组件，目前包含结果页原图/效果图对比滑块。
- `static/`：小程序静态资源，包含应用图标和首页展示图。
- `utils/`：国际化、主题、AIGC 元数据写入等工具方法。
- `docs/`：上线检查、微信后台隐私指引和本交接文档。
- `scripts/`：构建后同步脚本，用于将正式构建产物同步到开发者工具常用调试目录。

## 构建与调试

```powershell
cd D:\liu\Desktop\yufeicode\ai_profile\aiidphoto-uniapp
npm install
npm run build:mp-weixin
```

构建完成后，正式审核包位于：

```text
D:\liu\Desktop\yufeicode\ai_profile\aiidphoto-uniapp\dist\build\mp-weixin
```

`build:mp-weixin` 会自动同步到：

```text
D:\liu\Desktop\yufeicode\ai_profile\aiidphoto-uniapp\unpackage\dist\dev\mp-weixin
```

这是为了避免微信开发者工具历史项目打开旧的 `unpackage` 调试目录后，出现“源码已改但真机仍是旧效果”的问题。正式上传审核时，建议只导入或选择 `dist/build/mp-weixin`。

## 上线关键配置

- `manifest.json` 已启用组件按需注入：`lazyCodeLoading: requiredComponents`。
- `api/config.js` 默认请求线上后端：`https://aiphoto-cn.foyli.cloud`。
- 正式构建通过 `VITE_PAYMENT_MODE=virtual` 启用微信虚拟支付。
- 小程序客户端不应包含虚拟支付 AppKey、微信支付密钥、商户私钥或服务器密码。
- `unpackage/`、`dist/`、`.env`、后端证书和运行数据已通过 `.gitignore` 排除。

## 首次使用与用户权益

- 新设备首次打开小程序会展示个人信息保护提示。
- 用户同意前不会触发微信登录、获取 OpenID 或查询生成次数。
- 新微信用户由服务端按 OpenID 对应用户首次建档并赠送 3 次基础生成机会。
- 同一微信用户更换设备不会重复领取免费次数。
- 购买成功后，服务端会增加对应生成次数；若付款后关闭小程序，再次查询权益时会尝试自动核对和补发待处理虚拟支付订单。

## 支付说明

- 当前小程序正式支付入口使用 `wx.requestVirtualPayment`。
- 后端负责生成 `signData`、`paySig` 和用户态 `signature`，客户端只负责调起支付与查询订单。
- 道具 ID、OfferID、AppKey、价格等敏感或运营配置均应只保存在服务端环境变量或微信后台，不应写入小程序包。
- iOS 是否显示购买入口取决于客户端能力判断和微信后台是否完成苹果 IAP 相关配置；如需支持 iPhone，请确认客户端没有额外屏蔽 iOS 平台。

## 隐私与合规

- 小程序内已提供隐私政策和用户协议页面。
- 微信后台《用户隐私保护指引》需与实际功能保持一致，至少覆盖照片选择、相机、保存到相册、OpenID 对应标识、订单信息、IP/请求日志、人像照片及面部特征、AI 生成内容标识和导出日志。
- 第三方共享清单需覆盖微信基础能力、微信虚拟支付、阿里云 ECS、阿里云百炼、HivisionIDPhotos 及其实际基础设施提供方。
- HivisionIDPhotos 当前存在中国大陆以外云区域处理的合规风险，需在隐私指引和第三方清单中如实披露；长期建议迁移到中国大陆云区域以降低审核和合规风险。
- AI 生成/编辑结果在界面显式标注，并在 JPEG/PNG 中写入隐式 AIGC 标识；用户导出无显式水印图片时会记录必要审计日志。

## 提审前检查清单

- 使用微信开发者工具打开 `dist/build/mp-weixin`，执行“代码质量”和“体验评分”。
- 真机验证首次隐私弹窗、微信登录、3 次免费权益、相机/相册授权、生成、保存相册和打印排版。
- 真机验证 Android/HarmonyOS/Windows 虚拟支付购买和权益到账。
- 如已配置苹果 IAP，使用 iPhone 真机验证购买入口、支付调起和权益到账。
- 确认结果页原图/效果图对比滑块不会带动整个页面滚动。
- 确认正式包不包含 `.env`、证书、私钥、AppKey、商户密钥、服务器密码、`localhost`、测试支付入口或未完成页面。

## 审核备注建议

提交审核时可在备注中说明：

```text
新用户首次使用赠送 3 次基础生成机会。用户同意隐私指引后可选择或拍摄照片，选择规格并生成证件照/形象照。购买入口使用微信小程序虚拟支付购买 3 次生成机会。生成或编辑结果带 AI 内容标识，保存到相册由用户主动触发。
```

如 iOS 已开通并验证苹果 IAP，可补充：

```text
iOS、Android、HarmonyOS 和 Windows 微信均通过微信小程序虚拟支付购买生成次数，具体可用性以微信客户端能力和后台配置为准。
```

## 相关文档

- `production-readiness.md`：上线检查和剩余人工事项。
- `wechat-admin-privacy-guide.md`：微信公众平台隐私指引与第三方共享清单填写参考。
