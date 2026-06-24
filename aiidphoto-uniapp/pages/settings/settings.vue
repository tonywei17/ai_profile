<template>
  <view class="settings-page">
    <!-- 状态栏占位 -->
    <view class="status-bar-placeholder" :style="{ height: statusBarHeight + 'px' }"></view>
    
    <!-- 设置页面头部 -->
    <view class="settings-header" :style="{ height: navigationBarHeight + 'px' }">
      <view class="header-left">
        <view class="back-btn" @click="goBack">
          <text>←</text>
        </view>
        <text class="header-title">{{ t('settings.title') }}</text>
      </view>
      <view class="header-right" :style="{ paddingRight: headerRightPadding + 'px' }">
        <view class="close-btn" @click="goBack">
          <text>✕</text>
        </view>
      </view>
    </view>

    <!-- 滚动内容 -->
    <scroll-view scroll-y class="scroll-content">
      <!-- Hero区域 -->
      <view class="settings-hero">
        <view class="hero-gradient"></view>
        <view class="hero-content">
          <view class="hero-left">
            <view class="app-info">
              <view class="app-logo">
                <text class="logo-text">AI</text>
              </view>
              <text class="app-name">{{ t('settings.app.name') }}</text>
            </view>
            <text class="subscription-status" :class="{ 'premium': isPremium }">
              {{ isPremium ? t('home.premiumUser') : t('home.basicUser') }}
            </text>
            <text class="subscription-desc">{{ t('settings.subscription.freeDesc') }}</text>
            <view class="attempts-info">
              <text class="attempts-number">{{ remainingAttempts }}</text>
              <text class="attempts-label">{{ t('home.remainingAttempts') }}</text>
            </view>
            <view class="feature-badge">
              <text class="badge-text">{{ t('settings.subscription.features') }}</text>
            </view>
          </view>
          <view class="hero-right">
            <view class="gear-icon-bg">
              <text class="gear-icon">⚙️</text>
            </view>
          </view>
        </view>
      </view>

      <!-- 语言设置 -->
      <view class="settings-section">
        <view class="section-header">
          <text class="section-icon">🌍</text>
          <text class="section-title">{{ t('settings.language') }}</text>
        </view>
        <view class="section-content">
          <view 
            class="language-row"
            :class="{ active: currentLocale === 'zh-Hans' }"
            @tap="setLanguage('zh-Hans')"
          >
            <text class="language-flag">🇨🇳</text>
            <text class="language-name">简体中文</text>
            <view v-if="currentLocale === 'zh-Hans'" class="check-icon">✓</view>
          </view>
          <view 
            class="language-row"
            :class="{ active: currentLocale === 'en' }"
            @tap="setLanguage('en')"
          >
            <text class="language-flag">🇺🇸</text>
            <text class="language-name">English</text>
            <view v-if="currentLocale === 'en'" class="check-icon">✓</view>
          </view>
        </view>
      </view>

      <!-- 生成次数管理 -->
      <view class="settings-section">
        <view class="section-header">
          <text class="section-icon">💎</text>
          <text class="section-title">{{ t('settings.subscription.title') }}</text>
        </view>
        <view class="section-content">
          <view class="subscription-info">
            <text class="subscription-status">
              {{ t('settings.subscription.currentStatus') }}:
              {{ isPremium ? t('home.premiumUser') : t('settings.subscription.freeUser') }}
            </text>
          </view>
          <view v-if="paymentEnabled" class="action-row" @tap="openSubscription">
            <view class="action-icon">🚀</view>
            <text class="action-label">{{ t('settings.subscription.upgrade') }}</text>
            <text class="action-arrow">→</text>
          </view>
          <view v-if="paymentEnabled" class="action-row" @tap="restorePurchase">
            <view class="action-icon">🔄</view>
            <text class="action-label">{{ t('settings.subscription.restore') }}</text>
            <text class="action-arrow">→</text>
          </view>
        </view>
      </view>

      <!-- 服务信息 -->
      <view class="service-section">
        <view class="service-header">
          <text class="service-icon">⚖️</text>
          <text class="service-title">{{ t('settings.legal') }}</text>
        </view>
        <view class="service-content">
          <view class="action-row" @tap="openPrivacyPolicy">
            <view class="action-icon">🔒</view>
            <text class="action-label">{{ t('settings.privacy') }}</text>
            <text class="action-arrow">→</text>
          </view>
          <view class="action-row" @tap="openTerms">
            <view class="action-icon">📄</view>
            <text class="action-label">{{ t('settings.terms') }}</text>
            <text class="action-arrow">→</text>
          </view>
          <view class="action-row" @tap="contactSupport">
            <view class="action-icon">💬</view>
            <view class="support-label">
              <text class="action-label">{{ t('settings.support.title') }}</text>
              <text class="action-hint">{{ t('settings.support.email') }}</text>
            </view>
            <text class="action-arrow">→</text>
          </view>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import { useI18n } from '@/utils/i18n.js'
import paymentAPI from '@/api/payment.js'

// 获取i18n实例
const { t, setLocale, locale: currentLocale } = useI18n()

// 系统信息
const statusBarHeight = ref(0)
const screenWidth = ref(375)
const menuButtonRect = ref({ width: 0, height: 0, top: 0, right: 0, bottom: 0, left: 0 })
const headerRightPadding = computed(() => {
  if (menuButtonRect.value.left > 0) {
    return Math.max(12, screenWidth.value - menuButtonRect.value.left + 8)
  }
  return 16
})
const navigationBarHeight = computed(() => {
  if (menuButtonRect.value.height > 0) {
    const verticalGap = Math.max(4, menuButtonRect.value.top - statusBarHeight.value)
    return menuButtonRect.value.height + verticalGap * 2
  }
  return 48
})

// 状态
const remainingAttempts = ref(0)
const isPremium = ref(false)
const paymentEnabled = paymentAPI.isPaymentEnabled()

// 获取系统信息
onMounted(async () => {
  const systemInfo = uni.getSystemInfoSync()
  statusBarHeight.value = systemInfo.statusBarHeight || 0
  screenWidth.value = systemInfo.screenWidth || systemInfo.windowWidth || 375
  // #ifdef MP-WEIXIN
  try {
    menuButtonRect.value = uni.getMenuButtonBoundingClientRect()
  } catch (error) {
    console.error('获取胶囊按钮位置失败:', error)
  }
  // #endif
  
  console.log('设置页面onMounted: 当前语言为', currentLocale.value)
  
  uni.$on('paymentStatusChanged', handlePaymentStatusChanged)
})

onUnmounted(() => {
  uni.$off('paymentStatusChanged', handlePaymentStatusChanged)
})

onShow(() => {
  loadUserStatus()
})

// 加载用户状态
const loadUserStatus = async () => {
  try {
    const result = await paymentAPI.getRemainingAttempts()
    console.log('设置页面用户状态加载:', result)
    remainingAttempts.value = result.totalAttempts
    isPremium.value = result.proAttempts > 0
  } catch (error) {
    console.error('加载用户状态失败:', error)
    remainingAttempts.value = 0
    isPremium.value = false
  }
}

const handlePaymentStatusChanged = () => {
  loadUserStatus()
}

// 设置语言
const setLanguage = (locale) => {
  setLocale(locale)
  currentLocale.value = locale
  uni.showToast({
    title: '语言已切换',
    icon: 'success'
  })
}

// 打开隐私政策
const openPrivacyPolicy = () => {
  uni.navigateTo({
    url: '/pages/privacy/privacy'
  })
}

// 打开用户协议
const openTerms = () => {
  uni.navigateTo({
    url: '/pages/terms/terms'
  })
}

// 获取法律文档语言代码
const getLegalLang = (code) => {
  if (code.startsWith('zh')) return 'zh'
  if (code.startsWith('ja')) return 'ja'
  if (code.startsWith('ko')) return 'ko'
  if (code.startsWith('vi')) return 'vi'
  if (code.startsWith('id')) return 'id'
  if (code.startsWith('pt')) return 'pt'
  return 'en'
}

// 打开购买页面
const openSubscription = () => {
  uni.navigateTo({
    url: '/pages/subscription/subscription'
  })
}

// 刷新购买状态
const restorePurchase = async () => {
  uni.showLoading({
    title: '刷新中...'
  })
  
  try {
    await paymentAPI.restorePurchases()
    await loadUserStatus()
    uni.hideLoading()
    uni.showToast({
      title: '购买状态已刷新',
      icon: 'success'
    })
  } catch (error) {
    uni.hideLoading()
    console.error('刷新购买状态失败:', error)
    uni.showToast({
      title: '刷新失败，请重试',
      icon: 'none'
    })
  }
}

const contactSupport = () => {
  const email = 'liuchengcheng@foyli-ai.com'
  uni.setClipboardData({
    data: email,
    success: () => {
      uni.showToast({
        title: t('settings.support.copied'),
        icon: 'none'
      })
    }
  })
}

// 返回
const goBack = () => {
  uni.navigateBack()
}
</script>

<style lang="scss" scoped>
.settings-page {
  min-height: 100vh;
  background-color: #f8f9fa;
  display: flex;
  flex-direction: column;
}

/* 状态栏占位 */
.status-bar-placeholder {
  width: 100%;
  background-color: #f8f9fa;
}

/* 设置页面头部 */
.settings-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  min-height: 48px;
  padding: 0 16px;
  box-sizing: border-box;
  background-color: #ffffff;
  border-bottom: 1px solid #e5e5e5;
  flex-shrink: 0;
}

.header-right {
  display: flex;
  align-items: center;
  flex-shrink: 0;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
  flex: 1;
}

.back-btn {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 22px;
  color: #666666;
  background-color: transparent;
  border: none;
  border-radius: 10px;
  background: #f0f2f5;
}

.header-title {
  font-size: 18px;
  font-weight: 600;
  color: #333333;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.close-btn {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 17px;
  color: #666666;
  background-color: transparent;
  border: none;
  border-radius: 10px;
  background: #f0f2f5;
}

/* 滚动内容 */
.scroll-content {
  flex: 1 !important;
  padding: 16px !important;
  padding-left: 16px !important;
  padding-right: 16px !important;
  margin: 0 auto !important;
  margin-top: 0 !important;
  overflow-y: auto !important;
  max-width: 100% !important;
  box-sizing: border-box !important;
}

/* Hero区域 */
.settings-hero {
  height: 176px !important;
  border-radius: 16px !important;
  overflow: visible !important;
  margin-bottom: 18px !important;
  margin-top: 0px !important;
  position: relative !important;
  background: transparent !important;
}

.hero-gradient {
  position: absolute !important;
  top: 0 !important;
  left: 0 !important;
  right: 0 !important;
  bottom: 0 !important;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
  opacity: 0.85 !important;
  border-radius: 16px !important;
  z-index: 0 !important;
}

.hero-content {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 100%;
  padding: 18px 20px;
}

.hero-left {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 7px;
  max-width: calc(100% - 116px);
}

.app-info {
  display: flex;
  align-items: center;
  gap: 8px;
}

.app-logo {
  width: 32px;
  height: 32px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.logo-text {
  font-size: 16px;
  font-weight: 700;
  color: #FFFFFF;
}

.app-name {
  font-size: 18px;
  font-weight: 700;
  color: #FFFFFF;
}

.subscription-status {
  font-size: 22px;
  font-weight: 700;
  color: #FFFFFF;
  line-height: 1.2;
}

.subscription-desc {
  font-size: 16px;
  color: #FFFFFF;
  line-height: 1.5;
  font-weight: 700;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.5), 0 1px 2px rgba(0, 0, 0, 0.3);
  letter-spacing: 0.5px;
}

.feature-badge {
  display: inline-block;
  padding: 6px 10px;
  background-color: rgba(255, 255, 255, 0.18);
  border-radius: 20px;
  align-self: flex-start;
  margin-top: auto;
}

.badge-text {
  font-size: 11px;
  font-weight: 500;
  color: #FFFFFF;
}

.hero-right {
  width: 116px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.gear-icon-bg {
  width: 80px;
  height: 80px;
  background: rgba(255, 255, 255, 0.10);
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.gear-icon {
  font-size: 56px;
  color: rgba(255, 255, 255, 0.36);
}

/* 设置区域 */
.settings-section {
  margin-bottom: 24px;
  background-color: #ffffff;
  border-radius: 16px;
  overflow: hidden;
  border: 1.5px solid #e5e5e5;
}

.section-header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 16px;
  background-color: #ffffff;
  border-bottom: 1px solid #f0f0f0;
}

.section-icon {
  font-size: 20px;
}

.section-title {
  font-size: 15px;
  font-weight: 600;
  color: #333333;
}

.section-content {
  padding: 0;
}

.option-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  transition: background-color 0.15s ease;
}

.option-row:active {
  background-color: #f8f9fa;
}

.option-row.active {
  background-color: #e8f4fd;
}

.option-icon {
  font-size: 18px;
  width: 24px;
  text-align: center;
}

.option-label {
  flex: 1;
  font-size: 15px;
  font-weight: 500;
  color: #333333;
}

.check-icon {
  font-size: 16px;
  color: #2464c8;
  font-weight: 600;
}

/* 语言选择 */
.language-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  transition: background-color 0.15s ease;
}

.language-row:active {
  background-color: #f8f9fa;
}

.language-row.active {
  background-color: #e8f4fd;
}

.language-flag {
  font-size: 18px;
  width: 24px;
  text-align: center;
}

.language-name {
  flex: 1;
  font-size: 15px;
  font-weight: 500;
  color: #333333;
}

/* 服务区域 */
.service-section {
  margin-bottom: 24px;
}

.service-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 12px;
}

.service-icon {
  font-size: 20px;
}

.service-title {
  font-size: 15px;
  font-weight: 600;
  color: #333333;
}

.service-content {
  background-color: #ffffff;
  border-radius: 16px;
  overflow: hidden;
  border: 1.5px solid #e5e5e5;
}

.action-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  transition: background-color 0.15s ease;
}

.action-row:active {
  background-color: #f8f9fa;
}

.action-row:not(:last-child) {
  border-bottom: 1px solid #f0f0f0;
}

.action-icon {
  font-size: 18px;
  width: 24px;
  text-align: center;
}

.action-label {
  flex: 1;
  font-size: 15px;
  font-weight: 500;
  color: #333333;
}

.support-label {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.support-label .action-label {
  flex: none;
}

.action-hint {
  font-size: 12px;
  color: #888888;
}

.action-arrow {
  font-size: 14px;
  color: #999999;
}

.logo-text {
  font-size: 18px;
  font-weight: 700;
  color: #FFFFFF;
}

.app-name {
  font-size: 20px;
  font-weight: 700;
  color: #FFFFFF;
}

.subscription-status {
  font-size: 16px;
  font-weight: 600;
  color: #FFFFFF;
  opacity: 0.9;
}

.subscription-desc {
  font-size: 13px;
  color: #FFFFFF;
  opacity: 0.7;
  line-height: 1.4;
}

.feature-badge {
  display: inline-block;
  padding: 6px 12px;
  background-color: rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  align-self: flex-start;
}

.badge-text {
  font-size: 11px;
  font-weight: 600;
  color: #FFFFFF;
}

.hero-right {
  display: flex;
  align-items: center;
  justify-content: center;
}

.gear-icon {
  width: 60px;
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32px;
  opacity: 0.6;
}

/* 设置区域 */
.settings-section {
  margin-bottom: 24px;
  background-color: #ffffff;
  border-radius: 16px;
  overflow: hidden;
  border: 1px solid #e5e5e5;
}

.section-header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 16px;
  background-color: #ffffff;
  border-bottom: 1px solid #f0f0f0;
}

.section-icon {
  font-size: 20px;
}

.section-title {
  font-size: 15px;
  font-weight: 600;
  color: #333333;
}

.section-content {
  padding: 0;
}

.option-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  transition: background-color 0.15s ease;
}

.option-row:active {
  background-color: #f8f9fa;
}

.option-row.active {
  background-color: #e8f4fd;
}

.option-icon {
  font-size: 18px;
  width: 24px;
  text-align: center;
}

.option-label {
  flex: 1;
  font-size: 15px;
  font-weight: 500;
  color: #333333;
}

.check-icon {
  font-size: 16px;
  color: #4a90e2;
  font-weight: 600;
}

/* 语言选择 */
.language-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  transition: background-color 0.15s ease;
}

.language-row:active {
  background-color: #f8f9fa;
}

.language-row.active {
  background-color: #e8f4fd;
}

.language-flag {
  font-size: 18px;
  width: 24px;
  text-align: center;
}

.language-name {
  flex: 1;
  font-size: 15px;
  font-weight: 500;
  color: #333333;
}

/* 服务区域 */
.service-section {
  margin-bottom: 24px;
}

.service-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 12px;
}

.service-icon {
  font-size: 20px;
}

.service-title {
  font-size: 15px;
  font-weight: 600;
  color: #333333;
}

.service-content {
  background-color: #ffffff;
  border-radius: 16px;
  overflow: hidden;
  border: 1px solid #e5e5e5;
}

.action-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  transition: background-color 0.15s ease;
}

.action-row:active {
  background-color: #f8f9fa;
}

.action-row:not(:last-child) {
  border-bottom: 1px solid #f0f0f0;
}

.action-icon {
  font-size: 18px;
  width: 24px;
  text-align: center;
}

.action-label {
  flex: 1;
  font-size: 15px;
  font-weight: 500;
  color: #333333;
}

.action-arrow {
  font-size: 14px;
  color: #999999;
}

/* 用户状态样式 */
.attempts-info {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 12px 0;
}

.attempts-number {
  font-size: 24px;
  font-weight: 700;
  color: #FFFFFF;
}

.attempts-label {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.82);
}

.subscription-status.premium {
  color: #FFFFFF;
  font-weight: 600;
}

/* 推荐系统样式 */
.referral-info {
  padding: 16px;
  background-color: #f8f9fa;
  border-radius: 12px;
  margin-bottom: 12px;
}

.referral-code {
  font-size: 16px;
  font-weight: 600;
  color: #2464c8;
  margin-bottom: 8px;
}

.referral-bonus {
  display: inline-block;
  padding: 4px 8px;
  background-color: #e8f4ff;
  border-radius: 6px;
}

.bonus-text {
  font-size: 12px;
  color: #2464c8;
  font-weight: 500;
}

.redeem-section {
  display: flex;
  gap: 12px;
  align-items: center;
  margin-top: 12px;
}

.redeem-input {
  flex: 1;
}

.redeem-field {
  width: 100%;
  padding: 12px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  font-size: 14px;
  background-color: #ffffff;
}

.redeem-btn {
  padding: 12px 20px;
  background-color: #2464c8;
  border-radius: 8px;
  min-width: 60px;
  text-align: center;
}

.redeem-text {
  font-size: 14px;
  font-weight: 500;
  color: #ffffff;
}

/* 订阅管理样式 */
.subscription-info {
  padding: 16px;
  background-color: #f8f9fa;
  border-radius: 12px;
  margin-bottom: 12px;
}

.subscription-status {
  font-size: 16px;
  font-weight: 600;
  color: #333333;
  margin-bottom: 4px;
}

.subscription-desc {
  font-size: 13px;
  color: #666666;
  line-height: 1.4;
}
</style>
