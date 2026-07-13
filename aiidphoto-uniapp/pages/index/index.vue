<template>
  <view class="page">
    <!-- 状态栏占位 -->
    <view class="status-bar-placeholder" :style="{ height: statusBarHeight + 'px' }"></view>
    
    <!-- 首页头部 -->
    <view class="home-header" :style="{ height: navigationBarHeight + 'px' }">
      <view class="header-left">
        <view class="app-logo">
          <image :src="appIconSrc" class="logo-image" mode="aspectFill"></image>
        </view>
        <view class="header-title">
          <text class="title">{{ t('home.title') }}</text>
          <text class="subtitle">{{ t('home.subtitle') }}</text>
        </view>
      </view>
      <view class="header-right" :style="{ paddingRight: headerRightPadding + 'px' }">
        <view class="icon-btn" @tap="navigateToHistory">
          <AppIcon name="history" :size="20" color="var(--color-ink-black)" />
        </view>
        <view class="icon-btn" @tap="navigateToSettings">
          <AppIcon name="settings" :size="20" color="var(--color-ink-black)" />
        </view>
      </view>
    </view>

    <!-- 滚动内容 -->
    <scroll-view scroll-y class="scroll-content">
      <!-- Hero Banner -->
      <view class="hero-banner">
        <image
          :src="heroPortraitSrc"
          class="hero-image"
          mode="aspectFill"
        />
        <view class="hero-gradient"></view>
        <view class="hero-content">
          <view class="hero-left">
            <text class="hero-title">{{ t('home.title') }}</text>
            <text class="hero-subtitle">{{ t('home.subtitle') }}</text>
            <text class="hero-tagline">{{ t('home.tagline') }}</text>
            <view v-if="paymentEnabled" class="price-tag">
              <text class="price-label">{{ t('home.limitedOffer') }}</text>
              <text class="price-value">{{ t('home.price') }}</text>
            </view>
          </view>
          <view class="hero-right">
          </view>
        </view>
      </view>

      <!-- 服务分类 -->
      <view class="service-categories">
        <view class="category-grid">
          <view class="category-item" v-for="(item, index) in categories" :key="index" @tap="navigateToCreation(item.specId)">
            <view class="category-icon">
              <AppIcon :name="item.icon" :size="26" color="var(--color-sky-blue)" />
            </view>
            <text class="category-title">{{ item.title }}</text>
            <text class="category-subtitle">{{ item.subtitle }}</text>
          </view>
        </view>
      </view>

      <!-- 信任统计 -->
      <view class="trust-stats">
        <view class="stat-item">
          <view class="stat-highlight">
            <text class="stat-number">3次</text>
            <text class="stat-label">免费体验</text>
          </view>
          <text class="stat-desc">{{ t('home.trust.usersDesc') }}</text>
        </view>
        <view class="stat-divider"></view>
        <view class="stat-item">
          <view class="stat-highlight">
            <text class="stat-number">{{ t('home.trust.retry') }}</text>
            <text class="stat-label">{{ t('home.trust.retryLabel') }}</text>
          </view>
          <text class="stat-desc">{{ t('home.trust.retryDesc') }}</text>
        </view>
        <view class="stat-divider"></view>
        <view class="stat-item">
          <view class="stat-highlight">
            <text class="stat-number">{{ t('home.trust.privacy') }}</text>
            <text class="stat-label">{{ t('home.trust.privacyLabel') }}</text>
          </view>
          <text class="stat-desc">{{ t('home.trust.privacyDesc') }}</text>
        </view>
      </view>

      <!-- 效果展示 -->
      <view class="showcase">
        <view class="showcase-header">
          <text class="showcase-title">{{ t('home.showcase.title') }}</text>
        </view>
        <view class="showcase-cards">
          <view class="showcase-card">
            <view class="showcase-image-wrap">
              <image
                class="showcase-image"
                :src="showcaseMaleSrc"
                mode="aspectFit"
              />
              <text class="showcase-badge">{{ t('home.showcase.badge') }}</text>
            </view>
            <text class="showcase-label">{{ t('home.showcase.idCard') }}</text>
          </view>
          <view class="showcase-card">
            <view class="showcase-image-wrap">
              <image
                class="showcase-image"
                :src="showcaseFemaleSrc"
                mode="aspectFit"
              />
              <text class="showcase-badge">{{ t('home.showcase.badge') }}</text>
            </view>
            <text class="showcase-label">{{ t('home.showcase.portrait') }}</text>
          </view>
        </view>
        <text class="showcase-note">{{ t('home.showcase.disclaimer') }}</text>
      </view>
    </scroll-view>

    <!-- 底部操作栏 -->
    <view class="home-bottom-bar" :style="{ paddingBottom: (28 + bottomSafeHeight) + 'px' }">
      <view class="bottom-content">
        <view class="price-info">
          <view v-if="paymentEnabled" class="price-main">
            <text class="price-number">{{ t('home.priceNumber') }}</text>
            <text class="price-unit">{{ t('home.priceUnit') }}</text>
          </view>
          <text v-else class="price-number">剩余 {{ remainingAttempts }} 次</text>
        </view>
        <view class="primary-btn" @tap="navigateToCreation()">
          <text class="btn-text">{{ t('home.start') }}</text>
          <text class="btn-arrow">→</text>
        </view>
      </view>
    </view>

    <PrivacyConsentDialog
      :visible="showPrivacyDialog"
      agree-text="同意并开始使用"
      content="首次使用前，请了解：制作证件照需要处理你主动选择或拍摄的人像照片及面部特征，并通过 HTTPS 发送至已声明的云服务完成本次处理。新用户将获赠 3 次基础生成机会。"
      @agree="handleAgreePrivacyAuthorization"
      @reject="handleRejectPrivacyAuthorization"
      @view-privacy="openPrivacyContract"
    />
  </view>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import { useI18n } from '@/utils/i18n.js'
import paymentAPI from '@/api/payment.js'
import AppIcon from '@/components/AppIcon.vue'
import PrivacyConsentDialog from '@/components/PrivacyConsentDialog.vue'

// 获取i18n实例
const { t, locale: currentLocale } = useI18n()

// 系统信息
const statusBarHeight = ref(0)
const screenWidth = ref(375)
const safeAreaInsets = ref({ top: 0, right: 0, bottom: 0, left: 0 })
const menuButtonRect = ref({ width: 0, height: 0, top: 0, right: 0, bottom: 0, left: 0 })

// 用户状态
const remainingAttempts = ref(0)
const isPremium = ref(false)
const paymentEnabled = paymentAPI.isPaymentEnabled()
const PRIVACY_NOTICE_KEY = 'aiidphotoPrivacyNoticeAcceptedV1'
const showPrivacyDialog = ref(false)
const privacyReady = ref(false)
let userStatusLoadPending = false
let resolvePrivacyAuthorization = null

// 应用图标
const appIconSrc = ref('/static/app-icon.png')
const heroPortraitSrc = ref('/static/home-hero-portrait.jpg')
const showcaseMaleSrc = ref('/static/showcase-male.jpg')
const showcaseFemaleSrc = ref('/static/showcase-female.jpg')

// 计算右侧按钮的右边距
const headerRightPadding = computed(() => {
  // #ifdef MP-WEIXIN
  if (menuButtonRect.value.left > 0) {
    return Math.max(12, screenWidth.value - menuButtonRect.value.left + 8)
  }
  // #endif
  return 16
})

const navigationBarHeight = computed(() => {
  if (menuButtonRect.value.height > 0) {
    const verticalGap = Math.max(4, menuButtonRect.value.top - statusBarHeight.value)
    return menuButtonRect.value.height + verticalGap * 2
  }
  return 48
})

// 计算底部安全区域高度
const bottomSafeHeight = computed(() => {
  return safeAreaInsets.value.bottom || 0
})

// 初始化
onMounted(async () => {
  // 获取系统信息
  const systemInfo = uni.getSystemInfoSync()
  statusBarHeight.value = systemInfo.statusBarHeight || 0
  screenWidth.value = systemInfo.screenWidth || systemInfo.windowWidth || 375
  
  // 获取安全区域
  if (systemInfo.safeArea) {
    safeAreaInsets.value = {
      top: systemInfo.safeArea.top || 0,
      right: systemInfo.screenWidth - (systemInfo.safeArea.right || systemInfo.screenWidth),
      bottom: systemInfo.screenHeight - (systemInfo.safeArea.bottom || systemInfo.screenHeight),
      left: systemInfo.safeArea.left || 0
    }
  }
  
  // 获取微信胶囊按钮位置
  // #ifdef MP-WEIXIN
  try {
    const menuRect = uni.getMenuButtonBoundingClientRect()
    menuButtonRect.value = menuRect
  } catch (e) {
    console.error('获取胶囊按钮位置失败:', e)
  }
  // #endif
  
  uni.$on('paymentStatusChanged', handlePaymentStatusChanged)

  // #ifdef MP-WEIXIN
  if (wx.onNeedPrivacyAuthorization) {
    wx.onNeedPrivacyAuthorization(handleNeedPrivacyAuthorization)
  }
  checkPrivacyAuthorization()
  // #endif

  // #ifndef MP-WEIXIN
  markPrivacyReady()
  // #endif
})

onUnmounted(() => {
  uni.$off('paymentStatusChanged', handlePaymentStatusChanged)
  // #ifdef MP-WEIXIN
  if (wx.offNeedPrivacyAuthorization) {
    wx.offNeedPrivacyAuthorization(handleNeedPrivacyAuthorization)
  }
  // #endif
})

onShow(() => {
  if (privacyReady.value) {
    loadUserStatus()
  } else {
    userStatusLoadPending = true
  }
})

const markPrivacyReady = () => {
  privacyReady.value = true
  showPrivacyDialog.value = false
  if (userStatusLoadPending) {
    userStatusLoadPending = false
    loadUserStatus()
  }
}

const handleNeedPrivacyAuthorization = (resolve) => {
  resolvePrivacyAuthorization = resolve
  privacyReady.value = false
  showPrivacyDialog.value = true
}

const checkPrivacyAuthorization = () => {
  const acceptedOnDevice = Boolean(uni.getStorageSync(PRIVACY_NOTICE_KEY))
  // #ifdef MP-WEIXIN
  if (wx.getPrivacySetting) {
    wx.getPrivacySetting({
      success: ({ needAuthorization }) => {
        if (acceptedOnDevice && !needAuthorization) {
          markPrivacyReady()
        } else {
          showPrivacyDialog.value = true
        }
      },
      fail: () => {
        showPrivacyDialog.value = true
      }
    })
    return
  }
  // #endif
  if (acceptedOnDevice) {
    markPrivacyReady()
  } else {
    showPrivacyDialog.value = true
  }
}

const openPrivacyContract = () => {
  // #ifdef MP-WEIXIN
  if (wx.openPrivacyContract) {
    wx.openPrivacyContract()
    return
  }
  // #endif
  uni.navigateTo({ url: '/pages/privacy/privacy' })
}

const handleAgreePrivacyAuthorization = () => {
  uni.setStorageSync(PRIVACY_NOTICE_KEY, true)
  if (resolvePrivacyAuthorization) {
    resolvePrivacyAuthorization({
      buttonId: 'privacy-agree-btn',
      event: 'agree'
    })
    resolvePrivacyAuthorization = null
  }
  markPrivacyReady()
}

const handleRejectPrivacyAuthorization = () => {
  privacyReady.value = false
  showPrivacyDialog.value = true
  if (resolvePrivacyAuthorization) {
    resolvePrivacyAuthorization({ event: 'disagree' })
    resolvePrivacyAuthorization = null
  }
  uni.showToast({
    title: '同意隐私指引后方可使用',
    icon: 'none'
  })
}

// 加载用户状态
const loadUserStatus = async () => {
  try {
    const status = await paymentAPI.getRemainingAttempts()
    remainingAttempts.value = status.totalAttempts
    isPremium.value = status.proAttempts > 0
  } catch (error) {
    console.error('加载用户状态失败:', error)
  }
}

const handlePaymentStatusChanged = () => {
  loadUserStatus()
}

// 跳转到订阅页面
const navigateToSubscription = () => {
  if (!paymentEnabled) {
    uni.showToast({
      title: '当前设备暂不支持购买',
      icon: 'none'
    })
    return
  }
  uni.navigateTo({
    url: '/pages/subscription/subscription'
  })
}

// 获取系统信息
const getCurrentLanguage = () => {
  const systemInfo = uni.getSystemInfoSync()
  statusBarHeight.value = systemInfo.statusBarHeight || 0
  safeAreaInsets.value = systemInfo.safeAreaInsets || { top: 0, right: 0, bottom: 0, left: 0 }
  
  // 获取微信胶囊按钮位置
  // #ifdef MP-WEIXIN
  try {
    const menuRect = uni.getMenuButtonBoundingClientRect()
    menuButtonRect.value = menuRect
  } catch (e) {
    console.error('获取胶囊按钮位置失败:', e)
  }
  // #endif
  
  console.log('首页onMounted: 当前语言为', currentLocale.value)
}

// 服务分类数据（使用i18n）
// specId 对应 pages/creation/creation.vue 中 specs 数组的真实规格 id
const categories = computed(() => [
  {
    icon: 'id-card',
    specId: 'chinaID',
    title: t('home.categories.idCard'),
    subtitle: t('home.categories.idCardDesc')
  },
  {
    icon: 'passport',
    specId: 'chinaPassport',
    title: t('home.categories.passport'),
    subtitle: t('home.categories.passportDesc')
  },
  {
    icon: 'car',
    specId: 'driverLicense',
    title: t('home.categories.driverLicense'),
    subtitle: t('home.categories.driverLicenseDesc')
  },
  {
    icon: 'briefcase',
    specId: 'resume',
    title: t('home.categories.resume'),
    subtitle: t('home.categories.resumeDesc')
  },
  {
    icon: 'graduation',
    specId: 'studentID',
    title: t('home.categories.student'),
    subtitle: t('home.categories.studentDesc')
  },
  {
    icon: 'user',
    specId: 'standardPortrait',
    title: t('home.categories.avatar'),
    subtitle: t('home.categories.avatarDesc')
  }
])

// 导航到制作页面（specId 为可选的预选规格，creation 页面若接入 onLoad options.specId 即可读取）
const navigateToCreation = (specId) => {
  const url = typeof specId === 'string' && specId
    ? `/pages/creation/creation?specId=${specId}`
    : '/pages/creation/creation'
  uni.navigateTo({ url })
}

// 导航到历史记录
const navigateToHistory = () => {
  uni.navigateTo({
    url: '/pages/history/history'
  })
}

// 导航到设置页面
const navigateToSettings = () => {
  uni.navigateTo({
    url: '/pages/settings/settings'
  })
}
</script>

<style lang="scss" scoped>
.page {
  min-height: 100vh;
  background-color: var(--color-bg-primary);
  display: flex;
  flex-direction: column;
}

/* 状态栏占位 */
.status-bar-placeholder {
  width: 100%;
  background-color: var(--color-bg-primary);
}

/* 首页头部 */
.home-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  min-height: 48px;
  padding: 0 16px;
  box-sizing: border-box;
  background-color: var(--color-bg-primary);
  border-bottom: 0.5px solid var(--color-bg-secondary);
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
  flex: 1;
}

.app-logo {
  width: 44px;
  height: 44px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, var(--color-sky-blue), var(--color-sky-blue-mid));
  border-radius: var(--radius-lg);
  box-shadow: 0 2px 8px rgba(36, 100, 200, 0.2);
  overflow: hidden;
}

.logo-image {
  width: 100%;
  height: 100%;
}

.logo-text {
  font-size: 16px;
  font-weight: 700;
  color: #FFFFFF;
}

.header-title {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.title {
  font-size: 17px;
  font-weight: 700;
  color: var(--color-ink-black);
  letter-spacing: -0.5px;
  white-space: nowrap;
}

.subtitle {
  font-size: 11px;
  font-weight: 400;
  letter-spacing: 0.3px;
  color: var(--color-branch-gray);
  max-width: 132px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.header-right {
  display: flex;
  flex-shrink: 0;
  gap: 6px;
}

.icon-btn {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  border-radius: 10px;
  background: var(--color-bg-secondary);
  transition: opacity 0.15s ease;
}

.icon-btn:active {
  opacity: 0.85;
}

/* 滚动内容 */
.scroll-content {
  flex: 1;
  padding: 0 0 calc(64px + var(--spacing-2xl) + env(safe-area-inset-bottom));
  overflow-y: auto;
}

/* Hero Banner */
.hero-banner {
  position: relative;
  height: 190px;
  margin: 0 -16px 24px;
  overflow: hidden;
  border-radius: 0;
}

.hero-image {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}

.hero-gradient {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(90deg, rgba(21, 73, 160, 0.88) 0%, rgba(45, 112, 205, 0.66) 42%, rgba(65, 137, 230, 0.12) 70%, transparent 100%);
}

.hero-content {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 100%;
  padding: var(--spacing-xl);
}

.hero-left {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 6px;
  max-width: 245px;
}

.hero-title {
  font-size: 26px;
  font-weight: 700;
  color: #ffffff;
  line-height: 1.2;
}

.hero-subtitle {
  font-size: 15px;
  font-weight: 500;
  color: rgba(255, 255, 255, 0.92);
  line-height: 1.2;
}

.hero-tagline {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.75);
  line-height: 1.2;
}

.price-tag {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 5px 10px;
  background: rgba(255, 255, 255, 0.18);
  border-radius: 20px;
  align-self: flex-start;
  margin-top: auto;
}

.price-label {
  font-size: 10px;
  font-weight: 500;
  color: #ffffff;
}

.price-value {
  font-size: 13px;
  font-weight: 700;
  color: var(--color-promo-orange);
}

.price-original {
  font-size: 10px;
  color: rgba(255, 255, 255, 0.55);
  text-decoration: line-through;
}

.hero-right {
  display: flex;
  align-items: flex-start;
  justify-content: flex-end;
  flex: 1;
}

.ai-badge {
  padding: 6px 12px;
  background: rgba(255, 255, 255, 0.9);
  border-radius: 6px;
  margin-top: 12px;
  margin-right: 18px;
}

.ai-badge-text {
  font-size: 10px;
  font-weight: 600;
  color: var(--color-sky-blue);
}

.badge-text {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.5px;
  color: #FFFFFF;
}

.price-original {
  font-size: 12px;
  font-weight: 400;
  text-decoration: line-through;
  color: rgba(255, 255, 255, 0.7);
}

.hero-right {
  display: flex;
  align-items: center;
  justify-content: center;
  margin-left: 16px;
}

.ai-badge-text {
  font-size: 10px;
  font-weight: 600;
  color: var(--color-sky-blue);
}

/* 服务分类 */
.service-categories {
  padding: var(--spacing-lg) var(--spacing-lg) var(--spacing-xl);
}

.category-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: var(--spacing-md);
  max-width: 600px;
  margin: 0 auto;
}

.category-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 7px;
  padding: 14px 8px;
  background-color: rgba(36, 100, 200, 0.10);
  border-radius: 14px;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
  min-height: 90px;
}

.category-item:active {
  transform: scale(0.96);
  background-color: rgba(36, 100, 200, 0.15);
}

.category-icon {
  width: 54px;
  height: 54px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: rgba(36, 100, 200, 0.10);
  border-radius: 14px;
  font-size: 22px;
}

.category-title {
  font-size: 11px;
  font-weight: 600;
  color: #333333;
  text-align: center;
  line-height: 1.2;
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.category-subtitle {
  font-size: 9px;
  color: #666666;
  text-align: center;
  line-height: 1.2;
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* 信任统计 */
.stat-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
}

.stat-highlight {
  display: flex;
  align-items: baseline;
  gap: 1px;
}

.stat-label {
  font-size: 11px;
  font-weight: 500;
  color: #333333;
}

.stat-desc {
  font-size: 10px;
  color: #666666;
  text-align: center;
}

.stat-divider {
  width: 1px;
  height: 36px;
  background-color: rgba(0, 0, 0, 0.1);
}

/* 效果展示 */
.showcase {
  padding: 0 0 24px;
}

.showcase-title {
  font-size: 15px;
  font-weight: 600;
  color: #333333;
}

.showcase-cards {
  display: flex;
  gap: 12px;
  padding: 0 16px;
}

.category-subtitle {
  font-size: 10px;
  font-weight: 400;
  color: var(--color-branch-gray);
  text-align: center;
  letter-spacing: 0.2px;
}

/* 信任统计 */
.trust-stats {
  display: flex;
  align-items: center;
  padding: var(--spacing-lg);
  background-color: var(--color-bg-secondary);
  border-radius: var(--radius-xl);
  margin: 0 var(--spacing-lg) var(--spacing-xl);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.stat-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 16px 0;
}

.stat-highlight {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.stat-number {
  font-size: 20px;
  font-weight: 700;
  color: var(--color-sky-blue);
  letter-spacing: -0.5px;
}

.stat-label {
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.8px;
  text-transform: uppercase;
  color: var(--color-branch-gray);
}

.stat-desc {
  font-size: 12px;
  font-weight: 400;
  color: var(--color-branch-gray);
  letter-spacing: 0.2px;
}

.stat-divider {
  width: 1px;
  height: 44px;
  background-color: var(--color-bg-primary);
  margin: 0 8px;
}

/* 效果展示 */
.showcase {
  padding: 0 0 24px;
}

.showcase-header {
  margin-bottom: var(--spacing-md);
  padding: 0 var(--spacing-lg);
}

.showcase-title {
  font-size: 16px;
  font-weight: 700;
  color: var(--color-ink-black);
  letter-spacing: -0.3px;
}

.showcase-cards {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}

.showcase-card {
  display: flex;
  flex-direction: column;
  gap: 10px;
  overflow: hidden;
  border-radius: 14px;
  background-color: var(--color-bg-secondary);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.showcase-card:active {
  transform: scale(0.98);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.showcase-image-wrap {
  position: relative;
  width: 100%;
  height: 118px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: var(--color-bg-tertiary);
  overflow: hidden;
}

.showcase-image {
  width: 100%;
  height: 100%;
}

.showcase-badge {
  position: absolute;
  top: 7px;
  right: 7px;
  padding: 3px 7px;
  border-radius: 999px;
  background: rgba(20, 30, 48, 0.72);
  color: #ffffff;
  font-size: 9px;
  font-weight: 500;
}

.showcase-label {
  padding: 10px 14px;
  font-size: 13px;
  font-weight: 600;
  color: var(--color-ink-black);
  letter-spacing: -0.2px;
}

.showcase-note {
  display: block;
  padding: var(--spacing-sm) var(--spacing-lg) 0;
  color: var(--color-branch-gray);
  font-size: 11px;
  line-height: 1.5;
}

/* 底部操作栏 */
.home-bottom-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  padding: var(--spacing-md) var(--spacing-lg) var(--spacing-lg);
  background-color: var(--color-bg-primary);
  border-top: 0.5px solid var(--color-bg-secondary);
  z-index: 100;
  box-shadow: 0 -2px 12px rgba(0, 0, 0, 0.04);
  padding-bottom: calc(16px + env(safe-area-inset-bottom));
}

.bottom-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.price-info {
  display: flex;
  flex-direction: column;
  gap: 3px;
  padding-left: 8px;
}

.price-main {
  display: flex;
  align-items: baseline;
  gap: 3px;
}

.price-number {
  font-size: 24px;
  font-weight: 700;
  color: var(--color-sky-blue);
}

.price-unit {
  font-size: 12px;
  font-weight: 500;
  color: #333333;
}

.price-original {
  font-size: 11px;
  color: #666666;
  text-decoration: line-through;
  line-height: 1;
}

.primary-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 14px 20px;
  background: linear-gradient(90deg, var(--color-sky-blue), var(--color-sky-blue-mid));
  border-radius: 26px;
  min-width: 120px;
  flex-shrink: 0;
  transition: opacity 0.15s ease, transform 0.15s ease;
}

.primary-btn:active {
  opacity: 0.85;
  transform: scale(0.97);
}

.btn-text {
  font-size: 16px;
  font-weight: 600;
  color: #ffffff;
}

.btn-arrow {
  font-size: 14px;
  font-weight: 600;
  color: #ffffff;
}

/* 用户状态卡片 */
.user-status-card {
  background: var(--color-bg-primary);
  border-radius: 16px;
  border: 1px solid var(--color-bg-secondary);
  padding: 20px;
  margin-bottom: 20px;
}

.status-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.status-title {
  font-size: 18px;
  font-weight: 600;
  color: var(--color-ink-black);
}

.status-badge {
  padding: 6px 12px;
  border-radius: 20px;
  background: var(--color-bg-secondary);
  
  &.premium {
    background: var(--gradient-premium);
  }
}

.badge-text {
  font-size: 12px;
  font-weight: 600;
  color: var(--color-branch-gray);
  
  .premium & {
    color: #ffffff;
  }
}

.status-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.attempts-info {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.attempts-number {
  font-size: 32px;
  font-weight: 700;
  color: var(--color-ink-black);
  line-height: 1;
}

.attempts-label {
  font-size: 12px;
  color: var(--color-branch-gray);
  margin-top: 4px;
}

.status-actions {
  flex-shrink: 0;
}

.purchase-btn {
  padding: 12px 20px;
  background: var(--gradient-premium);
  border-radius: 20px;
  transition: opacity 0.15s ease;
}

.purchase-btn:active {
  opacity: 0.85;
}

.purchase-text {
  font-size: 14px;
  font-weight: 600;
  color: #ffffff;
}
</style>
