const api = require('../../utils/api'); const ui = require('../../utils/ui')
Page({ data: { list: [], total: 0, page: 1, loading: false, error: '' }, onShow() { this.load() }, onPullDownRefresh() { this.load().finally(() => wx.stopPullDownRefresh()) }, onReachBottom() { if (this.data.list.length < this.data.total) this.load(true) },
  async load(more = false) { if (this.data.loading || !(await ui.auth())) return; const page = more === true ? this.data.page + 1 : 1; this.setData({ loading: true, error: '' }); try { const r = await api.get('pet/submissions', { page }); this.setData({ list: (page > 1 ? this.data.list : []).concat(r.list.map(ui.decorate)), page, total: r.total }) } catch (e) { this.setData({ error: e.message }) } finally { this.setData({ loading: false }) } },
  add() { wx.navigateTo({ url: '/pages/edit/index?kind=place' }) }, detail(e) { wx.navigateTo({ url: '/pages/place/index?id=' + e.currentTarget.dataset.id }) }
})
