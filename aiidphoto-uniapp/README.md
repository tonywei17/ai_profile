# 光影形象馆 - uni-app跨端版本

## 项目简介

AI证件照生成应用，基于uni-app框架开发，支持微信小程序、iOS App、Android App、H5多端运行。

## 技术栈

- **框架**：uni-app (Vue 3)
- **状态管理**：Pinia
- **国际化**：vue-i18n
- **构建工具**：Vite

## 开发环境要求

- Node.js >= 16
- npm >= 8
- 微信开发者工具（小程序开发）

## 安装依赖

```bash
cd aiidphoto-uniapp
npm install
```

## 运行项目

### 微信小程序

1. 编译小程序代码：
```bash
npm run dev:mp-weixin
```

2. 编译完成后，使用微信开发者工具打开 `dist/dev/mp-weixin` 目录

### H5

```bash
npm run dev:h5
```

### App

```bash
npm run dev:app
```

## 构建生产版本

### 微信小程序

```bash
npm run build:mp-weixin
```

### H5

```bash
npm run build:h5
```

### App

```bash
npm run build:app
```

## 项目结构

```
aiidphoto-uniapp/
├── pages/              # 页面
├── components/         # 组件
├── store/             # Pinia状态管理
├── api/               # API接口
├── utils/             # 工具函数
├── models/            # 数据模型
├── locales/           # 国际化文件
├── static/            # 静态资源
├── package.json
├── manifest.json      # 应用配置
├── pages.json         # 页面配置
├── App.vue            # 应用入口
├── main.js            # 主入口
└── vite.config.js     # Vite配置
```

## 配置说明

### manifest.json

需要修改以下配置：

1. **小程序AppID**：
```json
"mp-weixin": {
  "appid": "YOUR_MINIAPP_APPID"
}
```

2. **后端URL**（如果需要修改）：
在 `api/config.js` 中修改 `baseURL`

## 注意事项

1. 首次运行需要安装依赖
2. 小程序开发需要配置合法域名
3. 支付功能需要配置微信支付商户号
4. 图片资源需要放在 `static/images/` 目录下
