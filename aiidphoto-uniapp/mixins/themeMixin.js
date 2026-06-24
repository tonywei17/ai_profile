/**
 * 主题混入
 * 为页面提供主题切换功能
 */
import { ref, onMounted, onUnmounted } from 'vue'
import themeManager from '@/utils/theme.js'

export function useTheme() {
  // 主题类名
  const themeClass = ref('')
  
  // 更新主题类
  const updateThemeClass = () => {
    themeClass.value = themeManager.getCurrentThemeClass()
  }
  
  onMounted(() => {
    // 初始化主题类
    updateThemeClass()
    
    // 监听主题变化
    uni.$on('updateTheme', updateThemeClass)
  })
  
  onUnmounted(() => {
    // 移除监听
    uni.$off('updateTheme', updateThemeClass)
  })
  
  return {
    themeClass,
    updateThemeClass
  }
}
