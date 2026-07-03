<template>
  <view v-if="visible" class="privacy-mask">
    <view class="privacy-dialog">
      <text class="privacy-title">{{ title }}</text>
      <text class="privacy-content">{{ content }}</text>
      <view class="privacy-link" @tap="$emit('view-privacy')">
        <text>查看《小程序用户隐私保护指引》</text>
      </view>
      <button
        id="privacy-agree-btn"
        class="privacy-button primary"
        open-type="agreePrivacyAuthorization"
        @agreeprivacyauthorization="$emit('agree', $event)"
      >
        {{ agreeText }}
      </button>
      <button class="privacy-button secondary" @tap="$emit('reject')">
        {{ rejectText }}
      </button>
    </view>
  </view>
</template>

<script setup>
/**
 * PrivacyConsentDialog - 个人信息保护提示弹窗(统一组件)
 *
 * 从 pages/index/index.vue 与 pages/creation/creation.vue 中逐行复制的
 * 隐私同意弹窗抽取而来。隐私授权状态机(wx.onNeedPrivacyAuthorization /
 * wx.getPrivacySetting / resolve 回调)仍由页面持有,组件只负责展示与事件转发。
 *
 * 注意:同意按钮固定 id 为 'privacy-agree-btn',页面在 agree 回调里调用
 * resolvePrivacyAuthorization({ buttonId: 'privacy-agree-btn', event: 'agree' })。
 */
defineProps({
  // 是否显示弹窗
  visible: {
    type: Boolean,
    default: false
  },
  // 标题
  title: {
    type: String,
    default: '个人信息保护提示'
  },
  // 正文说明,不同页面可传各自的处理说明文案
  content: {
    type: String,
    default:
      '制作证件照需要处理你主动选择或拍摄的人像照片及面部特征,并通过 HTTPS 发送至已声明的云服务完成本次处理。照片不用于模型训练或公开展示,处理完成后不在我们的服务器持久化保存。'
  },
  // 同意按钮文案(首页:"同意并开始使用";创作页:"同意并继续")
  agreeText: {
    type: String,
    default: '同意并继续'
  },
  // 拒绝按钮文案
  rejectText: {
    type: String,
    default: '暂不同意'
  }
})

defineEmits(['agree', 'reject', 'view-privacy'])
</script>

<style scoped>
.privacy-mask {
  position: fixed;
  inset: 0;
  z-index: 10000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  background: rgba(15, 23, 42, 0.58);
}

.privacy-dialog {
  width: 100%;
  max-width: 360px;
  padding: 24px;
  border-radius: 20px;
  background: var(--color-bg-primary);
  box-shadow: 0 18px 50px rgba(15, 23, 42, 0.2);
  box-sizing: border-box;
}

.privacy-title {
  display: block;
  margin-bottom: 14px;
  color: var(--color-ink-black);
  font-size: 20px;
  font-weight: var(--font-weight-bold);
  text-align: center;
}

.privacy-content {
  display: block;
  color: var(--color-branch-gray);
  font-size: 14px;
  line-height: 1.7;
}

.privacy-link {
  padding: 14px 0 18px;
  color: var(--color-sky-blue);
  font-size: 13px;
  text-align: center;
}

.privacy-button {
  width: 100%;
  height: 44px;
  margin: 0;
  border-radius: 22px;
  font-size: 15px;
  line-height: 44px;
}

.privacy-button::after {
  border: none;
}

.privacy-button.primary {
  color: #ffffff;
  background: linear-gradient(90deg, var(--color-sky-blue), var(--color-sky-blue-mid));
}

.privacy-button.secondary {
  margin-top: 10px;
  color: var(--color-branch-gray);
  background: var(--color-bg-secondary);
}
</style>
