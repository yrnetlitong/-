const types = { cat: '猫咪', dog: '狗狗', other: '其他', feed: '喂食', bath: '洗澡', internal: '内驱', external: '外驱', vaccine: '疫苗', exam: '体检', custom: '自定义', male: '男生', female: '女生', unknown: '未填写', yes: '已绝育', no: '未绝育', restaurant: '餐厅', hotel: '酒店', park: '公园', grooming: '洗护', hospital: '医院', once: '单次', daily: '每天', weekly: '每周', monthly: '每月' }
const pad = n => String(n).padStart(2, '0')
function date(value, short = false) {
  if (!value) return '-'
  const d = new Date(Number(value) * 1000)
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}` + (short ? '' : ` ${pad(d.getHours())}:${pad(d.getMinutes())}`)
}
function decorate(row) {
  return Object.assign({}, row, { typeText: row.type_name || types[row.type] || row.type, categoryText: row.category_name || types[row.category], genderText: types[row.gender], neuteredText: types[row.neutered], cycleText: types[row.cycle], timeText: date(row.occurred_at || row.due_at || row.create_time), nextText: date(row.next_at), statusText: ['待审核', '已通过', '已驳回', '已下架'][row.status], overdue: row.due_at && row.due_at * 1000 < Date.now(), cover: (row.images || [])[0] || '/images/pet.png' })
}
async function auth() {
  await getApp().ready
  if (getApp().globalData.user) return true
  const pages = getCurrentPages(); const current = pages[pages.length - 1]
  wx.setStorageSync('petknow_return', '/' + current.route + '?' + Object.keys(current.options || {}).map(k => k + '=' + encodeURIComponent(current.options[k])).join('&'))
  wx.navigateTo({ url: '/pages/login/index' })
  return false
}
function error(e) { wx.showToast({ title: e.message || '操作失败', icon: 'none' }) }
function confirm(content) { return new Promise(resolve => wx.showModal({ title: '请确认', content, confirmColor: '#B6532D', success: r => resolve(r.confirm) })) }
function preview(e) { const urls = e.currentTarget.dataset.urls; wx.previewImage({ urls, current: e.currentTarget.dataset.src }) }
module.exports = { types, date, decorate, auth, error, confirm, preview }
