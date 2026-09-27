const api = require('../../utils/api'); const ui = require('../../utils/ui')
Page({ data: { list: [], total: 0, page: 1, status: 'pending', loading: false, error: '', template: '' }, onLoad(o) { this.petId = o.pet_id || '' }, onShow() { this.load() }, onPullDownRefresh() { this.load().finally(() => wx.stopPullDownRefresh()) }, onReachBottom() { if (this.data.list.length < this.data.total) this.load(true) },
  async load(more = false) {
    if (this.data.loading || !(await ui.auth())) return
    const page = more === true ? this.data.page + 1 : 1; this.setData({ loading: true, error: '' })
    try { const [r, c] = await Promise.all([api.get('pet/reminders', { page, status: this.data.status, pet_id: this.petId }), api.get('index/config')]); this.setData({ list: (page > 1 ? this.data.list : []).concat(r.list.map(ui.decorate)), total: r.total, page, template: c.template_id }) }
    catch (e) { this.setData({ error: e.message }) } finally { this.setData({ loading: false }) }
  }, filter(e) { this.setData({ status: e.currentTarget.dataset.status }); this.load() }, add() { wx.navigateTo({ url: '/pages/edit/index?kind=reminder&pet_id=' + this.petId }) }, edit(e) { wx.navigateTo({ url: '/pages/edit/index?kind=reminder&id=' + e.currentTarget.dataset.id }) },
  async action(e) { if (this.busy) return; const { id, action } = e.currentTarget.dataset; if (action === 'remove' && !await ui.confirm('确认删除这个提醒吗？')) return; this.busy = true; try { await api.post('pet/reminderAction', { id, action }); await this.load() } catch (err) { ui.error(err) } finally { this.busy = false } },
  subscribe(e) {
    const id = e.currentTarget.dataset.id; const template = this.data.template
    if (!template) return
    wx.requestSubscribeMessage({ tmplIds: [template], success: async r => { if (r[template] === 'accept') { try { await api.post('pet/reminderAction', { id, action: 'subscribe' }); wx.showToast({ title: '已订阅本次提醒' }); this.load() } catch (err) { ui.error(err) } } else ui.error(new Error('未订阅，仍可在小程序内查看提醒')) }, fail: () => ui.error(new Error('订阅失败，请检查微信通知设置')) })
  }
})
