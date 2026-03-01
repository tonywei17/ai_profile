# 环境配置 & 快速上手

## 前置要求

| 工具 | 版本 | 用途 |
|------|------|------|
| Xcode | 15+ | iOS 开发 |
| Swift | 5.9+ | 编程语言 |
| Node.js | 22+ | 后端开发 |
| gcloud CLI | 任意 | GCP 部署 |
| Firebase CLI | 任意 | Firebase 管理 |

## iOS 项目启动

```bash
# 克隆仓库
git clone https://github.com/tonywei17/ai_profile.git
cd ai_profile

# 打开 Xcode 项目
open AIIDPhoto.xcodeproj
```

或命令行构建：

```bash
xcodebuild \
  -project AIIDPhoto.xcodeproj \
  -scheme AIIDPhoto \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

## 后端启动（本地开发）

```bash
cd backend
cp .env.example .env
# 编辑 .env，填入 GEMINI_API_KEY
npm install
npm run dev
```

本地服务运行在 `http://localhost:8080`。

## 配置说明（Info.plist）

| 键 | 值 | 说明 |
|----|-----|------|
| `BACKEND_BASE_URL` | Cloud Run URL | 生产环境后端地址 |
| `GEMINI_ENDPOINT` | Gemini API URL | 开发直连（留空使用后端） |
| `GEMINI_API_KEY` | API Key | 开发直连（生产留空） |

## 模拟器运行

```bash
# 构建 + 安装 + 启动
SIMULATOR_ID="36A7B000-9CB2-406E-AA3A-F75B34651856"  # iPhone 17 Pro
xcodebuild -project AIIDPhoto.xcodeproj -scheme AIIDPhoto \
  -sdk iphonesimulator -destination "id=$SIMULATOR_ID" build
xcrun simctl install $SIMULATOR_ID \
  build/DerivedData/Build/Products/Debug-iphonesimulator/AIIDPhoto.app
xcrun simctl launch $SIMULATOR_ID com.nexus.aiidphoto
```

## Claude Code Skills（项目专属）

| Skill | 调用方式 | 用途 |
|-------|---------|------|
| swift-conventions | 自动 | Swift/iOS 编码规范 |
| `/build` | 手动 | 构建 Xcode 项目 |
| `/swift-review` | 手动 | 代码审查 |
| `/xcode-fix` | 手动 | 修复编译错误 |
| `/deploy-backend` | 手动 | 部署后端到 Cloud Run |
