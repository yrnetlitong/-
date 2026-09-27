const api = require('../../utils/api'); const ui = require('../../utils/ui')
Page({ data: { item: null, loading: false, error: '' }, onLoad(o) { this.id = o.id }, onShow() { return this.load() }, async load() { if (!(await ui.auth())) return; this.setData({ loading: true, error: '' }); try { this.setData({ item: ui.decorate(await api.get('pet/record', { id: this.id })) }) } catch (e) { this.setData({ error: e.message }) } finally { this.setData({ loading: false }) } }, preview: ui.preview,
  async remove() { if (!await ui.confirm('确认删除这条养护记录吗？')) return; try { await api.post('pet/removeRecord', { id: this.id }); wx.navigateBack() } catch (e) { ui.error(e) } }
})
