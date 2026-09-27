const api = require('../../utils/api'); const ui = require('../../utils/ui')
Page({ data: { pet: null, list: [], total: 0, page: 1, type: '', types: ui.types, recordTypes: [], loading: false, error: '' },
  onLoad(o) { this.id = o.id }, onShow() { this.load() }, onPullDownRefresh() { this.load().finally(() => wx.stopPullDownRefresh()) }, onReachBottom() { if (this.data.list.length < this.data.total) this.load(true) },
  async load(more = false) {
    if (this.data.loading || !(await ui.auth())) return
    const page = more === true ? this.data.page + 1 : 1; this.setData({ loading: true, error: '' })
    try { const [pet, result, config] = await Promise.all([api.get('pet/detail', { id: this.id }), api.get('pet/records', { pet_id: this.id, type: this.data.type, page }), api.get('index/config')]); this.setData({ recordTypes: config.record_schemas || [], pet: ui.decorate(pet), list: (page > 1 ? this.data.list : []).concat(result.list.map(ui.decorate)), total: result.total, page }) }
    catch (e) { this.setData({ error: e.message }) } finally { this.setData({ loading: false }) }
  }, filter(e) { this.setData({ type: e.currentTarget.dataset.type }); this.load() },
  edit() { wx.navigateTo({ url: '/pages/edit/index?kind=pet&id=' + this.id }) },
  record() { wx.navigateTo({ url: '/pages/edit/index?kind=record&pet_id=' + this.id }) },
  remind() { wx.navigateTo({ url: '/pages/reminders/index?pet_id=' + this.id }) },
  detail(e) { wx.navigateTo({ url: '/pages/record/index?id=' + e.currentTarget.dataset.id }) },
  async remove() { if (!await ui.confirm('删除宠物后，它的养护记录和提醒将一并清空。确认删除吗？')) return; try { await api.post('pet/remove', { id: this.id }); wx.navigateBack() } catch (e) { ui.error(e) } }, preview: ui.preview
})
