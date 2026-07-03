const configuredBaseURL =
  import.meta.env.VITE_API_BASE_URL || 'https://aiphoto-cn.foyli.cloud'

const config = {
  baseURL: configuredBaseURL.replace(/\/+$/, ''),
  timeout: 150000,
  headers: {
    'Content-Type': 'application/json'
  },
  endpoints: {
    wechatLogin: '/api/wechat/login',
    wechatUserInfo: '/api/wechat/user-info',
    wechatValidateToken: '/api/wechat/validate-token',
    paymentEntitlements: '/api/payment/entitlements',
    virtualPaymentCreateOrder: '/api/payment/virtual/create-order',
    virtualPaymentQueryOrder: '/api/payment/virtual/order',
    geminiGenerate: '/api/gemini/generate',
    aigcExportLog: '/api/gemini/export-log',
    referralRegister: '/api/referral/register',
    referralRedeem: '/api/referral/redeem',
    tripoGenerate: '/api/tripo/generate'
  }
}

export default config
