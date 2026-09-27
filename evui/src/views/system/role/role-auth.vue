<!-- 角色权限分配弹窗 -->
<template>
  <el-dialog
    title="分配权限"
    :visible="visible"
    width="440px"
    :destroy-on-close="true"
    :lock-scroll="false"
    @update:visible="updateVisible">
    <el-scrollbar
      v-loading="authLoading"
      style="height: 50vh;"
      wrapStyle="overflow-x: hidden;">
      <el-tree
        ref="tree"
        :data="authData"
        :props="{label: 'title'}"
        node-key="id"
        :default-expand-all="true"
        :default-checked-keys="checked"
        show-checkbox>
        <span slot-scope="{ data }">
          <i :class="data.icon"></i>
          <span> {{ data.title }}</span>
        </span>
      </el-tree>
    </el-scrollbar>
    <div slot="footer">
      <el-button @click="updateVisible(false)">取消</el-button>
      <el-button
        type="primary"
        @click="save"
        :loading="loading" :disabled="authLoading">保存
      </el-button>
    </div>
  </el-dialog>
</template>

<script>
import {getRolePermissions,saveRolePermissions} from '@/api/system'
export default {
  name: 'RoleAuth',
  props: {
    // 弹窗是否打开
    visible: Boolean,
    // 当前角色数据
    data: Object
  },
  data() {
    return {
      // 权限数据
      authData: [],
      // 权限数据请求状态
      authLoading: false,
      // 提交状态
      loading: false
    }
  },
  computed: {
    // 权限树选中数据
    checked() {
      const checked = []
      this.$util.eachTreeData(this.authData, d => {
        if (d.checked && (!d.children || !d.children.length)) {
          checked.push(d.id)
        }
      })
      return checked
    }
  },
  watch: {
    visible() {
      if (this.visible) {
        this.query()
      }
    }
  },
  methods: {
    /* 查询权限数据 */
    query() {
      this.authData = []
      if (!this.data) {return}
      this.authLoading = true
      getRolePermissions(this.data.id).then(rows => {
        this.authData = this.$util.toTreeData(rows, 'id', 'pid')
      }).catch(e => this.$message.error(e.message)).finally(()=>{this.authLoading=false})
    },
    /* 保存权限分配 */
    save() {
      if(this.loading || this.authLoading || !this.$refs.tree){return}
      this.loading = true
      const ids = this.$refs.tree.getCheckedKeys().concat(this.$refs.tree.getHalfCheckedKeys())
      saveRolePermissions({role_id:this.data.id,menu_id:ids}).then(()=>{
        this.$message.success('授权已保存，用户刷新页面后生效')
        this.updateVisible(false)
      }).catch(e=>this.$message.error(e.message)).finally(()=>{this.loading=false})
    },
    /* 更新visible */
    updateVisible(value) {
      this.$emit('update:visible', value)
    }
  }
}
</script>

<style scoped>
</style>
