/**
 * axios配置
 */
import Vue from 'vue'
import VueAxios from 'vue-axios'
import axios from 'axios'
import store from '../store'
import router from '../router'
import setting from './setting'
import {MessageBox} from 'element-ui'

Vue.use(VueAxios, axios)

// 设置统一的url
axios.defaults.baseURL = process.env.VUE_APP_API_BASE_URL

/* 请求拦截器 */
axios.interceptors.request.use((config) => {
  // 添加token到header
  const token = setting.takeToken()
  if (token) {
    config.headers[setting.tokenHeaderName] = token
  }
  return config
}, (error) => {
  return Promise.reject(error)
})

/* 响应拦截器 */
axios.interceptors.response.use((res) => {
  // 登录过期处理
  if (res.data.code === 401) {
    if (res.config.url === setting.menuUrl) {
      goLogin()
    } else {
      MessageBox.alert('登录状态已过期, 请退出重新登录!', '系统提示', {
        confirmButtonText: '重新登录',
        callback: (action) => {
          if (action === 'confirm') {
            goLogin(true)
          }
        },
        beforeClose: () => {
          MessageBox.close()
        }
      })
    }
    return Promise.reject(new Error(res.data.msg))
  }
  // token自动续期
  const access_token = res.headers[setting.tokenHeaderName]
  if (access_token) {
    const remember = !!localStorage.getItem(setting.tokenStoreName)
    setting.cacheToken(access_token, remember, setting.takeTokenExpireAt())
  }
  return res
}, (error) => {
  return Promise.reject(error)
})

/**
 * 跳转到登录页面
 */
function goLogin(reload) {
  store.dispatch('user/removeToken').then(() => {
    if (reload) {
      const loginUrl = router.resolve({path: '/login'}).href
      location.replace(loginUrl)  // 避免重复注册动态路由，且兼容 /adminadmin/ 部署路径
    } else {
      const path = router.currentRoute.path
      return router.push({
        path: '/login',
        query: path && path !== '/' ? {from: path} : null
      })
    }
  })
}
