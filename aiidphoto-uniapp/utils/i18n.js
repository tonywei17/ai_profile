/**
 * 轻量级国际化管理器
 */

import { ref } from 'vue'

// 导入语言包
import zhHans from '@/locales/zh-Hans.json'
import en from '@/locales/en.json'

const messages = {
  'zh-Hans': zhHans,
  'en': en
}

// 当前语言（响应式）
const currentLocale = ref('zh-Hans')

/**
 * 设置语言
 * @param {string} locale - 语言代码
 */
const setLocale = (locale) => {
  if (messages[locale]) {
    currentLocale.value = locale
    uni.setStorageSync('locale', locale)
  }
}

/**
 * 获取当前语言
 * @returns {string} 当前语言代码
 */
const getLocale = () => {
  return currentLocale.value
}

/**
 * 初始化语言（从存储中读取）
 */
const initLocale = () => {
  try {
    const savedLocale = uni.getStorageSync('locale')
    console.log('保存的语言设置:', savedLocale)
    
    if (savedLocale && messages[savedLocale]) {
      currentLocale.value = savedLocale
      console.log('使用保存的语言:', savedLocale)
    } else {
      // 如果没有保存的语言设置，强制使用中文
      currentLocale.value = 'zh-Hans'
      uni.setStorageSync('locale', 'zh-Hans')
      console.log('使用默认语言: zh-Hans')
    }
  } catch (e) {
    console.error('读取语言设置失败:', e)
    // 出错时强制使用中文
    currentLocale.value = 'zh-Hans'
    uni.setStorageSync('locale', 'zh-Hans')
  }
}

/**
 * 翻译函数
 * @param {string} key - 翻译键，支持点号分隔的路径
 * @param {Object} params - 参数对象
 * @returns {string} 翻译后的文本
 */
const t = (key, params = {}) => {
  const keys = key.split('.')
  let value = messages[currentLocale.value]
  
  for (const k of keys) {
    if (value && typeof value === 'object' && k in value) {
      value = value[k]
    } else {
      return key // 找不到翻译时返回原键
    }
  }
  
  if (typeof value !== 'string') {
    return key
  }
  
  // 替换参数
  let result = value
  for (const [paramKey, paramValue] of Object.entries(params)) {
    result = result.replace(new RegExp(`{${paramKey}}`, 'g'), paramValue)
  }
  
  return result
}

// 初始化
initLocale()

export default {
  setLocale,
  getLocale,
  t
}

// 导出响应式实例
export const useI18n = () => {
  return {
    locale: currentLocale,
    t,
    setLocale,
    getLocale
  }
}
