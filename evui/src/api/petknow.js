import axios from 'axios'
function unwrap(promise) {
  return promise.then(({data}) => {
    if (data.code !== 0) {throw new Error(data.msg || '请求失败')}
    return data.data
  })
}
export const getPetList = params => unwrap(axios.get('/petknow/index', {params}))
export const getPetDetail = params => unwrap(axios.get('/petknow/detail', {params}))
export const operatePet = data => unwrap(axios.post('/petknow/operate', data))
export const savePetSettings = data => unwrap(axios.post('/petknow/settings', data))

export const getPetMapConfig = () => unwrap(axios.get('/petknow/mapconfig', {params:{module:'places'}}))
