<template>
  <view class="privacy-page">
    <!-- 状态栏占位 -->
    <view class="status-bar-placeholder" :style="{ height: statusBarHeight + 'px' }"></view>
    
    <!-- 页面头部 -->
    <view class="privacy-header">
      <view class="header-left">
        <view class="back-btn" @click="goBack">
          <AppIcon name="back" :size="20" color="var(--color-ink-black)" />
        </view>
        <text class="header-title">隐私政策</text>
      </view>
    </view>

    <!-- 内容区域 -->
    <scroll-view scroll-y class="content-scroll">
      <view class="privacy-content">
        <view class="content-section">
          <text class="section-title">光影形象馆 — 隐私政策</text>
          <text class="section-content">生效日期：2026年6月12日；最后更新：2026年6月14日</text>
          <text class="section-content">本隐私政策适用于羽飞科技(广西)有限责任公司（以下简称"我们"）运营的微信小程序"光影形象馆"。本政策说明我们如何收集、使用、保存、共享和保护你的个人信息，以及你如何行使相关权利。</text>
          <text class="section-content">重要提示：你上传的人像照片可能包含面部特征，属于敏感个人信息。请仅上传你本人照片，或确保已获得被拍摄人及其监护人的充分授权。</text>
        </view>

        <view class="content-section">
          <text class="section-title">1. 个人信息处理者</text>
          <view class="company-info">
            <text class="info-item">名称：羽飞科技(广西)有限责任公司</text>
            <text class="info-item">联系邮箱：liuchengcheng@foyli-ai.com</text>
          </view>
        </view>

        <view class="content-section">
          <text class="section-title">2. 我们处理哪些信息</text>
          <text class="section-content">为提供服务，我们处理你主动选择或拍摄的照片、照片中的人像和面部特征、证件照规格与编辑参数、微信登录产生的 OpenID 对应标识、生成次数及订单状态，以及请求时间、路径、状态码、请求 ID 和 IP 地址等安全日志。</text>
          <text class="section-content">我们不会主动要求你提供姓名、身份证号、手机号、通讯录、精确位置或通讯内容等与本小程序基本功能无关的信息。</text>
        </view>

        <view class="content-section">
          <text class="section-title">3. 照片和 AI 生成如何处理</text>
          <view class="process-list">
            <text class="process-item">1. 你在设备上选择或拍摄照片。</text>
            <text class="process-item">2. 小程序将照片压缩后，通过 HTTPS 发送至我们的阿里云 ECS 后端。</text>
            <text class="process-item">3. 后端调用 HivisionIDPhotos 服务进行人像检测、裁切、抠图和换底色。</text>
            <text class="process-item">4. 如你选择外观编辑，后端可能调用阿里云百炼/通义万相进行二阶段图像编辑。</text>
            <text class="process-item">5. 处理结果返回小程序后，由你决定是否保存到相册。</text>
          </view>
          <text class="section-content">我们不会将你的照片用于训练模型、公开展示、出售或与本政策未列明的第三方共享。</text>
          <text class="section-content">生成或编辑后的图片会写入 AI 生成合成内容隐式标识。你主动申请导出不含显式水印的图片时，我们会记录对应生成内容标识、用户标识、导出类型和时间，以履行生成合成内容标识与审计义务；日志不包含照片内容，保存期限不少于六个月，法律法规另有规定的从其规定。</text>
        </view>

        <view class="content-section">
          <text class="section-title">4. 第三方 SDK 与服务</text>
          <text class="section-content">本小程序及后端使用微信小程序基础能力、微信虚拟支付、阿里云 ECS、阿里云百炼，以及由我们部署在 Google Cloud 基础设施上的 HivisionIDPhotos 服务。相关服务可能处理完成对应功能所必需的照片、OpenID 对应标识、订单信息或安全日志。</text>
        </view>

        <view class="content-section">
          <text class="section-title">5. 共享、委托处理与跨境处理</text>
          <text class="section-content">为实现照片生成，我们会把必要数据提供给本政策列明的服务方处理。阿里云 ECS 后端及阿里云百炼位于中国大陆；HivisionIDPhotos 当前由我们部署在中国大陆以外的云区域，因此你主动上传的照片、目标规格和背景参数会在完成本次人像检测、抠图、裁切和换底色时发生跨境传输。相关数据仅用于本次处理，不在我们的服务器持久化保存。若你不同意该处理，请不要上传照片或使用生成功能。</text>
          <text class="section-content">阿里云百炼用于外观编辑时，会接收你的照片和文本编辑指令。微信虚拟支付处理商品 ID、业务订单号、支付状态和交易单号等必要交易信息。</text>
        </view>

        <view class="content-section">
          <text class="section-title">6. 设备权限</text>
          <text class="section-content">相机与照片选择：仅在你主动拍照或选择照片时使用，用于取得本次生成所需图片。</text>
          <text class="section-content">相册写入：仅在你主动点击保存时使用，用于将生成照片或打印排版图保存到系统相册。拒绝授权不影响浏览和其他无需该权限的功能。</text>
        </view>

        <view class="content-section">
          <text class="section-title">7. 你的权利</text>
          <text class="section-content">你可以通过 liuchengcheng@foyli-ai.com 联系我们，要求查询、更正、删除、复制个人信息，撤回同意，或投诉我们的个人信息处理行为。我们会在验证身份后依法处理。</text>
          <text class="section-content">由于照片不在服务器持久化保存，你可通过删除小程序本地历史记录或相册文件来删除设备侧数据。购买问题和退款按照微信平台规则处理，也可通过联系邮箱向我们反馈。</text>
        </view>

        <view class="content-section">
          <text class="section-title">8. 未成年人保护</text>
          <text class="section-content">本小程序不面向 14 周岁以下儿童。若监护人帮助未成年人制作证件照，应确保已获得必要同意并承担监护责任。如你认为我们错误处理了未成年人个人信息，请联系我们删除或处理。</text>
        </view>

        <view class="content-section">
          <text class="section-title">9. 安全措施</text>
          <view class="security-list">
            <text class="security-item">• 照片和接口请求通过 HTTPS/TLS 传输。</text>
            <text class="security-item">• AI 服务密钥仅保存在后端服务器，小程序客户端不包含相关密钥。</text>
            <text class="security-item">• 服务器日志不记录请求体，不记录照片 base64 内容。</text>
            <text class="security-item">• 生成接口启用服务端鉴权、IP 限速和预算控制以降低滥用风险。</text>
          </view>
        </view>

        <view class="content-section">
          <text class="section-title">10. 政策更新</text>
          <text class="section-content">如本政策发生重大变化，我们会在本页面更新生效日期。若变化涉及敏感个人信息、处理目的、共享对象或用户权利的重大调整，我们会在小程序内或页面显著位置提示。</text>
        </view>

        <view class="content-section contact-section">
          <text class="section-title">联系我们</text>
          <view class="contact-info">
            <text class="contact-item">运营者：羽飞科技(广西)有限责任公司</text>
            <text class="contact-item">联系邮箱：liuchengcheng@foyli-ai.com</text>
          </view>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import AppIcon from '@/components/AppIcon.vue'
// 系统信息
const statusBarHeight = ref(0)

// 获取系统信息
onMounted(() => {
  const systemInfo = uni.getSystemInfoSync()
  statusBarHeight.value = systemInfo.statusBarHeight || 0
})

// 返回
const goBack = () => {
  uni.navigateBack()
}
</script>

<style lang="scss" scoped>
.privacy-page {
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

/* 页面头部 */
.privacy-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px;
  background-color: #ffffff;
  border-bottom: 1px solid #e5e7eb;
  
  .header-left {
    display: flex;
    align-items: center;
    gap: 12px;
    
    .back-btn {
      width: 32px;
      height: 32px;
      display: flex;
      align-items: center;
      justify-content: center;
      border-radius: 6px;
      background-color: #f3f4f6;
      
      text {
        font-size: 18px;
        color: #374151;
      }
    }
    
    .header-title {
      font-size: 18px;
      font-weight: 600;
      color: #111827;
    }
  }
}

/* 内容区域 */
.content-scroll {
  flex: 1;
  padding: 16px;
}

.privacy-content {
  background-color: #ffffff;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.content-section {
  margin-bottom: 24px;
  
  &:last-child {
    margin-bottom: 0;
  }
  
  .section-title {
    font-size: 16px;
    font-weight: 600;
    color: #111827;
    margin-bottom: 8px;
    display: block;
  }
  
  .section-content {
    font-size: 14px;
    color: #6b7280;
    line-height: 1.6;
    margin-bottom: 12px;
    display: block;
  }
}

.company-info {
  margin-top: 8px;
  
  .info-item {
    font-size: 14px;
    color: #6b7280;
    line-height: 1.5;
    margin-bottom: 4px;
    display: block;
  }
}

.data-table, .service-table {
  margin-top: 8px;
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid #e5e7eb;
}

.table-header {
  display: flex;
  background-color: #f5f5f7;
  font-weight: 600;
}

.table-row {
  display: flex;
  border-bottom: 1px solid #e5e7eb;
}

.table-row:last-child {
  border-bottom: none;
}

.table-cell {
  flex: 1;
  padding: 8px 12px;
  font-size: 14px;
  color: #6b7280;
  line-height: 1.4;
  border-right: 1px solid #e5e7eb;
  word-break: break-word;
}

.table-cell:last-child {
  border-right: none;
}

.table-header .table-cell {
  color: #374151;
  font-weight: 600;
}

.process-list, .security-list, .retention-list, .rights-list {
  margin-top: 8px;
  
  .process-item, .security-item, .retention-item, .rights-item {
    font-size: 14px;
    color: #6b7280;
    line-height: 1.5;
    margin-bottom: 4px;
    display: block;
  }
}

.contact-section {
  background-color: #f5f5f7;
  padding: 16px;
  border-radius: 8px;
  margin-top: 24px;
}

.contact-info {
  margin-top: 8px;
  
  .contact-item {
    font-size: 14px;
    color: #6b7280;
    line-height: 1.5;
    margin-bottom: 4px;
    display: block;
  }
}
</style>
