# CN 后端部署指南（阿里云 ECS）

> 文件名保留 `cloud-run-deploy.md` 是历史原因。CN 版主后端当前运行在阿里云 ECS；Hivision 服务仍通过外部 `HIVISION_URL` 调用。

## 当前服务信息

| 项目 | 值 |
|------|-----|
| 云服务商 | 阿里云 ECS |
| 区域 | 广州 |
| 操作系统 | Ubuntu 22.04 |
| 项目路径 | `/opt/aiidphoto-backend` |
| PM2 进程 | `aiidphoto-backend` |
| 启动脚本 | `/opt/aiidphoto-backend/dist/index.js` |
| Node.js | 20.19.6 |
| 本机监听 | `127.0.0.1:9528` |
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
rsync -av --delete \
  --exclude node_modules \
  --exclude .env \
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

生产环境由 PM2 ecosystem 注入：

| 变量 | 用途 |
|------|------|
| `NODE_ENV` | `production` |
| `PORT` | `9528` |
| `HIVISION_URL` | HivisionIDPhotos endpoint |
| `BAILIAN_API_KEY` | 阿里云百炼 API Key |
| `APP_API_KEY` | iOS `X-App-Key` 校验 |
| `REQUIRE_APP_KEY` | 是否强制拒绝缺失/错误 App Key |
| `DAILY_BUDGET` | 每日生成预算熔断 |

不要把真实 Key 写入文档或提交到仓库。

## 上线前检查

- [x] `aiphoto-cn.foyli.cloud` A 记录解析到 ECS 公网 IP。
- [x] 为 `aiphoto-cn.foyli.cloud` 配置 HTTPS 证书。
- [x] HTTPS `/health` 公网可访问。
- [x] iOS `BACKEND_BASE_URL` 切换到 HTTPS 阿里云域名。
- [x] 阿里云部署版本与本地 `backend/src` 对齐，并完成服务器端 `npm run build` + PM2 重启。
- [x] 将 `REQUIRE_APP_KEY` 改为 `true`，缺失 Key 返回 401，携带 iOS Key 可进入参数校验。
- [ ] 通过真机生成测试。
