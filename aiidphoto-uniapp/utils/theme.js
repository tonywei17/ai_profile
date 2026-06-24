/**
 * 主题管理器
 * 负责管理应用的主题切换
 */

// 主题类名
const DARK_THEME_CLASS = 'dark-theme'

/**
 * 初始化主题
 * 在应用启动时调用
 */
const initTheme = () => {
  console.log('主题管理器初始化')
  
  // 监听主题变化事件
  uni.$on('themeChanged', (theme) => {
    console.log('收到主题变化事件:', theme)
    // 通知所有页面更新主题
    uni.$emit('updateTheme', theme)
  })
}

/**
 * 获取当前主题类
 * @returns {string} 当前主题类名
 */
const getCurrentThemeClass = () => {
  const theme = getCurrentActualTheme()
  return theme === 'dark' ? DARK_THEME_CLASS : ''
}

/**
 * 获取当前主题
 * @returns {string} 当前主题 ('light' | 'dark' | 'system')
 */
const getCurrentTheme = () => {
  return uni.getStorageSync('appearance') || 'system'
}

/**
 * 获取当前实际主题（考虑系统设置）
 * @returns {string} 实际主题 ('light' | 'dark')
 */
const getCurrentActualTheme = () => {
  const appearance = getCurrentTheme()
  
  if (appearance === 'dark') {
    return 'dark'
  } else if (appearance === 'light') {
    return 'light'
  } else {
    // 跟随系统
    const systemInfo = uni.getSystemInfoSync()
    return systemInfo.theme || 'light'
  }
}

/**
 * 切换到指定主题
 * @param {string} mode - 主题模式 ('light' | 'dark' | 'system')
 */
const switchTheme = (mode) => {
  const theme = mode === 'dark' ? 'dark' : 'light'
  const themeClass = theme === 'dark' ? DARK_THEME_CLASS : ''
  
  // 保存设置
  uni.setStorageSync('appearance', mode)
  uni.setStorageSync('theme_class', themeClass)
  
  // 应用主题
  applyThemeClass(themeClass)
  
  // 设置导航栏和背景色
  if (theme === 'dark') {
    uni.setNavigationBarColor({
      frontColor: '#ffffff',
      backgroundColor: '#1a1a1a'
    })
    uni.setBackgroundColor({
      backgroundColor: '#1a1a1a',
      backgroundColorTop: '#1a1a1a',
      backgroundColorBottom: '#1a1a1a'
    })
  } else {
    uni.setNavigationBarColor({
      frontColor: '#000000',
      backgroundColor: '#ffffff'
    })
    uni.setBackgroundColor({
      backgroundColor: '#ffffff',
      backgroundColorTop: '#ffffff',
      backgroundColorBottom: '#ffffff'
    })
  }
  
  // 触发全局事件
  uni.$emit('themeChanged', theme)
  
  console.log('主题已切换为:', theme)
}

export default {
  initTheme,
  getCurrentThemeClass,
  getCurrentTheme,
  getCurrentActualTheme,
  switchTheme,
  DARK_THEME_CLASS
}
