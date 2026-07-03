/**
 * 支付订单结果轮询(标准支付与虚拟支付共用)
 *
 * 说明:closed/refunded 属终态,无论 tolerateQueryErrors 与否都立即抛出
 * (终态订单不可能再变为 paid,继续轮询只会白等到超时)。
 */

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

// 终态异常标记,确保不被 tolerateQueryErrors 吞掉
class OrderTerminalError extends Error {}

/**
 * 轮询订单直到支付成功
 * @param {(orderId: string) => Promise<{status: string}>} queryOrderStatus - 订单查询函数
 * @param {string} orderId
 * @param {object} options
 * @param {number} options.maxAttempts - 最大轮询次数
 * @param {number} options.intervalMs - 轮询间隔
 * @param {boolean} options.tolerateQueryErrors - true 时查询失败不中断轮询(最后一次仍抛出)
 * @param {string} options.unpaidMessage - 订单关闭/退款时的报错文案
 * @param {string} options.timeoutMessage - 轮询超时的报错文案
 * @returns {Promise<object>} 已支付订单
 */
export const waitForPaidOrder = async (queryOrderStatus, orderId, {
  maxAttempts = 8,
  intervalMs = 1000,
  tolerateQueryErrors = false,
  unpaidMessage = '订单未支付',
  timeoutMessage = '支付结果确认超时，请稍后在页面重新查看次数'
} = {}) => {
  for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
    try {
      const order = await queryOrderStatus(orderId)
      if (order.status === 'paid') {
        return order
      }
      if (order.status === 'closed' || order.status === 'refunded') {
        throw new OrderTerminalError(unpaidMessage)
      }
    } catch (error) {
      if (error instanceof OrderTerminalError) {
        throw error
      }
      if (!tolerateQueryErrors || attempt === maxAttempts - 1) {
        throw error
      }
    }
    await sleep(intervalMs)
  }
  throw new Error(timeoutMessage)
}
