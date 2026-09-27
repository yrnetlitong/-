<template>
  <el-dialog width="520px" :visible="visible" :destroy-on-close="true" custom-class="ele-dialog-form" :title="data?'修改用户':'添加用户'" @update:visible="updateVisible">
    <el-form ref="form" :model="form" :rules="rules" label-width="90px">
      <el-form-item label="用户姓名:" prop="realname"><el-input v-model="form.realname" maxlength="20" placeholder="请输入用户姓名" clearable/></el-form-item>
      <el-form-item label="用户账号:" prop="username"><el-input v-model="form.username" maxlength="20" :disabled="!!data" placeholder="请输入用户账号" clearable/></el-form-item>
      <el-form-item label="角色:" prop="role_ids"><el-select v-model="form.role_ids" multiple class="ele-fluid" placeholder="请选择角色"><el-option v-for="role in roleList" :key="role.id" :value="role.id" :label="role.name"/></el-select></el-form-item>
      <el-form-item label="登录密码:" prop="password"><el-input v-model="form.password" show-password maxlength="20" autocomplete="new-password" :placeholder="data?'留空保留原密码':'请输入6至20位密码'"/></el-form-item>
      <el-form-item label="状态:" prop="status"><el-radio-group v-model="form.status"><el-radio :label="1">在用</el-radio><el-radio :label="2">禁用</el-radio></el-radio-group></el-form-item>
    </el-form>
    <div slot="footer"><el-button @click="updateVisible(false)">取消</el-button><el-button type="primary" :loading="loading" @click="save">保存</el-button></div>
  </el-dialog>
</template>
<script>
import {saveUser, getUserRoles} from '@/api/user'
export default {
  name:'UserEdit', props:{visible:Boolean,data:Object},
  data(){return {form:{},loading:false,roleList:[],rules:{
    realname:[{required:true,whitespace:true,message:'请输入用户姓名',trigger:'blur'}],
    username:[{required:true,pattern:/^[A-Za-z0-9_]{3,20}$/,message:'账号为3至20位字母、数字或下划线',trigger:'blur'}],
    role_ids:[{required:true,type:'array',min:1,message:'请选择角色',trigger:'change'}],
    password:[{validator:(rule,value,callback)=>{if((!this.data || value) && !/^\S{6,20}$/.test(value || '')){return callback(new Error('密码为6至20位非空白字符'))}callback()},trigger:'blur'}],
    status:[{required:true,message:'请选择状态',trigger:'change'}]
  }}},
  watch:{visible:{immediate:true,handler(value){if(value){const d=this.data || {};this.form={id:d.id,realname:d.realname || '',username:d.username || '',role_ids:(d.roles || []).map(r=>r.id),password:'',status:d.status || 1};this.queryRoles()}}}},
  methods:{
    updateVisible(value){this.$emit('update:visible',value)},
    async queryRoles(){try{const r=await getUserRoles();if(r.data.code!==0){throw new Error(r.data.msg)}this.roleList=r.data.data}catch(e){this.$message.error(e.message)}},
    save(){this.$refs.form.validate(async valid=>{if(!valid || this.loading){return}this.loading=true;try{const r=await saveUser(this.form);if(r.data.code!==0){throw new Error(r.data.msg)}this.$message.success(r.data.msg);this.updateVisible(false);this.$emit('done')}catch(e){this.$message.error(e.message)}finally{this.loading=false}})}
  }
}
</script>
