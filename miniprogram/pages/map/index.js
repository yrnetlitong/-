const api = require('../../utils/api'); const ui = require('../../utils/ui')
Page({
  data: { list: [], userPlaces: [], markers: [], category: '', categories: [], loading: false, error: '', latitude: 35.86, longitude: 104.2, scale: 4, located: false, placesOpen: false, selected: null },
  onLoad() {
    wx.getLocation({ type: 'gcj02', success: location => {
      this.setData({ latitude: location.latitude, longitude: location.longitude, scale: 11, located: true })
    }, fail: () => wx.showToast({ title: '未获取定位，可手动浏览地图', icon: 'none' }) })
  },
  onShow() { this.load() },
  async load() {
    const requestId = this.requestId = (this.requestId || 0) + 1
    const params = { page: 1, limit: 100, category: this.data.category }
    this.setData({ loading: true, error: '' })
    try {
      const config = await api.get('index/config')
      let list = []; let result
      do {
        result = await api.get('index/places', params)
        if (requestId !== this.requestId) return
        list = list.concat(result.list.map(ui.decorate)); params.page++
      } while (result.list.length && list.length < result.total)
      const selected = list.find(p => this.data.selected && Number(p.id) === Number(this.data.selected.id)) || null
      const markers = this.makeMarkers(list, selected)
      const patch = { list, userPlaces: list.filter(p => p.source === 'user'), markers, selected, categories: Object.entries(config.categories).map(([value, label]) => ({ value, label })) }
      this.setData(patch)
    } catch (e) { if (requestId === this.requestId) this.setData({ error: e.message }) }
    finally { if (requestId === this.requestId) this.setData({ loading: false }) }
  },
  filter(e) { this.setData({ category: e.currentTarget.dataset.value, placesOpen: false, selected: null, list: [], userPlaces: [], markers: [] }); this.load() },
  retry() { if (!this.data.loading) this.load() },
  showUserPlaces() { this.setData({ placesOpen: true, selected: null, markers: this.makeMarkers(this.data.list, null) }) },
  closePlaces() { this.setData({ placesOpen: false }) },
  makeMarkers(list, selected) {
    return list.map(p => {
      const active = !!selected && Number(p.id) === Number(selected.id)
      return { id: Number(p.id), latitude: Number(p.latitude), longitude: Number(p.longitude), iconPath: '/images/pet.png', width: active ? 38 : 28, height: active ? 38 : 28, zIndex: active ? 10 : 1, callout: { content: active ? '已选中 · ' + p.name : p.name, display: active ? 'ALWAYS' : 'BYCLICK', padding: 10, borderRadius: 12, bgColor: active ? '#AD603C' : '#FFFDF9', color: active ? '#FFFFFF' : '#654837' } }
    })
  },
  selectPlace(e) {
    const id = Number(e.detail && e.detail.markerId)
    const selected = this.data.list.find(p => Number(p.id) === id)
    if (selected) this.setData({ selected, placesOpen: false, markers: this.makeMarkers(this.data.list, selected) })
  },
  closeSelected() { this.setData({ selected: null, markers: this.makeMarkers(this.data.list, null) }) },
  detail(e) { const id = Number(e.currentTarget.dataset.id); if (id) wx.navigateTo({ url: '/pages/place/index?id=' + id }) },
  async submit() { if (await ui.auth()) wx.navigateTo({ url: '/pages/edit/index?kind=place' }) }
})
