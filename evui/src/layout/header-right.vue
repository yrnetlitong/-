<!-- 顶栏右侧区域按钮 -->
<template>
  <div class="ele-admin-header-tool">
    <!-- 全屏切换 -->
    <button
      type="button"
      class="ele-admin-header-tool-item ele-header-icon-button hidden-xs-only"
      :aria-label="fullscreen ? '退出全屏' : '进入全屏'"
      @click="changeFullscreen">
      <i :class="fullscreen ? 'el-icon-_screen-restore' : 'el-icon-_screen-full'"></i>
    </button>
    <!-- 语言切换 -->
    <div class="ele-admin-header-tool-item">
      <el-dropdown placement="bottom" @command="changeLanguage">
        <i class="el-icon-_language"></i>
        <el-dropdown-menu slot="dropdown">
          <el-dropdown-item command="en">
            <span :class="{'ele-text-primary': language === 'en'}">English</span>
          </el-dropdown-item>
          <el-dropdown-item command="zh_CN">
            <span :class="{'ele-text-primary': language === 'zh_CN'}">简体中文</span>
          </el-dropdown-item>
          <el-dropdown-item command="zh_TW">
            <span :class="{'ele-text-primary': language === 'zh_TW'}">繁體中文</span>
          </el-dropdown-item>
        </el-dropdown-menu>
      </el-dropdown>
    </div>
    <!-- 消息通知（已移除） -->
    <!-- <div class="ele-admin-header-tool-item">
      <ele-notice/>
    </div> -->
    <!-- 用户信息 -->
    <div class="ele-admin-header-tool-item">
      <el-dropdown @command="onUserDropClick">
        <div class="ele-admin-header-avatar">
          <el-avatar :src="loginUser.avatar"/>
          <span class="hidden-xs-only">{{ loginUser.nickname }}</span>
          <i class="el-icon-arrow-down hidden-xs-only"></i>
        </div>
        <el-dropdown-menu slot="dropdown">
          <el-dropdown-item command="profile" icon="el-icon-user">
            {{ $t('layout.header.profile') }}
          </el-dropdown-item>
          <el-dropdown-item command="password" icon="el-icon-key">
            {{ $t('layout.header.password') }}
          </el-dropdown-item>
          <el-dropdown-item command="logout" icon="el-icon-switch-button" divided>
            {{ $t('layout.header.logout') }}
          </el-dropdown-item>
        </el-dropdown-menu>
      </el-dropdown>
    </div>
    <!-- 主题设置 -->
    <button
      v-if="showSetting"
      type="button"
      class="ele-admin-header-tool-item ele-header-icon-button"
      aria-label="打开主题设置"
      @click="openSetting">
      <i class="el-icon-_more"></i>
    </button>
  </div>
</template>

<script>
// import EleNotice from './notice'; // 已移除通知功能
import {isFullscreen, toggleFullscreen} from 'ele-admin/packages/util'

export default {
  name: 'EleHeaderRight',
  // components: {EleNotice}, // 已移除通知功能
  emits: ['item-click', 'change-language'],
  props: {
    // 是否显示打开设置抽屉按钮
    showSetting: {
      type: Boolean,
      default: true
    }
  },
  computed: {
    // 当前登录用户信息
    loginUser() {
      return this.$store.state.user.user
    },
    // 当前语言
    language() {
      return this.$i18n.locale
    }
  },
  data() {
    return {
      // 是否全屏状态
      fullscreen: false
    }
  },
  methods: {
    /* 个人信息下拉菜单点击 */
    onUserDropClick(command) {
      if (command === 'logout') {
        // 退出登录
        this.$confirm(
          this.$t('layout.logout.message'),
          this.$t('layout.logout.title'),
          {type: 'warning'}
        ).then(() => {
          // 调用接口退出登录
          this.$http.get('/login/logout').then(res => {
            if (res.data.code === 0) {
              // 清除缓存的token
              this.$store.dispatch('user/removeToken').then(() => {
                const loginUrl = this.$router.resolve({path: '/login'}).href
                location.replace(loginUrl)  // 避免重复注册动态路由，且兼容 /adminadmin/ 部署路径
              })
            } else {
              this.$message.error(res.data.msg)
            }
          }).catch((e) => {
            this.$message.error(e.message)
          })

        }).catch(() => {
        })
      } else if (command === 'profile') {
        if (this.$route.fullPath !== '/user/profile') {
          this.$router.push('/user/profile')
        }
      } else if (command === 'password') {
        this.$emit('item-click', 'password')
      }
    },
    /* 打开设置抽屉 */
    openSetting() {
      this.$emit('item-click', 'setting')
    },
    /* 全屏切换 */
    changeFullscreen() {
      try {
        this.fullscreen = toggleFullscreen()
      } catch (e) {
        this.$message.error('您的浏览器不支持全屏模式')
      }
    },
    /* 检查全屏状态 */
    checkFullscreen() {
      this.fullscreen = isFullscreen()
    },
    /* 切换语言 */
    changeLanguage(lang) {
      this.$emit('change-language', lang)
    }
  }
}
</script>

<style scoped>
.ele-header-icon-button {
  padding: 0;
  color: inherit;
  font: inherit;
  border: 0;
  background: transparent;
  cursor: pointer;
}
</style>
