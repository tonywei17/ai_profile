import App from './App'
import { createSSRApp } from 'vue'
import i18n from './utils/i18n.js'

export function createApp() {
  const app = createSSRApp(App)
  
  // 全局注册i18n
  app.config.globalProperties.$t = i18n.t
  app.config.globalProperties.$i18n = i18n
  
  return {
    app
  }
}
