<template>
  <div class="ele-body">
    <el-card shadow="never">
      <el-form inline @submit.native.prevent="search">
        <el-form-item><el-input v-model="query.keyword" :placeholder="label+'名称'" clearable @keyup.enter.native="search"/></el-form-item>
        <el-form-item><el-select v-model="query.status" placeholder="状态" clearable><el-option label="启用" :value="1"/><el-option label="停用" :value="2"/></el-select></el-form-item>
        <el-form-item><el-button type="primary" @click="search">查询</el-button><el-button @click="reset">重置</el-button></el-form-item>
      </el-form>
      <div class="toolbar"><el-button v-if="canEdit" type="primary" icon="el-icon-plus" @click="edit()">新增{{label}}</el-button><el-button icon="el-icon-refresh" :loading="loading" @click="load">刷新</el-button></div>
      <el-table :data="rows" border v-loading="loading">
        <el-table-column prop="name" :label="label" min-width="160"/>
        <el-table-column v-if="module==='recordtypes'" label="记录字段" min-width="300"><template slot-scope="s"><el-tag v-for="f in s.row.fields" :key="f.key" class="field-tag" size="small">{{f.label}}{{f.required?' *':''}}</el-tag></template></el-table-column>
        <el-table-column prop="sort" label="排序" width="90"/>
        <el-table-column label="状态" width="90"><template slot-scope="s"><el-tag :type="s.row.status===1?'success':'info'" size="small">{{s.row.status===1?'启用':'停用'}}</el-tag></template></el-table-column>
        <el-table-column v-if="canEdit || allowed('status') || allowed('remove')" label="操作" width="200"><template slot-scope="s"><el-button v-if="canEdit" type="text" @click="edit(s.row)">编辑</el-button><el-button v-if="allowed('status')" type="text" @click="operate(s.row,'status')">{{s.row.status===1?'停用':'启用'}}</el-button><el-button v-if="allowed('remove')" type="text" class="danger" @click="operate(s.row,'remove')">删除</el-button></template></el-table-column>
      </el-table>
      <el-pagination class="pagination" :current-page.sync="page" :page-size="20" :total="total" layout="total,prev,pager,next" @current-change="load"/>
    </el-card>
    <el-dialog :title="(form.id?'编辑':'新增')+label" :visible.sync="open" width="760px" top="6vh" append-to-body destroy-on-close :close-on-click-modal="false">
      <el-form ref="form" :model="form" label-width="90px" class="type-form">
        <el-form-item label="类型名称" prop="name" :rules="[{required:true,whitespace:true,message:'请填写'+label+'名称',trigger:'blur'}]"><el-input v-model="form.name" maxlength="40" show-word-limit/></el-form-item>
        <el-form-item label="排序"><el-input-number v-model="form.sort" :min="0" :max="65535" :precision="0"/></el-form-item>
        <el-form-item label="状态"><el-radio-group v-model="form.status"><el-radio :label="1">启用</el-radio><el-radio :label="2">停用</el-radio></el-radio-group></el-form-item>
        <el-form-item v-if="module==='recordtypes'" label="记录字段" required>
          <el-table :data="form.fields" border>
            <el-table-column label="字段名称" min-width="170"><template slot-scope="s"><el-input v-model="s.row.label" maxlength="40" placeholder="例如：食物内容"/></template></el-table-column>
            <el-table-column label="输入方式" width="130"><template slot-scope="s"><el-select v-model="s.row.kind"><el-option label="单行文本" value="text"/><el-option label="多行文本" value="textarea"/><el-option label="数字" value="number"/></el-select></template></el-table-column>
            <el-table-column label="必填" width="60"><template slot-scope="s"><el-checkbox v-model="s.row.required"/></template></el-table-column>
            <el-table-column label="操作" width="110"><template slot-scope="s"><el-button type="text" :disabled="s.$index===0" @click="move(s.$index)">上移</el-button><el-button type="text" :disabled="form.fields.length===1" @click="form.fields.splice(s.$index,1)">移除</el-button></template></el-table-column>
          </el-table>
          <el-button class="add-field" icon="el-icon-plus" :disabled="form.fields.length>=20" @click="addField">添加字段</el-button>
          <div class="help">按此顺序显示在小程序记录表单中；修改字段不会改变已保存的历史记录。</div>
        </el-form-item>
      </el-form>
      <span slot="footer"><el-button :disabled="saving" @click="open=false">取消</el-button><el-button type="primary" :loading="saving" @click="save">保存</el-button></span>
    </el-dialog>
  </div>
</template>
<script>
import {getPetList,operatePet} from '@/api/petknow'
export default {
  name:'PetknowTypeManager', props:{module:{type:String,required:true}},
  data(){return {rows:[],total:0,page:1,query:{keyword:'',status:''},loading:false,saving:false,open:false,form:{fields:[]}}},
  computed:{label(){return this.module==='recordtypes'?'记录类型':'点位类型'},canEdit(){return this.$hasPermission('pet:'+this.module+':edit')}},
  mounted(){this.load()},activated(){this.load()},
  methods:{
    allowed(action){return this.$hasPermission('pet:'+this.module+':'+action)},
    async load(){if(this.loading){return}this.loading=true;try{const r=await getPetList({...this.query,module:this.module,page:this.page});this.rows=r.list;this.total=r.total;if(!r.list.length&&this.page>1){this.page--;this.loading=false;return this.load()}}catch(e){this.$message.error(e.message)}finally{this.loading=false}},
    search(){this.page=1;this.load()},reset(){this.query={keyword:'',status:''};this.search()},
    edit(row){this.form=row?{fields:[],...JSON.parse(JSON.stringify(row))}:{name:'',status:1,sort:125,fields:[]};if(!row&&this.module==='recordtypes'){this.addField()}this.open=true;this.$nextTick(()=>this.$refs.form.clearValidate())},
    addField(){this.form.fields.push({key:'f'+Date.now().toString(36)+Math.random().toString(36).slice(2,6),label:'',kind:'text',required:false})},
    move(i){const row=this.form.fields.splice(i,1)[0];this.form.fields.splice(i-1,0,row)},
    save(){this.$refs.form.validate(async valid=>{if(!valid||this.saving){return}const names=this.form.fields.map(f=>f.label.trim());if(this.module==='recordtypes'&&(names.some(n=>!n)||new Set(names).size!==names.length)){return this.$message.error('字段名称不能为空或重复')}this.saving=true;try{await operatePet({...this.form,fields:this.form.fields.map(f=>({...f,required:Number(f.required)})),module:this.module,action:'save'});this.open=false;this.$message.success('保存成功');this.load()}catch(e){this.$message.error(e.message)}finally{this.saving=false}})},
    async operate(row,action){try{await this.$confirm(action==='remove'?'确认删除此'+this.label+'？已有数据引用的类型只能停用。':'确认更改此'+this.label+'状态？','提示',{type:'warning'});await operatePet({module:this.module,id:row.id,action});this.$message.success('操作成功');this.load()}catch(e){if(e&&e.message){this.$message.error(e.message)}}}
  }
}
</script>
<style scoped>
.toolbar{margin-bottom:15px}.field-tag{margin:3px 6px 3px 0}.pagination{margin-top:20px;text-align:right}.type-form{max-height:65vh;overflow-y:auto;padding-right:12px}.add-field{margin-top:12px}.help{color:#909399;font-size:12px;line-height:1.7;margin-top:10px}.danger{color:#f56c6c}
</style>
