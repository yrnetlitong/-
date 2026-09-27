import axios from 'axios'
const unwrap = promise => promise.then(({data}) => {
  if(data.code!==0){throw new Error(data.msg || '请求失败')}
  return data.data
})
export const getRolePermissions = role_id => unwrap(axios.get('/role/getPermissionList',{params:{role_id}}))
export const saveRolePermissions = data => unwrap(axios.post('/role/savePermission',data))
export const getLogDetail = (kind,id) => unwrap(axios.get('/'+kind+'/info',{params:{id}}))
export async function getLogExport(kind,where){
  let list=[],page=1,result
  do{result=await unwrap(axios.get('/'+kind+'/index',{params:{...where,page,limit:100,export:'1'}}));list=list.concat(result.list);page++}while(result.list.length && list.length<result.total)
  return list
}
