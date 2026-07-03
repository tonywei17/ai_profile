<script setup>
import { onLaunch, onShow, onHide } from '@dcloudio/uni-app'
import wechatAuthService from './services/wechatAuthService.js'

onLaunch(async () => {
  console.log('App Launch')
  // #ifdef MP-WEIXIN
  try {
    await wechatAuthService.ensureLogin()
  } catch (error) {
    console.error('微信登录初始化失败:', error)
  }
  // #endif
})

onShow(() => {
  console.log('App Show')
})

onHide(() => {
  console.log('App Hide')
})
</script>

<style lang="scss">
/* 全局样式变量(微信小程序 WXSS 不保证支持 :root,统一挂在 page 上) */
page {
  /* 主题色 */
  --color-sky-blue: #2464C8;
  --color-sky-blue-mid: #4189E6;
  --color-sky-blue-soft: #5BA4F0;
  --color-promo-orange: #FF7C21;
  --color-promo-red: #EA3737;

  /* 会员/付费色(裁决:废弃模板紫 #667eea→#764ba2,统一到品牌蓝体系) */
  --color-premium-start: #2464C8;
  --color-premium-end: #4A90E2;
  --gradient-premium: linear-gradient(135deg, var(--color-premium-start), var(--color-premium-end));
  --color-premium-gold: #F5A623; /* 会员徽章点缀可选 */

  /* 编辑设计色 - 亮色模式 */
  --color-paper-tan: #D6C9B5;
  --color-ink-black: #1A1A1A;
  --color-ink-border: #1A1A1A;
  --color-branch-gray: #8C8C8C;
  --color-tree-green: #5A7D3C;
  --color-ink-fill: #1A1A1A;
  --color-ink-fill-foreground: #FFFFFF;
  
  /* 背景色 */
  --color-bg-primary: #FFFFFF;
  --color-bg-secondary: #F5F5F5;
  --color-bg-tertiary: #EFF3F9;
  
  /* 间距 */
  --spacing-xs: 4px;
  --spacing-sm: 8px;
  --spacing-md: 12px;
  --spacing-lg: 16px;
  --spacing-xl: 24px;
  --spacing-2xl: 32px;
  
  /* 圆角 */
  --radius-sm: 4px;
  --radius-md: 6px;
  --radius-lg: 10px;
  --radius-xl: 14px;
  --radius-full: 9999px;
  
  /* 字体大小 */
  --font-size-xs: 9px;
  --font-size-sm: 10px;
  --font-size-base: 11px;
  --font-size-md: 12px;
  --font-size-lg: 13px;
  --font-size-xl: 15px;
  --font-size-2xl: 18px;
  --font-size-3xl: 26px;
  --font-size-4xl: 28px;
  --font-size-5xl: 38px;
  
  /* 字重 */
  --font-weight-regular: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;
  
  /* 动画时长 */
  --duration-fast: 150ms;
  --duration-normal: 200ms;
  --duration-slow: 250ms;
}

/* 全局重置 */
page {
  background-color: var(--color-bg-primary);
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif;
  font-size: var(--font-size-lg);
  line-height: 1.5;
  color: var(--color-ink-black);
}

/* 通用样式 */
.text-ink-black {
  color: var(--color-ink-black);
}

.text-branch-gray {
  color: var(--color-branch-gray);
}

.text-sky-blue {
  color: var(--color-sky-blue);
}

.text-promo-orange {
  color: var(--color-promo-orange);
}

.bg-paper-tan {
  background-color: var(--color-paper-tan);
}

.bg-sky-blue {
  background-color: var(--color-sky-blue);
}

/* 玻璃效果 */
.glass-background {
  background: linear-gradient(135deg, rgba(36, 100, 200, 0.1), rgba(65, 137, 230, 0.05));
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
}

/* 标题渐变 */
.title-gradient {
  background: linear-gradient(135deg, #4275DC, #7085E6);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

@media (prefers-color-scheme: dark) {
  .title-gradient {
    background: linear-gradient(135deg, #8CB3FF, #B3C7FF);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }
}
</style>
