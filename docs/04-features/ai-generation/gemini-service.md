# AI 图像生成功能

## 概述

CN 版生成链路以 HivisionIDPhotos 和阿里云百炼为主。`GeminiService` 是 iOS 端历史命名，当前职责是把图片、规格和编辑选项发送到后端代理。

## 调用路径

```text
PhotoCreationView.generate()
  ├── SubscriptionManager.canGenerate()   # 成片制作包剩余次数
  ├── ReferralManager.bonusGenerations    # 无付费次数时可使用奖励次数
  ├── buildPrompt / buildCosmeticPrompt
  └── GeminiService.generateIDPhoto(...)
        └── POST /api/gemini/generate
              ├── HivisionIDPhotos        # 证件照裁切、抠图、换底
              └── Qwen/Wanx/Bailian       # 外观编辑或 fallback
```

## 接口规范

```http
POST /api/gemini/generate
Content-Type: application/json
X-App-Key: <app key>
```

```json
{
  "image": "<base64 JPEG>",
  "prompt": "生成指令",
  "cosmeticPrompt": "可选，外观编辑指令",
  "tier": "pro",
  "specWidth": 295,
  "specHeight": 413,
  "specBgColor": "ffffff"
}
```

成功：

```json
{ "image": "<base64 result>", "provider": "hivision | hivision+cosmetic | qwen-image-edit | bailian" }
```

失败：

```json
{ "error": "<message>" }
```

## 本地最新实现

本地 `backend/src/routes/gemini.ts` 已支持：

- Hivision 优先生成标准证件照底图。
- 当有 `cosmeticPrompt` 时，在 Hivision 结果上追加 Qwen/Bailian 外观编辑。
- 外观编辑失败时降级返回 Hivision 基础结果。
- 对 `specBgColor` 和 `specWidth/specHeight` 做格式与范围校验。
- 生成接口单 IP 3 req/min，且有每日预算熔断。

## 生产部署差异

2026-05-24 阿里云服务器 `/opt/aiidphoto-backend` 实测仍是较早版本：

- provider 链为 Hivision → Qwen Plus → Qwen → Bailian fallback。
- 尚未读取 `cosmeticPrompt` 字段。
- 尚未包含本地最新的规格颜色/尺寸校验。

如果要让服装/发型/表情/美颜在 Hivision 结果上稳定生效，需要把本地最新后端部署到阿里云，并做真实图片回归。

## 错误处理

| 错误类型 | 用户提示 |
|---------|---------|
| `invalidConfig` | 服务配置异常，请检查网络设置后重试 |
| `invalidImage` | 图片格式不支持，请换一张照片 |
| `networkError` 429 | 请求太频繁了，请稍后再试 |
| `networkError` 5xx | 服务暂时不可用，请稍后再试 |
| `decodeFailed` | 生成结果解析失败，请重试 |

## 图片规格

- iOS 上传：JPEG，压缩质量 0.92。
- Hivision 输入：规格生成时图片最长边上限 1500px。
- iOS 当前按成片制作包交付，生成请求使用高质量 `pro` tier。
- 成功生成后扣减 1 次本地制作包次数或奖励次数；失败不扣减。
- 请求超时：iOS 150s；provider 调用 90s；Nginx read timeout 180s。
