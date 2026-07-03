import config from './config.js'
import { get } from './request.js'
import wechatAuthService from '../services/wechatAuthService.js'

const ATTEMPTS_PER_PURCHASE = 3
const PAYMENT_MODE =
  import.meta.env.VITE_PAYMENT_MODE || (import.meta.env.DEV ? 'standard' : 'disabled')
const DISPLAY_PRICE =
  PAYMENT_MODE === 'virtual' ? '¥3.80' : PAYMENT_MODE === 'standard' ? '¥0.01' : ''

const isPaymentEnabled = () => {
  if (PAYMENT_MODE === 'standard') {
    return true
  }
  if (PAYMENT_MODE !== 'virtual') {
    return false
  }

  // #ifdef MP-WEIXIN
  return typeof wx.requestVirtualPayment === 'function'
  // #endif

  // #ifndef MP-WEIXIN
  return false
  // #endif
}

const loadPaymentProvider = () => {
  if (PAYMENT_MODE === 'virtual') {
    return import('./paymentVirtual.js')
  }
  if (PAYMENT_MODE === 'standard') {
    return import('./paymentStandard.js')
  }
  return null
}

const notifyStatusChanged = () => {
  uni.$emit('paymentStatusChanged')
}

const getRemainingAttempts = async () => {
  await wechatAuthService.ensureLogin()
  const response = await get(
    config.endpoints.paymentEntitlements,
    {},
    { showLoading: false }
  )
  if (!response.success) {
    throw new Error(response.error || '读取生成次数失败')
  }
  return response.data
}

const useAttempt = async (type = 'free') => {
  const status = await getRemainingAttempts()
  return type === 'pro'
    ? status.proAttempts > 0
    : status.freeAttempts > 0 || status.proAttempts > 0
}

const queryOrderStatus = async (orderId) => {
  const providerPromise = loadPaymentProvider()
  if (!providerPromise) {
    throw new Error('当前设备暂不支持购买')
  }
  const payment = await providerPromise
  return payment.queryOrderStatus(orderId)
}

const purchasePhotoTask = async () => {
  if (!isPaymentEnabled()) {
    throw new Error('当前设备暂不支持购买')
  }
  const payment = await loadPaymentProvider()
  const order = await payment.purchasePhotoTask()
  notifyStatusChanged()
  return order
}

const restorePurchases = async () => {
  const entitlements = await getRemainingAttempts()
  notifyStatusChanged()
  return entitlements
}

const disabledClientMutation = async () => {
  throw new Error('生成次数由服务器管理')
}

export default {
  getRemainingAttempts,
  useAttempt,
  purchasePhotoTask,
  restorePurchases,
  queryOrderStatus,
  getDisplayPrice: () => DISPLAY_PRICE,
  isPaymentEnabled,
  saveRemainingAttempts: disabledClientMutation,
  consumeAttempt: disabledClientMutation,
  grantAttempts: disabledClientMutation,
  grantFreeAttempts: disabledClientMutation,
  ATTEMPTS_PER_PURCHASE
}
