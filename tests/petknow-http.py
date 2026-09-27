import json,subprocess,urllib.request,urllib.error,urllib.parse,time,os
from pathlib import Path
os.chdir(Path(__file__).resolve().parent.parent)
password=os.environ['PETKNOW_TEST_ADMIN_PASSWORD']
BASE='http://127.0.0.1:8000'
count=0

def php(code):
 p=subprocess.run(['php'],input="<?php require 'vendor/autoload.php'; $app=new think\\App(getcwd());$app->initialize(); define('DB_PREFIX',config('database.connections.mysql.prefix')); "+code,text=True,capture_output=True,check=True)
 return json.loads(p.stdout)
def req(path,data=None,token='',expected=0):
 global count
 headers={'Content-Type':'application/json'}
 if token:headers['Authorization']='Bearer '+token
 r=urllib.request.Request(BASE+path,data=json.dumps(data).encode() if data is not None else None,headers=headers)
 try:response=urllib.request.urlopen(r,timeout=20)
 except urllib.error.HTTPError as e:response=e
 body=json.loads(response.read())
 assert body.get('code')==expected,(path,body)
 count+=1
 return body.get('data')
def upload(token,payload,mime='image/png',expected=0):
 global count
 boundary='petknowQA';body=b'--'+boundary.encode()+b'\r\nContent-Disposition: form-data; name="file"; filename="acceptance.png"\r\nContent-Type: '+mime.encode()+b'\r\n\r\n'+payload+b'\r\n--'+boundary.encode()+b'--\r\n'
 r=urllib.request.Request(BASE+'/api/upload/uploadImage',data=body,headers={'Authorization':'Bearer '+token,'Content-Type':'multipart/form-data; boundary='+boundary})
 try:res=urllib.request.urlopen(r)
 except urllib.error.HTTPError as e:res=e
 j=json.loads(res.read());assert j['code']==expected,j;count+=1;return j.get('data')
assert php("echo json_encode(in_array(config('database.connections.mysql.hostname'), ['127.0.0.1','localhost'], true));"), '验收数据仅允许写入本地数据库'
fixtures=php('''$out=[];foreach([1,2] as $i){$id=think\\facade\\Db::name('member')->insertGetId(['username'=>'acceptance_'.bin2hex(random_bytes(8)),'nickname'=>'验收账号'.$i,'status'=>1,'mark'=>1,'create_time'=>time()]);$out[]=app\\common\\service\\PetSession::issue($id)+['id'=>$id];}echo json_encode($out);''')
a,b=fixtures;t=a['token'];admin='';official=0;limited=None;managed=0;dynamic_type=0;log_fixtures=[]
try:
 cap=req('/admin/login/captcha')
 captcha=php("echo json_encode(think\\facade\\Cache::get('login_captcha_"+cap['key']+"')); ")
 req('/admin/login/login',{'username':'admin','password':password,'captcha':'520','key':cap['key']},expected=1)
 login=req('/admin/login/login',{'username':'admin','password':password,'captcha':captcha,'key':cap['key']});admin=login['access_token']
 req('/admin/login/login',{'username':'admin','password':password,'captcha':captcha,'key':cap['key']},expected=1)
 limited=php("$id=think\\facade\\Db::name('user')->insertGetId(['username'=>'qa_'.bin2hex(random_bytes(6)),'realname'=>'权限验收','status'=>1,'mark'=>1]);$role=think\\facade\\Db::name('role')->insertGetId(['name'=>'验收只读','code'=>'qa_'.bin2hex(random_bytes(6)),'status'=>1,'mark'=>1]);think\\facade\\Db::name('user_role')->insert(['user_id'=>$id,'role_id'=>$role]);$menu=think\\facade\\Db::name('menu')->where(['permission'=>'pet:pets:view','type'=>1])->value('id');think\\facade\\Db::name('role_menu')->insert(['role_id'=>$role,'menu_id'=>$menu]);echo json_encode(['id'=>$id,'role'=>$role,'token'=>(new Jwt())->getToken((string)$id)]);")
 for path in ['/admin/role/getPermissionList?role_id='+str(limited['role']),'/admin/loginlog/index','/admin/actionlog/index','/admin/menu/index']:
  req(path,token=limited['token'],expected=403)
 req('/admin/role/savePermission',{'role_id':limited['role'],'menu_id':[]},limited['token'],403)
 permission_rows=req('/admin/role/getPermissionList?role_id='+str(limited['role']),token=admin)
 permission_map={x['permission']:x['id'] for x in permission_rows if x['type']==1}
 assert all(x in permission_map for x in ['sys:role:permission','sys:loginlog:delete','sys:operlog:detail','pet:records:detail','pet:records:edit'])
 visible=req('/admin/index/getMenuList',token=admin)
 assert [x['title'] for x in visible if not x['hide']]==['系统管理','用户信息','记录管理','友好点位']
 selected=[permission_map['pet:pets:view'],permission_map['sys:loginlog:view']]
 req('/admin/role/savePermission',{'role_id':limited['role'],'menu_id':selected},admin)
 req('/admin/loginlog/index',token=limited['token'])
 req('/admin/loginlog/index?export=1',token=limited['token'],expected=403)
 req('/admin/loginlog/delete',{'id':0},limited['token'],403)
 assigned=req('/admin/role/getPermissionList?role_id='+str(limited['role']),token=admin)
 assert {x['id'] for x in assigned if x.get('checked')} >= set(selected)
 req('/admin/role/savePermission',{'role_id':limited['role'],'menu_id':[999999]},admin,1)
 req('/admin/role/savePermission',{'role_id':limited['role'],'menu_id':[]},admin)
 req('/admin/loginlog/index',token=limited['token'],expected=403)
 req('/admin/role/savePermission',{'role_id':limited['role'],'menu_id':[permission_map['pet:pets:view']]},admin)
 for kind in ['loginlog','actionlog']:
  logs=req('/admin/'+kind+'/index',token=admin)
  if logs['list']:req('/admin/'+kind+'/info?id='+str(logs['list'][0]['id']),token=admin)
 log_fixtures=php("$m=new app\\admin\\model\\ActionLog();$out=[];foreach([1,3] as $kind){$out[]=think\\facade\\Db::table($m->getTable())->insertGetId(['username'=>'日志验收','type'=>$kind,'mark'=>1,'param'=>json_encode(['password'=>'sensitive-test']),'create_time'=>time()]);}echo json_encode($out);")
 for kind,id in zip(['loginlog','actionlog'],log_fixtures):
  detail=req('/admin/'+kind+'/info?id='+str(id),token=admin)
  assert 'sensitive-test' not in detail['param']
 req('/admin/loginlog/delete',{'id':log_fixtures[1]},admin,1)
 req('/admin/loginlog/delete',{'id':log_fixtures[0]},admin)
 req('/admin/loginlog/info?id='+str(log_fixtures[0]),token=admin,expected=1)
 req('/admin/actionlog/delete',{'id':log_fixtures[1]},admin,404)
 managed_data={'realname':'管理验收','username':'qa_manage_'+str(int(time.time())),'role_ids':[limited['role']],'password':'qaPass2468','status':1}
 managed=req('/admin/user/edit',managed_data,admin)['id']
 user=req('/admin/user/info?id='+str(managed),token=admin)
 assert user['realname']=='管理验收' and len(user['roles'])==1
 def user_login(pwd,expected=0):
  cap=req('/admin/login/captcha')
  code=php("echo json_encode(think\\facade\\Cache::get('login_captcha_"+cap['key']+"')); ")
  return req('/admin/login/login',{'username':managed_data['username'],'password':pwd,'captcha':code,'key':cap['key']},expected=expected)
 user_login('qaPass2468')
 req('/admin/user/edit',dict(managed_data,id=managed,realname='修改姓名',password=''),admin)
 user_login('qaPass2468')
 req('/admin/user/edit',dict(managed_data,id=managed,password='qaPass9876'),admin)
 user_login('qaPass2468',1);user_login('qaPass9876')
 for patch in [{'realname':''},{'username':'bad space'},{'role_ids':[]},{'role_ids':[999999]},{'password':'123'},{'status':0}]:
  req('/admin/user/edit',dict(managed_data,id=managed,**patch),admin,1)
 req('/admin/user/edit',dict(managed_data,id=managed,status=2,password=''),admin)
 user_login('qaPass9876',1)
 menus=req('/admin/index/getMenuList',token=admin)
 assert all(m.get('hide')==1 for m in menus if m['path']=='/data')
 req('/admin/petknow/index?module=pets',token=limited['token'])
 req('/admin/petknow/index?module=members',token=limited['token'],expected=403)
 req('/admin/petknow/index?module=placetypes',token=limited['token'],expected=403)
 req('/admin/petknow/mapconfig?module=places',token=limited['token'],expected=403)
 mapconfig=req('/admin/petknow/mapconfig?module=places',token=admin)
 assert mapconfig['service_host'].endswith('/_AMapService') and 'security_code' not in mapconfig
 req('/api/amap/'+'0'*48+'/_AMapService/v3/place/text?s=rsv3',expected=403)
 proxy=mapconfig['service_host'].removeprefix(BASE)
 req(proxy+'/v3/invalid?s=rsv3',expected=403)
 req(proxy+'/v3/place/text?s=rsv3&callback=alert(1)',expected=403)
 def flatten(nodes):
  return [child for node in nodes for child in [node]+flatten(node.get('children',[]))]
 assert any(m.get('path')=='/petknow/placetypes' for m in flatten(menus))

 req('/admin/petknow/operate',{'module':'pets','action':'remove','id':0},limited['token'],403)
 req('/admin/petknow/settings',{'module':'settings'},limited['token'],403)
 req('/admin/petknow/delete?module=pets',token=limited['token'],expected=404)
 req('/api/pet/pets',expected=401);req('/api/pet/pets',token=admin,expected=401)
 image=upload(t,open('miniprogram/images/pet.png','rb').read());assert urllib.request.urlopen(image).status==200
 upload(t,b'not-an-image',expected=422);upload('',b'not-an-image',expected=401)
 req('/api/pet/saveProfile',{'nickname':'验收昵称','avatar':image},t)
 assert req('/api/pet/profile',token=t)['nickname']=='验收昵称'
 req('/api/pet/saveProfile',{'nickname':'','avatar':''},t,422)
 petdata={'name':'验收宠物','type':'cat','gender':'female','neutered':'yes','weight':3.2,'birthday':'2024-02-29','images':[image],'note':'详情换行\n中文和 emoji 🐾'}
 pet=req('/api/pet/save',petdata,t)['id']; petdata.update(id=pet,name='验收宠物修改');req('/api/pet/save',petdata,t)
 assert req('/api/pet/detail?id='+str(pet),token=t)['name']=='验收宠物修改'
 req('/api/pet/detail?id='+str(pet),token=b['token'],expected=422)
 req('/api/pet/save',dict(petdata,weight=-1),t,422)
 req('/api/pet/save',dict(petdata,birthday='2025-02-30'),t,422)
 records=[]
 for kind in ['feed','bath','internal','external']:
  payload={'pet_id':pet,'type':kind,'product':'验收用品','occurred_at':time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time()-120)),'amount':'20g','method':'按说明','images':[image]}
  records.append(req('/api/pet/saveRecord',payload,t)['id'])
  assert req('/api/pet/records?pet_id='+str(pet)+'&type='+kind,token=t)['total']==1
 req('/api/pet/record?id='+str(records[0]),token=t)
 req('/api/pet/removeRecord',{'id':records[0]},b['token'],422);req('/api/pet/removeRecord',{'id':records[0]},t)
 req('/api/pet/removeRecord',{'id':records[0]},t,422)
 # 多页读取及单页上限。
 for i in range(22):req('/api/pet/save',dict(petdata,id=0,name='分页验收'+str(i)),t)
 pg1=req('/api/pet/pets',token=t);pg2=req('/api/pet/pets?page=2',token=t)
 assert len(pg1['list'])==20 and len(pg2['list'])==3 and not ({x['id'] for x in pg1['list']}&{x['id'] for x in pg2['list']})
 rem={'pet_id':pet,'title':'验收提醒','type':'bath','cycle':'daily','interval_days':1,'advance_days':0,'enabled':1,'due_at':time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time()+86400))}
 rid=req('/api/pet/saveReminder',rem,t)['id'];req('/api/pet/reminderAction',{'id':rid,'action':'toggle'},t)
 assert req('/api/pet/reminder?id='+str(rid),token=t)['enabled']==0
 req('/api/pet/reminderAction',{'id':rid,'action':'toggle'},t);req('/api/pet/saveReminder',dict(rem,id=rid,title='已编辑提醒'),t)
 req('/api/pet/reminderAction',{'id':rid,'action':'complete'},t);req('/api/pet/reminderAction',{'id':rid,'action':'complete'},t,422)
 parent=req('/api/pet/reminder?id='+str(rid),token=t)
 req('/api/pet/reminderAction',{'id':rid,'action':'toggle'},t,422)
 req('/api/pet/reminderAction',{'id':rid,'action':'remove'},t,422)
 req('/api/pet/reminderAction',{'id':parent['next_id'],'action':'remove'},t)
 req('/api/pet/reminderAction',{'id':rid,'action':'remove'},t)
 place={'name':'验收点位','category':'park','address':'验收地址','latitude':31.23,'longitude':121.47,'phone':'021-12345678','rules':'牵绳','images':[image],'note':'审核私密备注'}
 pid=req('/api/pet/savePlace',place,t)['id'];req('/api/index/place?id='+str(pid),expected=404)
 pending=req('/admin/petknow/index?module=places&source=user&status=0',token=admin)
 assert any(str(x['id'])==str(pid) for x in pending['list']), '投稿必须出现在后台待审核列表'
 assert all(x['status']==0 and x['source']=='user' for x in pending['list'])
 req('/admin/petknow/operate',{'module':'places','id':pid,'action':'reject','reason':''},admin,422)
 req('/admin/petknow/operate',{'module':'places','id':pid,'action':'reject','reason':'补充规则'},admin)
 assert req('/api/index/place?id='+str(pid),token=t)['rejection']=='补充规则'
 req('/api/pet/savePlace',dict(place,id=pid,rules='牵绳并清理排泄物'),t)
 req('/admin/petknow/operate',{'module':'places','id':pid,'action':'approve'},admin)
 assert not any(str(x['id'])==str(pid) for x in req('/admin/petknow/index?module=places&source=user&status=0',token=admin)['list'])
 assert any(str(x['id'])==str(pid) for x in req('/api/index/places?keyword='+urllib.parse.quote('验收点位'))['list'])
 req('/admin/petknow/operate',{'module':'places','id':pid,'action':'approve'},admin,422)
 public=req('/api/index/place?id='+str(pid));assert 'note' not in public and public['status']==1
 req('/api/pet/savePlace',dict(place,id=pid),t,422)
 req('/api/pet/review',{'place_id':pid,'rating':5,'content':'验收评价'},t)
 req('/api/pet/review',{'place_id':pid,'rating':5,'content':'重复评价'},t,422)
 assert req('/api/index/reviews?place_id='+str(pid))['total']==1
 notices=req('/api/pet/messages',token=t);assert len(notices['list'])>=2
 req('/api/pet/readMessage',{'id':notices['list'][0]['id']},t)
 assert req('/api/pet/messages',token=t)['list'][0]['pet_read_at']>0
 for action in ['status','status']:req('/admin/petknow/operate',{'module':'places','id':pid,'action':action},admin)
 official=req('/admin/petknow/operate',dict(place,module='places',action='save',name='官方验收点位'),admin)['id']
 req('/admin/petknow/operate',dict(place,id=official,module='places',action='save',name='官方验收修改'),admin)
 req('/admin/petknow/operate',{'module':'places','id':official,'action':'top'},admin)
 assert req('/api/index/places?keyword='+urllib.parse.quote('官方验收修改'))['list'][0]['is_top']==1
 for module in ['overview','members','pets','records','places','reminders','settings']:
  req('/admin/petknow/index?module='+module,token=admin)
 for module,id in [('members',a['id']),('pets',pet),('records',records[1]),('places',pid)]:req('/admin/petknow/detail?module='+module+'&id='+str(id),token=admin)
 definition={'module':'recordtypes','action':'save','name':'HTTP动态类型','sort':1,'status':1,'fields':[{'key':'food','label':'食物内容','kind':'text','required':1},{'key':'quantity','label':'喂食量','kind':'number','required':1}]}
 req('/admin/petknow/index?module=recordtypes',token=limited['token'],expected=403)
 req('/admin/petknow/operate',definition,limited['token'],403)
 req('/admin/petknow/operate',dict(definition,fields=[]),admin,422)
 req('/admin/petknow/operate',dict(definition,fields=definition['fields']*2),admin,422)
 dynamic_type=req('/admin/petknow/operate',definition,admin)['id']
 req('/admin/petknow/operate',definition,admin,422)
 listing=req('/admin/petknow/index?module=recordtypes&keyword=HTTP',token=admin)
 assert listing['total']==1 and len(listing['list'][0]['fields'])==2
 code=listing['list'][0]['code']
 config=req('/api/index/config');assert config['record_types'][code]=='HTTP动态类型'
 dynamic={'pet_id':pet,'type':code,'occurred_at':time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time()-120)),'values':{'food':'鸡肉','quantity':'30'}}
 req('/api/pet/saveRecord',dict(dynamic,values={'food':'鸡肉'}),t,422)
 req('/api/pet/saveRecord',dict(dynamic,values={'food':'鸡肉','quantity':'abc'}),t,422)
 rid=req('/api/pet/saveRecord',dynamic,t)['id']
 rr=req('/api/pet/record?id='+str(rid),token=t);assert rr['type_name']=='HTTP动态类型' and [v['value'] for v in rr['field_values']]==['鸡肉','30']
 req('/api/pet/saveReminder',dict(rem,type=code),t)
 req('/admin/petknow/operate',dict(definition,id=dynamic_type,name='HTTP更名类型'),admin)
 rr=req('/api/pet/record?id='+str(rid),token=t);assert rr['type_name']=='HTTP动态类型'
 req('/admin/petknow/operate',{'module':'recordtypes','action':'remove','id':dynamic_type},admin,422)
 req('/admin/petknow/operate',{'module':'recordtypes','action':'status','id':dynamic_type},admin)
 assert code not in req('/api/index/config')['record_types']
 req('/api/pet/saveRecord',dynamic,t,422)
 req('/api/pet/saveReminder',dict(rem,type=code),t,422)
 settings=req('/admin/petknow/index?module=settings',token=admin)
 req('/admin/petknow/settings',dict(settings,module='settings',pet_default_days='invalid'),admin,422)
 req('/admin/petknow/settings',dict(settings,module='settings'),admin)
 req('/admin/petknow/operate',{'module':'members','id':a['id'],'action':'status'},admin)
 req('/api/pet/profile',token=t,expected=401)
 req('/admin/petknow/operate',{'module':'members','id':a['id'],'action':'status'},admin)
 req('/api/pet/remove',{'id':pet},t)
 assert req('/api/pet/records?pet_id='+str(pet),token=t)['total']==0
 req('/admin/petknow/operate',{'module':'recordtypes','action':'remove','id':dynamic_type},admin)
 req('/api/pet/logout',{},t);req('/api/pet/profile',token=t,expected=401)
 print('HTTP 全流程通过：',count,'个请求断言，含动态类型配置与权限、字段校验、历史快照、停用限制、上传、编辑、四类记录、分页、周期删除、投稿审核、评价、消息、官方点位、后台模块、停用和退出')
finally:
 if log_fixtures:
  php("$m=new app\\admin\\model\\ActionLog();think\\facade\\Db::table($m->getTable())->whereIn('id',"+str(log_fixtures)+")->delete();echo json_encode(true);")
 if dynamic_type:
  php("think\\facade\\Db::name('dict_data')->where('id',"+str(dynamic_type)+")->delete();echo json_encode(true);")
 if managed:
  php("think\\facade\\Db::name('user_role')->where('user_id',"+str(managed)+")->delete();think\\facade\\Db::name('user')->where('id',"+str(managed)+")->delete();echo json_encode(true);")
 if limited:
  php("think\\facade\\Db::name('user_role')->where('user_id',"+str(limited['id'])+")->delete();think\\facade\\Db::name('role_menu')->where('role_id',"+str(limited['role'])+")->delete();think\\facade\\Db::name('role')->where('id',"+str(limited['role'])+")->delete();think\\facade\\Db::name('user')->where('id',"+str(limited['id'])+")->delete();echo json_encode(true);")
 ids=','.join(str(x['id']) for x in fixtures)
 php('''$ids=['''+ids+'''];foreach(['pet_review','pet_record','pet_reminder','pet','pet_place'] as $table){think\\facade\\Db::name($table)->whereIn('member_id',$ids)->delete();}think\\facade\\Db::name('notice')->whereIn('pet_member_id',$ids)->delete();think\\facade\\Db::name('member')->whereIn('id',$ids)->delete();think\\facade\\Db::name('pet_place')->where('id','''+str(official)+''')->where('source','official')->delete();echo json_encode(true);''')
