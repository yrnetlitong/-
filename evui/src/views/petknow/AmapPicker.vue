<template>
  <el-dialog title="高德地图选点" :visible="visible" @update:visible="$emit('update:visible',$event)" width="960px" top="5vh" append-to-body :close-on-click-modal="false" @opened="init" @closed="dispose">
    <el-alert v-if="error" :title="error" type="error" :closable="false" show-icon class="map-error"/>
    <el-form inline @submit.native.prevent="search">
      <el-form-item><el-input v-model="keyword" placeholder="搜索城市、地址或场所名称" clearable maxlength="100" @keyup.enter.native="search"/></el-form-item>
      <el-form-item><el-button type="primary" :disabled="!ready" :loading="searching" @click="search">搜索地点</el-button><el-button v-if="error && !ready" @click="init">重试加载</el-button></el-form-item>
    </el-form>
    <div class="map-layout" v-loading="loading">
      <div ref="map" class="amap-canvas"/>
      <div v-if="searched" class="map-results"><el-empty v-if="!results.length" description="未找到地点，请补充城市或更换关键词" :image-size="70"/><button v-for="p in results" :key="p.id" class="map-result" @click="choosePoi(p)"><strong>{{p.name}}</strong><span>{{p.addressText}}</span></button></div>
    </div>
    <div class="map-selection"><span v-if="locating"><i class="el-icon-loading"/> 正在获取地址…</span><template v-else-if="selected"><strong>{{selected.address}}</strong><div>经度：{{selected.longitude}} 纬度：{{selected.latitude}}</div></template><span v-else>搜索地点或点击地图，选择点位的实际位置。</span></div>
    <span slot="footer"><el-button @click="$emit('update:visible',false)">取消</el-button><el-button type="primary" :disabled="!selected || locating" @click="confirm">使用此位置</el-button></span>
  </el-dialog>
</template>
<script>
import AMapLoader from '@amap/amap-jsapi-loader'
import {getPetMapConfig} from '@/api/petknow'
export default {
  name:'PetknowAmapPicker',props:{visible:Boolean,location:{type:Object,default:()=>({})}},
  data(){return {keyword:'',loading:false,ready:false,searching:false,searched:false,locating:false,error:'',results:[],selected:null}},
  beforeDestroy(){this.dispose()},
  methods:{
    async init(){
      this.dispose();this.loading=true;this.error='';this.keyword=this.location.address || '';this.results=[];this.searched=false;this.selected=null
      const generation=this.generation
      try{
        const config=await getPetMapConfig();if(!this.visible||generation!==this.generation){return}
        AMapLoader.reset();window._AMapSecurityConfig={serviceHost:config.service_host}
        const AMap=await AMapLoader.load({key:config.key,version:'2.0',plugins:['AMap.PlaceSearch','AMap.Geocoder','AMap.ToolBar']})
        if(!this.visible||generation!==this.generation){return}
        this.AMap=AMap
        const hasLocation=this.location.longitude!==undefined&&this.location.latitude!==undefined&&Number.isFinite(Number(this.location.longitude))&&Number.isFinite(Number(this.location.latitude))
        const center=hasLocation?[Number(this.location.longitude),Number(this.location.latitude)]:[104.2,35.86]
        this.map=new AMap.Map(this.$refs.map,{zoom:hasLocation?16:4,center,resizeEnable:true})
        this.map.addControl(new AMap.ToolBar());this.marker=new AMap.Marker({map:this.map,position:center,visible:hasLocation})
        this.geocoder=new AMap.Geocoder({extensions:'base'});this.placeSearch=new AMap.PlaceSearch({pageSize:10,extensions:'base'})
        this.map.on('click',e=>this.selectPoint(e.lnglat))
        if(hasLocation&&this.location.address){this.selected={address:this.location.address,longitude:center[0],latitude:center[1]}}
        this.ready=true
      }catch(e){if(generation===this.generation){this.error=e.message || '地图加载失败，请检查网络或高德参数'}}finally{if(generation===this.generation){this.loading=false}}
    },
    search(){
      if(!this.ready||this.searching||!this.keyword.trim()){return}
      this.searching=true;this.error='';const generation=this.generation
      this.placeSearch.search(this.keyword.trim(),(status,result)=>{
        if(generation!==this.generation){return}this.searching=false;this.searched=true
        this.results=status==='complete'?(result.poiList.pois || []).filter(p=>p.location).map(p=>({...p,addressText:[p.pname,p.cityname,p.adname,p.address].filter(x=>typeof x==='string').join('')})):[]
        if(status==='error'){this.error='地点搜索失败：'+(result.info || '请检查网络后重试')}
      })
    },
    choosePoi(p){this.map.setZoomAndCenter(16,p.location);this.selectPoint(p.location,p.name)},
    selectPoint(point,name=''){
      const sequence=this.sequence=(this.sequence || 0)+1;const generation=this.generation
      this.selected=null;this.locating=true;this.error='';this.marker.setPosition(point);this.marker.show()
      this.geocoder.getAddress(point,(status,result)=>{
        if(generation!==this.generation||sequence!==this.sequence){return}this.locating=false
        if(status!=='complete'||!result.regeocode||!result.regeocode.formattedAddress){this.error='地址解析失败，请重新选点或搜索更具体的位置';return}
        this.selected={name,address:result.regeocode.formattedAddress,longitude:Number(point.getLng().toFixed(7)),latitude:Number(point.getLat().toFixed(7))}
      })
    },
    confirm(){if(!this.selected||this.locating){return}this.$emit('select',{...this.selected});this.$emit('update:visible',false)},
    dispose(){this.generation=(this.generation || 0)+1;if(this.map){this.map.destroy();this.map=null}this.ready=false;this.loading=false;this.searching=false;this.locating=false}
  }
}
</script>
<style scoped>
.map-error{margin-bottom:15px}.map-layout{display:flex;height:400px;min-height:300px;border:1px solid #dcdfe6}.amap-canvas{flex:1;min-width:0;height:100%}.map-results{width:260px;overflow-y:auto;border-left:1px solid #dcdfe6;background:#fff}.map-result{display:block;width:100%;border:0;border-bottom:1px solid #ebeef5;background:white;text-align:left;padding:14px;cursor:pointer;color:#303133}.map-result:hover,.map-result:focus{background:#ecf5ff}.map-result strong,.map-result span{display:block;line-height:1.6;word-break:break-word}.map-result span{color:#909399;font-size:12px;margin-top:6px}.map-selection{padding-top:16px;line-height:1.7;color:#606266}.map-selection div{font-size:12px;color:#909399}@media(max-width:768px){.map-layout{height:360px;flex-direction:column}.amap-canvas{min-height:240px}.map-results{width:100%;height:120px;border-left:0}}
</style>
