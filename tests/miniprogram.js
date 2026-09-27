const assert = require('assert')
const fs = require('fs')
const vm = require('vm')
const path = require('path')
const root = path.join(__dirname, '..', 'miniprogram')
function page(name, state, api, wx = {}) {
  let result
  const ui = { auth: async () => state.loggedIn, decorate: x => x, types: {}, date: () => '2027-01-01 09:00', error() {} }
  vm.runInNewContext(fs.readFileSync(path.join(root, 'pages', name, 'index.js'), 'utf8'), {
    require: file => file.includes('utils/api') ? api : ui,
    Page: value => { result = value },
    wx: { setNavigationBarTitle() {}, ...wx }
  })
  result.setData = patch => { for (const [key,value] of Object.entries(patch)) { const parts=key.split('.'); let target=result.data; for(const part of parts.slice(0,-1)) { target=target[part] } target[parts[parts.length-1]]=value } }
  return result
}
async function run() {
  const state = { loggedIn: false }
  let reads = 0
  const record = page('record', state, { get: async () => { reads++; return { id: 7 } } })
  record.onLoad({ id: 7 }); await record.onShow()
  assert.equal(reads, 0)
  state.loggedIn = true; await record.onShow()
  assert.equal(record.data.item.id, 7, '登录返回记录详情必须加载')
  state.loggedIn = false
  const edit = page('edit', state, { get: async () => ({}) })
  await edit.onLoad({ kind: 'pet' })
  assert.equal(edit.data.fields.length, 0)
  state.loggedIn = true; edit.onShow()
  await new Promise(resolve => setImmediate(resolve))
  assert(edit.data.fields.some(field => field.key === 'name'), '登录返回宠物表单必须初始化')
  edit.data.form.name = '未提交草稿'; edit.onShow()
  await new Promise(resolve => setImmediate(resolve))
  assert.equal(edit.data.form.name, '未提交草稿', '返回页面不得清空表单')
  const schemas = [{code:'food',name:'食物',fields:[{key:'food',label:'食物内容',kind:'text',required:true},{key:'amount',label:'喂食量',kind:'number',required:true}]},{code:'wash',name:'洗澡',fields:[{key:'shampoo',label:'洗护用品',kind:'text',required:false}]}]
  const dynamic = page('edit',state,{get:async url=>url==='index/config'?{record_schemas:schemas}:{total:1,list:[{id:1,name:'小猫'}]}})
  await dynamic.onLoad({kind:'record'})
  assert(dynamic.data.fields.some(f=>f.key==='value_food'))
  dynamic.data.form.value_food='旧类型内容'
  dynamic.choose({currentTarget:{dataset:{key:'type'}},detail:{value:1}})
  assert(dynamic.data.fields.some(f=>f.key==='value_shampoo'))
  assert(!dynamic.data.fields.some(f=>f.key==='value_food'))
  assert(!('value_food' in dynamic.data.form),'切换类型不得携带旧类型内容')
  const reminderForm = page('edit',state,{get:async url=>url==='index/config'?{record_schemas:schemas}:{total:1,list:[{id:1,name:'小猫'}]}})
  await reminderForm.onLoad({kind:'reminder'})
  assert.deepEqual(reminderForm.data.fields.find(f=>f.key==='type').options.map(f=>f.value),['food','wash'],'提醒与记录必须共用后台类型')
  let modal
  const home = page('home',state,{}, {showModal: value=>{modal=value},navigateTo:()=>{throw new Error('问诊不应跳转')}})
  home.go({currentTarget:{dataset:{path:'consult'}}})
  assert.equal(modal.content,'暂未开放功能')
  assert.equal(modal.showCancel,false)
  const placeForm=page('edit',state,{get:async()=>({categories:{custompark:'新公园',cafe:'宠物咖啡'}})})
  await placeForm.onLoad({kind:'place'})
  assert.deepEqual(placeForm.data.fields.find(f=>f.key==='category').options.map(f=>f.value),['custompark','cafe'])
  assert.equal(placeForm.data.form.category,'custompark')
  let locateSuccess
  const centered=page('map',state,{get:async url=>url==='index/config'?{categories:{}}:{total:1,list:[{id:1,latitude:39,longitude:116}]}},{getLocation: options=>{locateSuccess=options.success}})
  centered.onLoad();await centered.load();locateSuccess({latitude:30.5,longitude:104.1})
  await centered.load()
  assert.equal(centered.data.latitude,30.5,'点位加载不能覆盖当前位置')
  assert.equal(centered.data.longitude,104.1);assert.equal(centered.data.scale,11)
  assert.equal(centered.data.located,true)
  const denied=page('map',state,{}, {getLocation: options=>options.fail(),showToast(){}})
  denied.onLoad();assert.equal(denied.data.located,false);assert.equal(denied.data.scale,4,'拒绝定位保留全国视角')
  let selectedUrl = ''
  let mapReads = 0
  const map = page('map', state, {get:async (url, params) => {
    if (url === 'index/config') return {categories:{park:'公园'}}
    mapReads++
    return {total:101,list:Array.from({length:params.page===1?100:1},(_,i)=>({id:(params.page-1)*100+i+1,latitude:31,longitude:121,source:'official'}))}
  }}, {navigateTo: ({url})=>{selectedUrl=url}})
  await map.load()
  assert.equal(mapReads,2,'地图必须读取后续分页点位')
  assert.equal(map.data.markers.length,101)
  assert.equal(map.data.scale,4,'加载全国点位不能自动放大地图')
  map.selectPlace({detail:{markerId:2}})
  assert.equal(selectedUrl,'','首次点击点位只展示卡片')
  assert.equal(map.data.selected.id,2)
  assert.equal(map.data.markers[1].iconPath,'/images/pet.png')
  assert(map.data.markers[1].width>map.data.markers[0].width,'选中点位放大高亮')
  map.selectPlace({detail:{markerId:3}})
  assert.equal(map.data.selected.id,3)
  assert.equal(map.data.markers[1].width,28,'旧点位取消高亮')
  map.detail({currentTarget:{dataset:{id:3}}})
  assert.equal(selectedUrl,'/pages/place/index?id=3','信息卡跳转选中的点位')
  map.closeSelected();assert.equal(map.data.selected,null)
  const reviewPage=page('place',state,{})
  reviewPage.rate({currentTarget:{dataset:{rating:2}}});assert.equal(reviewPage.data.rating,2)
  reviewPage.rate({currentTarget:{dataset:{rating:6}}});assert.equal(reviewPage.data.rating,2,'只接受1至5星')
  map.data.list=[{id:1,source:'official'},{id:2,source:'user'}]
  map.showUserPlaces();assert.equal(map.data.placesOpen,true)
  assert.equal(map.data.selected,null)
  map.closePlaces();assert.equal(map.data.placesOpen,false)
  const submissions=page('map',state,{get:async url=>url==='index/config'?{categories:{}}:{total:2,list:[{id:1,source:'official'},{id:2,source:'user'}]}})
  await submissions.load();assert.deepEqual(submissions.data.userPlaces.map(x=>x.id),[2],'投稿弹窗不包含官方点位')
  assert.equal(reviewPage.data.reviewOpen,false,'评分表单默认不展示')
  reviewPage.openReview();assert.equal(reviewPage.data.reviewOpen,true)
  reviewPage.input({detail:{value:'草稿'}});reviewPage.closeReview()
  assert.equal(reviewPage.data.content,'');assert.equal(reviewPage.data.reviewOpen,false)
  const submitted=page('place',state,{post:async()=>{},get:async url=>url==='index/place'?{id:1,status:1}:{list:[{id:1,rating:4}],page:1,total:1}},{showToast(){}})
  submitted.id=1;submitted.openReview();submitted.data.content='体验很好';submitted.data.rating=4
  await submitted.review();assert.equal(submitted.data.reviewOpen,false);assert.equal(submitted.data.reviews.length,1,'提交后刷新评论列表')
  const failedReview=page('place',state,{post:async()=>{throw new Error('网络失败')}})
  failedReview.openReview();failedReview.data.content='保留草稿';await failedReview.review()
  assert.equal(failedReview.data.reviewOpen,true);assert.equal(failedReview.data.content,'保留草稿','失败保留窗口和输入')
  let release
  const stale = page('map',state,{get:async(url,params)=>{
    if(url==='index/config') return {categories:{park:'公园'}}
    if(params.category==='old') await new Promise(resolve=>{release=resolve})
    return {total:1,list:[{id:params.category==='old'?1:2,latitude:31,longitude:121}]}
  }})
  stale.data.category='old';const first=stale.load()
  await new Promise(resolve=>setImmediate(resolve))
  stale.data.category='new';await stale.load();release();await first
  assert.equal(stale.data.markers[0].id,2,'旧分类慢请求不能覆盖新分类')
  let cleared = 0; let navigated = 0; const storage = {}; const app = { clearSession() { cleared++ } }
  const module = { exports: {} }
  let mode = '401'
  vm.runInNewContext(fs.readFileSync(path.join(root, 'utils/api.js'), 'utf8'), {
    require: () => ({ apiBase: 'https://example.test/api' }), module,
    getApp: () => app, getCurrentPages: () => [{ route: 'pages/record/index', options: { id: 7 } }],
    wx: {
      getStorageSync: () => ({ token: 'test-token' }), setStorageSync: (k, v) => { storage[k] = v },
      navigateTo: () => { navigated++ },
      request: o => mode === 'network' ? o.fail() : o.success({ statusCode: 401, data: { code: 401, msg: '请重新登录' } }),
      uploadFile: o => o.success({ statusCode: 401, data: JSON.stringify({ code: 401, msg: '请重新登录' }) })
    }
  })
  const api = module.exports
  await assert.rejects(api.get('pet/profile'), /请重新登录/)
  await assert.rejects(api.upload('test.png'), /请重新登录/)
  assert.equal(cleared, 2, '上传和普通请求过期都应清除会话')
  assert.equal(navigated, 1, '并发过期请求不能重复打开登录页')
  assert.equal(storage.petknow_return, '/pages/record/index?id=7')
  mode = 'network'
  await assert.rejects(api.get('pet/profile'), /网络连接失败/)
  assert.equal(cleared, 2, '网络中断不应清除会话')
  console.log('通过：登录返回详情/表单、草稿保留、请求及上传过期、并发跳转、网络失败反馈')
}
run().catch(error => { console.error(error); process.exitCode = 1 })
