<template>
  <div :class="['login-wrapper', ['', 'login-form-right', 'login-form-left'][direction]]">
    <el-form
      ref="form"
      size="large"
      :model="form"
      :rules="rules"
      class="login-form ele-bg-white"
      @keyup.enter.native="doSubmit">
      <div class="login-heading">
        <img class="login-logo" src="@/assets/logo.png" alt=""/>
        <div>
          <h1>{{ projectName }}</h1>
          <p>{{ $t('login.title') }}</p>
        </div>
      </div>
      <el-form-item prop="username">
        <label class="login-sr-only" for="login-username">{{ $t('login.username') }}</label>
        <el-input
          id="login-username"
          clearable
          autocomplete="username"
          v-model="form.username"
          prefix-icon="el-icon-user"
          :placeholder="$t('login.username')"/>
      </el-form-item>
      <el-form-item prop="password">
        <label class="login-sr-only" for="login-password">{{ $t('login.password') }}</label>
        <el-input
          id="login-password"
          show-password
          autocomplete="current-password"
          v-model="form.password"
          prefix-icon="el-icon-lock"
          :placeholder="$t('login.password')"/>
      </el-form-item>
      <el-form-item prop="captcha">
        <label class="login-sr-only" for="login-captcha">{{ $t('login.captcha') }}</label>
        <div class="login-input-group">
          <el-input
            id="login-captcha"
            clearable
            autocomplete="off"
            maxlength="8"
            v-model="form.captcha"
            prefix-icon="el-icon-_vercode"
            :placeholder="$t('login.captcha')"/>
          <button
            type="button"
            class="login-captcha"
            :disabled="captchaLoading"
            aria-label="刷新验证码"
            title="点击刷新验证码"
            @click="changeCode">
            <img v-if="captcha" :src="captcha" alt="图形验证码"/>
            <i v-else class="el-icon-loading" aria-hidden="true"></i>
          </button>
        </div>
      </el-form-item>
      <div class="el-form-item">
        <el-checkbox v-model="form.remember">{{ $t('login.remember') }}</el-checkbox>
      </div>
      <div class="el-form-item">
        <el-button
          size="large"
          type="primary"
          class="login-btn"
          :loading="loading"
          @click="doSubmit">
          {{ loading ? $t('login.loading') : $t('login.login') }}
        </el-button>
      </div>
    </el-form>
    <div class="login-copyright">Copyright © 2026. All rights reserved.</div>
  </div>
</template>

<script>
import setting from '@/config/setting'

export default {
  name: 'Login',
  data() {
    return {
      // 登录框方向, 0居中, 1居右, 2居左
      direction: 0,
      // 加载状态
      loading: false,
      // 表单数据
      form: {
        username: '',
        password: '',
        captcha: '',
        key: '',
        remember: true
      },
      // 验证码base64数据
      captcha: '',
      captchaLoading: false,
      projectName: process.env.VUE_APP_NAME || this.$t('login.title'),
      // 验证码内容, 实际项目去掉
      text: ''
    }
  },
  computed: {
    // 表单验证规则
    rules() {
      return {
        username: [
          {required: true, message: this.$t('login.username'), type: 'string', trigger: 'blur'}
        ],
        password: [
          {required: true, message: this.$t('login.password'), type: 'string', trigger: 'blur'}
        ],
        captcha: [
          {required: true, message: this.$t('login.captcha'), type: 'string', trigger: 'blur'}
        ]
      }
    },
    // 当前语言
    language() {
      return this.$i18n.locale
    }
  },
  mounted() {
    if (setting.takeToken()) {
      this.goHome()
    } else {
      this.changeCode()
    }
  },
  methods: {
    /* 提交 */
    doSubmit() {
      if (this.loading) {
        return
      }
      this.$refs.form.validate((valid) => {
        if (!valid) {
          return false
        }
        this.loading = true
        this.$http.post('/login/login', this.form).then((res) => {
          if (res.data.code === 0) {
            this.$message.success('登录成功')
            this.$store.dispatch('user/setToken', {
              token: 'Bearer ' + res.data.data.access_token,
              remember: this.form.remember,
              expiresAt: res.data.data.expires_at
            }).then(() => {
              this.goHome()
            })
          } else {
            this.$message.error(res.data.msg)
            // 重新刷新验证码
            this.changeCode()
          }
        }).catch((e) => {
          this.$message.error(e.message)
          this.changeCode()
        }).finally(() => {
          this.loading = false
        })
      })
    },
    /* 跳转到首页 */
    goHome() {
      const query = this.$route.query
      const path = query && query.from ? query.from : '/'
      this.$router.push(path).catch(() => {
      })
    },
    /* 更换图形验证码 */
    changeCode() {
      if (this.captchaLoading) {
        return
      }
      this.captchaLoading = true
      this.form.captcha = ''
      this.$http.get('/login/captcha').then(res => {
        if (res.data.code === 0) {
          this.captcha = res.data.data.captcha
          this.form.key = res.data.data.key
          this.$refs.form.clearValidate()
        } else {
          this.$message.error(res.data.msg)
        }
      }).catch((e) => {
        this.$message.error(e.message)
      }).finally(() => {
        this.captchaLoading = false
      })
    }
  }
}
</script>

<style scoped>
/* 背景 */
.login-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 50px 20px 84px;
  position: relative;
  box-sizing: border-box;
  background-color: #e9e5d9;
  background-image: url("~@/assets/login-cat.svg"), url("~@/assets/login-dog.svg");
  background-position: left center, right center;
  background-repeat: no-repeat;
  background-size: 44% auto, 44% auto;
  min-height: 100vh;
}

.login-wrapper:before {
  content: "";
  background: rgba(255, 255, 255, .12);
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
}

/* 卡片 */
.login-form {
  margin: 0;
  width: 400px;
  max-width: 100%;
  padding: 32px;
  position: relative;
  box-shadow: 0 24px 64px rgba(8, 29, 55, .24);
  box-sizing: border-box;
  border: 1px solid rgba(255, 255, 255, .7);
  border-radius: 10px;
  z-index: 2;
}

.login-form-right .login-form {
  margin: 0 15% 0 auto;
}

.login-form-left .login-form {
  margin: 0 auto 0 15%;
}

.login-heading {
  display: flex;
  align-items: center;
  gap: 14px;
  margin-bottom: 28px;
}

.login-logo {
  width: 48px;
  height: 48px;
  object-fit: contain;
}

.login-heading h1 {
  margin: 0 0 5px;
  font-size: 22px;
  font-weight: 600;
  line-height: 1.25;
}

.login-heading p {
  margin: 0;
  color: #909399;
  font-size: 13px;
}

.login-sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

.login-form > .el-form-item {
  margin-bottom: 25px;
}

/* 验证码 */
.login-input-group {
  display: flex;
  align-items: center;
}

.login-input-group ::v-deep .el-input {
  flex: 1;
}

.login-captcha {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 38px;
  width: 102px;
  padding: 0;
  margin-left: 10px;
  border-radius: 4px;
  border: 1px solid #DCDFE6;
  text-align: center;
  cursor: pointer;
  overflow: hidden;
  background: #fff;
  transition: border-color .2s, opacity .2s;
}

.login-captcha img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.login-captcha:hover {
  border-color: #409EFF;
}

.login-captcha:disabled {
  cursor: wait;
  opacity: .7;
}

.login-btn {
  display: block;
  width: 100%;
}

/* 第三方登录图标 */
.login-oauth-icon {
  color: #FFF;
  padding: 5px;
  margin: 0 10px;
  font-size: 18px;
  border-radius: 50%;
  cursor: pointer;
}

/* 底部版权 */
.login-copyright {
  color: #eee;
  padding-top: 20px;
  text-align: center;
  position: relative;
  z-index: 1;
}

/* 响应式 */
@media screen and (min-height: 550px) {
  .login-copyright {
    position: absolute;
    bottom: 20px;
    right: 0;
    left: 0;
  }
}

@media screen and (max-width: 768px) {
  .login-wrapper {
    padding: 24px 16px 72px;
  }

  .login-form {
    padding: 26px 22px;
  }

  .login-heading {
    margin-bottom: 24px;
  }
}
</style>
