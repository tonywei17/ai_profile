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
import { icons } from './appIcons.js'

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
