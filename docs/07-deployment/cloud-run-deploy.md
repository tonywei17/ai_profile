# CN 后端部署指南（阿里云 ECS）

> 文件名保留 `cloud-run-deploy.md` 是历史原因。CN 版主后端当前运行在阿里云 ECS；
> Hivision 自 2026-07-13 起也已迁移到同一台 ECS 上的自建 Docker 容器（不再依赖
> 外部 Google Cloud Run），详见 [deploy-2026-07-13.md](deploy-2026-07-13.md)。

## 当前服务信息

| 项目 | 值 |
|------|-----|
| 云服务商 | 阿里云 ECS |
| 区域 | 广州 |
| 操作系统 | Ubuntu 22.04 |
| 项目路径 | `/opt/aiidphoto-backend` |
| PM2 进程 | `aiidphoto-backend`（`ecosystem.config.js`，`exec_mode: fork`） |
| 启动脚本 | `/opt/aiidphoto-backend/dist/index.js` |
| Node.js | 20.19.6 |
| 本机监听 | `127.0.0.1:9528` |
| Hivision 容器 | `hivision-api`（`linzeyi/hivision_idphotos`，`restart: unless-stopped`），`127.0.0.1:8899 -> 8080`，`HIVISION_URL=http://127.0.0.1:8899` |
| Nginx 配置 | `/etc/nginx/sites-available/aiphoto-cn.foyli.cloud` |
| 反向代理 | `aiphoto-cn.foyli.cloud` → `http://127.0.0.1:9528` |
| 生成超时 | iOS 150s，后端 provider 90s，Nginx read timeout 180s |

## 当前公网状态

2026-05-24 实测：

- 服务器本机 `http://127.0.0.1:9528/health` 返回 `{"status":"ok"}`。
- 服务器本机带 Host header 访问 Nginx `http://127.0.0.1/health` 返回 `{"status":"ok"}`。
- 阿里云 DNS 已添加 `aiphoto-cn.foyli.cloud` A 记录，解析到 ECS 公网 IP。
- Let's Encrypt 证书已通过 Certbot 配置到 Nginx。
- `http://aiphoto-cn.foyli.cloud/health` 会 301 到 HTTPS。
- `https://aiphoto-cn.foyli.cloud/health` 返回 `{"status":"ok"}`。

因此，iOS 生产 `BACKEND_BASE_URL` 已可以使用 `https://aiphoto-cn.foyli.cloud`。上线前仍需做真机生成和 App Store 关键路径回归。

## 部署流程

```bash
# 1. 本地构建后端
cd backend
npm install
npm run build

# 2. 上传代码到服务器
# 登录信息见 /Users/weiwenxin/Project/Foyli/Ali_cloud/SERVER_INFO.md
#
# ⚠️ certs/ 和 data/ 必须排除：这两个目录只存在于服务器上（在 backend/.gitignore
# 里，本地从未有过），--delete 会把它们当成"多余文件"删掉。2026-07-13 曾因漏排除
# certs/ 导致微信支付证书被误删、触发生产中断，详见 deploy-2026-07-13.md。
rsync -av --delete \
  --exclude node_modules \
  --exclude .env \
  --exclude certs \
  --exclude data \
  ./ root@<server>:/opt/aiidphoto-backend/

# 3. 服务器安装依赖并构建
ssh root@<server>
cd /opt/aiidphoto-backend
npm install
npm run build

# 4. 重启进程
pm2 restart aiidphoto-backend
pm2 save

# 5. 校验 Nginx
nginx -t
systemctl reload nginx
```

## 验证

```bash
# 服务器本机
curl http://127.0.0.1:9528/health

# 服务器上经 Nginx Host header
curl -H "Host: aiphoto-cn.foyli.cloud" http://127.0.0.1/health

# DNS 生效后，公网验证
curl https://aiphoto-cn.foyli.cloud/health
```

生成接口 smoke test 应使用真实测试图片 base64，避免无效图片触发 provider 报错：

```bash
curl -X POST https://aiphoto-cn.foyli.cloud/api/gemini/generate \
  -H "Content-Type: application/json" \
  -H "X-App-Key: <app key>" \
  -d '{
    "image": "<base64 JPEG>",
    "prompt": "生成中国一寸白底证件照",
    "tier": "free",
    "specWidth": 295,
    "specHeight": 413,
    "specBgColor": "ffffff"
  }'
```

## 日常运维

```bash
pm2 list
pm2 show aiidphoto-backend
pm2 logs aiidphoto-backend --lines 100

systemctl status nginx
nginx -t
tail -n 100 /var/log/nginx/access.log
tail -n 100 /var/log/nginx/error.log
```

## 环境变量

生产环境由 `/opt/aiidphoto-backend/ecosystem.config.js` 注入（服务器本地文件，
权限 600，**含真实密钥，故意不提交到仓库**；2026-07-13 从之前只存在于 PM2 内存
的 `pm2_env` 重建为该文件，见 [deploy-2026-07-13.md](deploy-2026-07-13.md)）。
改动环境变量后需要 `pm2 delete aiidphoto-backend && pm2 start ecosystem.config.js`
让新文件生效——单独 `pm2 restart` 不会重新读取 `ecosystem.config.js` 的变化。

以下是 `backend/src/config.ts` 实际读取的完整 key 列表（仅列变量名，不含值）：

| 变量 | 用途 |
|------|------|
| `NODE_ENV` | `production` |
| `PORT` | `9528` |
| `HIVISION_URL` | Hivision 服务地址，现为自建容器 `http://127.0.0.1:8899` |
| `BAILIAN_API_KEY` | 阿里云百炼 API Key |
| `TRIPO_BASE_URL` | Tripo 服务地址（如启用） |
| `APP_API_KEY` | iOS `X-App-Key` 校验 |
| `REQUIRE_APP_KEY` | 是否强制拒绝缺失/错误 App Key |
| `REFERRAL_HMAC_SECRET` | 推荐码 HMAC 签名，必须与 `APP_API_KEY` 分离 |
| `DAILY_BUDGET` | 每日生成预算熔断 |
| `WECHAT_APP_ID` / `WECHAT_APP_SECRET` | 微信小程序身份 |
| `SESSION_TOKEN_SECRET` | 会话 token 签名密钥 |
| `WECHAT_MCH_ID` / `WECHAT_SERIAL_NO` / `WECHAT_API_V3_KEY` | 微信支付商户配置 |
| `WECHAT_KEY_PATH` | 微信支付商户私钥文件路径（指向服务器 `certs/`，**不在仓库里**） |
| `WECHAT_PLATFORM_PUBLIC_KEY_PATH` / `WECHAT_PLATFORM_SERIAL_NO` | 微信支付平台证书 |
| `WECHAT_NOTIFY_URL` | 微信支付回调地址 |
| `WECHAT_VIRTUAL_PAY_ENABLED` / `WECHAT_VIRTUAL_OFFER_ID` / `WECHAT_VIRTUAL_SANDBOX_APP_KEY` / `WECHAT_VIRTUAL_PRODUCTION_APP_KEY` / `WECHAT_VIRTUAL_ENV` / `WECHAT_VIRTUAL_PRODUCT_ID` / `WECHAT_VIRTUAL_PRODUCT_PRICE` | 微信虚拟支付（小程序内购）配置 |
| `PAYMENT_DATA_PATH` | 订单记录 JSON 存储路径（指向服务器 `data/`，**不在仓库里**） |

不要把真实 Key 写入文档或提交到仓库。生产最佳方案是把 `APP_API_KEY`、`REFERRAL_HMAC_SECRET`、`BAILIAN_API_KEY` 等敏感值放入阿里云 KMS Secrets Manager，ECS 通过实例 RAM 角色最小权限读取；当前的 `ecosystem.config.js` 明文注入只作为过渡方案。

## 上线前检查

- [x] `aiphoto-cn.foyli.cloud` A 记录解析到 ECS 公网 IP。
- [x] 为 `aiphoto-cn.foyli.cloud` 配置 HTTPS 证书。
- [x] HTTPS `/health` 公网可访问。
- [x] iOS `BACKEND_BASE_URL` 切换到 HTTPS 阿里云域名。
- [x] 阿里云部署版本与本地 `backend/src` 对齐，并完成服务器端 `npm run build` + PM2 重启。
- [x] 将 `REQUIRE_APP_KEY` 改为 `true`，缺失 Key 返回 401，携带 iOS Key 可进入参数校验。
- [ ] 通过真机生成测试。
