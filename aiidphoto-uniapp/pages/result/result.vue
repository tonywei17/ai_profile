<template>
  <view class="page">
    <!-- 状态栏占位 -->
    <view class="status-bar-placeholder" :style="{ height: statusBarHeight + 'px' }"></view>
    
    <!-- 头部 -->
    <view class="result-header">
      <view class="header-left">
        <view class="back-btn" @click="goBack">
          <text>←</text>
        </view>
        <text class="header-title">{{ t('result.title') }}</text>
      </view>
      <view class="header-right" :style="{ paddingRight: headerRightPadding + 'px' }">
        <view class="save-btn" @tap="saveToAlbum">
          <text class="save-text">{{ t('result.save') }}</text>
        </view>
      </view>
    </view>

    <!-- 滚动内容 -->
    <view class="comparison-panel">
      <!-- 对比区域 -->
      <view class="comparison-section">
        <view class="section-heading">
          <text class="section-title">{{ t('result.comparison') }}</text>
          <text class="aigc-badge">AI生成/编辑</text>
        </view>
        <view class="comparison-container">
          <ComparisonSlider 
            :originalImage="originalImage"
            :generatedImage="generatedImage"
            @slider-change="onSliderChange"
          />
        </view>
      </view>
    </view>

    <scroll-view scroll-y class="scroll-content">
      <!-- 操作按钮 -->
      <view class="action-section">
        <view class="action-grid">
          <view class="action-item" @tap="saveToAlbum">
            <view class="action-icon">💾</view>
            <text class="action-label">{{ t('result.save') }}</text>
          </view>
          <view class="action-item" @tap="openPrintLayout">
            <view class="action-icon">🖨️</view>
            <text class="action-label">{{ t('result.print') }}</text>
          </view>
          <view class="action-item" @tap="retakePhoto">
            <view class="action-icon">🔄</view>
            <text class="action-label">{{ t('result.retake') }}</text>
          </view>
        </view>
      </view>

      <!-- 图片信息 -->
      <view class="info-section">
        <text class="section-title">{{ t('result.info') }}</text>
        <view class="info-card">
          <view class="info-row">
            <text class="info-label">{{ t('result.spec') }}</text>
            <text class="info-value">{{ specInfo.name }}</text>
          </view>
          <view class="info-row">
            <text class="info-label">{{ t('result.size') }}</text>
            <text class="info-value">{{ specInfo.sizeLabel }}</text>
          </view>
          <view class="info-row">
            <text class="info-label">{{ t('result.createdAt') }}</text>
            <text class="info-value">{{ formatDate(createdAt) }}</text>
          </view>
        </view>
      </view>
    </scroll-view>

    <canvas
      canvas-id="printCanvas"
      style="position: fixed; top: -9999px; left: -9999px; width: 1500px; height: 2102px;"
    ></canvas>
  </view>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useI18n } from '@/utils/i18n.js'
import ComparisonSlider from '@/components/ComparisonSlider.vue'
import historyAPI from '@/api/history.js'
import printLayoutAPI from '@/api/printLayout.js'
import geminiAPI from '@/api/gemini.js'

// 获取i18n实例
const { t } = useI18n()

// 系统信息
const statusBarHeight = ref(0)
const menuButtonRect = ref({ width: 0, height: 0, top: 0, right: 0, bottom: 0, left: 0 })

// 计算右侧按钮的右边距
const headerRightPadding = computed(() => {
  // #ifdef MP-WEIXIN
  if (menuButtonRect.value.width > 0) {
    return menuButtonRect.value.width + 16
  }
  // #endif
  return 16
})

// 页面数据
const originalImage = ref('')
const generatedImage = ref('')
const produceId = ref('')
const specInfo = ref({})
const createdAt = ref(Date.now())

// 获取页面参数
onMounted(() => {
  console.log('[ResultPage] isolated-comparison-v2')
  const systemInfo = uni.getSystemInfoSync()
  statusBarHeight.value = systemInfo.statusBarHeight || 0
  
  // 获取微信胶囊按钮位置
  // #ifdef MP-WEIXIN
  try {
    const menuRect = uni.getMenuButtonBoundingClientRect()
    menuButtonRect.value = menuRect
  } catch (e) {
    console.error('获取胶囊按钮位置失败:', e)
  }
  // #endif
  
  // 获取页面参数
  const pages = getCurrentPages()
  const currentPage = pages[pages.length - 1]
  const options = currentPage.options
  
  console.log('结果页面参数:', options)
  
  if (options) {
    originalImage.value = options.originalImage || ''
    generatedImage.value = options.generatedImage || ''
    produceId.value = options.produceId || ''
    createdAt.value = parseInt(options.createdAt) || Date.now()
    
    console.log('解析后的原图路径:', originalImage.value)
    console.log('解析后的生成图路径:', generatedImage.value)
    
    // 解析规格信息
    if (options.specInfo) {
      try {
        specInfo.value = JSON.parse(decodeURIComponent(options.specInfo))
      } catch (e) {
        console.error('解析规格信息失败:', e)
        specInfo.value = { name: '证件照', sizeLabel: '1寸' }
      }
    }
  }
})

// 格式化日期
const formatDate = (timestamp) => {
  const date = new Date(timestamp)
  const now = new Date()
  const diff = now - date
  
  if (diff < 60000) {
    return t('result.time.justNow')
  } else if (diff < 3600000) {
    return `${Math.floor(diff / 60000)}${t('result.time.minutesAgo')}`
  } else if (diff < 86400000) {
    return `${Math.floor(diff / 3600000)}${t('result.time.hoursAgo')}`
  } else {
    return `${date.getMonth() + 1}/${date.getDate()}`
  }
}

// 滑块变化
const onSliderChange = (value) => {
  // 可以用于统计或其他处理
  console.log('滑块位置:', value)
}

// 保存到相册
const saveToAlbum = async () => {
  try {
    const confirmed = await geminiAPI.requestUnmarkedExport(
      produceId.value,
      'photo'
    )
    if (!confirmed) return
    // 保存生成的图片到相册
    uni.saveImageToPhotosAlbum({
      filePath: generatedImage.value,
      success: () => {
        uni.showToast({
          title: t('result.saved'),
          icon: 'success'
        })
        
        // 添加到历史记录
        addToHistory()
      },
      fail: (error) => {
        console.error('保存失败:', error)
        uni.showToast({
          title: t('result.saveFailed'),
          icon: 'none'
        })
      }
    })
  } catch (error) {
    console.error('保存异常:', error)
    uni.showToast({
      title: t('result.saveFailed'),
      icon: 'none'
    })
  }
}

// 分享图片
const shareImage = async () => {
  try {
    // #ifdef MP-WEIXIN
    // 微信小程序分享
    uni.showShareMenu({
      withShareTicket: true
    })
    // #endif
    
    // #ifdef H5
    // H5分享：复制图片链接或下载
    if (navigator.share) {
      // 使用Web Share API
      const response = await fetch(generatedImage.value)
      const blob = await response.blob()
      const file = new File([blob], 'id-photo.jpg', { type: 'image/jpeg' })
      
      navigator.share({
        title: 'AI证件照',
        text: '看看我的AI证件照！',
        files: [file]
      }).catch(() => {
        // 如果分享失败，显示下载提示
        uni.showToast({
          title: '请长按图片保存分享',
          icon: 'none'
        })
      })
    } else {
      uni.showToast({
        title: '请长按图片保存分享',
        icon: 'none'
      })
    }
    // #endif
    
    // #ifdef APP-PLUS
    // APP分享：使用原生分享
    uni.share({
      provider: 'weixin',
      type: 2, // 图片分享
      imageUrl: generatedImage.value,
      success: () => {
        uni.showToast({
          title: '分享成功',
          icon: 'success'
        })
      },
      fail: () => {
        uni.showToast({
          title: '分享失败',
          icon: 'none'
        })
      }
    })
    // #endif
    
  } catch (error) {
    console.error('分享失败:', error)
    uni.showToast({
      title: t('result.shareFailed'),
      icon: 'none'
    })
  }
}

// 打开打印排版
const openPrintLayout = () => {
  if (!generatedImage.value) {
    uni.showToast({ title: '暂无可排版图片', icon: 'none' })
    return
  }

  uni.showActionSheet({
    itemList: ['5寸 (89×127)', '6寸 (102×152)', '7寸 (127×178)'],
    success: async (res) => {
      const paperSizes = [
        printLayoutAPI.PrintPaperSize.FIVE_INCH,
        printLayoutAPI.PrintPaperSize.SIX_INCH,
        printLayoutAPI.PrintPaperSize.SEVEN_INCH
      ]
      const selectedPaper = paperSizes[res.tapIndex]
      try {
        const confirmed = await geminiAPI.requestUnmarkedExport(
          produceId.value,
          'print-layout'
        )
        if (!confirmed) return
      } catch (error) {
        uni.showToast({ title: error.message || '暂时无法导出', icon: 'none' })
        return
      }
      const sizeMatch = String(specInfo.value.sizeLabel || '').match(
        /([\d.]+)\s*[×xX]\s*([\d.]+)/
      )
      const photoSizeMM = {
        width:
          Number(specInfo.value.widthPx) > 0
            ? Number(specInfo.value.widthPx) / 300 * 25.4
            : Number(sizeMatch?.[1] || 25),
        height:
          Number(specInfo.value.heightPx) > 0
            ? Number(specInfo.value.heightPx) / 300 * 25.4
            : Number(sizeMatch?.[2] || 35)
      }

      uni.showLoading({ title: '生成排版中...', mask: true })
      try {
        const layout = printLayoutAPI.calculateLayout(photoSizeMM, selectedPaper)
        const printImagePath = await printLayoutAPI.renderLayout(
          generatedImage.value,
          layout,
          true,
          produceId.value
        )
        uni.saveImageToPhotosAlbum({
          filePath: printImagePath,
          success: () => {
            uni.hideLoading()
            uni.showToast({
              title: `已保存${layout.totalCount}张排版照片`,
              icon: 'success',
              duration: 2000
            })
          },
          fail: () => {
            uni.hideLoading()
            uni.showToast({ title: t('result.printFailed'), icon: 'none' })
          }
        })
      } catch (error) {
        uni.hideLoading()
        console.error('生成排版失败:', error)
        uni.showToast({ title: t('result.printFailed'), icon: 'none' })
      }
    }
  })
}

// 重新拍摄
const retakePhoto = () => {
  uni.redirectTo({
    url: '/pages/creation/creation'
  })
}

// 添加到历史记录
const addToHistory = async () => {
  try {
    await historyAPI.addRecord({
      imagePath: generatedImage.value,
      specId: specInfo.value.id || 'default',
      specName: specInfo.value.name || '证件照',
      sizeLabel: specInfo.value.sizeLabel || '1寸',
      isCustomSize: specInfo.value.isCustomSize || false
    })
  } catch (error) {
    console.error('添加历史记录失败:', error)
  }
}

// 返回
const goBack = () => {
  uni.navigateBack()
}
</script>

<style lang="scss" scoped>
.page {
  height: 100vh;
  background-color: var(--color-bg-primary);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* 状态栏占位 */
.status-bar-placeholder {
  width: 100%;
  background-color: var(--color-bg-primary);
}

/* 头部 */
.result-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  background-color: var(--color-bg-primary);
  border-bottom: 0.5px solid var(--color-bg-secondary);
}

.header-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.back-btn {
  width: 44px;
  height: 44px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  color: var(--color-branch-gray);
}

.header-title {
  font-size: 28px;
  font-weight: 700;
  color: var(--color-ink-black);
}

.header-right {
  display: flex;
  align-items: center;
}

.save-btn {
  padding: 8px 12px;
  background-color: var(--color-primary);
  border-radius: 8px;
}

.save-text {
  font-size: 14px;
  font-weight: 500;
  color: white;
}

/* 滚动内容 */
.scroll-content {
  flex: 1;
  min-height: 0;
  box-sizing: border-box;
  padding: 12px 16px 24px;
}

/* 对比区域 */
.comparison-panel {
  flex-shrink: 0;
  box-sizing: border-box;
  padding: 12px 16px 0;
  background-color: var(--color-bg-primary);
}

.comparison-section {
  margin-bottom: 12px;
}

.section-title {
  font-size: 18px;
  font-weight: 600;
  color: var(--color-ink-black);
  margin-bottom: 16px;
}

.section-heading {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 16px;
}

.section-heading .section-title {
  margin-bottom: 0;
}

.aigc-badge {
  flex-shrink: 0;
  padding: 4px 8px;
  border: 1px solid rgba(36, 100, 200, 0.28);
  border-radius: 999px;
  background: rgba(36, 100, 200, 0.08);
  color: #2464c8;
  font-size: 11px;
  font-weight: 600;
}

.comparison-container {
  background-color: var(--color-bg-secondary);
  border-radius: 12px;
  padding: 10px;
  min-height: 300px;
  overflow: hidden;
}

/* 操作区域 */
.action-section {
  margin-bottom: 24px;
}

.action-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}

.action-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 20px;
  background-color: var(--color-bg-secondary);
  border-radius: 12px;
  transition: background-color 0.15s ease;
}

.action-item:active {
  background-color: var(--color-bg-tertiary);
}

.action-icon {
  font-size: 32px;
  margin-bottom: 8px;
}

.action-label {
  font-size: 14px;
  color: var(--color-ink-black);
}

/* 信息区域 */
.info-section {
  margin-bottom: 24px;
}

.info-card {
  background-color: var(--color-bg-secondary);
  border-radius: 12px;
  padding: 16px;
}

.info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 0;
  border-bottom: 0.5px solid var(--color-bg-tertiary);
}

.info-row:last-child {
  border-bottom: none;
}

.info-label {
  font-size: 14px;
  color: var(--color-branch-gray);
}

.info-value {
  font-size: 14px;
  color: var(--color-ink-black);
  font-weight: 500;
}
</style>
