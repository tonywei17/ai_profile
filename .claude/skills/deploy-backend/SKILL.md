---
name: deploy-backend
description: Deploy the AIIDPhoto backend to GCP Cloud Run (Tokyo region). Use when backend code changes are ready to deploy.
disable-model-invocation: true
allowed-tools: Bash(gcloud *)
---

# Deploy AIIDPhoto Backend to Cloud Run

Deploys `backend/` to Cloud Run using Cloud Build (no local Docker needed).

## Project Info
- **GCP Project**: `ai-id-photo-prod`
- **Region**: `asia-northeast1` (Tokyo)
- **Service**: `aiidphoto-backend`
- **URL**: `https://aiidphoto-backend-616059029156.asia-northeast1.run.app`
- **API Key**: Stored in Secret Manager as `GEMINI_API_KEY` (never in code)

## Deploy Command

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

## After Deploy

Verify the deployment:
```bash
curl https://aiidphoto-backend-616059029156.asia-northeast1.run.app/health
```

Expected: `{"status":"ok"}`

## Update API Key

To rotate the Gemini API key:
```bash
echo -n "NEW_KEY_HERE" | gcloud secrets versions add GEMINI_API_KEY \
  --project=ai-id-photo-prod \
  --data-file=-
```

## Logs

```bash
gcloud run services logs read aiidphoto-backend \
  --project=ai-id-photo-prod \
  --region=asia-northeast1 \
  --limit=50
```
