const api = require('../../utils/api'); const ui = require('../../utils/ui')
Page({ data: { list: [], total: 0, page: 1, loading: false, error: '', guest: true },
  onShow() { this.load() }, onPullDownRefresh() { this.load().finally(() => wx.stopPullDownRefresh()) }, onReachBottom() { if (this.data.list.length < this.data.total) this.load(true) },
  async load(more = false) {
    if (this.data.loading) return
    await getApp().ready
    this.setData({ guest: !getApp().globalData.user })
    if (this.data.guest) { this.setData({ list: [] }); return }
    const page = more === true ? this.data.page + 1 : 1; this.setData({ loading: true, error: '' })
    try { const r = await api.get('pet/pets', { page }); this.setData({ list: (page > 1 ? this.data.list : []).concat(r.list.map(ui.decorate)), total: r.total, page }) }
    catch (e) { this.setData({ error: e.message }) } finally { this.setData({ loading: false }) }
  },
  async add() { if (await ui.auth()) wx.navigateTo({ url: '/pages/edit/index?kind=pet' }) },
  detail(e) { wx.navigateTo({ url: '/pages/pet/index?id=' + e.currentTarget.dataset.id }) }, login() { wx.navigateTo({ url: '/pages/login/index' }) }
})
