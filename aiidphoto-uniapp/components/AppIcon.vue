<template>
  <view class="app-icon" :style="iconStyle"></view>
</template>

<script setup>
/**
 * AppIcon - 单色线性图标组件(微信小程序兼容)
 *
 * 微信小程序模板不支持 <svg> 标签,这里采用 CSS mask 方案:
 * 将 24x24 线性 SVG(stroke-width:2, round cap/join)预编码为 base64 data-URI,
 * 设为 -webkit-mask-image / mask-image,再用 background-color 着色。
 *
 * 用法:
 *   <AppIcon name="camera" :size="24" color="#2464C8" />
 *   <AppIcon name="chevron-right" size="32rpx" />   // size 支持带单位字符串
 *   color 默认 currentColor,跟随父元素文字颜色。
 */
import { computed } from 'vue'

const props = defineProps({
  // 图标名,见下方 icons 字典的 key
  name: {
    type: String,
    required: true
  },
  // 尺寸:数字或纯数字字符串按 px 处理,带单位字符串(如 '32rpx')原样使用
  size: {
    type: [Number, String],
    default: 20
  },
  // 图标颜色,任意 CSS 颜色值(含 var() token),默认继承文字颜色
  color: {
    type: String,
    default: 'currentColor'
  }
})

/* 图标字典:name → base64(24x24 viewBox 线性 SVG, stroke:black, fill:none) */
const icons = {
  /* 左箭头/返回 */
  'back':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik0xOSAxMkg1Ii8+PHBhdGggZD0iTTEyIDE5bC03LTcgNy03Ii8+PC9zdmc+',
  /* 叉/关闭 */
  'close':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik0xOCA2TDYgMTgiLz48cGF0aCBkPSJNNiA2bDEyIDEyIi8+PC9zdmc+',
  /* 勾 */
  'check':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik0yMCA2TDkgMTdsLTUtNSIvPjwvc3ZnPg==',
  /* 右箭头(细) */
  'chevron-right':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik05IDE4bDYtNi02LTYiLz48L3N2Zz4=',
  /* 下箭头(细) */
  'chevron-down':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik02IDlsNiA2IDYtNiIvPjwvc3ZnPg==',
  /* 时钟带回退箭头/历史记录 */
  'history':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik0zIDEyYTkgOSAwIDEgMCA5LTkgOS43NSA5Ljc1IDAgMCAwLTYuNzQgMi43NEwzIDgiLz48cGF0aCBkPSJNMyAzdjVoNSIvPjxwYXRoIGQ9Ik0xMiA3djVsNCAyIi8+PC9zdmc+',
  /* 齿轮/设置 */
  'settings':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik0xMi4yMiAyaC0uNDRhMiAyIDAgMCAwLTIgMnYuMThhMiAyIDAgMCAxLTEgMS43M2wtLjQzLjI1YTIgMiAwIDAgMS0yIDBsLS4xNS0uMDhhMiAyIDAgMCAwLTIuNzMuNzNsLS4yMi4zOGEyIDIgMCAwIDAgLjczIDIuNzNsLjE1LjFhMiAyIDAgMCAxIDEgMS43MnYuNTFhMiAyIDAgMCAxLTEgMS43NGwtLjE1LjA5YTIgMiAwIDAgMC0uNzMgMi43M2wuMjIuMzhhMiAyIDAgMCAwIDIuNzMuNzNsLjE1LS4wOGEyIDIgMCAwIDEgMiAwbC40My4yNWEyIDIgMCAwIDEgMSAxLjczVjIwYTIgMiAwIDAgMCAyIDJoLjQ0YTIgMiAwIDAgMCAyLTJ2LS4xOGEyIDIgMCAwIDEgMS0xLjczbC40My0uMjVhMiAyIDAgMCAxIDIgMGwuMTUuMDhhMiAyIDAgMCAwIDIuNzMtLjczbC4yMi0uMzlhMiAyIDAgMCAwLS43My0yLjczbC0uMTUtLjA4YTIgMiAwIDAgMS0xLTEuNzR2LS41YTIgMiAwIDAgMSAxLTEuNzRsLjE1LS4wOWEyIDIgMCAwIDAgLjczLTIuNzNsLS4yMi0uMzhhMiAyIDAgMCAwLTIuNzMtLjczbC0uMTUuMDhhMiAyIDAgMCAxLTIgMGwtLjQzLS4yNWEyIDIgMCAwIDEtMS0xLjczVjRhMiAyIDAgMCAwLTItMnoiLz48Y2lyY2xlIGN4PSIxMiIgY3k9IjEyIiByPSIzIi8+PC9zdmc+',
  /* 相机 */
  'camera':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik0yMyAxOWEyIDIgMCAwIDEtMiAySDNhMiAyIDAgMCAxLTItMlY4YTIgMiAwIDAgMSAyLTJoNGwyLTNoNmwyIDNoNGEyIDIgMCAwIDEgMiAyeiIvPjxjaXJjbGUgY3g9IjEyIiBjeT0iMTMiIHI9IjQiLz48L3N2Zz4=',
  /* 图片/相册 */
  'album':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxyZWN0IHg9IjMiIHk9IjMiIHdpZHRoPSIxOCIgaGVpZ2h0PSIxOCIgcng9IjIiLz48Y2lyY2xlIGN4PSI4LjUiIGN5PSI4LjUiIHI9IjEuNSIvPjxwYXRoIGQ9Ik0yMSAxNWwtNS01TDUgMjEiLz48L3N2Zz4=',
  /* 下载/保存 */
  'save':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik0yMSAxNXY0YTIgMiAwIDAgMS0yIDJINWEyIDIgMCAwIDEtMi0ydi00Ii8+PHBhdGggZD0iTTcgMTBsNSA1IDUtNSIvPjxwYXRoIGQ9Ik0xMiAxNVYzIi8+PC9zdmc+',
  /* 打印机 */
  'printer':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik02IDlWMmgxMnY3Ii8+PHBhdGggZD0iTTYgMThINGEyIDIgMCAwIDEtMi0ydi01YTIgMiAwIDAgMSAyLTJoMTZhMiAyIDAgMCAxIDIgMnY1YTIgMiAwIDAgMS0yIDJoLTIiLz48cmVjdCB4PSI2IiB5PSIxNCIgd2lkdGg9IjEyIiBoZWlnaHQ9IjgiLz48L3N2Zz4=',
  /* 刷新/重新生成 */
  'refresh':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik0yMSAxMmE5IDkgMCAxIDEtMi42NC02LjM2TDIxIDgiLz48cGF0aCBkPSJNMjEgM3Y1aC01Ii8+PC9zdmc+',
  /* 锁 */
  'lock':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxyZWN0IHg9IjMiIHk9IjExIiB3aWR0aD0iMTgiIGhlaWdodD0iMTEiIHJ4PSIyIi8+PHBhdGggZD0iTTcgMTFWN2E1IDUgMCAwIDEgMTAgMHY0Ii8+PC9zdmc+',
  /* 皇冠/会员 */
  'crown':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik0zIDE3TDIgNmw1LjUgNEwxMiA0bDQuNSA2TDIyIDZsLTEgMTFIM3oiLz48cGF0aCBkPSJNNCAyMWgxNiIvPjwvc3ZnPg==',
  /* 地球/语言 */
  'globe':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxjaXJjbGUgY3g9IjEyIiBjeT0iMTIiIHI9IjEwIi8+PHBhdGggZD0iTTIgMTJoMjAiLz48cGF0aCBkPSJNMTIgMmExNS4zIDE1LjMgMCAwIDEgNCAxMCAxNS4zIDE1LjMgMCAwIDEtNCAxMCAxNS4zIDE1LjMgMCAwIDEtNC0xMCAxNS4zIDE1LjMgMCAwIDEgNC0xMHoiLz48L3N2Zz4=',
  /* 盾牌/隐私 */
  'shield':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik0xMiAyMnM4LTQgOC0xMFY1bC04LTMtOCAzdjdjMCA2IDggMTAgOCAxMHoiLz48L3N2Zz4=',
  /* 文档 */
  'document':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik0xNCAySDZhMiAyIDAgMCAwLTIgMnYxNmEyIDIgMCAwIDAgMiAyaDEyYTIgMiAwIDAgMCAyLTJWOHoiLz48cGF0aCBkPSJNMTQgMnY2aDYiLz48cGF0aCBkPSJNMTYgMTNIOCIvPjxwYXRoIGQ9Ik0xNiAxN0g4Ii8+PC9zdmc+',
  /* 客服气泡 */
  'chat':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik0yMSAxMS41YTguMzggOC4zOCAwIDAgMS0uOSAzLjggOC41IDguNSAwIDAgMS03LjYgNC43IDguMzggOC4zOCAwIDAgMS0zLjgtLjlMMyAyMWwxLjktNS43YTguMzggOC4zOCAwIDAgMS0uOS0zLjggOC41IDguNSAwIDAgMSA0LjctNy42IDguMzggOC4zOCAwIDAgMSAzLjgtLjloLjVhOC40OCA4LjQ4IDAgMCAxIDggOHYuNXoiLz48L3N2Zz4=',
  /* 垃圾桶/删除 */
  'trash':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik0zIDZoMTgiLz48cGF0aCBkPSJNMTkgNnYxNGEyIDIgMCAwIDEtMiAySDdhMiAyIDAgMCAxLTItMlY2Ii8+PHBhdGggZD0iTTggNlY0YTIgMiAwIDAgMSAyLTJoNGEyIDIgMCAwIDEgMiAydjIiLz48cGF0aCBkPSJNMTAgMTF2NiIvPjxwYXRoIGQ9Ik0xNCAxMXY2Ii8+PC9zdmc+',
  /* 证件卡 */
  'id-card':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxyZWN0IHg9IjIiIHk9IjUiIHdpZHRoPSIyMCIgaGVpZ2h0PSIxNCIgcng9IjIiLz48Y2lyY2xlIGN4PSI4IiBjeT0iMTEiIHI9IjIiLz48cGF0aCBkPSJNNSAxN2MuNi0xLjYgMS43LTIuNSAzLTIuNXMyLjQuOSAzIDIuNSIvPjxwYXRoIGQ9Ik0xNCAxMGg1Ii8+PHBhdGggZD0iTTE0IDE0aDQiLz48L3N2Zz4=',
  /* 护照 */
  'passport':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxyZWN0IHg9IjQiIHk9IjIiIHdpZHRoPSIxNiIgaGVpZ2h0PSIyMCIgcng9IjIiLz48Y2lyY2xlIGN4PSIxMiIgY3k9IjEwIiByPSIzIi8+PHBhdGggZD0iTTggMTdoOCIvPjwvc3ZnPg==',
  /* 汽车/驾照 */
  'car':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik0xOSAxN2gyYy42IDAgMS0uNCAxLTF2LTNjMC0uOS0uNy0xLjctMS41LTEuOUMxOC43IDEwLjYgMTYgMTAgMTYgMTBzLTEuMy0xLjQtMi4yLTIuM2MtLjUtLjQtMS4xLS43LTEuOC0uN0g1Yy0uNiAwLTEuMS40LTEuNC45bC0xLjQgMi45QTMuNyAzLjcgMCAwIDAgMiAxMnY0YzAgLjYuNCAxIDEgMWgyIi8+PGNpcmNsZSBjeD0iNyIgY3k9IjE3IiByPSIyIi8+PHBhdGggZD0iTTkgMTdoNiIvPjxjaXJjbGUgY3g9IjE3IiBjeT0iMTciIHI9IjIiLz48L3N2Zz4=',
  /* 公文包/简历 */
  'briefcase':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxyZWN0IHg9IjIiIHk9IjciIHdpZHRoPSIyMCIgaGVpZ2h0PSIxNCIgcng9IjIiLz48cGF0aCBkPSJNMTYgMjFWNWEyIDIgMCAwIDAtMi0yaC00YTIgMiAwIDAgMC0yIDJ2MTYiLz48L3N2Zz4=',
  /* 学位帽 */
  'graduation':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik0yMiAxMEwxMiA1IDIgMTBsMTAgNSAxMC01eiIvPjxwYXRoIGQ9Ik02IDEydjVjMCAxLjcgMi43IDMgNiAzczYtMS4zIDYtM3YtNSIvPjxwYXRoIGQ9Ik0yMiAxMHY2Ii8+PC9zdmc+',
  /* 头像/用户 */
  'user':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik0yMCAyMXYtMmE0IDQgMCAwIDAtNC00SDhhNCA0IDAgMCAwLTQgNHYyIi8+PGNpcmNsZSBjeD0iMTIiIGN5PSI3IiByPSI0Ii8+PC9zdmc+',
  /* AI 星光 */
  'sparkle':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik0xMiAzbDEuOSA1LjhhMiAyIDAgMCAwIDEuMyAxLjNMMjEgMTJsLTUuOCAxLjlhMiAyIDAgMCAwLTEuMyAxLjNMMTIgMjFsLTEuOS01LjhhMiAyIDAgMCAwLTEuMy0xLjNMMyAxMmw1LjgtMS45YTIgMiAwIDAgMCAxLjMtMS4zTDEyIDN6Ii8+PHBhdGggZD0iTTE5IDN2NCIvPjxwYXRoIGQ9Ik0xNyA1aDQiLz48L3N2Zz4=',
  /* 右上箭头/外链 */
  'arrow-up-right':
    'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxwYXRoIGQ9Ik03IDE3TDE3IDciLz48cGF0aCBkPSJNNyA3aDEwdjEwIi8+PC9zdmc+'
}

// 归一化尺寸:数字/纯数字字符串 → px,其余(如 '32rpx')原样透传
const normalizedSize = computed(() => {
  const raw = props.size
  if (typeof raw === 'number') return `${raw}px`
  if (/^\d+(\.\d+)?$/.test(raw)) return `${raw}px`
  return raw
})

// 用字符串形式的内联样式,避免小程序端对 -webkit- 前缀对象 key 的序列化问题
const iconStyle = computed(() => {
  const base64 = icons[props.name]
  if (!base64) {
    console.warn(`[AppIcon] 未知图标名: ${props.name}`)
    return `width:${normalizedSize.value};height:${normalizedSize.value};`
  }
  const url = `url("data:image/svg+xml;base64,${base64}")`
  return [
    `width:${normalizedSize.value}`,
    `height:${normalizedSize.value}`,
    `background-color:${props.color}`,
    `-webkit-mask-image:${url}`,
    `mask-image:${url}`
  ].join(';')
})
</script>

<style scoped>
.app-icon {
  display: inline-block;
  flex-shrink: 0;
  vertical-align: middle;
  -webkit-mask-repeat: no-repeat;
  mask-repeat: no-repeat;
  -webkit-mask-position: center;
  mask-position: center;
  -webkit-mask-size: contain;
  mask-size: contain;
}
</style>
