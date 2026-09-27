const api = require('../../utils/api'); const ui = require('../../utils/ui')
Page({ data: { agree: false, loading: false, config: {}, error: '' }, async onLoad() { try { this.setData({ config: await api.get('index/config') }) } catch (e) { this.setData({ error: e.message }) } }, agree(e) { this.setData({ agree: e.detail.value.includes('yes') }) },
  async login() {
    if (this.data.loading) return
    if (!this.data.agree) return ui.error(new Error('请先同意使用微信身份创建账号'))
    this.setData({ loading: true, error: '' })
    try {
      const session = await new Promise((resolve, reject) => wx.login({ success: resolve, fail: reject }))
      const result = await api.post('index/login', { code: session.code, agree: true })
      wx.setStorageSync('petknow_session', { token: result.token, expires_at: result.expires_at }); getApp().globalData.user = result.user
      const target = wx.getStorageSync('petknow_return'); wx.removeStorageSync('petknow_return')
      if (getCurrentPages().length > 1) wx.navigateBack()
      else if (target && !['/pages/home/index', '/pages/pets/index', '/pages/map/index', '/pages/profile/index'].includes(target.split('?')[0])) wx.redirectTo({ url: target })
      else wx.switchTab({ url: target ? target.split('?')[0] : '/pages/home/index' })
    } catch (e) { this.setData({ error: e.message || '微信登录失败，请重试' }) } finally { this.setData({ loading: false }) }
  }, guest() { wx.switchTab({ url: '/pages/home/index' }) }, info(e) { wx.navigateTo({ url: '/pages/info/index?kind=' + e.currentTarget.dataset.kind }) }
})
