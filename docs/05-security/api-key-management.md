# API Key 安全管理

## 原则

**AI provider API Key 不进入 iOS 客户端，不写入公开文档，不提交到仓库。**

## 当前 CN 方案

```text
iOS App
  └─ X-App-Key
      ↓
阿里云 ECS / Nginx / Node 后端
  ├─ 阿里云 KMS Secrets Manager
  │   ├─ APP_API_KEY
  │   ├─ REFERRAL_HMAC_SECRET
  │   └─ BAILIAN_API_KEY
  ├─ HIVISION_URL
  └─ HivisionIDPhotos / 阿里云百炼
      ↓
图片生成结果
```

## Key 分类

| Key | 位置 | 用途 |
|-----|------|------|
| `APP_API_KEY` | iOS build setting 注入 + 后端 KMS/PM2 环境 | 轻量识别 App 请求 |
| `REFERRAL_HMAC_SECRET` | 仅服务器 KMS/PM2 环境 | 推荐码 HMAC 签名 |
| `BAILIAN_API_KEY` | 仅服务器 KMS/PM2 环境 | 调用阿里云百炼 / Qwen / Wanx |
| `HIVISION_URL` | 仅服务器 PM2 环境 | 调用 HivisionIDPhotos 服务 |

`APP_API_KEY` 不是强安全边界，因为客户端可被逆向；它只能减少随意调用。真正的成本保护依赖服务端限速、预算熔断和后续账号/设备级鉴权。

## 阿里云最佳安全方案

上线目标是“密钥只在服务端短暂落内存，仓库、文档、iOS 源码、服务器磁盘配置均不持有长期明文 provider key”。

1. **KMS Secrets Manager 存密钥**
   - 在阿里云 KMS Secrets Manager 建立 `aiidphoto/prod/app-api-key`、`aiidphoto/prod/referral-hmac-secret`、`aiidphoto/prod/bailian-api-key`。
   - 每个 secret 独立轮换，`APP_API_KEY` 与 `REFERRAL_HMAC_SECRET` 不共用。

2. **ECS 使用 RAM Role 取密钥**
   - 给 ECS 绑定实例 RAM 角色，不在服务器写入 RAM 用户 AccessKey。
   - 自定义最小权限策略，仅允许读取上述 secret 资源，禁止通配读取全账号 secret。
   - Node 后端启动时通过阿里云 SDK 读取 secret，缓存到进程内存；失败则拒绝启动或禁用对应 provider。

3. **PM2 ecosystem 降级为非敏感配置**
   - PM2 只保留 `PORT`、`NODE_ENV`、`HIVISION_URL`、`DAILY_BUDGET`、secret 名称等非敏感值。
   - 过渡期如仍使用 PM2 明文环境变量，必须限制文件权限，不同步回本地，不提交到仓库，并安排迁移到 KMS。

4. **iOS 客户端只注入调用标识**
   - `APP_API_KEY` 通过 `AIIDPHOTO_APP_API_KEY` build setting 注入；XcodeGen 读取 tracked `App.xcconfig`，再可选 include 本地 `ios/AIIDPhoto/Configuration/Secrets.xcconfig`，该文件必须 gitignored。
   - 该 key 泄露风险按“可被复制的客户端标识”处理，不承载 provider 访问权限。

5. **成本与滥用保护放在后端**
   - 保持 `REQUIRE_APP_KEY=true`、IP 限速、每日预算熔断。
   - 下一阶段补 Apple App Attest / DeviceCheck、StoreKit 交易校验、设备级 ledger、生成记录持久化，防止复制客户端 key 后刷量。

## 当前风险

| 风险 | 状态 | 建议 |
|------|------|------|
| `REQUIRE_APP_KEY=true` | 已启用 | 保持开启；上线后补设备级滥用保护和交易校验 |
| 旧 `APP_API_KEY` 曾进入 git | 低风险，仓库为私有仓库；当前已从源码配置移除 | 不作为上线阻断，不强制轮转；仅在仓库外泄、转公开、协作者权限变化或发现异常调用时轮换 |
| PM2 ecosystem 持有明文 Key | 过渡实现 | 迁移到 KMS Secrets Manager + ECS RAM Role |
| 推荐码内存存储 | 当前实现 | 迁移到数据库或 KV 存储 |
| HTTPS 证书续期 | 已由 Certbot 定时任务处理 | 定期检查 `certbot certificates -d aiphoto-cn.foyli.cloud` |

## 按需轮换流程

```bash
# 1. 登录服务器
ssh root@<server>

# 2. 按需轮换阿里云 KMS Secrets Manager 中的 secret
#    过渡期如仍使用 PM2 明文变量，再编辑 ecosystem 环境变量
cd /opt/aiidphoto-backend
vim ecosystem.config.cjs

# 3. 重启并保存 PM2 状态
pm2 restart aiidphoto-backend
pm2 save

# 4. 验证
curl http://127.0.0.1:9528/health
pm2 logs aiidphoto-backend --lines 50
```

## .gitignore 要求

确保以下文件不被提交：

```text
backend/.env
ios/AIIDPhoto/Configuration/Secrets.xcconfig
ios/AIIDPhoto/Configuration/*.local.xcconfig
*.pem
*.key
ecosystem.config.cjs
```

如果需要保留 PM2 模板，提交 `ecosystem.config.example.cjs`，真实 Key 用占位符。
