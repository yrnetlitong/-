const config = require('../config')
function expireSession() {
  getApp().clearSession()
  const pages = getCurrentPages(); const current = pages[pages.length - 1]
  if (current && current.route !== 'pages/login/index' && !getApp().loginRedirecting) {
    getApp().loginRedirecting = true
    wx.setStorageSync('petknow_return', '/' + current.route + '?' + Object.keys(current.options || {}).map(k => k + '=' + encodeURIComponent(current.options[k])).join('&'))
    wx.navigateTo({ url: '/pages/login/index', complete() { getApp().loginRedirecting = false } })
  }
}
function request(path, data = {}, method = 'GET') {
  const session = wx.getStorageSync('petknow_session') || {}
  return new Promise((resolve, reject) => {
    wx.request({
      url: config.apiBase + '/' + path, method, data,
      header: { Authorization: session.token ? 'Bearer ' + session.token : '' },
      timeout: 20000,
      success(res) {
        if (res.data && res.data.code === 0) return resolve(res.data.data)
        if (res.statusCode === 401 || (res.data && res.data.code === 401)) {
          expireSession()
        }
        reject(new Error((res.data && res.data.msg) || '请求失败，请稍后重试'))
      },
      fail() { reject(new Error('网络连接失败，请检查网络后重试')) }
    })
  })
}
function upload(filePath) {
  const session = wx.getStorageSync('petknow_session') || {}
  return new Promise((resolve, reject) => {
    wx.uploadFile({ timeout: 20000, url: config.apiBase + '/upload/uploadImage', filePath, name: 'file', header: { Authorization: 'Bearer ' + (session.token || '') },
      success(res) {
        try { const body = JSON.parse(res.data); if (res.statusCode === 401 || body.code === 401) expireSession(); if (body.code === 0) resolve(body.data); else reject(new Error(body.msg || '上传失败')) }
        catch (_) { reject(new Error('上传失败，请重试')) }
      }, fail() { reject(new Error('上传失败，请检查网络')) }
    })
  })
}
module.exports = { get: (path, data) => request(path, data), post: (path, data) => request(path, data, 'POST'), upload }
