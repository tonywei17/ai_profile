# API Key 安全管理

## 原则

**AI provider API Key 不进入 iOS 客户端，不写入公开文档，不提交到仓库。**

## 当前 CN 方案

```text
iOS App
  └─ X-App-Key
      ↓
阿里云 ECS / Nginx / Node 后端
  ├─ HIVISION_URL
  └─ BAILIAN_API_KEY
      ↓
HivisionIDPhotos / 阿里云百炼
```

## Key 分类

| Key | 位置 | 用途 |
|-----|------|------|
| `APP_API_KEY` | iOS Info.plist + 后端 PM2 环境 | 轻量识别 App 请求 |
| `BAILIAN_API_KEY` | 仅服务器 PM2 环境 | 调用阿里云百炼 / Qwen / Wanx |
| `HIVISION_URL` | 仅服务器 PM2 环境 | 调用 HivisionIDPhotos 服务 |

`APP_API_KEY` 不是强安全边界，因为客户端可被逆向；它只能减少随意调用。真正的成本保护依赖服务端限速、预算熔断和后续账号/设备级鉴权。

## 当前风险

| 风险 | 状态 | 建议 |
|------|------|------|
| `REQUIRE_APP_KEY=true` | 已启用 | 保持开启；上线后补账号/设备级滥用保护 |
| PM2 ecosystem 持有明文 Key | 当前实现 | 限制服务器权限，避免把 ecosystem 文件同步回仓库 |
| 推荐码内存存储 | 当前实现 | 迁移到数据库或 KV 存储 |
| HTTPS 证书续期 | 已由 Certbot 定时任务处理 | 定期检查 `certbot certificates -d aiphoto-cn.foyli.cloud` |

## 轮换流程

```bash
# 1. 登录服务器
ssh root@<server>

# 2. 编辑 PM2 ecosystem 环境变量
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
*.pem
*.key
ecosystem.config.cjs
```

如果需要保留 PM2 模板，提交 `ecosystem.config.example.cjs`，真实 Key 用占位符。
