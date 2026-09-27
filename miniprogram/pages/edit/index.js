const api = require('../../utils/api'); const ui = require('../../utils/ui')
const options = {
  type: [['cat', '猫咪'], ['dog', '狗狗'], ['other', '其他']],
  gender: [['unknown', '未填写'], ['male', '男生'], ['female', '女生']],
  neutered: [['unknown', '未填写'], ['yes', '已绝育'], ['no', '未绝育']],
  cycle: [['once', '单次'], ['daily', '每天'], ['weekly', '每周'], ['monthly', '每月'], ['custom', '自定义天数']]
}
const text = (key, label, max, required = false, kind = 'text') => ({ key, label, max, required, kind })
const select = (key, label, values) => ({ key, label, kind: 'select', options: values.map(x => ({ value: x[0], label: x[1] })) })
function fields(kind, schemas = [], type = '', categories = []) {
  const typeOptions = schemas.map(row => [row.code, row.name])
  const schema = schemas.find(row => row.code === type)
  if (kind === 'pet') return [text('name', '宠物昵称', 40, true), select('type', '宠物类型', options.type), text('breed', '品种', 80), select('gender', '性别', options.gender), { key: 'birthday', label: '生日', kind: 'date' }, text('weight', '体重（kg）', 7, true, 'digit'), text('color', '毛色', 60), select('neutered', '绝育情况', options.neutered), text('vaccination', '疫苗情况', 500, false, 'textarea'), text('character_note', '性格特点', 500), text('note', '想记住的小细节', 3000, false, 'textarea')]
  if (kind === 'record') return [select('type', '记录类型', typeOptions), { key: 'occurred_at', label: '记录时间', kind: 'datetime', required: true }, ...(schema ? schema.fields.map(f => text('value_' + f.key, f.label, f.kind === 'textarea' ? 3000 : 120, f.required, f.kind === 'number' ? 'digit' : f.kind)) : []), { key: 'next_at', label: '下次养护时间（可选）', kind: 'datetime' }, text('note', '备注说明', 3000, false, 'textarea')]
  if (kind === 'reminder') return [text('title', '提醒事项', 80, true), select('type', '提醒类型', typeOptions), { key: 'due_at', label: '到期时间', kind: 'datetime', required: true }, select('cycle', '重复周期', options.cycle), text('interval_days', '自定义周期天数', 4, true, 'number'), text('advance_days', '提前提醒天数', 3, true, 'number')]
  return [text('name', '场所名称', 100, true), select('category', '场所分类', categories), text('address', '详细地址', 255, true), text('phone', '联系电话', 30), text('hours', '开放时间', 100), text('rules', '宠物友好规则', 3000, true, 'textarea'), text('note', '补充说明（仅审核人员可见）', 3000, false, 'textarea')]
}
Page({
  data: { kind: 'pet', title: '', fields: [], form: {}, pets: [], petIndex: 0, loading: false, saving: false, uploading: false, error: '', dates: {}, times: {} },
  async onLoad(o) {
    this.options = o; this.kind = ['pet', 'record', 'reminder', 'place'].includes(o.kind) ? o.kind : 'pet'
    this.setData({ kind: this.kind, title: { pet: '认识你的毛孩子', record: '记下这份小日常', reminder: '把关心交给提醒', place: '分享一个友好去处' }[this.kind] })
    wx.setNavigationBarTitle({ title: this.data.title }); await this.load()
  },
  async load() {
    if (this.data.loading) return
    this.setData({ loading: true, error: '' })
    if (!(await ui.auth())) { this.setData({ loading: false }); return }
    try {
      let form = { name: '', type: this.kind === 'pet' ? 'cat' : 'feed', gender: 'unknown', neutered: 'unknown', weight: '0', birthday: '', images: [], cycle: 'once', interval_days: '1', advance_days: '0', enabled: 1, category: 'park' }
      if (['record', 'reminder'].includes(this.kind)) {
        const config = await api.get('index/config'); this.defaultDays = config.default_days || {}; this.schemas = config.record_schemas || []
        if (!this.schemas.length) throw new Error('暂无可用记录类型，请联系管理员配置')
        form.type = this.schemas[0].code
        if (this.kind === 'reminder') form.due_at = ui.date(Date.now() / 1000 + Number(this.defaultDays[form.type] || 1) * 86400)
      }
      if (this.kind === 'record') form.occurred_at = ui.date(Date.now() / 1000)
      if (this.kind === 'place') {
        const config = await api.get('index/config'); this.categories = Object.entries(config.categories || {})
        if (!this.categories.length) throw new Error('暂无可用点位类型，请联系管理员配置')
        form.category = this.categories[0][0]
      }
      if (this.options.id) {
        const endpoint = { pet: 'pet/detail', reminder: 'pet/reminder', place: 'index/place' }[this.kind]
        form = await api.get(endpoint, { id: this.options.id })
        if (this.kind === 'place' && !this.categories.some(row => row[0] === form.category)) this.categories.push([form.category, (form.category_name || form.category) + '（已停用）'])
        if (form.due_at) form.due_at = ui.date(form.due_at)
        if (this.kind === 'reminder' && !this.schemas.some(row => row.code === form.type)) this.schemas.push({ code: form.type, name: (form.type_name || ui.types[form.type] || form.type) + '（已停用）', fields: [] })
      }
      if (['record', 'reminder'].includes(this.kind)) {
        let pets = []; let page = 1; let result
        do { result = await api.get('pet/pets', { limit: 100, page }); pets = pets.concat(result.list); page++ } while (pets.length < result.total)
        form.pet_id = form.pet_id || Number(this.options.pet_id) || (pets[0] && pets[0].id)
        this.setData({ pets, petIndex: Math.max(0, pets.findIndex(p => p.id === form.pet_id)) })
      }
      const dates = {}; const times = {}
      fields(this.kind, this.schemas, this.data.form.type, this.categories).filter(f => f.kind === 'datetime').forEach(f => { if (form[f.key]) { const parts = form[f.key].split(' '); dates[f.key] = parts[0]; times[f.key] = parts[1] } })
      this.setData({ form, dates, times }); this.refreshFields(); this.initialized = true
    } catch (e) { this.setData({ error: e.message }) } finally { this.setData({ loading: false }) }
  },
  refreshFields() { this.setData({ fields: fields(this.kind, this.schemas, this.data.form.type, this.categories).map(f => Object.assign(f, { selected: f.options ? Math.max(0, f.options.findIndex(o => o.value === this.data.form[f.key])) : 0 })) }) },
  input(e) { this.setData({ ['form.' + e.currentTarget.dataset.key]: e.detail.value }) },
  choose(e) { const field = this.data.fields.find(f => f.key === e.currentTarget.dataset.key); if (this.kind === 'record' && field.key === 'type') { const form = {...this.data.form}; Object.keys(form).filter(k => k.startsWith('value_')).forEach(k => delete form[k]); this.setData({ form }) } this.setData({ ['form.' + field.key]: field.options[Number(e.detail.value)].value }); if (this.kind === 'reminder' && field.key === 'type' && !this.options.id) { const due = ui.date(Date.now() / 1000 + Number((this.defaultDays || {})[this.data.form.type] || 1) * 86400); this.setData({ 'form.due_at': due, 'dates.due_at': due.split(' ')[0], 'times.due_at': due.split(' ')[1] }) } this.refreshFields() },
  choosePet(e) { const i = Number(e.detail.value); this.setData({ petIndex: i, 'form.pet_id': this.data.pets[i].id }) },
  date(e) { const key = e.currentTarget.dataset.key; if (key === 'birthday') this.setData({ 'form.birthday': e.detail.value }); else { this.setData({ ['dates.' + key]: e.detail.value, ['form.' + key]: e.detail.value + ' ' + (this.data.times[key] || '09:00') }) } },
  time(e) { const key = e.currentTarget.dataset.key; this.setData({ ['times.' + key]: e.detail.value }); if (this.data.dates[key]) this.setData({ ['form.' + key]: this.data.dates[key] + ' ' + e.detail.value }) },
  clearDate(e) { const key = e.currentTarget.dataset.key; this.setData({ ['form.' + key]: '', ['dates.' + key]: '', ['times.' + key]: '' }) },
  async images() {
    if (this.data.uploading) return
    try {
      const res = await new Promise((resolve, reject) => wx.chooseMedia({ count: 9 - (this.data.form.images || []).length, mediaType: ['image'], success: resolve, fail: reject }))
      this.setData({ uploading: true })
      for (const file of res.tempFiles) { const url = await api.upload(file.tempFilePath); this.setData({ 'form.images': (this.data.form.images || []).concat(url) }) }
    } catch (e) { if (!String(e.errMsg).includes('cancel')) ui.error(e) } finally { this.setData({ uploading: false }) }
  },
  deleteImage(e) { this.setData({ 'form.images': this.data.form.images.filter((_, i) => i !== Number(e.currentTarget.dataset.index)) }) }, preview: ui.preview,
  location() { wx.chooseLocation({ success: r => this.setData({ 'form.address': r.address || r.name, 'form.latitude': r.latitude, 'form.longitude': r.longitude, 'form.name': this.data.form.name || r.name }), fail: e => { if (!e.errMsg.includes('cancel')) wx.showModal({ title: '未能选择位置', content: '请在小程序设置中允许位置权限后重试。', showCancel: false }) } }) },
  async save() {
    if (this.data.saving || this.data.uploading) return
    const form = Object.assign({}, this.data.form)
    for (const f of this.data.fields) {
      if ((f.required && (form[f.key] === undefined || String(form[f.key]).trim() === '')) || (f.max && String(form[f.key] || '').length > f.max)) { ui.error(new Error('请检查' + f.label)); return }
    }
    if (this.kind === 'record') {
      const schema = (this.schemas || []).find(row => row.code === form.type)
      if (!schema) return ui.error(new Error('请选择记录类型'))
      form.values = {}
      for (const f of schema.fields) {
        const value = String(form['value_' + f.key] || '').trim()
        if (value && f.kind === 'number' && !Number.isFinite(Number(value))) return ui.error(new Error(f.label + '请填写数字'))
        form.values[f.key] = value; delete form['value_' + f.key]
      }
    }
    if (['record', 'reminder'].includes(this.kind) && !form.pet_id) return ui.error(new Error('请先添加宠物'))
    if (this.kind === 'place' && (form.latitude === undefined || form.longitude === undefined)) return ui.error(new Error('请通过地图选择具体位置'))
    if (form.birthday && form.birthday > ui.date(Date.now() / 1000, true)) return ui.error(new Error('生日不能晚于今天'))
    if (form.occurred_at && new Date(form.occurred_at.replace(/-/g, '/')).getTime() > Date.now()) return ui.error(new Error('记录时间不能晚于当前时间'))
    for (const key of ['next_at', 'due_at']) if (form[key] && new Date(form[key].replace(/-/g, '/')).getTime() <= Date.now()) return ui.error(new Error('下次时间必须晚于当前时间'))
    this.setData({ saving: true })
    try {
      await api.post({ pet: 'pet/save', record: 'pet/saveRecord', reminder: 'pet/saveReminder', place: 'pet/savePlace' }[this.kind], form)
      wx.showToast({ title: this.kind === 'place' ? '投稿已送审' : '保存成功' })
      wx.navigateBack({ fail: () => wx.switchTab({ url: '/pages/pets/index' }) })
    } catch (e) { ui.error(e) } finally { this.setData({ saving: false }) }
  }, addPet() { wx.navigateTo({ url: '/pages/edit/index?kind=pet' }) }, onShow() { if (this.options && !this.data.loading && (!this.initialized || (this.data.pets.length === 0 && ['record', 'reminder'].includes(this.kind)))) this.load() }
})
