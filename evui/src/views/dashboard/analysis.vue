<template>
  <petknow-board v-if="$hasPermission('pet:overview:view')" module="overview"/>
  <el-card v-else class="ele-body" shadow="never">
    <h2>欢迎使用豆知宠物管理后台</h2>
    <p>请从左侧菜单进入已授权的业务模块。</p>
  </el-card>
</template>
<script>
import PetknowBoard from '@/views/petknow/Board'
export default { name: 'Analysis', components: { PetknowBoard } }
</script>
