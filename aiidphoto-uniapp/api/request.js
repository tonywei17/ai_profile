import config from './config.js'

function request(options) {
  return new Promise((resolve, reject) => {
    const {
      url,
      method = 'GET',
      data = {},
      headers = {},
      timeout = config.timeout
    } = options
    const token = uni.getStorageSync('wechatToken')
    const requestHeaders = {
      ...config.headers,
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...headers
    }

    if (options.showLoading !== false) {
      uni.showLoading({ title: '加载中...', mask: true })
    }

    uni.request({
      url: `${config.baseURL}${url}`,
      method,
      data,
      header: requestHeaders,
      timeout,
      success: (response) => {
        if (options.showLoading !== false) {
          uni.hideLoading()
        }
        if (response.statusCode >= 200 && response.statusCode < 300) {
          resolve(response.data)
          return
        }
        reject({
          message:
            response.data?.error ||
            response.data?.message ||
            `请求失败 (${response.statusCode})`,
          statusCode: response.statusCode,
          data: response.data
        })
      },
      fail: (error) => {
        if (options.showLoading !== false) {
          uni.hideLoading()
        }
        reject({
          message: error.errMsg || '网络错误',
          errCode: error.errCode
        })
      }
    })
  })
}

export function get(url, params = {}, options = {}) {
  return request({ url, method: 'GET', data: params, ...options })
}

export function post(url, data = {}, options = {}) {
  return request({ url, method: 'POST', data, ...options })
}

export default request
