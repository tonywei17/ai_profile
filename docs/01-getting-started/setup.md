# 环境配置 & 快速上手

## 前置要求

| 工具 | 版本 | 用途 |
|------|------|------|
| Xcode | 15+ | iOS 开发 |
| Swift | 5.9+ | 编程语言 |
| Node.js | 20+ | 后端开发 |
| npm | 随 Node 安装 | 后端依赖与构建 |
| 阿里云 ECS 访问权限 | 生产部署时需要 | 查看/部署 CN 后端 |
| XcodeBuildMCP | 可选 | 本地构建、运行、截图和发布 QA |

## iOS 项目启动

```bash
# 克隆仓库
git clone https://github.com/tonywei17/ai_profile.git
cd ai_profile_cn

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
# 编辑 .env，填入 HIVISION_URL / BAILIAN_API_KEY / APP_API_KEY
npm install
npm run dev
```

本地服务运行在 `http://localhost:8080`。

## 配置说明（Info.plist）

| 键 | 值 | 说明 |
|----|-----|------|
| `BACKEND_BASE_URL` | `https://aiphoto-cn.foyli.cloud` | CN 生产环境阿里云后端地址 |
| `APP_API_KEY` | App 侧调用密钥 | 由 iOS 通过 `X-App-Key` 发送给后端 |

CN 线上后端当前运行在阿里云 ECS，通过 Nginx 反向代理到本机 PM2 进程。`aiphoto-cn.foyli.cloud` 已完成 DNS 和 HTTPS；上线前仍需真机端到端生成和 ATS 回归。

## 模拟器运行

```bash
# 构建 + 安装 + 启动
SIMULATOR_ID="36A7B000-9CB2-406E-AA3A-F75B34651856"  # iPhone 17 Pro
xcodebuild -project AIIDPhoto.xcodeproj -scheme AIIDPhoto \
  -sdk iphonesimulator -destination "id=$SIMULATOR_ID" build
xcrun simctl install $SIMULATOR_ID \
  build/DerivedData/Build/Products/Debug-iphonesimulator/AIIDPhoto.app
xcrun simctl launch $SIMULATOR_ID com.yufeicn.aiidphoto
```

## 常用验证

```bash
# iOS 构建
xcodebuild -project AIIDPhoto.xcodeproj -scheme AIIDPhoto -configuration Release build

# 后端类型检查/构建
cd backend && npm run build
```

更多发布前检查见 `docs/07-deployment/cloud-run-deploy.md` 和 `docs/dev-logs/2026-05-24.md`。
