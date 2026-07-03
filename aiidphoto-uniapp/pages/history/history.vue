<template>
  <view class="page">
    <!-- 状态栏占位 -->
    <view class="status-bar-placeholder" :style="{ height: statusBarHeight + 'px' }"></view>
    
    <!-- 历史记录头部 -->
    <view class="history-header">
      <view class="header-left">
        <view class="back-btn" @click="goBack">
          <AppIcon name="back" :size="20" color="var(--color-ink-black)" />
        </view>
        <text class="header-title">{{ t('history.title') }}</text>
      </view>
      <view class="header-right" :style="{ paddingRight: headerRightPadding + 'px' }">
        <view class="clear-btn" @tap="clearAllHistory" v-if="historyList.length > 0">
          <text class="clear-text">{{ t('history.clearAll') }}</text>
        </view>
      </view>
    </view>

    <!-- 滚动内容 -->
    <scroll-view scroll-y class="scroll-content">
      <!-- 加载态 -->
      <view v-if="isLoading" class="loading-state">
        <view class="loading-spinner"></view>
        <text class="loading-text">{{ t('common.loading') }}</text>
      </view>

      <!-- 空状态 -->
      <view v-else-if="historyList.length === 0" class="empty-state">
        <view class="empty-icon">
          <AppIcon name="history" :size="40" color="var(--color-branch-gray)" />
        </view>
        <text class="empty-text">{{ t('history.empty') }}</text>
      </view>

      <!-- 历史记录列表 -->
      <view v-else class="history-list">
        <view 
          v-for="(item, index) in historyList" 
          :key="item.id"
          class="history-item"
          @tap="viewHistoryItem(item)"
        >
          <view class="item-image">
            <image :src="item.imagePath" mode="aspectFill" />
          </view>
          <view class="item-info">
            <text class="item-spec">{{ item.specName }}</text>
            <text class="item-size">{{ item.sizeLabel }}</text>
            <text class="item-date">{{ formatDate(item.createdAt || item.date) }}</text>
          </view>
          <view class="item-actions">
            <view class="action-btn delete" @tap.stop="deleteHistoryItem(item.id)">
              <AppIcon name="trash" :size="18" color="var(--color-branch-gray)" />
            </view>
          </view>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useI18n } from '@/utils/i18n.js'
import historyAPI from '@/api/history.js'
import AppIcon from '@/components/AppIcon.vue'

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

// 历史记录列表
const historyList = ref([])

// 加载态(仅用于首次进入页面,避免先闪"暂无历史记录"空态再出列表)
const isLoading = ref(true)

// 获取系统信息
onMounted(async () => {
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

  // 加载历史记录
  try {
    await loadHistory()
  } finally {
    isLoading.value = false
  }
})

// 加载历史记录
const loadHistory = async () => {
  try {
    const records = await historyAPI.getHistory()
    historyList.value = records
  } catch (error) {
    console.error('加载历史记录失败:', error)
  }
}

// 格式化日期
const formatDate = (timestamp) => {
  const date = new Date(timestamp)
  const now = new Date()
  const diff = now - date
  
  if (diff < 60000) {
    return t('history.time.justNow')
  } else if (diff < 3600000) {
    return `${Math.floor(diff / 60000)}${t('history.time.minutesAgo')}`
  } else if (diff < 86400000) {
    return `${Math.floor(diff / 3600000)}${t('history.time.hoursAgo')}`
  } else if (diff < 604800000) {
    return `${Math.floor(diff / 86400000)}${t('history.time.daysAgo')}`
  } else {
    return `${date.getMonth() + 1}/${date.getDate()}`
  }
}

// 查看历史记录项
const viewHistoryItem = (item) => {
  if (!item.imagePath) {
    uni.showToast({
      title: t('history.imageUnavailable'),
      icon: 'none'
    })
    return
  }

  uni.previewImage({
    current: item.imagePath,
    urls: [item.imagePath],
    fail: () => {
      uni.showToast({
        title: t('history.imageUnavailable'),
        icon: 'none'
      })
    }
  })
}

// 删除历史记录项
const deleteHistoryItem = async (id) => {
  uni.showModal({
    title: t('history.confirmDelete'),
    content: t('history.deleteConfirm'),
    success: async (res) => {
      if (res.confirm) {
        try {
          await historyAPI.deleteRecord(id)
          await loadHistory()
          uni.showToast({
            title: t('history.deleted'),
            icon: 'success'
          })
        } catch (error) {
          console.error('删除失败:', error)
          uni.showToast({
            title: t('history.deleteFailed'),
            icon: 'none'
          })
        }
      }
    }
  })
}

// 清空所有历史记录
const clearAllHistory = () => {
  uni.showModal({
    title: t('history.confirmClear'),
    content: t('history.clearConfirm'),
    success: async (res) => {
      if (res.confirm) {
        try {
          await historyAPI.clearAll()
          await loadHistory()
          uni.showToast({
            title: t('history.cleared'),
            icon: 'success'
          })
        } catch (error) {
          console.error('清空失败:', error)
          uni.showToast({
            title: t('history.clearFailed'),
            icon: 'none'
          })
        }
      }
    }
  })
}

// 返回
const goBack = () => {
  uni.navigateBack()
}
</script>

<style lang="scss" scoped>
.page {
  /* 固定视口高度,让 .scroll-content 的 flex:1 拿到确定高度(空态/加载态居中的前提) */
  height: 100vh;
  background-color: var(--color-bg-primary);
  display: flex;
  flex-direction: column;
}

/* 状态栏占位 */
.status-bar-placeholder {
  width: 100%;
  background-color: var(--color-bg-primary);
}

/* 历史记录头部 */
.history-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--spacing-md) var(--spacing-lg);
  background-color: var(--color-bg-primary);
  border-bottom: 0.5px solid var(--color-bg-secondary);
}

.header-left {
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
}

.back-btn {
  width: 44px;
  height: 44px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  color: var(--color-branch-gray);
  border-radius: 50%;
  transition: background-color 0.15s ease;
}

.back-btn:active {
  background-color: var(--color-bg-secondary);
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

.clear-btn {
  padding: var(--spacing-sm) var(--spacing-md);
  background-color: var(--color-bg-secondary);
  border-radius: var(--radius-md);
  transition: background-color 0.15s ease;
}

.clear-btn:active {
  background-color: var(--color-bg-tertiary);
}

.clear-text {
  font-size: 14px;
  font-weight: 500;
  color: var(--color-branch-gray);
}

/* 滚动内容 */
/*
 * uni-app 编译后 <scroll-view> 的真实 DOM 结构是:
 * <uni-scroll-view class="scroll-content">
 *   <div class="uni-scroll-view">            (定位包裹层,height:100% 但默认 display:block)
 *     <div class="uni-scroll-view">           (真正滚动层,同名 class,同样默认 display:block)
 *       <div class="uni-scroll-view-content"> (内容层,height:100% 但默认 display:block)
 *         <!-- 这里才是本文件模板里的 v-if 分支 -->
 *       </div>
 *     </div>
 *   </div>
 * </uni-scroll-view>
 * 直接在 .scroll-content 上写 flex:1/display:flex 只会作用在最外层 <uni-scroll-view>
 * 标签本身,而它只有一个块级子节点,flex 上下文在这里毫无意义——真正承载空状态/
 * 加载态/列表的是两层之外的 .uni-scroll-view-content,它默认是 display:block,
 * 导致 .empty-state 等子级的 flex:1 完全不生效,只能靠自身 min-height 撑出一个
 * 固定在顶部的盒子,而不是在可视区域内居中。这里必须用 :deep() 把中间这两层
 * 也强制改成 flex 列,让 flex:1 能一路传递到底。
 */
.scroll-content {
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
  padding: var(--spacing-lg);
  box-sizing: border-box;
  overflow-y: auto;
}

.scroll-content :deep(.uni-scroll-view) {
  display: flex;
  flex-direction: column;
  min-height: 0;
}

.scroll-content :deep(.uni-scroll-view-content) {
  display: flex;
  flex-direction: column;
  /* 内容层默认 height:auto,需撑满滚动层空态/加载态的 flex:1 才有居中空间 */
  min-height: 100%;
}

/* 加载态 */
/* 不再用 min-height:60vh 硬性撑出一个居中的盒子,而是 flex:1 真正填满
   .uni-scroll-view-content 传递下来的剩余可视高度,再用 justify-content:center
   在这个真实高度里居中,避免"盒子本身贴顶、盒子以下大片留白"的问题。 */
.loading-state {
  display: flex;
  flex: 1;
  min-height: 0;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: var(--spacing-2xl) var(--spacing-lg);
}

.loading-spinner {
  width: 32px;
  height: 32px;
  margin-bottom: var(--spacing-lg);
  border: 3px solid var(--color-bg-tertiary);
  border-top-color: var(--color-sky-blue);
  border-radius: 50%;
  animation: history-spin 0.8s linear infinite;
}

@keyframes history-spin {
  to {
    transform: rotate(360deg);
  }
}

.loading-text {
  font-size: 14px;
  color: var(--color-branch-gray);
}

/* 空状态:同上,依赖真正生效的 flex:1 在整段剩余可视高度内居中,
   而不是在自身 60vh 的盒子里居中、盒子本身却贴在 header 下方。 */
.empty-state {
  display: flex;
  flex: 1;
  min-height: 0;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: var(--spacing-2xl) var(--spacing-lg);
}

.empty-icon {
  width: 88px;
  height: 88px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: var(--spacing-lg);
  opacity: 0.5;
}

.empty-text {
  font-size: 14px;
  color: var(--color-branch-gray);
}

/* 历史记录列表 */
.history-list {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-md);
}

.history-item {
  display: flex;
  align-items: center;
  gap: var(--spacing-md);
  padding: var(--spacing-lg);
  background-color: var(--color-bg-secondary);
  border-radius: var(--radius-lg);
  transition: background-color 0.15s ease;
}

.history-item:active {
  background-color: var(--color-bg-tertiary);
}

.item-image {
  width: 72px;
  height: 72px;
  border-radius: var(--radius-md);
  overflow: hidden;
  background-color: var(--color-bg-primary);
}

.item-image image {
  width: 100%;
  height: 100%;
}

.item-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: var(--spacing-xs);
}

.item-spec {
  font-size: 15px;
  font-weight: 600;
  color: var(--color-ink-black);
}

.item-size {
  font-size: 12px;
  color: var(--color-branch-gray);
}

.item-date {
  font-size: 11px;
  color: var(--color-branch-gray);
}

.item-actions {
  display: flex;
  gap: var(--spacing-sm);
}

.action-btn {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: var(--radius-md);
  background-color: var(--color-bg-primary);
  transition: background-color 0.15s ease;
}

.action-btn:active {
  background-color: var(--color-bg-tertiary);
}
</style>
