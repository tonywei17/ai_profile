/**
 * 历史记录管理器
 */

const STORAGE_KEY = 'generation_history'
const MAX_RECORDS = 50

/**
 * 获取历史记录
 * @returns {Promise<Array>} 历史记录列表
 */
const getHistory = () => {
  return new Promise((resolve, reject) => {
    try {
      const data = uni.getStorageSync(STORAGE_KEY)
      if (data) {
        resolve(JSON.parse(data))
      } else {
        resolve([])
      }
    } catch (error) {
      reject(error)
    }
  })
}

/**
 * 保存历史记录
 * @param {Array} records - 历史记录列表
 * @returns {Promise<void>}
 */
const saveHistory = (records) => {
  return new Promise((resolve, reject) => {
    try {
      uni.setStorageSync(STORAGE_KEY, JSON.stringify(records))
      resolve()
    } catch (error) {
      reject(error)
    }
  })
}

/**
 * 添加历史记录
 * @param {Object} record - 记录对象
 * @param {string} record.imagePath - 图片路径
 * @param {string} record.specId - 规格ID
 * @param {string} record.specName - 规格名称
 * @param {string} record.sizeLabel - 尺寸标签
 * @param {boolean} record.isCustomSize - 是否自定义尺寸
 * @returns {Promise<void>}
 */
const addRecord = async (record) => {
  try {
    const records = await getHistory()
    
    // 创建新记录
    const newRecord = {
      id: Date.now().toString(),
      date: new Date().toISOString(),
      imagePath: record.imagePath,
      specId: record.specId,
      specName: record.specName,
      sizeLabel: record.sizeLabel,
      isCustomSize: record.isCustomSize || false
    }
    
    // 插入到开头
    records.unshift(newRecord)
    
    // 限制最大记录数
    if (records.length > MAX_RECORDS) {
      // 删除多余的记录（从末尾）
      const removed = records.splice(MAX_RECORDS)
      // 删除对应的图片文件
      removed.forEach(r => {
        try {
          uni.getFileSystemManager().unlink({
            filePath: r.imagePath
          })
        } catch (e) {
          console.error('删除历史图片失败:', e)
        }
      })
    }
    
    await saveHistory(records)
  } catch (error) {
    console.error('添加历史记录失败:', error)
    throw error
  }
}

/**
 * 删除历史记录
 * @param {string} recordId - 记录ID
 * @returns {Promise<void>}
 */
const deleteRecord = async (recordId) => {
  try {
    const records = await getHistory()
    const record = records.find(r => r.id === recordId)
    
    if (record) {
      // 删除图片文件
      try {
        uni.getFileSystemManager().unlink({
          filePath: record.imagePath
        })
      } catch (e) {
        console.error('删除历史图片失败:', e)
      }
      
      // 从记录中删除
      const newRecords = records.filter(r => r.id !== recordId)
      await saveHistory(newRecords)
    }
  } catch (error) {
    console.error('删除历史记录失败:', error)
    throw error
  }
}

/**
 * 清空所有历史记录
 * @returns {Promise<void>}
 */
const clearAll = async () => {
  try {
    const records = await getHistory()
    
    // 删除所有图片文件
    records.forEach(r => {
      try {
        uni.getFileSystemManager().unlink({
          filePath: r.imagePath
        })
      } catch (e) {
        console.error('删除历史图片失败:', e)
      }
    })
    
    // 清空记录
    await saveHistory([])
  } catch (error) {
    console.error('清空历史记录失败:', error)
    throw error
  }
}

/**
 * 格式化日期显示
 * @param {string} isoDate - ISO日期字符串
 * @returns {string} 格式化后的日期
 */
const formatDate = (isoDate) => {
  const date = new Date(isoDate)
  const now = new Date()
  const diff = now - date
  
  // 小于1小时
  if (diff < 3600000) {
    const minutes = Math.floor(diff / 60000)
    return minutes < 1 ? '刚刚' : `${minutes}分钟前`
  }
  
  // 小于24小时
  if (diff < 86400000) {
    const hours = Math.floor(diff / 3600000)
    return `${hours}小时前`
  }
  
  // 小于7天
  if (diff < 604800000) {
    const days = Math.floor(diff / 86400000)
    return `${days}天前`
  }
  
  // 超过7天显示具体日期
  const month = date.getMonth() + 1
  const day = date.getDate()
  return `${month}月${day}日`
}

export default {
  getHistory,
  addRecord,
  deleteRecord,
  clearAll,
  formatDate
}
