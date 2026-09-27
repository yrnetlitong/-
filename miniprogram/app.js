const api = require('./utils/api')
App({
  globalData: { user: null, config: null },
  onLaunch() {
    this.ready = this.restore()
  },
  async restore() {
    const session = wx.getStorageSync('petknow_session')
    if (session && session.expires_at * 1000 > Date.now()) {
      try { this.globalData.user = await api.get('pet/profile') } catch (_) { this.clearSession() }
    } else { this.clearSession() }
    try { this.globalData.config = await api.get('index/config') } catch (_) { this.globalData.config = null }
  },
  clearSession() {
    wx.removeStorageSync('petknow_session')
    this.globalData.user = null
  }
})
