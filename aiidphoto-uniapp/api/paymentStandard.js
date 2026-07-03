import { get, post } from './request.js'
import wechatAuthService from '../services/wechatAuthService.js'
import { waitForPaidOrder } from './paymentPolling.js'

const PRODUCT_ID = 'photo_task_3'
const CREATE_ORDER_ENDPOINT = '/api/payment/wechat/create-order'
const QUERY_ORDER_ENDPOINT = '/api/payment/order'

const requestPayment = (paymentData) =>
  new Promise((resolve, reject) => {
    uni.requestPayment({
      provider: 'wxpay',
      timeStamp: paymentData.timeStamp,
      nonceStr: paymentData.nonceStr,
      package: paymentData.package,
      signType: paymentData.signType || 'RSA',
      paySign: paymentData.paySign,
      success: resolve,
      fail: reject
    })
  })

export const queryOrderStatus = async (orderId) => {
  const response = await get(
    `${QUERY_ORDER_ENDPOINT}/${orderId}`,
    {},
    { showLoading: false }
  )
  if (!response.success) {
    throw new Error(response.error || '查询订单失败')
  }
  return response.data
}

export const purchasePhotoTask = async () => {
  await wechatAuthService.ensureLogin()
  const response = await post(CREATE_ORDER_ENDPOINT, {
    productId: PRODUCT_ID
  })
  if (!response.success) {
    throw new Error(response.error || '创建支付订单失败')
  }

  await requestPayment(response.data)
  return waitForPaidOrder(queryOrderStatus, response.data.orderId, {
    maxAttempts: 8,
    unpaidMessage: '订单未支付',
    timeoutMessage: '支付结果确认超时，请稍后在页面重新查看次数'
  })
}
