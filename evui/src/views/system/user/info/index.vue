<template>
  <div class="ele-body"><el-card shadow="never" v-loading="loading">
    <el-alert v-if="error" :title="error" type="error" :closable="false"/>
    <el-descriptions v-if="user" :column="2" border>
      <el-descriptions-item label="用户姓名">{{ user.realname }}</el-descriptions-item>
      <el-descriptions-item label="用户账号">{{ user.username }}</el-descriptions-item>
      <el-descriptions-item label="角色">{{ (user.roles || []).map(r=>r.name).join('、') || '-' }}</el-descriptions-item>
      <el-descriptions-item label="状态">{{ user.status===1?'在用':'禁用' }}</el-descriptions-item>
    </el-descriptions>
    <el-button v-if="user && $hasPermission('sys:user:edit')" type="primary" style="margin-top:20px" @click="showEdit=true">修改用户</el-button>
    <user-edit :data="user" :visible.sync="showEdit" @done="load"/>
  </el-card></div>
</template>
<script>
import {getUser} from '@/api/user'
import UserEdit from '../user-edit'
export default {
  name:'SystemUserInfo',components:{UserEdit},data(){return {user:null,loading:false,error:'',showEdit:false}},
  watch:{'$route.query.id':{immediate:true,handler(){this.load()}}},
  methods:{async load(){this.loading=true;this.error='';try{const r=await getUser(this.$route.query.id);if(r.data.code!==0){throw new Error(r.data.msg)}this.user=r.data.data}catch(e){this.error=e.message}finally{this.loading=false}}}
}
</script>
