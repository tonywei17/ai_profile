<template>
  <view class="page">
    <!-- 状态栏占位 -->
    <view class="status-bar-placeholder" :style="{ height: statusBarHeight + 'px' }"></view>
    
    <!-- 购买页面头部 -->
    <view class="subscription-header" :style="{ height: navigationBarHeight + 'px' }">
      <view class="header-left">
        <view class="back-btn" @click="goBack">
          <AppIcon name="back" :size="20" color="var(--color-ink-black)" />
        </view>
        <text class="header-title">{{ t('subscription.title') }}</text>
      </view>
      <view class="header-right" :style="{ paddingRight: headerRightPadding + 'px' }">
        <view class="close-btn" @click="goBack">
          <AppIcon name="close" :size="18" color="var(--color-branch-gray)" />
        </view>
      </view>
    </view>

    <!-- 滚动内容 -->
    <scroll-view scroll-y class="scroll-content" :style="{ paddingBottom: (24 + bottomSafeHeight) + 'px' }">
      <!-- Hero区域 -->
      <view class="subscription-hero">
        <view class="hero-gradient"></view>
        <view class="hero-content">
          <view v-if="paymentEnabled" class="discount-badge">
            <text class="badge-text">{{ t('subscription.discount') }}</text>
          </view>
          <text class="hero-title">{{ paymentEnabled ? t('subscription.heroTitle') : '免费体验版' }}</text>
          <text class="hero-subtitle">
            {{ paymentEnabled ? t('subscription.heroSubtitle') : '当前版本赠送3次基础证件照生成体验' }}
          </text>
        </view>
      </view>

      <!-- 产品卡片 -->
      <view v-if="paymentEnabled" class="product-card">
        <view class="product-header">
          <text class="product-title">{{ t('subscription.noSubscription') }}</text>
          <text class="product-price">{{ displayPrice }}</text>
        </view>
        <text class="product-desc">{{ t('subscription.priceExplain') }}</text>
        
        <view class="features-list">
          <view class="feature-item">
            <view class="feature-icon">
              <AppIcon name="check" :size="12" color="var(--color-premium-start)" />
            </view>
            <text class="feature-text">包含3次AI证件照生成机会</text>
          </view>
          <view class="feature-item">
            <view class="feature-icon">
              <AppIcon name="check" :size="12" color="var(--color-premium-start)" />
            </view>
            <text class="feature-text">{{ t('subscription.allSpecs') }}</text>
          </view>
          <view class="feature-item">
            <view class="feature-icon">
              <AppIcon name="check" :size="12" color="var(--color-premium-start)" />
            </view>
            <text class="feature-text">{{ t('subscription.proOptions') }}</text>
          </view>
          <view class="feature-item">
            <view class="feature-icon">
              <AppIcon name="check" :size="12" color="var(--color-premium-start)" />
            </view>
            <text class="feature-text">{{ t('subscription.customSize') }}</text>
          </view>
          <view class="feature-item">
            <view class="feature-icon">
              <AppIcon name="check" :size="12" color="var(--color-premium-start)" />
            </view>
            <text class="feature-text">{{ t('subscription.printLayout') }}</text>
          </view>
        </view>

        <view 
          class="purchase-btn"
          :class="{ disabled: isPurchasing }"
          @tap="handlePurchase"
        >
          <text class="btn-text">{{ isPurchasing ? '购买中...' : t('subscription.purchase') }}</text>
        </view>

        <view class="restore-btn" @tap="handleRestore">
          <text class="restore-text">{{ t('subscription.restore') }}</text>
        </view>
      </view>

      <view v-if="!paymentEnabled" class="product-card">
        <text class="product-title product-title-standalone">当前微信版本暂不支持购买</text>
        <text class="product-desc">请将微信升级到最新版本后重试；可继续使用已有生成次数。</text>
      </view>

      <!-- 底部说明 -->
      <view class="footer-note">
        <text class="note-text">
          {{ paymentEnabled ? '微信虚拟支付，购买后生成次数立即到账' : '请升级微信后重试，可继续使用已有生成次数' }}
        </text>
      </view>
    </scroll-view>
  </view>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import { useI18n } from '@/utils/i18n.js'
import paymentAPI from '@/api/payment.js'
import AppIcon from '@/components/AppIcon.vue'

// 获取i18n实例
const { t } = useI18n()

// 系统信息
const statusBarHeight = ref(0)
const screenWidth = ref(375)
const safeAreaInsets = ref({ top: 0, right: 0, bottom: 0, left: 0 })
const menuButtonRect = ref({ width: 0, height: 0, top: 0, right: 0, bottom: 0, left: 0 })

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

const bottomSafeHeight = computed(() => safeAreaInsets.value.bottom || 0)

// 状态
const isPurchasing = ref(false)
const isRestoring = ref(false)
const displayPrice = ref(paymentAPI.getDisplayPrice())
const remainingAttempts = ref(0)
const paymentEnabled = paymentAPI.isPaymentEnabled()

// 初始化
onMounted(async () => {
  const systemInfo = uni.getSystemInfoSync()
  statusBarHeight.value = systemInfo.statusBarHeight || 0
  screenWidth.value = systemInfo.screenWidth || systemInfo.windowWidth || 375
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
})

onShow(async () => {
  remainingAttempts.value = (await paymentAPI.getRemainingAttempts()).totalAttempts
})

// 处理购买
const handlePurchase = async () => {
  if (isPurchasing.value) return
  
  isPurchasing.value = true
  
  try {
    await paymentAPI.purchasePhotoTask()
    
    // 购买成功，更新剩余次数
    remainingAttempts.value = (await paymentAPI.getRemainingAttempts()).totalAttempts
    
    uni.showToast({
      title: '购买成功',
      icon: 'success'
    })
    
    // 延迟返回
    setTimeout(() => {
      goBack()
    }, 1500)
  } catch (error) {
    console.error('购买失败:', error)
    uni.showToast({
      title: error.message || '购买失败，请重试',
      icon: 'none',
      duration: 3000
    })
  } finally {
    isPurchasing.value = false
  }
}

// 刷新购买状态
const handleRestore = async () => {
  if (isRestoring.value) return
  
  isRestoring.value = true
  
  try {
    await paymentAPI.restorePurchases()
    
    // 恢复成功，更新剩余次数
    remainingAttempts.value = (await paymentAPI.getRemainingAttempts()).totalAttempts
    
    uni.showToast({
      title: '购买状态已刷新',
      icon: 'success'
    })
  } catch (error) {
    console.error('刷新购买状态失败:', error)
    uni.showToast({
      title: error.message || '刷新失败，请重试',
      icon: 'none'
    })
  } finally {
    isRestoring.value = false
  }
}

// 返回
const goBack = () => {
  uni.navigateBack()
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

/* 购买页面头部 */
.subscription-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  min-height: 48px;
  padding: 0 var(--spacing-lg);
  box-sizing: border-box;
  background-color: var(--color-bg-primary);
  border-bottom: 0.5px solid var(--color-bg-secondary);
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
  border-radius: var(--radius-lg);
  background: var(--color-bg-secondary);
  color: var(--color-branch-gray);
}

.header-title {
  font-size: 18px;
  font-weight: 700;
  color: var(--color-ink-black);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.header-right {
  display: flex;
  align-items: center;
  flex-shrink: 0;
}

.close-btn {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: var(--radius-lg);
  background: var(--color-bg-secondary);
}

/* 滚动内容 */
.scroll-content {
  flex: 1;
  padding: var(--spacing-lg) var(--spacing-lg);
  max-width: 400px;
  margin: 0 auto;
  width: 100%;
  box-sizing: border-box;
}

/* Hero区域 */
.subscription-hero {
  height: 200px;
  border-radius: var(--radius-xl);
  overflow: hidden;
  margin-bottom: var(--spacing-xl);
  position: relative;
}

.hero-gradient {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: var(--gradient-premium);
}

.hero-content {
  position: relative;
  z-index: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  padding: var(--spacing-xl);
  text-align: center;
}

.discount-badge {
  padding: var(--spacing-xs) var(--spacing-md);
  background: rgba(255, 255, 255, 0.2);
  border-radius: var(--radius-full);
  margin-bottom: var(--spacing-lg);
}

.badge-text {
  font-size: 12px;
  font-weight: 600;
  color: #fff;
}

.hero-title {
  font-size: 24px;
  font-weight: 700;
  color: #fff;
  margin-bottom: var(--spacing-sm);
}

.hero-subtitle {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.9);
  line-height: 1.5;
}

/* 产品卡片 */
.product-card {
  padding: var(--spacing-xl);
  background: var(--color-bg-primary);
  border-radius: var(--radius-xl);
  border: 1px solid var(--color-bg-secondary);
  margin-bottom: var(--spacing-xl);
  box-sizing: border-box;
}

.product-header {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  margin-bottom: var(--spacing-sm);
}

.product-title {
  font-size: 18px;
  font-weight: 600;
  color: var(--color-ink-black);
}

/* 禁用购买态：标题独立成行，与说明文字保持间距，避免与 product-header 内的胶囊布局冲突 */
.product-title-standalone {
  display: block;
  margin-bottom: var(--spacing-sm);
}

.product-price {
  font-size: 28px;
  font-weight: 700;
  color: var(--color-premium-start);
}

.product-desc {
  display: block;
  font-size: 13px;
  color: var(--color-branch-gray);
  margin-bottom: var(--spacing-lg);
}

.features-list {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-md);
  margin-bottom: var(--spacing-xl);
}

.feature-item {
  display: flex;
  align-items: center;
  gap: 10px;
}

.feature-icon {
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  /* 取 --color-premium-start (#2464C8) 的 10% 透明度，token 体系暂无半透明变体 */
  background: rgba(36, 100, 200, 0.1);
  border-radius: 50%;
  flex-shrink: 0;
}

.feature-text {
  font-size: 14px;
  color: var(--color-ink-black);
}

.purchase-btn {
  width: 100%;
  padding: var(--spacing-lg);
  background: var(--gradient-premium);
  border-radius: var(--radius-full);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: var(--spacing-md);
  transition: opacity 0.2s, transform 0.15s ease;
  box-sizing: border-box;
  /* 取 --color-premium-start (#2464C8) 的 24% 透明度，token 体系暂无半透明变体 */
  box-shadow: 0 8px 20px rgba(36, 100, 200, 0.24);

  &:active {
    opacity: 0.85;
    transform: scale(0.98);
  }

  &.disabled {
    opacity: 0.5;
    pointer-events: none;

    &:active {
      opacity: 0.5;
      transform: none;
    }
  }
}

.btn-text {
  font-size: 16px;
  font-weight: 600;
  color: #fff;
}

.restore-btn {
  width: 100%;
  padding: var(--spacing-md);
  display: flex;
  align-items: center;
  justify-content: center;
  box-sizing: border-box;
  border-radius: var(--radius-lg);
  background: var(--color-bg-secondary);
}

.restore-text {
  font-size: 14px;
  color: var(--color-branch-gray);
}

/* 底部说明 */
.footer-note {
  padding: var(--spacing-lg);
  text-align: center;
}

.note-text {
  font-size: 12px;
  color: var(--color-branch-gray);
  line-height: 1.5;
}
</style>
