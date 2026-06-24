import config from './config.js'
import { post } from './request.js'
import wechatAuthService from '../services/wechatAuthService.js'

/**
 * 将图片文件转换为base64
 * @param {string} filePath - 图片文件路径
 * @returns {Promise<string>} base64字符串
 */
const imageToBase64 = (filePath) => {
  return new Promise((resolve, reject) => {
    uni.getFileSystemManager().readFile({
      filePath: filePath,
      encoding: 'base64',
      success: (res) => {
        resolve(res.data)
      },
      fail: (err) => {
        reject(err)
      }
    })
  })
}

/**
 * 压缩图片
 * @param {string} src - 源图片路径
 * @param {number} quality - 压缩质量 0-100
 * @returns {Promise<string>} 压缩后的图片路径
 */
const compressImage = (src, quality = 80) => {
  return new Promise((resolve, reject) => {
    uni.compressImage({
      src: src,
      quality: quality,
      success: (res) => {
        resolve(res.tempFilePath)
      },
      fail: (err) => {
        reject(err)
      }
    })
  })
}

/**
 * 调用后端API生成证件照
 * @param {Object} params - 请求参数
 * @param {string} params.image - base64编码的图片
 * @param {string} params.prompt - 生成提示词
 * @param {string} params.tier - 'free' 或 'pro'
 * @param {number} params.specWidth - 规格宽度(像素)
 * @param {number} params.specHeight - 规格高度(像素)
 * @param {string} params.specBgColor - 背景色(十六进制)
 * @param {string} params.cosmeticPrompt - 美颜提示词(可选)
 * @param {string} params.attirePrompt - 服装提示词(可选)
 * @param {string} params.hairPrompt - 发型提示词(可选)
 * @param {string} params.accessoryPrompt - 配饰提示词(可选)
 * @param {string} params.backgroundPrompt - 背景提示词(可选)
 * @returns {Promise<string>} base64编码的生成结果图片
 */
const generateIDPhoto = async (params) => {
  const {
    image,
    prompt = '生成证件照：浅色纯色背景，35x45mm，正脸居中，头肩框图，光照均匀，自然风格。',
    tier = 'free',
    specWidth,
    specHeight,
    specBgColor,
    cosmeticPrompt,
    attirePrompt,
    hairPrompt,
    accessoryPrompt,
    backgroundPrompt
  } = params

  // 第二段（阿里云百炼 qwen-image-edit / wanx2.1-imageedit）的外观编辑指令：
  // 换装 / 发型 / 配饰 / 美颜。必须作为独立的 cosmeticPrompt 字段发送，后端才会
  // 在 Hivision 出图后触发百炼修图阶段（此前被拼进 prompt 丢失，导致第二段从不生效）。
  // 强制「保持人脸 / 身份不变」，避免证件照失真。背景由 Hivision 填纯色，不进此段。
  const cosmeticEdits = [attirePrompt, hairPrompt, accessoryPrompt, cosmeticPrompt].filter(Boolean)
  const composedCosmeticPrompt = cosmeticEdits.length
    ? `在保持人物五官、身份和肤色不变的前提下，${cosmeticEdits.join('，')}，证件照风格`
    : ''

  // prompt 仅用于 Hivision 不可用时的兜底链，保留原拼接行为
  let fullPrompt = prompt
  for (const part of [attirePrompt, hairPrompt, accessoryPrompt, backgroundPrompt, cosmeticPrompt]) {
    if (part) {
      fullPrompt += `，${part}`
    }
  }

  console.log('兜底 prompt:', fullPrompt)
  console.log('第二段 cosmeticPrompt:', composedCosmeticPrompt || '(无，走基础)')

  const requestBody = {
    image,
    prompt: fullPrompt,
    tier,
    ...(composedCosmeticPrompt && { cosmeticPrompt: composedCosmeticPrompt }),
    ...(specWidth && { specWidth }),
    ...(specHeight && { specHeight }),
    ...(specBgColor && { specBgColor })
  }

  try {
    await wechatAuthService.ensureLogin()
    const result = await post(
      config.endpoints.geminiGenerate,
      requestBody,
      { showLoading: false, timeout: config.timeout }
    )
    if (result.image && result.produceId) {
      return {
        image: result.image,
        produceId: result.produceId,
        provider: result.provider
      }
    }
    throw new Error('生成结果无效')
  } catch (error) {
    console.error('生成证件照失败:', error)
    throw error
  }
}

/**
 * 将base64图片保存为临时文件
 * @param {string} base64Data - base64图片数据
 * @returns {Promise<string>} 临时文件路径
 */
const saveBase64Image = (base64Data) => {
  return new Promise((resolve, reject) => {
    // 移除data URL前缀（如果有）
    let base64 = base64Data
    if (base64.includes(',')) {
      base64 = base64.split(',')[1]
    }

    const fs = uni.getFileSystemManager()
    const tempPath = `${wx.env.USER_DATA_PATH}/temp_${Date.now()}.jpg`

    fs.writeFile({
      filePath: tempPath,
      data: base64,
      encoding: 'base64',
      success: () => {
        resolve(tempPath)
      },
      fail: (err) => {
        reject(err)
      }
    })
  })
}

const requestUnmarkedExport = async (produceId, exportType = 'photo') => {
  if (!produceId) {
    throw new Error('生成内容标识缺失，请重新生成后再保存')
  }
  const confirmed = await new Promise((resolve) => {
    uni.showModal({
      title: '导出无显式水印图片',
      content:
        '该图片由 AI 生成或编辑，文件内含隐式标识。你主动申请导出无显式水印版本，仅可用于合法用途；如公开发布或传播，请主动标注“AI生成”。',
      confirmText: '确认导出',
      cancelText: '取消',
      success: (result) => resolve(result.confirm),
      fail: () => resolve(false)
    })
  })
  if (!confirmed) {
    return false
  }
  const response = await post(
    config.endpoints.aigcExportLog,
    { produceId, exportType },
    { showLoading: false }
  )
  if (!response.success) {
    throw new Error(response.error || '导出记录失败')
  }
  return true
}

export default {
  imageToBase64,
  compressImage,
  generateIDPhoto,
  saveBase64Image,
  requestUnmarkedExport
}
