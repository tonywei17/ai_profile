<template>
  <view class="page">
    <!-- 状态栏占位 -->
    <view class="status-bar-placeholder" :style="{ height: statusBarHeight + 'px' }"></view>
    
    <!-- 生成流程头部 -->
    <view class="generation-header" :style="{ height: navigationBarHeight + 'px' }">
      <view class="header-left">
        <view class="back-btn" @tap="goBack">
          <AppIcon name="back" :size="22" color="var(--color-ink-black)" />
        </view>
        <text class="header-title">{{ t('app.name') }}</text>
      </view>
      <view class="header-right" :style="{ paddingRight: headerRightPadding + 'px' }">
        <view class="icon-btn" @tap="navigateToHistory">
          <AppIcon name="history" :size="20" color="var(--color-ink-black)" />
        </view>
        <view v-if="paymentEnabled" class="subscription-btn" @tap="navigateToSubscription">
          <text class="subscription-text">{{ t('common.pro') }}</text>
        </view>
      </view>
    </view>

    <!-- 滚动内容 -->
    <scroll-view scroll-y class="scroll-content">
      <!-- 进度步骤 -->
      <view class="progress-steps">
        <view class="steps-container">
          <view 
            v-for="(step, index) in steps" 
            :key="index"
            class="step-item"
            :class="{ active: index + 1 <= currentStep, completed: index + 1 < currentStep }"
          >
            <view class="step-circle">
              <AppIcon v-if="index + 1 < currentStep" name="check" :size="14" color="#FFFFFF" />
              <text v-else class="step-number">{{ index + 1 }}</text>
            </view>
            <text class="step-title">{{ step }}</text>
          </view>
        </view>
      </view>

      <!-- Hero区域 - 图片选择 -->
      <view class="hero-section">
        <view v-if="!inputImage" class="upload-placeholder" @tap="showPhotoSourceDialog">
          <view class="upload-icon">
            <AppIcon name="arrow-up-right" :size="32" color="var(--color-sky-blue)" />
          </view>
          <text class="upload-title">{{ t('creation.upload.title') }}</text>
          <text class="upload-subtitle">{{ t('creation.upload.subtitle') }}</text>
          <view class="upload-tips">
            <AppIcon name="check" :size="12" color="var(--color-sky-blue-mid)" />
            <text class="tips-text">{{ t('creation.upload.tips') }}</text>
          </view>
        </view>
        <view v-else class="image-preview">
          <image class="preview-image" :src="inputImage" mode="aspectFit" />
          <view class="change-photo-btn" @tap="showPhotoChangeDialog">
            <AppIcon name="refresh" :size="12" color="#FFFFFF" />
            <text class="change-photo-text">{{ t('creation.upload.changePhoto') }}</text>
          </view>
        </view>
      </view>

      <!-- 规格选择 -->
      <view class="section">
        <view class="spec-selector">
          <text class="section-label">{{ t('creation.format') }}</text>
          <view class="spec-grid">
            <view 
              v-for="(spec, index) in displayedSpecs" 
              :key="spec.id"
              class="spec-item"
              :class="{ active: selectedSpec && selectedSpec.id === spec.id && !isCustomSize, locked: spec.isPro && !isSubscribed }"
              @tap="selectSpec(spec)"
            >
              <view class="spec-content">
                <text class="spec-name">{{ spec.displayName }}</text>
                <text class="spec-size">{{ spec.sizeLabel }}</text>
              </view>
              <view v-if="spec.isPro && !isSubscribed" class="lock-icon">
                <AppIcon name="lock" :size="13" color="var(--color-branch-gray)" />
              </view>
            </view>
          </view>
          <view v-if="specs.length > 4" class="expand-btn" @tap="toggleShowAll">
            <text class="expand-text">{{ showAll ? t('creation.showLess') : t('creation.showMore') }}</text>
            <view class="icon-down" :class="{ rotate: showAll }">
              <AppIcon name="chevron-down" :size="14" color="var(--color-branch-gray)" />
            </view>
          </view>
          <view
            class="custom-size-row"
            :class="{ active: isCustomSize, locked: !isSubscribed }"
            @tap="selectCustomSize"
          >
            <view class="custom-size-content">
              <view class="custom-size-copy">
                <text class="custom-size-name">{{ t('creation.customSize') }}</text>
                <text class="custom-size-desc">
                  {{ isCustomSize ? selectedSpec.sizeLabel : '输入宽高，生成指定规格' }}
                </text>
              </view>
              <text class="pro-tag">{{ t('common.pro') }}</text>
            </view>
            <view v-if="isCustomSize" class="custom-selected-mark">
              <AppIcon name="check" :size="12" color="var(--color-sky-blue)" />
              <text class="custom-selected-text">已选</text>
            </view>
            <view v-else-if="!isSubscribed" class="lock-icon">
              <AppIcon name="lock" :size="13" color="var(--color-branch-gray)" />
            </view>
            <AppIcon v-else name="chevron-right" :size="18" color="var(--color-branch-gray)" />
          </view>
          <view v-if="showCustomSizePanel && isSubscribed" class="custom-size-panel">
            <view class="dimension-fields">
              <view class="dimension-field">
                <text class="dimension-label">宽度</text>
                <view class="dimension-input-wrap">
                  <input
                    v-model="customSize.width"
                    class="dimension-input"
                    type="digit"
                    maxlength="5"
                    placeholder="25"
                  />
                  <text class="dimension-unit">mm</text>
                </view>
              </view>
              <text class="dimension-symbol">×</text>
              <view class="dimension-field">
                <text class="dimension-label">高度</text>
                <view class="dimension-input-wrap">
                  <input
                    v-model="customSize.height"
                    class="dimension-input"
                    type="digit"
                    maxlength="5"
                    placeholder="35"
                  />
                  <text class="dimension-unit">mm</text>
                </view>
              </view>
            </view>
            <text class="dimension-tip">支持 10–300 mm，按 300 DPI 输出</text>
            <view class="apply-custom-size-btn" @tap="applyCustomSize">
              <text>应用此尺寸</text>
            </view>
          </view>
        </view>
      </view>

      <!-- Pro选项 -->
      <view class="section">
        <view class="pro-options">
          <view class="pro-header" @tap="toggleProOptions">
            <text class="pro-title">{{ t('creation.aiCustomize') }}</text>
            <text v-if="!isSubscribed" class="pro-badge">{{ t('common.pro') }}</text>
            <view class="icon-down" :class="{ rotate: isProOptionsExpanded }">
              <AppIcon name="chevron-down" :size="14" color="var(--color-branch-gray)" />
            </view>
          </view>
          <view v-if="isProOptionsExpanded" class="pro-content">
            <!-- 美颜 -->
            <view class="option-category">
              <view class="category-heading">
                <text class="category-title">{{ t('creation.beauty') }}</text>
                <text class="selected-summary">已选：{{ getOptionDisplayName(beautyLevels, photoOptions.beauty) }}</text>
              </view>
              <scroll-view scroll-x class="option-scroll">
                <view class="option-chips">
                  <view 
                    v-for="level in beautyLevels" 
                    :key="level.id"
                    class="option-chip"
                    :class="{ active: photoOptions.beauty === level.id, locked: level.isPro && !isSubscribed }"
                    @tap="selectBeauty(level)"
                  >
                    <text class="chip-label">{{ level.displayName }}</text>
                    <view v-if="photoOptions.beauty === level.id" class="selection-check">
                      <AppIcon name="check" :size="11" color="var(--color-sky-blue)" />
                    </view>
                    <AppIcon v-if="level.isPro && !isSubscribed" name="lock" :size="12" color="var(--color-branch-gray)" />
                  </view>
                </view>
              </scroll-view>
            </view>
            <!-- 服装 -->
            <view class="option-category">
              <view class="category-heading">
                <text class="category-title">{{ t('creation.attire') }}</text>
                <text class="selected-summary">已选：{{ getOptionDisplayName(attires, photoOptions.attire) }}</text>
              </view>
              <scroll-view scroll-x class="option-scroll">
                <view class="option-chips">
                  <view 
                    v-for="attire in attires" 
                    :key="attire.id"
                    class="option-chip"
                    :class="{ active: photoOptions.attire === attire.id, locked: attire.isPro && !isSubscribed }"
                    @tap="selectAttire(attire)"
                  >
                    <text class="chip-label">{{ attire.displayName }}</text>
                    <view v-if="photoOptions.attire === attire.id" class="selection-check">
                      <AppIcon name="check" :size="11" color="var(--color-sky-blue)" />
                    </view>
                    <AppIcon v-if="attire.isPro && !isSubscribed" name="lock" :size="12" color="var(--color-branch-gray)" />
                  </view>
                </view>
              </scroll-view>
            </view>
            <!-- 发型 -->
            <view class="option-category">
              <view class="category-heading">
                <text class="category-title">{{ t('creation.hair') }}</text>
                <text class="selected-summary">已选：{{ getOptionDisplayName(hairs, photoOptions.hair) }}</text>
              </view>
              <scroll-view scroll-x class="option-scroll">
                <view class="option-chips">
                  <view 
                    v-for="hair in hairs" 
                    :key="hair.id"
                    class="option-chip"
                    :class="{ active: photoOptions.hair === hair.id, locked: hair.isPro && !isSubscribed }"
                    @tap="selectHair(hair)"
                  >
                    <text class="chip-label">{{ hair.displayName }}</text>
                    <view v-if="photoOptions.hair === hair.id" class="selection-check">
                      <AppIcon name="check" :size="11" color="var(--color-sky-blue)" />
                    </view>
                    <AppIcon v-if="hair.isPro && !isSubscribed" name="lock" :size="12" color="var(--color-branch-gray)" />
                  </view>
                </view>
              </scroll-view>
            </view>
            <!-- 背景色 -->
            <view class="option-category">
              <view class="category-heading">
                <text class="category-title">{{ t('creation.background') }}</text>
                <text class="selected-summary">已选：{{ getOptionDisplayName(backgrounds, photoOptions.background) }}</text>
              </view>
              <scroll-view scroll-x class="option-scroll">
                <view class="option-chips">
                  <view 
                    v-for="bg in backgrounds" 
                    :key="bg.id"
                    class="option-chip"
                    :class="{ active: photoOptions.background === bg.id, locked: bg.isPro && !isSubscribed }"
                    @tap="selectBackground(bg)"
                  >
                    <view v-if="bg.swatchColor" class="color-swatch" :style="{ backgroundColor: bg.swatchColor }"></view>
                    <text class="chip-label">{{ bg.displayName }}</text>
                    <view v-if="photoOptions.background === bg.id" class="selection-check">
                      <AppIcon name="check" :size="11" color="var(--color-sky-blue)" />
                    </view>
                    <AppIcon v-if="bg.isPro && !isSubscribed" name="lock" :size="12" color="var(--color-branch-gray)" />
                  </view>
                </view>
              </scroll-view>
            </view>
            <!-- 配饰 -->
            <view class="option-category">
              <view class="category-heading">
                <text class="category-title">{{ t('creation.accessories') }}</text>
                <text class="selected-summary">已选：{{ getOptionDisplayName(accessories, photoOptions.accessories) }}</text>
              </view>
              <scroll-view scroll-x class="option-scroll">
                <view class="option-chips">
                  <view 
                    v-for="acc in accessories" 
                    :key="acc.id"
                    class="option-chip"
                    :class="{ active: photoOptions.accessories === acc.id, locked: acc.isPro && !isSubscribed }"
                    @tap="selectAccessories(acc)"
                  >
                    <text class="chip-label">{{ acc.displayName }}</text>
                    <view v-if="photoOptions.accessories === acc.id" class="selection-check">
                      <AppIcon name="check" :size="11" color="var(--color-sky-blue)" />
                    </view>
                    <AppIcon v-if="acc.isPro && !isSubscribed" name="lock" :size="12" color="var(--color-branch-gray)" />
                  </view>
                </view>
              </scroll-view>
            </view>
          </view>
        </view>
      </view>

      <!-- 结果卡片 -->
      <view v-if="outputImage" id="resultCard" class="section">
        <view class="result-card">
          <view class="result-header">
            <text class="result-title">{{ t('result.title') }}</text>
            <text class="aigc-badge">AI生成/编辑</text>
          </view>
          <view class="result-image-container">
            <image class="result-image" :src="outputImage" mode="aspectFit" />
          </view>
          <!-- 主操作行：重新生成 + 保存到相册 -->
          <view class="result-main-actions">
            <view class="regenerate-result-btn" @tap="regeneratePhoto">
              <AppIcon name="refresh" :size="14" color="var(--color-sky-blue)" />
              <text class="regenerate-result-text">重新生成</text>
            </view>
            <view class="save-result-btn" @tap="saveImage">
              <AppIcon name="save" :size="14" color="#FFFFFF" />
              <text class="save-result-text">保存到相册</text>
            </view>
          </view>
          <!-- 其他操作 -->
          <view class="result-actions">
            <view class="action-btn" @tap="showPrintLayout">
              <text class="action-text">{{ t('result.print') }}</text>
            </view>
          </view>
        </view>
      </view>
    </scroll-view>

    <!-- 隐藏的Canvas用于打印排版 -->
    <canvas canvas-id="printCanvas" style="position: fixed; top: -9999px; left: -9999px; width: 1500px; height: 2102px;"></canvas>

    <!-- 底部操作栏 -->
    <view class="bottom-bar" :style="{ paddingBottom: (16 + bottomSafeHeight) + 'px' }">
      <view class="generate-btn" :class="{ disabled: !inputImage || isGenerating }" @tap="generatePhoto">
        <text class="btn-text">{{ isGenerating ? t('creation.generating') : t('creation.generate') }}</text>
      </view>
      <text class="generate-footnote">{{ t('creation.footnote') }}</text>
    </view>

    <!-- AI 生成中全屏遮罩：锁定页面其余交互 -->
    <view v-if="isGenerating" class="generating-mask" @tap.stop @touchmove.stop.prevent>
      <view class="generating-box">
        <view class="generating-spinner"></view>
        <text class="generating-title">{{ t('creation.generatingOverlay.title') }}</text>
        <text class="generating-desc">{{ t('creation.generatingOverlay.desc') }}</text>
      </view>
    </view>

    <!-- 隐私同意弹窗（统一组件，授权状态机仍由本页持有） -->
    <PrivacyConsentDialog
      :visible="showPrivacyDialog"
      content="制作证件照需要处理你主动选择或拍摄的人像照片及面部特征，并通过 HTTPS 发送至阿里云后端、阿里云百炼及我们部署在中国大陆以外云区域的 HivisionIDPhotos 服务完成本次处理。照片不用于模型训练或公开展示，处理完成后不在我们的服务器持久化保存。"
      agree-text="同意并继续"
      @agree="handleAgreePrivacyAuthorization"
      @reject="handleRejectPrivacyAuthorization"
      @view-privacy="openPrivacyContract"
    />
  </view>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { onLoad, onShow } from '@dcloudio/uni-app'
import AppIcon from '@/components/AppIcon.vue'
import PrivacyConsentDialog from '@/components/PrivacyConsentDialog.vue'
import geminiAPI from '@/api/gemini.js'
import printLayoutAPI from '@/api/printLayout.js'
import historyAPI from '@/api/history.js'
import paymentAPI from '@/api/payment.js'
import { useI18n } from '@/utils/i18n.js'

// 获取i18n实例
const { t } = useI18n()

// 进度步骤
const steps = ['上传照片', '选择场景', 'AI优化', '下载保存']
const currentStep = ref(1)

// 步骤条状态推进：只前进不后退（生成失败的回退由 generatePhoto 显式处理）
const markStepReached = (step) => {
  if (currentStep.value < step) {
    currentStep.value = step
  }
}

// 系统信息
const statusBarHeight = ref(0)
const screenWidth = ref(375)
const menuButtonRect = ref({ width: 0, height: 0, top: 0, right: 0, bottom: 0, left: 0 })
const safeAreaInsets = ref({ top: 0, right: 0, bottom: 0, left: 0 })

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

// 获取系统信息和用户状态
onMounted(async () => {
  // 获取系统信息
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
  
  uni.$on('paymentStatusChanged', handlePaymentStatusChanged)

  // #ifdef MP-WEIXIN
  if (wx.onNeedPrivacyAuthorization) {
    wx.onNeedPrivacyAuthorization(handleNeedPrivacyAuthorization)
  }
  checkPrivacyAuthorization()
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

// 状态
const inputImage = ref(null)
const outputImage = ref(null)
const outputProduceId = ref('')
const selectedSpec = ref(null) // 先初始化为null
const isCustomSize = ref(false)
const showCustomSizePanel = ref(false)
const customSize = ref({
  width: '25',
  height: '35'
})
const isGenerating = ref(false)
const showAll = ref(false)
const isProOptionsExpanded = ref(true)
const isSubscribed = ref(false)
const remainingAttempts = ref(0)
const paymentEnabled = paymentAPI.isPaymentEnabled()
const PRIVACY_NOTICE_KEY = 'aiidphotoPrivacyNoticeAcceptedV1'
const showPrivacyDialog = ref(false)
const privacyReady = ref(false)
let userStatusLoadPending = false
let resolvePrivacyAuthorization = null

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

const markPrivacyReady = () => {
  privacyReady.value = true
  showPrivacyDialog.value = false
  if (userStatusLoadPending) {
    userStatusLoadPending = false
    loadUserStatus()
  }
}

const openPrivacyContract = () => {
  // #ifdef MP-WEIXIN
  if (wx.openPrivacyContract) {
    wx.openPrivacyContract()
  }
  // #endif
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
    title: t('creation.toast.privacyRequired'),
    icon: 'none'
  })
}

// 加载用户状态
const loadUserStatus = async () => {
  try {
    const result = await paymentAPI.getRemainingAttempts()
    remainingAttempts.value = result.totalAttempts
    isSubscribed.value = result.proAttempts > 0
    console.log('生成页面用户状态加载:', result)
  } catch (error) {
    console.error('加载用户状态失败:', error)
    remainingAttempts.value = 0
    isSubscribed.value = false
  }
}

const handlePaymentStatusChanged = () => {
  loadUserStatus()
}

// 证件照规格数据（使用i18n）
const specs = computed(() => [
  // 免费规格
  { 
    id: 'chinaID', 
    displayName: t('creation.specs.chinaID'), 
    sizeLabel: '26×32 mm', 
    isPro: false,
    widthPx: 307,
    heightPx: 378,
    bgColorHex: 'ffffff',
    prompt: '将背景替换为纯白色（#FFFFFF），将服装替换为深色系正装衬衫（不着白色或浅色上衣），均匀柔和正面补光，轻微修肤保持自然，输出中国居民身份证标准证件照效果。重新构图为标准证件照：头部（下巴到头顶）占照片高度约2/3，画面仅包含头部和颈部到领口衣领处，不露出肩膀以下，头顶距照片顶边留约5%空白，人脸水平居中。保持人物的脸部五官完全不变。'
  },
  { 
    id: 'oneInch', 
    displayName: t('creation.specs.oneInch'), 
    sizeLabel: '25×35 mm', 
    isPro: false,
    widthPx: 295,
    heightPx: 413,
    bgColorHex: 'ffffff',
    prompt: '将背景替换为纯白色（#FFFFFF），将服装替换为正式商务衬衫或上衣，均匀柔和光线，轻微修肤，输出中国标准一寸证件照（25×35mm）效果。重新构图为标准证件照：头部（下巴到头顶）占照片高度约2/3，画面仅包含头部和颈部到领口衣领处，不露出肩膀以下，头顶距照片顶边留约5%空白，人脸水平居中。保持人物的脸部五官完全不变。'
  },
  { 
    id: 'twoInch', 
    displayName: t('creation.specs.twoInch'), 
    sizeLabel: '35×49 mm', 
    isPro: false,
    widthPx: 413,
    heightPx: 579,
    bgColorHex: 'ffffff',
    prompt: '将背景替换为纯白色（#FFFFFF），将服装替换为正式商务装，均匀柔和正面光线，输出中国标准二寸证件照（35×49mm）效果。重新构图为标准证件照：头部（下巴到头顶）占照片高度约2/3，画面仅包含头部和颈部到领口衣领处，不露出肩膀以下，头顶距照片顶边留约5%空白，人脸水平居中。保持人物的脸部五官完全不变。'
  },
  { 
    id: 'chinaPassport', 
    displayName: t('creation.specs.chinaPassport'), 
    sizeLabel: '33×48 mm', 
    isPro: false,
    widthPx: 390,
    heightPx: 567,
    bgColorHex: 'ffffff',
    prompt: '将背景替换为纯白色（#FFFFFF），将服装替换为深色纯色领口上衣（无图案无logo），均匀柔和正面光线，嘴巴自然闭合，输出中国护照申请标准照片效果。重新构图：头部（下巴到头顶）占照片高度约65%，仅含头部到衣领处，头顶距顶边留约8%空白，人脸水平居中。保持人物的脸部五官完全不变。'
  },
  { 
    id: 'driverLicense', 
    displayName: t('creation.specs.driverLicense'), 
    sizeLabel: '22×32 mm', 
    isPro: false,
    widthPx: 260,
    heightPx: 378,
    bgColorHex: '5395e2',
    prompt: '将背景替换为纯蓝色（#5395E2），将服装替换为整洁深色上衣（避免白色上衣），均匀柔和光线，输出中国机动车驾驶证标准证件照效果。重新构图为标准证件照：头部（下巴到头顶）占照片高度约2/3，画面仅包含头部和颈部到领口衣领处，不露出肩膀以下，头顶距照片顶边留约5%空白，人脸水平居中。保持人物的脸部五官完全不变。'
  },
  { 
    id: 'studentID', 
    displayName: t('creation.specs.studentCard'), 
    sizeLabel: '25×35 mm', 
    isPro: false,
    widthPx: 295,
    heightPx: 413,
    bgColorHex: '438edb',
    prompt: '将背景替换为淡蓝色（#438EDB），将服装替换为整洁学生装或正式上衣，均匀柔和光线，轻微修肤，输出学生证标准证件照效果。重新构图为标准证件照：头部（下巴到头顶）占照片高度约2/3，画面仅包含头部和颈部到领口衣领处，不露出肩膀以下，头顶距照片顶边留约5%空白，人脸水平居中。保持人物的脸部五官完全不变。'
  },
  { 
    id: 'socialSecurity', 
    displayName: t('creation.specs.socialSecurity'), 
    sizeLabel: '26×32 mm', 
    isPro: false,
    widthPx: 307,
    heightPx: 378,
    bgColorHex: 'ffffff',
    prompt: '将背景替换为纯白色（#FFFFFF），将服装替换为深色商务上衣，均匀柔和正面光线，输出中国社会保障卡标准证件照效果。重新构图为标准证件照：头部（下巴到头顶）占照片高度约2/3，画面仅包含头部和颈部到领口衣领处，不露出肩膀以下，头顶距照片顶边留约5%空白，人脸水平居中。保持人物的脸部五官完全不变。'
  },
  { 
    id: 'resume', 
    displayName: t('creation.specs.resume'), 
    sizeLabel: '25×35 mm', 
    isPro: false,
    widthPx: 295,
    heightPx: 413,
    bgColorHex: 'ffffff',
    prompt: '将背景替换为纯白色或浅蓝色，将服装替换为专业商务装（白衬衫或正装上衣），均匀柔和光线，轻微修肤，输出专业简历标准证件照效果。重新构图：画面包含头部到肩膀以下约一指宽区域，头部居中，面部占照片高度约60%。保持人物的脸部五官完全不变。'
  },
  { 
    id: 'standardPortrait', 
    displayName: '证件照（胸部以上）', 
    sizeLabel: '35×45 mm', 
    isPro: false,
    widthPx: 413,
    heightPx: 531,
    bgColorHex: 'ffffff',
    prompt: '将背景替换为纯白色（#FFFFFF），将服装替换为整洁商务装，均匀柔和影棚光线，轻微修肤，输出标准胸部以上证件人像效果。重新构图：画面包含头部到胸口约1/3处，头部占照片上方约55%高度，人物居中。保持人物的脸部五官完全不变。'
  },
  { 
    id: 'halfBody', 
    displayName: '半身照', 
    sizeLabel: '89×127 mm', 
    isPro: false,
    widthPx: 1050,
    heightPx: 1500,
    bgColorHex: 'ffffff',
    prompt: '将背景替换为纯白色或浅灰色影棚背景，将服装替换为专业商务休闲装，均匀柔和影棚光线，轻微修肤，输出专业半身人像效果（腰部以上，完整展示上半身和双手）。保持人物的脸部五官完全不变。'
  },
  { 
    id: 'fullBody', 
    displayName: '全身照', 
    sizeLabel: '102×152 mm', 
    isPro: false,
    widthPx: 1205,
    heightPx: 1795,
    bgColorHex: 'ffffff',
    prompt: '将背景替换为纯白色或浅灰色影棚背景，将服装替换为专业商务休闲装，均匀柔和影棚光线，轻微修肤，输出专业全身人像效果（头顶到鞋底完整呈现，头顶距上边留约5%空白）。保持人物的脸部五官完全不变。'
  },
  // Pro规格
  { 
    id: 'chinaMarriage', 
    displayName: '结婚登记照', 
    sizeLabel: '53×35 mm', 
    isPro: true,
    widthPx: 626,
    heightPx: 413,
    bgColorHex: 'c10000',
    prompt: '将背景替换为中国婚姻登记专用纯红色（#C10000），两人服装替换为半正式装（男士衬衫或西装，女士整洁上衣），均匀柔和正面光线，男左女右站立，输出中国结婚登记标准照片效果。重新构图：双人头肩特写，两人头部（下巴到头顶）合计占照片高度约2/3，仅含头部到领口处。保持人物的脸部五官完全不变。'
  },
  { 
    id: 'oneInchLarge', 
    displayName: '大一寸', 
    sizeLabel: '33×48 mm', 
    isPro: true,
    widthPx: 390,
    heightPx: 567,
    bgColorHex: 'ffffff',
    prompt: '将背景替换为纯白色（#FFFFFF），将服装替换为正式商务装，均匀柔和正面光线，输出中国大一寸（33×48mm）证件照效果，适用于普通话水平测试及党员申请。重新构图为标准证件照：头部（下巴到头顶）占照片高度约2/3，画面仅包含头部和颈部到领口衣领处，不露出肩膀以下，头顶距照片顶边留约5%空白，人脸水平居中。保持人物的脸部五官完全不变。'
  },
  { 
    id: 'twoInchSmall', 
    displayName: '小二寸', 
    sizeLabel: '35×45 mm', 
    isPro: true,
    widthPx: 413,
    heightPx: 531,
    bgColorHex: 'ffffff',
    prompt: '将背景替换为纯白色（#FFFFFF），将服装替换为纯色无图案上衣，均匀柔和正面光线，输出小二寸（35×45mm）证件照效果，符合ICAO生物特征标准。重新构图为标准证件照：头部（下巴到头顶）占照片高度约2/3，画面仅包含头部和颈部到领口衣领处，不露出肩膀以下，头顶距照片顶边留约5%空白，人脸水平居中。保持人物的脸部五官完全不变。'
  },
  { 
    id: 'ncreExam', 
    displayName: '计算机等级', 
    sizeLabel: '32×40 mm', 
    isPro: true,
    widthPx: 378,
    heightPx: 472,
    bgColorHex: 'ffffff',
    prompt: '将背景替换为纯白色（#FFFFFF），将服装替换为正式商务装，均匀柔和正面光线，输出全国计算机等级考试（NCRE）标准报名照片效果。重新构图为标准证件照：头部（下巴到头顶）占照片高度约2/3，画面仅包含头部和颈部到领口衣领处，不露出肩膀以下，头顶距照片顶边留约5%空白，人脸水平居中。保持人物的脸部五官完全不变。'
  }
])

// 初始化默认选择第一个规格
selectedSpec.value = specs.value[0]

// 首页分类卡跳转联动：onLoad 读取 specId 预选对应规格
// 仅预选免费规格；Pro 规格需订阅状态加载后由用户自行点选（避免未订阅时静默选中付费项）
onLoad((options) => {
  const specId = options && options.specId
  if (!specId) return
  const matched = specs.value.find((spec) => spec.id === specId)
  if (matched && !matched.isPro) {
    selectedSpec.value = matched
    isCustomSize.value = false
    showCustomSizePanel.value = false
    // 预选规格位于折叠区(前4个之外)时展开列表,保证选中态可见
    if (specs.value.indexOf(matched) >= 4) {
      showAll.value = true
    }
  }
})

const displayedSpecs = computed(() => {
  return showAll.value ? specs.value : specs.value.slice(0, 4)
})

// Pro选项数据（使用i18n）
// 选项 chips 统一为纯文字标签 + 选中态样式（不再使用 emoji 图标）
const beautyLevels = computed(() => [
  { id: 'natural', displayName: t('creation.natural'), isPro: false },
  { id: 'lightEnhance', displayName: t('creation.lightEnhance'), isPro: true },
  { id: 'professional', displayName: t('creation.proRetouch'), isPro: true }
])

const attires = computed(() => [
  { id: 'keepOriginal', displayName: t('creation.keepOriginal'), isPro: false },
  { id: 'darkSuit', displayName: t('creation.darkSuit'), isPro: true },
  { id: 'navySuit', displayName: t('creation.navySuit'), isPro: true },
  { id: 'whiteShirt', displayName: t('creation.whiteShirt'), isPro: true },
  { id: 'professionalBlouse', displayName: t('creation.professionalBlouse'), isPro: true }
])

const hairs = computed(() => [
  { id: 'keepOriginal', displayName: t('creation.keepOriginal'), isPro: false },
  { id: 'tidyUp', displayName: t('creation.tidyUp'), isPro: true }
])

const backgrounds = computed(() => [
  { id: 'specDefault', displayName: t('creation.default'), swatchColor: null, isPro: false },
  { id: 'pureWhite', displayName: t('creation.pureWhite'), swatchColor: '#FFFFFF', isPro: true },
  { id: 'lightBlue', displayName: t('creation.lightBlue'), swatchColor: '#D4E9F7', isPro: true },
  { id: 'lightGray', displayName: t('creation.lightGray'), swatchColor: '#E8E8E8', isPro: true },
  { id: 'red', displayName: t('creation.red'), swatchColor: '#D03030', isPro: true }
])

const accessories = computed(() => [
  { id: 'keepAsIs', displayName: t('creation.keepAsIs'), isPro: false },
  { id: 'removeGlasses', displayName: t('creation.removeGlasses'), isPro: true }
])

const photoOptions = ref({
  beauty: 'natural',
  attire: 'keepOriginal',
  hair: 'keepOriginal',
  background: 'specDefault',
  accessories: 'keepAsIs'
})

const getOptionDisplayName = (options, selectedId) => {
  return options.find((option) => option.id === selectedId)?.displayName || '未选择'
}

// 方法
const goBack = () => {
  uni.navigateBack()
}

const navigateToHistory = () => {
  uni.navigateTo({
    url: '/pages/history/history'
  })
}

const navigateToSubscription = () => {
  if (!paymentEnabled) {
    uni.showToast({
      title: t('creation.toast.purchaseUnavailable'),
      icon: 'none'
    })
    return
  }
  uni.navigateTo({
    url: '/pages/subscription/subscription'
  })
}

// Pro 锁定项点击：先简述会员权益，确认后再跳订阅页
const promptProUpgrade = () => {
  if (!paymentEnabled) {
    uni.showToast({
      title: t('creation.toast.purchaseUnavailable'),
      icon: 'none'
    })
    return
  }
  uni.showModal({
    title: t('creation.proLock.title'),
    content: t('creation.proLock.content'),
    confirmText: t('creation.proLock.confirm'),
    cancelText: t('creation.proLock.cancel'),
    success: (res) => {
      if (res.confirm) {
        uni.navigateTo({
          url: '/pages/subscription/subscription'
        })
      }
    }
  })
}

const chooseFromAlbum = () => {
  uni.chooseImage({
    count: 1,
    sizeType: ['compressed', 'original'],
    sourceType: ['album'],
    success: (res) => {
      const tempFilePath = res.tempFilePaths[0]
      // 压缩图片
      uni.compressImage({
        src: tempFilePath,
        quality: 80,
        success: (compressRes) => {
          inputImage.value = compressRes.tempFilePath
          outputImage.value = null
          outputProduceId.value = ''
          // 保留用户已选规格（含 specId 预选），无选择时兜底第一个规格
          if (!selectedSpec.value) selectedSpec.value = specs.value[0]
          markStepReached(2) // 照片就绪，进入"选择场景"
        },
        fail: () => {
          // 压缩失败则使用原图
          inputImage.value = tempFilePath
          outputImage.value = null
          outputProduceId.value = ''
          if (!selectedSpec.value) selectedSpec.value = specs.value[0]
          markStepReached(2)
        }
      })
    },
    fail: (err) => {
      uni.showToast({
        title: t('creation.toast.chooseImageFailed'),
        icon: 'none'
      })
    }
  })
}

const takePhoto = () => {
  uni.chooseImage({
    count: 1,
    sizeType: ['compressed'],
    sourceType: ['camera'],
    camera: 'back',
    success: (res) => {
      const tempFilePath = res.tempFilePaths[0]
      // 压缩图片
      uni.compressImage({
        src: tempFilePath,
        quality: 80,
        success: (compressRes) => {
          inputImage.value = compressRes.tempFilePath
          outputImage.value = null
          outputProduceId.value = ''
          if (!selectedSpec.value) selectedSpec.value = specs.value[0]
          markStepReached(2)
        },
        fail: () => {
          inputImage.value = tempFilePath
          outputImage.value = null
          outputProduceId.value = ''
          if (!selectedSpec.value) selectedSpec.value = specs.value[0]
          markStepReached(2)
        }
      })
    },
    fail: (err) => {
      uni.showToast({
        title: t('creation.toast.takePhotoFailed'),
        icon: 'none'
      })
    }
  })
}

const showPhotoSourceDialog = () => {
  uni.showActionSheet({
    itemList: [t('creation.photoSource.album'), t('creation.photoSource.camera')],
    success: (res) => {
      if (res.tapIndex === 0) {
        chooseFromAlbum()
      } else if (res.tapIndex === 1) {
        takePhoto()
      }
    }
  })
}

const showPhotoChangeDialog = () => {
  uni.showActionSheet({
    itemList: [t('creation.photoSource.album'), t('creation.photoSource.camera'), t('creation.photoSource.clear')],
    success: (res) => {
      if (res.tapIndex === 0) {
        chooseFromAlbum()
      } else if (res.tapIndex === 1) {
        takePhoto()
      } else if (res.tapIndex === 2) {
        clearPhoto()
      }
    }
  })
}

const clearPhoto = () => {
  inputImage.value = null
  outputImage.value = null
  outputProduceId.value = ''
  currentStep.value = 1 // 清除照片后回到"上传照片"步骤
}

const regeneratePhoto = () => {
  outputImage.value = null
  outputProduceId.value = ''
  currentStep.value = 2
}

const selectSpec = (spec) => {
  if (spec.isPro && !isSubscribed.value) {
    promptProUpgrade()
    return
  }
  selectedSpec.value = spec
  isCustomSize.value = false
  showCustomSizePanel.value = false
  // 已上传照片时，选择规格即激活"选择场景"步骤
  if (inputImage.value) markStepReached(2)
}

const selectCustomSize = () => {
  if (!isSubscribed.value) {
    promptProUpgrade()
    return
  }
  showCustomSizePanel.value = !showCustomSizePanel.value
}

const applyCustomSize = () => {
  const widthMM = Number(customSize.value.width)
  const heightMM = Number(customSize.value.height)
  if (
    !Number.isFinite(widthMM) ||
    !Number.isFinite(heightMM) ||
    widthMM < 10 ||
    widthMM > 300 ||
    heightMM < 10 ||
    heightMM > 300
  ) {
    uni.showToast({
      title: t('creation.toast.invalidCustomSize'),
      icon: 'none'
    })
    return
  }

  const normalizedWidth = Math.round(widthMM * 10) / 10
  const normalizedHeight = Math.round(heightMM * 10) / 10
  customSize.value.width = String(normalizedWidth)
  customSize.value.height = String(normalizedHeight)
  selectedSpec.value = {
    id: 'customSize',
    displayName: '自定义尺寸',
    sizeLabel: `${normalizedWidth}×${normalizedHeight} mm`,
    isPro: true,
    widthPx: Math.round((normalizedWidth / 25.4) * 300),
    heightPx: Math.round((normalizedHeight / 25.4) * 300),
    bgColorHex: 'ffffff',
    prompt: `生成 ${normalizedWidth}×${normalizedHeight}mm 的标准证件照。重新构图为标准证件照：头部（下巴到头顶）占照片高度约2/3，画面仅包含头部和颈部到领口衣领处，头顶保留适当空白，人脸水平居中。保持人物脸部五官完全不变。`
  }
  isCustomSize.value = true
  showCustomSizePanel.value = false
  if (inputImage.value) markStepReached(2)
  uni.showToast({
    title: t('creation.toast.customSizeApplied', { size: `${normalizedWidth}×${normalizedHeight}` }),
    icon: 'success'
  })
}

const toggleShowAll = () => {
  showAll.value = !showAll.value
}

const toggleProOptions = () => {
  isProOptionsExpanded.value = !isProOptionsExpanded.value
}

const selectBeauty = (level) => {
  if (level.isPro && !isSubscribed.value) {
    promptProUpgrade()
    return
  }
  photoOptions.value.beauty = level.id
}

const selectAttire = (attire) => {
  if (attire.isPro && !isSubscribed.value) {
    promptProUpgrade()
    return
  }
  photoOptions.value.attire = attire.id
}

const selectHair = (hair) => {
  if (hair.isPro && !isSubscribed.value) {
    promptProUpgrade()
    return
  }
  photoOptions.value.hair = hair.id
}

const selectBackground = (bg) => {
  if (bg.isPro && !isSubscribed.value) {
    promptProUpgrade()
    return
  }
  photoOptions.value.background = bg.id
}

const selectAccessories = (acc) => {
  if (acc.isPro && !isSubscribed.value) {
    promptProUpgrade()
    return
  }
  photoOptions.value.accessories = acc.id
}

const generatePhoto = async () => {
  if (!inputImage.value || isGenerating.value) return
  
  if (!selectedSpec.value) {
    uni.showToast({
      title: t('creation.toast.selectSpecFirst'),
      icon: 'none'
    })
    return
  }

  // 检查是否有足够的生成次数
  const status = await paymentAPI.getRemainingAttempts()
  if (status.totalAttempts <= 0) {
    // 次数耗尽：弹窗说明并引导去购买（取消则留在当前页）
    if (paymentEnabled) {
      uni.showModal({
        title: t('creation.noAttempts.title'),
        content: t('creation.noAttempts.content'),
        confirmText: t('creation.noAttempts.confirm'),
        cancelText: t('creation.noAttempts.cancel'),
        success: (res) => {
          if (res.confirm) {
            uni.navigateTo({
              url: '/pages/subscription/subscription'
            })
          }
        }
      })
    } else {
      uni.showToast({
        title: t('creation.toast.purchaseUnavailable'),
        icon: 'none'
      })
    }
    return
  }

  // 判断是否使用Pro功能
  const hasProOptions = photoOptions.value.beauty !== 'natural' ||
                        photoOptions.value.attire !== 'keepOriginal' ||
                        photoOptions.value.hair !== 'keepOriginal' ||
                        photoOptions.value.accessories !== 'keepAsIs' ||
                        photoOptions.value.background !== 'specDefault' ||
                        selectedSpec.value.isPro

  // 确定使用哪种次数
  let useProAttempts = false
  if (hasProOptions && status.proAttempts > 0) {
    useProAttempts = true
  } else if (!hasProOptions && status.freeAttempts > 0) {
    useProAttempts = false
  } else if (hasProOptions && status.proAttempts <= 0 && status.freeAttempts > 0) {
    // 有Pro选项但没有Pro次数，询问是否使用免费次数
    const useFree = await new Promise((resolve) => {
      uni.showModal({
        title: t('creation.proAttemptFallback.title'),
        content: t('creation.proAttemptFallback.content'),
        success: (res) => resolve(res.confirm)
      })
    })

    if (!useFree) return
    useProAttempts = false
  } else {
    uni.showToast({
      title: t('creation.toast.noAttempts'),
      icon: 'none'
    })
    return
  }

  console.log('=== 生成开始 ===')
  console.log('当前photoOptions:', JSON.stringify(photoOptions.value, null, 2))
  console.log('selectedSpec:', selectedSpec.value)
  console.log('isSubscribed:', isSubscribed.value)

  isGenerating.value = true
  currentStep.value = 3 // 生成开始时进入AI优化步骤

  try {
    // 扣除对应的次数
    const success = await paymentAPI.useAttempt(useProAttempts ? 'pro' : 'free')
    if (!success) {
      throw new Error(t('creation.toast.deductFailed'))
    }

    // 1. 将图片转换为base64
    const base64Image = await geminiAPI.imageToBase64(inputImage.value)

    // 2. 构建请求参数，使用选定规格的专用prompt
    const params = {
      image: base64Image,
      prompt: selectedSpec.value.prompt,
      tier: useProAttempts && hasProOptions ? 'pro' : 'free',
      specWidth: selectedSpec.value.widthPx,
      specHeight: selectedSpec.value.heightPx,
      specBgColor: selectedSpec.value.bgColorHex
    }

    // 3. 添加Pro选项提示词
    if (photoOptions.value.beauty !== 'natural') {
      const beautyPrompts = {
        lightEnhance: '轻度美颜，保持自然',
        professional: '专业修图，提升质感'
      }
      params.cosmeticPrompt = beautyPrompts[photoOptions.value.beauty]
    }

    // 添加服装选项
    if (photoOptions.value.attire !== 'keepOriginal') {
      const attirePrompts = {
        darkSuit: '替换为深色商务西装',
        navySuit: '替换为海军蓝西装',
        whiteShirt: '替换为白衬衫',
        professionalBlouse: '替换为职业女装'
      }
      if (attirePrompts[photoOptions.value.attire]) {
        params.attirePrompt = attirePrompts[photoOptions.value.attire]
      }
    }

    // 添加发型选项
    if (photoOptions.value.hair !== 'keepOriginal') {
      const hairPrompts = {
        tidyUp: '整理发型，保持整洁'
      }
      if (hairPrompts[photoOptions.value.hair]) {
        params.hairPrompt = hairPrompts[photoOptions.value.hair]
      }
    }

    // 添加配饰选项
    if (photoOptions.value.accessories !== 'keepAsIs') {
      const accessoryPrompts = {
        removeGlasses: '完全移除眼镜，修复眼部区域，保持自然外观，确保没有眼镜痕迹或反光'
      }
      if (accessoryPrompts[photoOptions.value.accessories]) {
        params.accessoryPrompt = accessoryPrompts[photoOptions.value.accessories]
        console.log('配饰选项:', photoOptions.value.accessories, '提示词:', params.accessoryPrompt)
      }
    }

    // 添加背景选项
    if (photoOptions.value.background !== 'specDefault') {
      const backgroundPrompts = {
        pureWhite: '将背景替换为纯白色（#FFFFFF）',
        lightBlue: '将背景替换为浅蓝色（#D4E9F7）',
        lightGray: '将背景替换为浅灰色（#E8E8E8）',
        red: '将背景替换为红色（#D03030）'
      }
      if (backgroundPrompts[photoOptions.value.background]) {
        params.backgroundPrompt = backgroundPrompts[photoOptions.value.background]
      }
    }

    // 4. 调用API生成
    const generatedResult = await geminiAPI.generateIDPhoto(params)

    // 5. 保存为临时文件
    const tempFilePath = await geminiAPI.saveBase64Image(generatedResult.image)

    // 6. 显示结果
    outputImage.value = tempFilePath
    outputProduceId.value = generatedResult.produceId
    currentStep.value = 4 // 生成成功时进入下载保存步骤
    await loadUserStatus()

    // 7. 保存到历史记录
    try {
      await historyAPI.addRecord({
        imagePath: tempFilePath,
        specId: selectedSpec.value.id,
        specName: selectedSpec.value.displayName,
        sizeLabel: selectedSpec.value.sizeLabel,
        isCustomSize: isCustomSize.value
      })
    } catch (err) {
      console.error('保存历史记录失败:', err)
      // 不影响主流程，静默失败
    }

    uni.showToast({
      title: t('creation.toast.generateSuccess'),
      icon: 'success'
    })

    // 8. 跳转到结果页面（redirectTo 用 result 替换当前 creation，页面栈深度恒定，返回即回首页）
    const specInfo = {
      id: selectedSpec.value.id,
      name: selectedSpec.value.displayName,
      sizeLabel: selectedSpec.value.sizeLabel,
      widthPx: selectedSpec.value.widthPx,
      heightPx: selectedSpec.value.heightPx,
      isCustomSize: isCustomSize.value
    }

    // 直接传递图片路径，不进行编码
    uni.redirectTo({
      url: `/pages/result/result?originalImage=${inputImage.value}&generatedImage=${tempFilePath}&produceId=${generatedResult.produceId}&specInfo=${encodeURIComponent(JSON.stringify(specInfo))}&createdAt=${Date.now()}`
    })
  } catch (error) {
    console.error('生成失败:', error)
    currentStep.value = 2 // 生成失败时回到选择场景步骤
    uni.showToast({
      title: error.message || t('creation.toast.generateFailed'),
      icon: 'none',
      duration: 3000
    })
  } finally {
    // 成功路径已先发起 redirectTo 再走到这里复位，不存在可重复点击的窗口
    isGenerating.value = false
  }
}

// 相册保存失败统一处理：权限被拒时引导用户去设置开启，其余情况提示保存失败
const handleSaveAlbumFail = (err) => {
  const errMsg = (err && err.errMsg) || ''
  if (errMsg.indexOf('auth deny') !== -1 || errMsg.indexOf('auth denied') !== -1 || errMsg.indexOf('authorize') !== -1) {
    uni.showModal({
      title: t('creation.albumAuth.title'),
      content: t('creation.albumAuth.content'),
      confirmText: t('creation.albumAuth.confirm'),
      cancelText: t('creation.albumAuth.cancel'),
      success: (res) => {
        if (res.confirm) {
          uni.openSetting()
        }
      }
    })
  } else {
    console.error('保存到相册失败:', err)
    uni.showToast({
      title: t('result.saveFailed'),
      icon: 'none'
    })
  }
}

const saveImage = async () => {
  try {
    const confirmed = await geminiAPI.requestUnmarkedExport(
      outputProduceId.value,
      'photo'
    )
    if (!confirmed) return
  } catch (error) {
    uni.showToast({ title: error.message || t('creation.toast.exportUnavailable'), icon: 'none' })
    return
  }
  uni.saveImageToPhotosAlbum({
    filePath: outputImage.value,
    success: () => {
      uni.showToast({
        title: t('result.saved'),
        icon: 'success'
      })
    },
    fail: (err) => {
      handleSaveAlbumFail(err)
    }
  })
}

const showPrintLayout = async () => {
  if (!outputImage.value) {
    uni.showToast({
      title: t('creation.toast.generateFirst'),
      icon: 'none'
    })
    return
  }

  if (!selectedSpec.value) {
    uni.showToast({
      title: t('creation.toast.selectSpecFirst'),
      icon: 'none'
    })
    return
  }

  uni.showActionSheet({
    itemList: [t('creation.paperSizes.fiveInch'), t('creation.paperSizes.sixInch'), t('creation.paperSizes.sevenInch')],
    success: async (res) => {
      const paperSizes = [
        printLayoutAPI.PrintPaperSize.FIVE_INCH,
        printLayoutAPI.PrintPaperSize.SIX_INCH,
        printLayoutAPI.PrintPaperSize.SEVEN_INCH
      ]
      const selectedPaper = paperSizes[res.tapIndex]
      try {
        const confirmed = await geminiAPI.requestUnmarkedExport(
          outputProduceId.value,
          'print-layout'
        )
        if (!confirmed) return
      } catch (error) {
        uni.showToast({ title: error.message || t('creation.toast.exportUnavailable'), icon: 'none' })
        return
      }

      uni.showLoading({
        title: t('creation.toast.printRendering')
      })

      try {
        // 计算布局
        const photoSizeMM = {
          width: selectedSpec.value.widthPx / 300 * 25.4,
          height: selectedSpec.value.heightPx / 300 * 25.4
        }
        const layout = printLayoutAPI.calculateLayout(photoSizeMM, selectedPaper)

        // 生成排版图片
        const layoutImagePath = await printLayoutAPI.renderLayout(
          outputImage.value,
          layout,
          true,
          outputProduceId.value
        )

        // 保存到相册
        uni.saveImageToPhotosAlbum({
          filePath: layoutImagePath,
          success: () => {
            uni.hideLoading()
            uni.showToast({
              title: t('creation.toast.printSavedCount', { count: layout.totalCount }),
              icon: 'success',
              duration: 2000
            })
          },
          fail: (err) => {
            uni.hideLoading()
            handleSaveAlbumFail(err)
          }
        })
      } catch (error) {
        uni.hideLoading()
        console.error('生成排版失败:', error)
        uni.showToast({
          title: t('result.printFailed'),
          icon: 'none'
        })
      }
    }
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

/* 生成流程头部 */
.generation-header {
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
  gap: 8px;
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
  border-radius: 8px;
  transition: background-color 0.15s ease;
}

.back-btn:active {
  background-color: var(--color-bg-secondary);
}

.header-title {
  font-size: 17px;
  font-weight: 700;
  color: var(--color-ink-black);
  letter-spacing: -0.3px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.header-right {
  display: flex;
  align-items: center;
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
  transition: background-color 0.15s ease;
}

.icon-btn:active {
  background-color: var(--color-bg-secondary);
}

.subscription-btn {
  height: 34px;
  min-width: 42px;
  padding: 0 10px;
  box-sizing: border-box;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: var(--color-ink-fill);
  border: 1px solid var(--color-ink-black);
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.subscription-text {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.5px;
  color: var(--color-ink-fill-foreground);
}

/* 滚动内容 */
.scroll-content {
  flex: 1;
  padding: 0 0 110px;
  overflow-y: auto;
}

/* 进度步骤 */
.progress-steps {
  padding: 14px 20px;
  background-color: #ffffff;
  border-bottom: 1px solid #e5e5e5;
}

.steps-container {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.step-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 5px;
  flex: 1;
  position: relative;
}

.step-item:not(:last-child)::after {
  content: '';
  position: absolute;
  top: 14px;
  right: -50%;
  left: 50%;
  height: 1.5px;
  background-color: #e5e5e5;
  z-index: 1;
}

.step-item.active:not(:last-child)::after {
  background-color: var(--color-sky-blue);
}

.step-circle {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #e5e5e5;
  position: relative;
  z-index: 2;
}

.step-item.active .step-circle {
  background-color: var(--color-sky-blue);
}

.step-item.completed .step-circle {
  background-color: var(--color-sky-blue);
}

.step-number {
  font-size: 12px;
  font-weight: 700;
  color: #999999;
}

.step-item.active .step-number {
  color: #ffffff;
}

.step-title {
  font-size: 10px;
  color: #999999;
  text-align: center;
}

.step-item.active .step-title {
  color: var(--color-sky-blue);
}

/* Hero区域 */
.hero-section {
  padding: 20px 16px;
  background: transparent;
  box-shadow: none;
  border: none;
}

.upload-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 14px;
  padding: 36px 24px;
  background: rgba(36, 100, 200, 0.03);
  border: 1.5px dashed rgba(36, 100, 200, 0.35);
  border-radius: 12px;
}

.upload-icon {
  width: 70px;
  height: 70px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(36, 100, 200, 0.10);
  border-radius: 50%;
  font-size: 44px;
  color: var(--color-sky-blue);
}

.upload-title {
  font-size: 16px;
  font-weight: 600;
  color: #1a1a1a;
  text-align: center;
}

.upload-subtitle {
  font-size: 12px;
  color: #8c8c8c;
  text-align: center;
}

.upload-tips {
  display: flex;
  align-items: center;
  gap: 4px;
}

.tips-text {
  font-size: 11px;
  color: #8c8c8c;
}

.upload-buttons {
  display: flex;
  gap: 12px;
  margin-top: 8px;
}

.upload-btn {
  padding: 12px 24px;
  border-radius: 8px;
  transition: all 0.15s ease;
}

.upload-btn.primary {
  background-color: var(--color-sky-blue);
  border: none;
}

.upload-btn.secondary {
  background-color: transparent;
  border: 1px solid var(--color-sky-blue);
}

.btn-text {
  font-size: 14px;
  font-weight: 500;
}

.upload-btn.primary .btn-text {
  color: #ffffff;
}

.upload-btn.secondary .btn-text {
  color: var(--color-sky-blue);
}

.upload-btn:active {
  transform: scale(0.96);
}

.image-preview {
  position: relative;
  max-width: 100%;
  clear: both;
  overflow: hidden;
  background: transparent;
  border: none;
  box-shadow: none;
  filter: none;
  padding: 8px 0;
  border: 1.5px dashed rgba(36, 100, 200, 0.3);
  border-radius: 12px;
  background: rgba(36, 100, 200, 0.02);
}

.preview-image {
  width: 100%;
  max-height: 200px;
  border-radius: 12px;
  object-fit: contain;
  box-shadow: none !important;
  display: block;
  background: transparent;
  border: none;
  filter: none;
  -webkit-box-shadow: none !important;
  -moz-box-shadow: none !important;
}

.change-photo-btn {
  position: absolute;
  bottom: 10px;
  right: 10px;
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 5px 10px;
  background: rgba(36, 100, 200, 0.85);
  border-radius: 20px;
  backdrop-filter: blur(10px);
}

.change-photo-text {
  font-size: 11px;
  color: #ffffff;
  font-weight: 500;
}

/* 操作按钮组 */
.action-buttons {
  display: flex;
  gap: 12px;
  padding: 0 16px;
  margin-top: 16px;
}

.regenerate-btn {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 14px 0;
  background: transparent !important;
  border: 1.5px solid var(--color-sky-blue);
  border-radius: 10px;
  transition: all 0.2s ease;
  color: var(--color-sky-blue) !important;
}

.regenerate-btn:active {
  background: rgba(36, 100, 200, 0.05) !important;
}

.regenerate-icon {
  font-size: 13px;
  color: var(--color-sky-blue) !important;
}

.regenerate-text {
  font-size: 14px;
  font-weight: 500;
  color: var(--color-sky-blue) !important;
}

.save-btn {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 14px 0;
  background: linear-gradient(90deg, var(--color-sky-blue), var(--color-sky-blue-mid)) !important;
  border: none;
  border-radius: 10px;
  transition: all 0.2s ease;
  color: #ffffff !important;
}

.save-btn:active {
  transform: scale(0.98);
}

.save-icon {
  font-size: 13px;
  color: #ffffff !important;
}

.save-text {
  font-size: 14px;
  font-weight: 500;
  color: #ffffff !important;
}

/* 规格选择 */
.section {
  padding: 20px 16px;
  border-bottom: 1px solid #f0f0f0;
}

.section-label {
  font-size: 15px;
  font-weight: 600;
  color: #333333;
  margin-bottom: 16px;
}

.spec-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}

.spec-item {
  padding: 16px;
  background-color: #ffffff;
  border: 1.5px solid #e5e5e5;
  border-radius: 12px;
  position: relative;
  transition: all 0.15s ease;
}

.spec-item.active {
  border-color: var(--color-sky-blue);
  background-color: rgba(36, 100, 200, 0.05);
}

.spec-item.locked {
  opacity: 0.6;
}

.spec-item:active {
  transform: scale(0.98);
}

.spec-content {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.spec-name {
  font-size: 14px;
  font-weight: 500;
  color: #333333;
}

.spec-size {
  font-size: 12px;
  color: #666666;
}

.lock-icon {
  position: absolute;
  top: 12px;
  right: 12px;
  font-size: 14px;
}

.upload-buttons {
  display: flex;
  gap: 12px;
  margin-top: 8px;
}

.upload-btn {
  padding: 14px 28px;
  border-radius: 10px;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.upload-btn:active {
  transform: scale(0.96);
}

.upload-btn.primary {
  background: linear-gradient(135deg, var(--color-sky-blue), var(--color-sky-blue-mid));
  box-shadow: 0 4px 12px rgba(36, 100, 200, 0.3);
}

.upload-btn.secondary {
  background-color: var(--color-bg-primary);
  border: 1.5px solid var(--color-ink-black);
}

.btn-text {
  font-size: 15px;
  font-weight: 600;
  color: #FFFFFF;
  letter-spacing: 0.2px;
}

.upload-btn.secondary .btn-text {
  color: var(--color-ink-black);
}

.image-preview {
  position: relative;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.preview-image {
  width: 100%;
  height: 320px;
  background-color: var(--color-bg-secondary);
}

.change-photo-btn {
  position: absolute;
  bottom: 20px;
  left: 50%;
  transform: translateX(-50%);
  padding: 10px 20px;
  background-color: rgba(0, 0, 0, 0.65);
  border-radius: 24px;
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
}

.change-photo-text {
  font-size: 13px;
  font-weight: 600;
  color: #FFFFFF;
  letter-spacing: 0.2px;
}

/* Section */
.section {
  padding: 0 0 24px;
}

/* 规格选择 */
.spec-selector {
  border: 1.5px solid var(--color-ink-black);
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.section-label {
  display: block;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 1px;
  text-transform: uppercase;
  color: var(--color-branch-gray);
  padding: 12px 16px;
  background-color: var(--color-bg-secondary);
}

.spec-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 0;
}

.spec-item {
  position: relative;
  padding: 18px 16px;
  min-height: 88px;
  background-color: var(--color-bg-primary);
  border-right: 1px solid var(--color-ink-black);
  border-bottom: 1px solid var(--color-ink-black);
  transition: background-color 0.15s ease;
}

.spec-item:nth-child(2n) {
  border-right: none;
}

.spec-item.active {
  background-color: var(--color-paper-tan);
}

.spec-item.locked {
  opacity: 0.5;
}

.spec-content {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.spec-name {
  font-size: 14px;
  font-weight: 600;
  color: var(--color-ink-black);
  letter-spacing: -0.2px;
}

.spec-size {
  font-size: 12px;
  font-weight: 400;
  letter-spacing: 0.3px;
  color: var(--color-ink-black);
}

.lock-icon {
  position: absolute;
  top: 16px;
  right: 16px;
  font-size: 12px;
  color: var(--color-branch-gray);
}

.expand-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 14px;
  border-top: 1px solid var(--color-ink-black);
  background-color: var(--color-bg-primary);
  transition: background-color 0.15s ease;
}

.expand-btn:active {
  background-color: var(--color-bg-secondary);
}

.expand-text {
  font-size: 13px;
  font-weight: 600;
  color: var(--color-ink-black);
  letter-spacing: 0.2px;
}

.icon-down {
  font-size: 12px;
  transition: transform 0.25s ease-in-out;
}

.icon-up {
  transform: rotate(180deg);
}

.custom-size-row {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 16px;
  border-top: 1px solid var(--color-ink-black);
  background-color: var(--color-bg-primary);
  transition: background-color 0.15s ease;
}

.custom-size-row:active {
  background-color: var(--color-bg-secondary);
}

.custom-size-row.active {
  background: rgba(36, 100, 200, 0.08);
  box-shadow: inset 4px 0 0 var(--color-sky-blue);
}

.custom-size-row.locked {
  opacity: 0.62;
}

.custom-size-content {
  display: flex;
  align-items: center;
  gap: 8px;
}

.custom-size-copy {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.custom-size-name {
  font-size: 14px;
  font-weight: 600;
  color: var(--color-ink-black);
  letter-spacing: -0.2px;
}

.custom-size-desc {
  font-size: 11px;
  color: var(--color-branch-gray);
}

.custom-selected-mark {
  display: flex;
  align-items: center;
  gap: 3px;
}

.custom-selected-text {
  font-size: 12px;
  font-weight: 700;
  color: var(--color-sky-blue);
}

.custom-size-panel {
  padding: 16px;
  border-top: 1px solid var(--color-ink-black);
  background: rgba(36, 100, 200, 0.04);
}

.dimension-fields {
  display: flex;
  align-items: flex-end;
  gap: 10px;
}

.dimension-field {
  flex: 1;
}

.dimension-label {
  display: block;
  margin-bottom: 7px;
  font-size: 12px;
  font-weight: 600;
  color: var(--color-ink-black);
}

.dimension-input-wrap {
  display: flex;
  align-items: center;
  height: 44px;
  padding: 0 12px;
  background: var(--color-bg-primary);
  border: 1.5px solid #9aa7b8;
  border-radius: 8px;
}

.dimension-input {
  flex: 1;
  min-width: 0;
  height: 44px;
  font-size: 16px;
  font-weight: 700;
  color: var(--color-ink-black);
}

.dimension-unit {
  font-size: 12px;
  color: var(--color-branch-gray);
}

.dimension-symbol {
  padding-bottom: 13px;
  font-size: 18px;
  color: var(--color-branch-gray);
}

.dimension-tip {
  display: block;
  margin-top: 8px;
  font-size: 11px;
  color: var(--color-branch-gray);
}

.apply-custom-size-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 44px;
  margin-top: 14px;
  border-radius: 8px;
  background: var(--color-sky-blue);
  color: #ffffff;
  font-size: 14px;
  font-weight: 700;
}

.apply-custom-size-btn:active {
  transform: scale(0.98);
  background: #1d55ab;
}

.pro-tag {
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.8px;
  color: var(--color-ink-fill-foreground);
  padding: 3px 8px;
  background-color: var(--color-ink-fill);
  border-radius: 4px;
}

/* Pro选项 */
.pro-options {
  border: 1.5px solid var(--color-ink-black);
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.pro-header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 16px;
  background-color: var(--color-bg-secondary);
  transition: background-color 0.15s ease;
}

.pro-header:active {
  background-color: var(--color-bg-tertiary);
}

.pro-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--color-ink-black);
  letter-spacing: -0.2px;
}

.pro-badge {
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.8px;
  color: var(--color-ink-fill-foreground);
  padding: 3px 8px;
  background-color: var(--color-ink-fill);
  border-radius: 4px;
}

.icon-down {
  margin-left: auto;
  font-size: 12px;
  color: var(--color-branch-gray);
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.icon-down.rotate {
  transform: rotate(-90deg);
}

.pro-content {
  padding: 0 0 16px;
}

.option-category {
  padding: 8px 0;
}

.category-heading {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 0 16px;
  margin-bottom: 8px;
}

.category-title {
  display: block;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.8px;
  text-transform: uppercase;
  color: var(--color-branch-gray);
}

.selected-summary {
  max-width: 65%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 11px;
  font-weight: 600;
  color: var(--color-sky-blue);
}

.option-scroll {
  white-space: nowrap;
}

.option-chips {
  display: flex;
  gap: 10px;
  padding: 4px 16px;
}

.option-chip {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 0 14px;
  min-height: 40px;
  background-color: var(--color-bg-primary);
  border: 1.5px solid var(--color-ink-black);
  border-radius: 8px;
  transition: all 0.2s ease;
}

.option-chip:active {
  transform: scale(0.96);
}

.option-chip.active {
  background: var(--color-sky-blue);
  border-color: #174b9d;
  border-width: 2px;
  box-shadow: 0 3px 9px rgba(36, 100, 200, 0.32);
  transform: translateY(-1px);
}

.option-chip.locked {
  opacity: 0.5;
}

.chip-label {
  font-size: 13px;
  font-weight: 500;
  color: var(--color-ink-black);
  letter-spacing: -0.1px;
}

.option-chip.active .chip-label {
  color: #ffffff;
  font-weight: 700;
}

.selection-check {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 18px;
  height: 18px;
  border-radius: 50%;
  background: #ffffff;
  color: var(--color-sky-blue);
  font-size: 11px;
  font-weight: 900;
}

.color-swatch {
  width: 16px;
  height: 16px;
  border-radius: 3px;
  border: 1px solid rgba(0, 0, 0, 0.2);
}

/* 结果卡片主操作行 */
.result-main-actions {
  display: flex;
  gap: 12px;
  padding: 0 16px;
  margin-bottom: 12px;
}

.regenerate-result-btn {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 14px 0;
  background: transparent;
  border: 1.5px solid var(--color-sky-blue);
  border-radius: 10px;
  transition: all 0.2s ease;
}

.regenerate-result-btn:active {
  background: rgba(36, 100, 200, 0.05);
}

.regenerate-result-text {
  font-size: 14px;
  font-weight: 500;
  color: var(--color-sky-blue);
}

.save-result-btn {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 14px 0;
  background: linear-gradient(90deg, var(--color-sky-blue), var(--color-sky-blue-mid));
  border: none;
  border-radius: 10px;
  transition: all 0.2s ease;
}

.save-result-btn:active {
  transform: scale(0.98);
}

.save-result-text {
  font-size: 14px;
  font-weight: 500;
  color: #ffffff;
}

/* 结果卡片 */
.result-card {
  border: 1.5px solid var(--color-ink-black);
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.result-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 18px 16px;
  border-bottom: 1px solid var(--color-bg-secondary);
  background-color: var(--color-bg-secondary);
}

.aigc-badge {
  flex-shrink: 0;
  padding: 4px 8px;
  border: 1px solid rgba(36, 100, 200, 0.28);
  border-radius: 999px;
  background: rgba(36, 100, 200, 0.08);
  color: var(--color-sky-blue);
  font-size: 11px;
  font-weight: 600;
}

.result-title {
  font-size: 16px;
  font-weight: 700;
  color: var(--color-ink-black);
  letter-spacing: -0.3px;
}

.result-image-container {
  padding: 20px 16px;
  background-color: var(--color-bg-secondary);
}

.result-image {
  width: 100%;
  height: 220px;
  border-radius: 8px;
  background-color: var(--color-bg-primary);
}

.result-actions {
  display: flex;
  gap: 10px;
  padding: 16px;
}

.action-btn {
  flex: 1;
  height: 44px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: var(--color-bg-secondary);
  border: 1px solid var(--color-ink-black);
  border-radius: 8px;
  transition: all 0.2s ease;
}

.action-btn:active {
  transform: scale(0.96);
  background-color: var(--color-bg-tertiary);
}

.action-text {
  font-size: 14px;
  font-weight: 600;
  color: var(--color-ink-black);
  letter-spacing: 0.2px;
}

/* 底部操作栏 */
.bottom-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 16px 20px 28px;
  background-color: #ffffff;
  border-top: 0.5px solid #e5e5e5;
  z-index: 100;
  padding-bottom: calc(28px + env(safe-area-inset-bottom));
}

.generate-btn {
  width: 100%;
  height: 52px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(90deg, var(--color-sky-blue), var(--color-sky-blue-mid));
  border-radius: 12px;
  box-shadow: 0 4px 16px rgba(36, 100, 200, 0.35);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.generate-btn:active {
  transform: scale(0.98);
  box-shadow: 0 2px 8px rgba(36, 100, 200, 0.25);
}

.generate-btn.disabled {
  opacity: 0.6;
  pointer-events: none;
}

.btn-text {
  font-size: 17px;
  font-weight: 700;
  color: #FFFFFF;
  letter-spacing: 0.3px;
}

.generate-footnote {
  font-size: 11px;
  color: #8c8c8c;
  text-align: center;
  margin-top: 6px;
}

/* 生成中全屏遮罩 */
.generating-mask {
  position: fixed;
  inset: 0;
  z-index: 9000;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(15, 23, 42, 0.6);
}

.generating-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  min-width: 200px;
  padding: 28px 32px;
  border-radius: 16px;
  background: var(--color-bg-primary);
  box-shadow: 0 18px 50px rgba(15, 23, 42, 0.2);
}

.generating-spinner {
  width: 36px;
  height: 36px;
  border: 3px solid rgba(36, 100, 200, 0.15);
  border-top-color: var(--color-sky-blue);
  border-radius: 50%;
  animation: generating-spin 0.9s linear infinite;
}

@keyframes generating-spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.generating-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--color-ink-black);
}

.generating-desc {
  font-size: 12px;
  color: var(--color-branch-gray);
}

/* 照片来源对话框 */
.photo-source-dialog {
  background-color: var(--color-bg-primary);
  border-radius: 16px 16px 0 0;
  padding: 8px 0;
}

.dialog-option {
  padding: 18px;
  text-align: center;
  border-bottom: 0.5px solid var(--color-bg-secondary);
  transition: background-color 0.15s ease;
}

.dialog-option:active {
  background-color: var(--color-bg-secondary);
}

.dialog-option.danger {
  color: var(--color-promo-red);
}

.option-text {
  font-size: 17px;
  font-weight: 600;
  color: var(--color-ink-black);
  letter-spacing: 0.2px;
}

.dialog-option.danger .option-text {
  color: var(--color-promo-red);
}
</style>
