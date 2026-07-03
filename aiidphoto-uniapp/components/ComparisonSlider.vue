<template>
  <view class="comparison-slider">
    <view
      class="slider-container"
      @touchstart.stop="onTouchStart"
      @touchmove.stop.prevent="onTouchMove"
      @touchend.stop="onTouchEnd"
      @touchcancel.stop="onTouchEnd"
    >
      <view class="images-container">
        <image
          class="comparison-image"
          :src="originalImage"
          mode="aspectFit"
          @error="onImageError"
        />

        <view
          class="generated-image-container"
          :style="{ width: sliderPosition + '%' }"
        >
          <image
            class="comparison-image generated-image"
            :src="generatedImage"
            :style="{ width: containerWidth + 'px' }"
            mode="aspectFit"
            @error="onImageError"
          />
        </view>

        <view
          :class="['slider-line', { dragging: isDragging }]"
          :style="{ left: sliderPosition + '%' }"
        >
          <view class="slider-handle">
            <text class="slider-icon">↔</text>
          </view>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup>
import { getCurrentInstance, nextTick, onMounted, ref } from 'vue'

defineProps({
  originalImage: {
    type: String,
    required: true
  },
  generatedImage: {
    type: String,
    required: true
  }
})

const emit = defineEmits(['sliderChange', 'dragStart', 'dragEnd'])
const instance = getCurrentInstance()
const sliderPosition = ref(50)
const isDragging = ref(false)
const containerWidth = ref(300)
const containerLeft = ref(0)

onMounted(() => {
  nextTick(measureContainer)
})

const measureContainer = () => {
  uni.createSelectorQuery()
    .in(instance?.proxy)
    .select('.slider-container')
    .boundingClientRect((rect) => {
      if (!rect) return
      containerWidth.value = rect.width || 300
      containerLeft.value = rect.left || 0
    })
    .exec()
}

const updateSliderPosition = (clientX) => {
  const width = Math.max(containerWidth.value, 1)
  const relativeX = clientX - containerLeft.value
  const nextPosition = Math.max(0, Math.min(100, (relativeX / width) * 100))
  sliderPosition.value = nextPosition
  emit('sliderChange', nextPosition)
}

const onTouchStart = (event) => {
  const touch = event.touches?.[0]
  if (!touch) return
  isDragging.value = true
  measureContainer()
  updateSliderPosition(touch.clientX)
  emit('dragStart')
}

const onTouchMove = (event) => {
  const touch = event.touches?.[0]
  if (!isDragging.value || !touch) return
  updateSliderPosition(touch.clientX)
}

const onTouchEnd = () => {
  if (!isDragging.value) return
  isDragging.value = false
  emit('dragEnd')
}

const onImageError = (event) => {
  console.error('对比图片加载失败:', event)
}
</script>

<style lang="scss" scoped>
.comparison-slider,
.slider-container,
.images-container {
  position: relative;
  width: 100%;
  height: 300px;
}

.comparison-slider,
.images-container {
  overflow: hidden;
  border-radius: 8px;
}

.slider-container {
  cursor: ew-resize;
}

.images-container {
  background-color: #f5f5f5;
}

.comparison-image {
  width: 100%;
  height: 100%;
}

.generated-image-container {
  position: absolute;
  top: 0;
  left: 0;
  height: 100%;
  overflow: hidden;
}

.generated-image {
  position: absolute;
  top: 0;
  left: 0;
  max-width: none;
}

.slider-line {
  position: absolute;
  top: 0;
  z-index: 10;
  width: 2px;
  height: 100%;
  background-color: #ffffff;
  box-shadow: 0 0 4px rgba(0, 0, 0, 0.3);
  transform: translateX(-50%);
  transition: left 0.08s ease-out;
}

.slider-line.dragging {
  transition: none;
}

.slider-handle {
  position: absolute;
  top: 50%;
  left: 50%;
  z-index: 11;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background-color: #2464c8;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.25);
  transform: translate(-50%, -50%);
}

.slider-icon {
  color: #ffffff;
  font-size: 20px;
  font-weight: 700;
}
</style>
