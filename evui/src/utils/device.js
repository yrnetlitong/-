/**
 * 终端检测工具
 */

/**
 * 判断是否为移动端
 * @returns {boolean}
 */
export function isMobile() {
  const userAgent = navigator.userAgent || navigator.vendor || window.opera
  return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(userAgent)
}

/**
 * 判断是否为微信浏览器
 * @returns {boolean}
 */
export function isWechat() {
  const ua = navigator.userAgent.toLowerCase()
  return ua.indexOf('micromessenger') !== -1
}

/**
 * 获取屏幕尺寸
 * @returns {{width: number, height: number}}
 */
export function getScreenSize() {
  return {
    width: document.documentElement.clientWidth || document.body.clientWidth,
    height: document.documentElement.clientHeight || document.body.clientHeight
  }
}
