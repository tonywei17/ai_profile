import config from './config.js'
import { get, post } from './request.js'
import wechatAuthService from '../services/wechatAuthService.js'

const requestVirtualPayment = (paymentData) =>
  new Promise((resolve, reject) => {
    wx.requestVirtualPayment({
      signData: paymentData.signData,
      paySig: paymentData.paySig,
      signature: paymentData.signature,
      mode: paymentData.mode,
      success: resolve,
      fail: reject
    })
  })

const createOrder = async (allowSessionRefresh = true) => {
  await wechatAuthService.ensureLogin()
  try {
    const response = await post(
      config.endpoints.virtualPaymentCreateOrder,
      {},
      { showLoading: false }
    )
    if (!response.success) {
      throw new Error(response.error || '创建虚拟支付订单失败')
    }
    return response.data
  } catch (error) {
    if (
      allowSessionRefresh &&
      error.statusCode === 409 &&
      error.data?.code === 'SESSION_REFRESH_REQUIRED'
    ) {
      wechatAuthService.clearLoginState()
      await wechatAuthService.login()
      return createOrder(false)
    }
    throw error
  }
}

export const queryOrderStatus = async (orderId) => {
  const response = await get(
    `${config.endpoints.virtualPaymentQueryOrder}/${orderId}`,
    {},
    { showLoading: false }
  )
  if (!response.success) {
    throw new Error(response.error || '查询虚拟支付订单失败')
  }
  return response.data
}

const waitForPaidOrder = async (orderId) => {
  for (let attempt = 0; attempt < 12; attempt += 1) {
    try {
      const order = await queryOrderStatus(orderId)
      if (order.status === 'paid') {
        return order
      }
      if (order.status === 'closed' || order.status === 'refunded') {
        throw new Error('订单未支付或已退款')
      }
    } catch (error) {
      if (attempt === 11) {
        throw error
      }
    }
    await new Promise((resolve) => setTimeout(resolve, 1000))
  }
  throw new Error('支付结果确认中，请稍后返回页面查看生成次数')
}

export const purchasePhotoTask = async () => {
  if (typeof wx.requestVirtualPayment !== 'function') {
    throw new Error('当前微信版本暂不支持虚拟支付，请升级微信后重试')
  }

  const paymentData = await createOrder()
  await requestVirtualPayment(paymentData)
  return waitForPaidOrder(paymentData.orderId)
}
