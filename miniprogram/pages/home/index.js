const api = require('../../utils/api'); const ui = require('../../utils/ui')
Page({
  data: { loading: false, error: '', pets: [], reminders: [], user: null, config: {} },
  onShow() { this.load() }, onPullDownRefresh() { this.load().finally(() => wx.stopPullDownRefresh()) },
  async load() {
    if (this.data.loading) return
    this.setData({ loading: true, error: '' })
    try {
      await getApp().ready
      const config = await api.get('index/config'); getApp().globalData.config = config
      const user = getApp().globalData.user
      this.setData({ config, user, pets: [], reminders: [] })
      if (user) {
        const results = await Promise.all([api.get('pet/pets', { limit: 3 }), api.get('pet/reminders', { status: 'pending', limit: 3 })])
        this.setData({ pets: results[0].list.map(ui.decorate), reminders: results[1].list.map(ui.decorate) })
      }
    } catch (e) { this.setData({ error: e.message }) }
    finally { this.setData({ loading: false }) }
  },
  go(e) { const path = e.currentTarget.dataset.path; if (path === 'consult') { wx.showModal({title:'线上问诊',content:'暂未开放功能',showCancel:false,confirmColor:'#B6532D'}); return } if (['pets', 'map', 'profile'].includes(path)) wx.switchTab({ url: '/pages/' + path + '/index' }); else wx.navigateTo({ url: '/pages/' + path }) },
  pet(e) { wx.navigateTo({ url: '/pages/pet/index?id=' + e.currentTarget.dataset.id }) }
})
