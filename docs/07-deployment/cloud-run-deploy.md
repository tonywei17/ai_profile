# Cloud Run 部署指南

## 服务信息

| 项目 | 值 |
|------|-----|
| GCP Project | `ai-id-photo-prod` |
| Region | `asia-northeast1`（东京） |
| Service | `aiidphoto-backend` |
| URL | `https://aiidphoto-backend-616059029156.asia-northeast1.run.app` |
| 内存 | 512Mi |
| CPU | 1 vCPU |
| 最大实例 | 10 |
| 认证 | 无（公开访问） |

## 部署（日常）

改好 `backend/src/` 代码后：

```bash
gcloud run deploy aiidphoto-backend \
  --source ./backend \
  --project=ai-id-photo-prod \
  --region=asia-northeast1 \
  --platform=managed \
  --allow-unauthenticated \
  --set-secrets="GEMINI_API_KEY=GEMINI_API_KEY:latest" \
  --memory=512Mi \
  --cpu=1 \
  --max-instances=10 \
  --quiet
```

或使用 Claude Code Skill：`/deploy-backend`

## 验证

```bash
# 健康检查
curl https://aiidphoto-backend-616059029156.asia-northeast1.run.app/health

# 测试生成接口（需要 base64 图片）
curl -X POST \
  https://aiidphoto-backend-616059029156.asia-northeast1.run.app/api/gemini/generate \
  -H "Content-Type: application/json" \
  -d '{"image": "BASE64_HERE", "prompt": "生成证件照"}'
```

## 查看日志

```bash
gcloud run services logs read aiidphoto-backend \
  --project=ai-id-photo-prod \
  --region=asia-northeast1 \
  --limit=50
```

或在 GCP Console：
`https://console.cloud.google.com/run/detail/asia-northeast1/aiidphoto-backend/logs?project=ai-id-photo-prod`

## 回滚

```bash
# 查看历史修订版
gcloud run revisions list \
  --service=aiidphoto-backend \
  --project=ai-id-photo-prod \
  --region=asia-northeast1

# 回滚到指定修订版
gcloud run services update-traffic aiidphoto-backend \
  --project=ai-id-photo-prod \
  --region=asia-northeast1 \
  --to-revisions=REVISION_NAME=100
```

## 首次部署记录（2026-03-01）

由于 Cloud Build 权限问题，首次部署通过本地 Docker 构建后推送到 Artifact Registry：

```bash
docker build --platform linux/amd64 \
  -t asia-northeast1-docker.pkg.dev/ai-id-photo-prod/cloud-run-source-deploy/aiidphoto-backend:latest .
docker push asia-northeast1-docker.pkg.dev/ai-id-photo-prod/cloud-run-source-deploy/aiidphoto-backend:latest
gcloud run deploy aiidphoto-backend --image ...
```

后续部署已改为 `--source` 方式（Cloud Build 自动构建）。
