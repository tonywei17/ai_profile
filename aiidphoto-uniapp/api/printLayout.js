/**
 * 打印纸张尺寸定义
 */
const PrintPaperSize = {
  FIVE_INCH: {
    id: 'fiveInch',
    widthMM: 89,
    heightMM: 127,
    widthPx: 1051,
    heightPx: 1500,
    sizeLabel: '89×127 mm',
    displayName: '5寸 (89×127)',
    priceHint: '约 1~2 元'
  },
  SIX_INCH: {
    id: 'sixInch',
    widthMM: 102,
    heightMM: 152,
    widthPx: 1205,
    heightPx: 1795,
    sizeLabel: '102×152 mm',
    displayName: '6寸 (102×152)',
    priceHint: '约 2~3 元'
  },
  SEVEN_INCH: {
    id: 'sevenInch',
    widthMM: 127,
    heightMM: 178,
    widthPx: 1500,
    heightPx: 2102,
    sizeLabel: '127×178 mm',
    displayName: '7寸 (127×178)',
    priceHint: '约 3~6 元'
  }
}

/**
 * 计算打印布局信息
 * @param {Object} photoSizeMM - 照片尺寸（毫米）{width, height}
 * @param {Object} paperSize - 纸张尺寸对象
 * @returns {Object} 布局信息
 */
const calculateLayout = (photoSizeMM, paperSize) => {
  const dpi = 300
  const photoW = Math.round(photoSizeMM.width / 25.4 * dpi)
  const photoH = Math.round(photoSizeMM.height / 25.4 * dpi)
  const minGap = 35 // ~3mm at 300dpi

  // 正常方向
  const colsN = Math.max(1, Math.floor((paperSize.widthPx + minGap) / (photoW + minGap)))
  const rowsN = Math.max(1, Math.floor((paperSize.heightPx + minGap) / (photoH + minGap)))
  const countN = colsN * rowsN

  // 旋转90度方向
  const colsR = Math.max(1, Math.floor((paperSize.widthPx + minGap) / (photoH + minGap)))
  const rowsR = Math.max(1, Math.floor((paperSize.heightPx + minGap) / (photoW + minGap)))
  const countR = colsR * rowsR

  if (countR > countN) {
    // 使用旋转布局
    const hMargin = (paperSize.widthPx - colsR * photoH) / (colsR + 1)
    const vMargin = (paperSize.heightPx - rowsR * photoW) / (rowsR + 1)
    
    return {
      paperSize,
      cols: colsR,
      rows: rowsR,
      photoWidthPx: photoH,
      photoHeightPx: photoW,
      rotated: true,
      totalCount: colsR * rowsR,
      hMargin,
      vMargin
    }
  }

  // 使用正常布局
  const hMargin = (paperSize.widthPx - colsN * photoW) / (colsN + 1)
  const vMargin = (paperSize.heightPx - rowsN * photoH) / (rowsN + 1)
  
  return {
    paperSize,
    cols: colsN,
    rows: rowsN,
    photoWidthPx: photoW,
    photoHeightPx: photoH,
    rotated: false,
    totalCount: colsN * rowsN,
    hMargin,
    vMargin
  }
}

/**
 * 获取照片在网格中的位置
 * @param {Object} layout - 布局信息
 * @param {number} col - 列索引
 * @param {number} row - 行索引
 * @returns {Object} {x, y} 坐标
 */
const getPhotoOrigin = (layout, col, row) => {
  return {
    x: layout.hMargin + col * (layout.photoWidthPx + layout.hMargin),
    y: layout.vMargin + row * (layout.photoHeightPx + layout.vMargin)
  }
}

/**
 * 使用Canvas绘制打印布局
 * @param {string} imagePath - 图片路径
 * @param {Object} layout - 布局信息
 * @param {boolean} showGuides - 是否显示辅助线
 * @returns {Promise<string>} 生成的图片路径
 */
const renderLayout = (imagePath, layout, showGuides = true, produceId = '') => {
  return new Promise((resolve, reject) => {
    const canvas = uni.createCanvasContext('printCanvas')
    
    // 设置画布尺寸
    canvas.width = layout.paperSize.widthPx
    canvas.height = layout.paperSize.heightPx
    
    // 填充白色背景
    canvas.setFillStyle('#FFFFFF')
    canvas.fillRect(0, 0, layout.paperSize.widthPx, layout.paperSize.heightPx)
    
    // 加载图片
    uni.getImageInfo({
      src: imagePath,
      success: (imgInfo) => {
        const imgWidth = imgInfo.width
        const imgHeight = imgInfo.height
        
        // 绘制所有照片
        for (let row = 0; row < layout.rows; row++) {
          for (let col = 0; col < layout.cols; col++) {
            const origin = getPhotoOrigin(layout, col, row)
            
            // 计算图片绘制参数（aspect fill）
            const scale = Math.max(
              layout.photoWidthPx / imgWidth,
              layout.photoHeightPx / imgHeight
            )
            const scaledW = imgWidth * scale
            const scaledH = imgHeight * scale
            const drawX = origin.x + (layout.photoWidthPx - scaledW) / 2
            const drawY = origin.y + (layout.photoHeightPx - scaledH) / 2
            
            // 如果需要旋转
            if (layout.rotated) {
              canvas.save()
              canvas.translate(origin.x + layout.photoWidthPx / 2, origin.y + layout.photoHeightPx / 2)
              canvas.rotate(90 * Math.PI / 180)
              canvas.drawImage(
                imagePath,
                -scaledW / 2,
                -scaledH / 2,
                scaledW,
                scaledH
              )
              canvas.restore()
            } else {
              canvas.drawImage(
                imagePath,
                drawX,
                drawY,
                scaledW,
                scaledH
              )
            }
            
            // 绘制辅助线
            if (showGuides) {
              canvas.setStrokeStyle('rgba(200, 200, 200, 0.5)')
              canvas.setLineWidth(1)
              canvas.strokeRect(origin.x, origin.y, layout.photoWidthPx, layout.photoHeightPx)
            }
          }
        }
        
        // 绘制完成
        canvas.draw(false, () => {
          // 导出图片
          uni.canvasToTempFilePath({
            canvasId: 'printCanvas',
            x: 0,
            y: 0,
            width: layout.paperSize.widthPx,
            height: layout.paperSize.heightPx,
            destWidth: layout.paperSize.widthPx,
            destHeight: layout.paperSize.heightPx,
            fileType: 'jpg',
            quality: 0.9,
            success: async (res) => {
              if (!produceId) {
                resolve(res.tempFilePath)
                return
              }
              try {
                resolve(
                  await aigcMetadata.addAigcMetadataToJpegFile(
                    res.tempFilePath,
                    produceId
                  )
                )
              } catch (error) {
                reject(error)
              }
            },
            fail: (err) => {
              reject(err)
            }
          })
        })
      },
      fail: (err) => {
        reject(err)
      }
    })
  })
}

/**
 * 计算打印布局信息（适配组件调用）
 * @param {Object} specInfo - 证件照规格信息
 * @param {string} paperSizeId - 纸张尺寸ID
 * @returns {Object} 布局信息
 */
const calculateLayoutForSpec = (specInfo, paperSizeId) => {
  // 根据纸张ID获取纸张尺寸
  const paperSizes = {
    'A4': { widthMM: 210, heightMM: 297, widthPx: 2480, heightPx: 3508 },
    'A3': { widthMM: 297, heightMM: 420, widthPx: 3508, heightPx: 4961 },
    'A5': { widthMM: 148, heightMM: 210, widthPx: 1748, heightPx: 2480 },
    '6x4': { widthMM: 152, heightMM: 102, widthPx: 1795, heightPx: 1205 }
  }
  
  const paperSize = paperSizes[paperSizeId] || paperSizes['A4']
  
  // 从规格信息获取照片尺寸
  const photoSizeMM = {
    width: specInfo.widthMM || 25,
    height: specInfo.heightMM || 35
  }
  
  return calculateLayout(photoSizeMM, paperSize)
}

/**
 * 渲染预览（使用Canvas 2D API）
 * @param {Object} options - 选项
 * @returns {Promise<void>}
 */
const renderPreview = async (options) => {
  const { canvasId, image, layout, scale = 0.3 } = options
  
  return new Promise((resolve, reject) => {
    console.log('【Canvas 2D】开始渲染预览，参数:', { canvasId, image, scale })
    
    // 获取Canvas 2D上下文
    uni.createSelectorQuery()
      .select(`#${canvasId}`)
      .fields({ node: true, size: true })
      .exec((res) => {
        console.log('【Canvas 2D】Canvas查询结果:', res)
        
        if (!res[0] || !res[0].node) {
          console.error('【Canvas 2D】无法获取Canvas节点')
          reject(new Error('无法获取Canvas节点'))
          return
        }
        
        const canvas = res[0].node
        const ctx = canvas.getContext('2d')
        
        // 设置Canvas尺寸
        const canvasWidth = layout.paperSize.widthPx * scale
        const canvasHeight = layout.paperSize.heightPx * scale
        
        canvas.width = canvasWidth
        canvas.height = canvasHeight
        
        console.log('【Canvas 2D】Canvas尺寸设置:', canvasWidth, 'x', canvasHeight)
        
        // 填充白色背景
        ctx.fillStyle = '#FFFFFF'
        ctx.fillRect(0, 0, canvasWidth, canvasHeight)
        
        // 加载图片
        uni.getImageInfo({
          src: image,
          success: (imgInfo) => {
            console.log('【Canvas 2D】图片信息:', imgInfo)
            
            // 创建图片对象
            const img = canvas.createImage()
            img.onload = () => {
              console.log('【Canvas 2D】图片加载完成')
              
              // 简化测试：只在画布中央绘制一张图片
              const imgWidth = imgInfo.width
              const imgHeight = imgInfo.height
              const maxWidth = canvasWidth * 0.8
              const maxHeight = canvasHeight * 0.8
              
              // 计算缩放比例
              const scaleRatio = Math.min(maxWidth / imgWidth, maxHeight / imgHeight)
              const drawWidth = imgWidth * scaleRatio
              const drawHeight = imgHeight * scaleRatio
              const drawX = (canvasWidth - drawWidth) / 2
              const drawY = (canvasHeight - drawHeight) / 2
              
              console.log('【Canvas 2D】绘制图片:', { drawX, drawY, drawWidth, drawHeight })
              
              // 绘制图片
              ctx.drawImage(img, drawX, drawY, drawWidth, drawHeight)
              
              console.log('【Canvas 2D】预览绘制完成')
              resolve()
            }
            
            img.onerror = (err) => {
              console.error('【Canvas 2D】图片加载失败:', err)
              reject(err)
            }
            
            img.src = image
          },
          fail: (err) => {
            console.error('【Canvas 2D】获取图片信息失败:', err)
            reject(err)
          }
        })
      })
  })
}

/**
 * 生成打印图片（适配组件调用）
 * @param {Object} options - 选项
 * @returns {Promise<string>} 生成的图片路径
 */
const generatePrintImage = async (options) => {
  const { image, layout, paperSize } = options
  
  return renderLayout(image, layout, true, options.produceId || '')
}

export default {
  PrintPaperSize,
  calculateLayout,
  calculateLayoutForSpec,
  getPhotoOrigin,
  renderLayout,
  renderPreview,
  generatePrintImage
}
import aigcMetadata from '@/utils/aigcMetadata.js'
