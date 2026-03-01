# API Key 安全管理

## 原则

**API Key 永远不出现在客户端代码或 Git 仓库中。**

## 当前方案

```
iOS App → Cloud Run 后端代理 → Gemini API
                ↑
         Secret Manager 注入
```

### Gemini API Key

- **存储位置**：GCP Secret Manager，项目 `ai-id-photo-prod`，Secret 名称 `GEMINI_API_KEY`
- **访问权限**：Cloud Run 默认 Service Account（`616059029156-compute@developer.gserviceaccount.com`），`roles/secretmanager.secretAccessor`
- **注入方式**：Cloud Run `--set-secrets="GEMINI_API_KEY=GEMINI_API_KEY:latest"`，以环境变量形式注入容器

### 轮换 API Key

```bash
# 1. 创建新版本
echo -n "NEW_KEY_HERE" | gcloud secrets versions add GEMINI_API_KEY \
  --project=ai-id-photo-prod \
  --data-file=-

# 2. 重新部署（自动使用 latest 版本）
gcloud run deploy aiidphoto-backend \
  --source ./backend \
  --project=ai-id-photo-prod \
  --region=asia-northeast1 \
  --set-secrets="GEMINI_API_KEY=GEMINI_API_KEY:latest"

# 3. 禁用旧版本
gcloud secrets versions disable VERSION_NUMBER \
  --secret=GEMINI_API_KEY \
  --project=ai-id-photo-prod
```

## .gitignore 要求

确保以下文件不被提交：

```
backend/.env
*.pem
*.key
```

## 待办

- [ ] 后端添加 Firebase Auth 验证（防止非 App 请求）
- [ ] 为 API Key 配置 Cloud Armor 或 IP 白名单（可选）
- [ ] 定期（每 90 天）轮换 API Key
