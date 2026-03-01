# AI 图像生成功能

## 概述

使用 Google Gemini `gemini-2.5-flash-image` 模型，将用户生活照转换为标准证件照。

## 调用路径

```
ContentView
  └── generateTapped()
        ├── UsageManager.canGenerate() → .allowed / .requireRewardedAd / .reachedLimit
        ├── .requireRewardedAd → AdManager.loadRewarded() + showRewarded()
        └── GeminiService.generateIDPhoto(from:prompt:)
              ├── Config.backendBaseURL != nil → requestViaBackend()  [生产]
              └── Config.geminiAPIKey != nil  → requestDirectGemini() [开发]
```

## 接口规范

### 后端代理（生产）

```
POST /api/gemini/generate
Content-Type: application/json

Body: { "image": "<base64 JPEG>", "prompt": "<生成指令>" }
Response: { "image": "<base64 结果>" }
Error:    { "error": "<错误信息>" }
```

### 直连 Gemini（开发 fallback）

遵循 Gemini Image Generation API 格式：
```json
{
  "contents": [{
    "parts": [
      { "text": "prompt" },
      { "inline_data": { "mime_type": "image/jpeg", "data": "base64" } }
    ]
  }]
}
```

## 默认提示词

```
生成证件照：浅色纯色背景，35x45mm，正脸居中，头肩框图，光照均匀，自然风格。
```

用户可在 UI 中修改提示词。

## 错误处理

| 错误类型 | 用户提示 |
|---------|---------|
| `invalidConfig` | API 配置无效，请检查网络设置 |
| `invalidImage` | 图片格式无效，请选择其他照片 |
| `networkError(code, msg)` | 服务器错误 (code)：msg |
| `decodeFailed` | 无法解析生成结果，请重试 |

## 图片规格

- 输入：JPEG，压缩质量 0.9，最大约 ~5MB
- 输出：后端返回 base64，解码为 `UIImage`
- 超时：60 秒

## 待实现（Phase 2）

- [ ] 证件照尺寸选择（1寸/2寸/护照/签证）
- [ ] 背景色选择（白/蓝/红/自定义）
- [ ] 图片裁剪（上传前裁剪人脸区域）
- [ ] 生成历史记录
