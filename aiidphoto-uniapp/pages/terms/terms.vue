<template>
  <view class="terms-page">
    <!-- 状态栏占位 -->
    <view class="status-bar-placeholder" :style="{ height: statusBarHeight + 'px' }"></view>
    
    <!-- 页面头部 -->
    <view class="terms-header">
      <view class="header-left">
        <view class="back-btn" @click="goBack">
          <AppIcon name="back" :size="20" color="var(--color-ink-black)" />
        </view>
        <text class="header-title">用户协议</text>
      </view>
    </view>

    <!-- 内容区域 -->
    <scroll-view scroll-y class="content-scroll">
      <view class="terms-content">
        <view class="content-section">
          <text class="section-title">光影形象馆 — 服务条款</text>
          <text class="section-content">生效日期：2026年6月12日；最后更新：2026年6月14日</text>
          <text class="section-content">本服务条款适用于羽飞科技(广西)有限责任公司（以下简称"我们"）提供的微信小程序"光影形象馆"。你访问或使用本小程序，即表示你同意本条款以及隐私政策。</text>
        </view>

        <view class="content-section">
          <text class="section-title">1. 服务内容</text>
          <text class="section-content">本小程序提供 AI 证件照、职业形象照、背景替换、基础美化、外观编辑、证件照规格裁切和打印排版等功能。生成结果基于你上传的照片、选择的规格和编辑参数。</text>
          <text class="section-content">本小程序不是政府机构、使领馆、考试机构或照相馆。不同证件、考试、地区和机构对照片要求可能不同，你应在提交前自行核对目标机构的最新要求。</text>
        </view>

        <view class="content-section">
          <text class="section-title">2. 使用规则</text>
          <view class="rules-list">
            <text class="rules-item">• 你应确保上传照片属于你本人，或你已获得被拍摄人及其监护人的充分授权。</text>
            <text class="rules-item">• 不得使用本小程序制作、伪造或辅助伪造身份证件、资格证明、通行证件或其他违法材料。</text>
            <text class="rules-item">• 不得上传违法、侵权、侮辱、色情、暴力、侵犯他人隐私或违反公序良俗的内容。</text>
            <text class="rules-item">• 不得通过自动化脚本、逆向工程、接口攻击、绕过限速或绕过付费限制的方式使用本小程序。</text>
          </view>
        </view>

        <view class="content-section">
          <text class="section-title">3. 付费商品与生成次数</text>
          <text class="section-content">本小程序提供免费体验，并可通过微信小程序虚拟支付一次性购买成片制作包。一个制作包包含 3 次 AI 生成机会，不提供自动续期订阅。具体商品名称、价格和权益以小程序内实际展示为准。</text>
          <view class="payment-list">
            <text class="payment-item">• 购买通过微信小程序虚拟支付能力处理。</text>
            <text class="payment-item">• 成片制作包属于消耗型项目，不会自动续费，也无需取消订阅。</text>
            <text class="payment-item">• 生成成功后扣减 1 次生成机会；生成失败通常不扣减。</text>
            <text class="payment-item">• 打印排版图包含在已生成结果中，不再单独收费。</text>
            <text class="payment-item">• 退款、支付异常及购买问题按照微信平台规则处理，也可通过设置页公布的联系邮箱反馈。</text>
          </view>
        </view>

        <view class="content-section">
          <text class="section-title">4. AI 生成结果说明</text>
          <text class="section-content">AI 生成结果可能存在瑕疵，包括但不限于五官细节误差、服装或发型不自然、背景边缘不完美、颜色偏差、尺寸或清晰度不满足特定机构要求。你应在使用前自行检查生成结果。</text>
          <text class="section-content">我们不保证任何生成照片一定通过证件、考试、签证、求职、平台认证或其他第三方审核。</text>
          <text class="section-content">生成或编辑结果会在应用界面标注为“AI生成/编辑”，图片文件写入生成合成内容隐式标识。证件照用途需要无显式水印时，你须在保存前主动确认申请导出，并仅将图片用于合法用途；如将图片公开发布或传播，应主动添加清晰的“AI生成”标识，不得删除、篡改或隐匿依法应保留的标识。</text>
        </view>

        <view class="content-section">
          <text class="section-title">5. 知识产权</text>
          <view class="ip-list">
            <text class="ip-item">• 你保留对自己上传照片的合法权利。</text>
            <text class="ip-item">• 你授予我们在完成本次生成服务所必需范围内处理照片的临时许可。</text>
            <text class="ip-item">• 本小程序的软件、界面、品牌、图标、文案和技术实现受法律保护，未经许可不得复制、修改、传播或用于竞争性服务。</text>
          </view>
        </view>

        <view class="content-section">
          <text class="section-title">6. 隐私与数据</text>
          <text class="section-content">我们处理个人信息的规则详见隐私政策、个人信息收集清单和第三方 SDK 与服务清单。</text>
        </view>

        <view class="content-section">
          <text class="section-title">7. 服务变更、中断与终止</text>
          <text class="section-content">为维护安全、升级模型、调整成本或遵守法律法规，我们可能调整、暂停或终止部分功能。对于已购买的商品，可按照微信平台规则申请退款或处理购买问题。</text>
        </view>

        <view class="content-section">
          <text class="section-title">8. 免责声明与责任限制</text>
          <text class="section-content">在法律允许范围内，本小程序按"现状"和"可用"基础提供。我们不对生成结果被任何机构接受、服务持续无误、第三方服务持续可用作出保证。</text>
          <text class="section-content">除法律另有强制规定外，我们因本小程序承担的责任不超过你在争议发生前 12 个月内为本小程序实际支付的费用总额。</text>
        </view>

        <view class="content-section">
          <text class="section-title">9. 适用法律与争议解决</text>
          <text class="section-content">本条款适用中华人民共和国法律。因本条款或本小程序产生争议的，双方应先友好协商；协商不成的，依法向有管辖权的人民法院解决。若你通过微信虚拟支付购买数字商品，微信平台的相关服务条款和退款规则同时适用。</text>
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
.terms-page {
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
.terms-header {
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

.terms-content {
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

.service-list, .responsibility-list, .payment-list, .subscription-list, .prohibited-list, .ip-list, .disclaimer-list, .termination-list, .rules-list {
  margin-top: 8px;
  
  .service-item, .responsibility-item, .payment-item, .subscription-item, .prohibited-item, .ip-item, .disclaimer-item, .termination-item, .rules-item {
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
