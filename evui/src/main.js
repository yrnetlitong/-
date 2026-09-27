/** 主入口js */
import Vue from 'vue'
import App from './App.vue'
import store from './store'
import router from './router'
import './config/axios-config'
import permission from './utils/permission'
import './styles/index.scss'
import EleAdmin from 'ele-admin'
import DialogDirective from 'ele-admin/packages/dialog-directive'
import VueClipboard from 'vue-clipboard2'
import i18n from './lang'
import VueLazyload from 'vue-lazyload'

Vue.config.productionTip = false
Vue.use(EleAdmin, {
  i18n: (key, value) => i18n.t(key, value)
})
Vue.use(permission)
Vue.use(DialogDirective)
Vue.use(VueClipboard)

// 列表页面二次进入自动刷新
Vue.mixin({
  data() {
    return {
      listActivatedOnce: false
    }
  },
  activated() {
    if (!this.$refs || !this.$refs.table || typeof this.$refs.table.reload !== 'function') {
      return
    }
    if (!this.listActivatedOnce) {
      this.listActivatedOnce = true
      return
    }
    this.$nextTick(() => {
      const where = this.where && typeof this.where === 'object' ? this.where : {}
      this.$refs.table.reload({where: where})
    })
  }
})

// 拉加载配置
Vue.use(VueLazyload, {
  preLoad: 1.3,
  error: require('./assets/404.jpg'),
  loading: require('./assets/loading.svg'),
  attempt: 1,
  listenEvents: ['scroll']
})

new Vue({
  router,
  store,
  i18n,
  render: h => h(App)
}).$mount('#app')
