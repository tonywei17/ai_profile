/**
 * 相册保存失败统一处理(creation / result 页共用)
 *
 * 权限判定优先走 uni.getSetting 的权威状态(scope.writePhotosAlbum === false),
 * getSetting 不可用时退回 errMsg 字符串嗅探。权限被拒时引导去设置开启,
 * 其余失败展示 toast。
 */

import { useI18n } from './i18n.js'

const { t } = useI18n()

const looksLikeAuthDenied = (err) => {
  const errMsg = ((err && err.errMsg) || '').toLowerCase()
  return errMsg.indexOf('auth') !== -1 || errMsg.indexOf('privacy') !== -1
}

const promptOpenSetting = () => {
  uni.showModal({
    title: t('common.albumAuth.title'),
    content: t('common.albumAuth.content'),
    confirmText: t('common.albumAuth.confirm'),
    cancelText: t('common.albumAuth.cancel'),
    success: (res) => {
      if (res.confirm) {
        uni.openSetting()
      }
    }
  })
}

const showSaveFailedToast = (failTitle) => {
  uni.showToast({
    title: failTitle || t('common.albumAuth.saveFailed'),
    icon: 'none'
  })
}

/**
 * @param {object} err - saveImageToPhotosAlbum 的 fail 回调参数
 * @param {string} [failTitle] - 非权限失败时的自定义 toast 文案
 */
export const handleSaveAlbumFail = (err, failTitle) => {
  console.error('保存到相册失败:', err)
  uni.getSetting({
    success: (res) => {
      const denied = res.authSetting && res.authSetting['scope.writePhotosAlbum'] === false
      if (denied || looksLikeAuthDenied(err)) {
        promptOpenSetting()
      } else {
        showSaveFailedToast(failTitle)
      }
    },
    fail: () => {
      if (looksLikeAuthDenied(err)) {
        promptOpenSetting()
      } else {
        showSaveFailedToast(failTitle)
      }
    }
  })
}
