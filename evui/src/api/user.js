import axios from 'axios'
export const saveUser = data => axios.post('/user/edit', data)
export const getUser = id => axios.get('/user/info', {params:{id}})
export const getUserRoles = () => axios.get('/role/getRoleList')
