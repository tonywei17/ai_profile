import config from '../api/config.js'
import { get, post } from '../api/request.js'

class WechatAuthService {
  constructor() {
    this.ensureLoginPromise = null
    this.lastValidationAt = 0
    this.restoreLoginState()
  }

  async login() {
    const loginResult = await new Promise((resolve, reject) => {
      uni.login({
        provider: 'weixin',
        success: resolve,
        fail: reject
      })
    })
    if (!loginResult.code) {
      throw new Error('微信登录未返回 code')
    }

    const response = await post(
      config.endpoints.wechatLogin,
      { code: loginResult.code },
      { showLoading: false }
    )
    if (!response.success) {
      throw new Error(response.error || '微信登录失败')
    }

    const { token, userId, openid, expiresIn } = response.data
    this.token = token
    this.userId = userId
    this.openid = openid
    this.expiresIn = expiresIn
    uni.setStorageSync('wechatToken', token)
    uni.setStorageSync('wechatUserId', userId)
    uni.setStorageSync('wechatOpenid', openid)
    uni.setStorageSync('wechatLoginTime', Date.now())
    this.lastValidationAt = Date.now()
    return response.data
  }

  restoreLoginState() {
    this.token = uni.getStorageSync('wechatToken') || ''
    this.userId = uni.getStorageSync('wechatUserId') || ''
    this.openid = uni.getStorageSync('wechatOpenid') || ''
    const loginTime = Number(uni.getStorageSync('wechatLoginTime') || 0)
    if (loginTime && Date.now() - loginTime > 24 * 60 * 60 * 1000) {
      this.clearLoginState()
      return false
    }
    return this.isLoggedIn()
  }

  async ensureLogin() {
    if (this.ensureLoginPromise) {
      return this.ensureLoginPromise
    }
    this.ensureLoginPromise = this.performEnsureLogin()
    try {
      return await this.ensureLoginPromise
    } finally {
      this.ensureLoginPromise = null
    }
  }

  async performEnsureLogin() {
    if (this.restoreLoginState()) {
      if (Date.now() - this.lastValidationAt < 5 * 60 * 1000) {
        return {
          token: this.token,
          userId: this.userId,
          openid: this.openid
        }
      }
      try {
        const response = await get(
          config.endpoints.wechatValidateToken,
          {},
          { showLoading: false }
        )
        if (response.success && response.data?.valid) {
          this.lastValidationAt = Date.now()
          return {
            token: this.token,
            userId: this.userId,
            openid: this.openid
          }
        }
      } catch {
        this.clearLoginState()
      }
    }
    return this.login()
  }

  async getOpenId() {
    const session = await this.ensureLogin()
    return session.openid
  }

  isLoggedIn() {
    return Boolean(this.token && this.userId && this.openid)
  }

  clearLoginState() {
    this.token = ''
    this.userId = ''
    this.openid = ''
    this.lastValidationAt = 0
    uni.removeStorageSync('wechatToken')
    uni.removeStorageSync('wechatUserId')
    uni.removeStorageSync('wechatOpenid')
    uni.removeStorageSync('wechatLoginTime')
  }
}

export default new WechatAuthService()
