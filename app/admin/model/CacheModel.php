<?php


namespace app\admin\model;


use think\Model;
use think\facade\Cache;

/**
 * 缓存基类
 *
 */
class CacheModel extends Model
{

    // 是否启用缓存
    protected $is_cache = false;

    /**
     * 重置缓存
     *
     * @param int $id 记录ID
     * @param array $data 数据源
     * @param bool $is_edit 是否编辑true或false
     * @return mixed 返回结果
     * @author admin
     * @date 2020-04-21
     */
    public function cacheReset($id, $data = [], $is_edit = false)
    {
        if (!$data) {
            $this->resetCacheFunc('info', $id);
        }
        $info = [];
        if ($is_edit) {
            $info = $this->getCacheFunc("info", $id);
        }
        if (is_array($data)) {
            $info = array_merge($info, $data);
        } else {
            $info = $data;
        }
        $cache_key = $this->getCacheKey('info', $id);
        $result = $this->setCache($cache_key, $info);
        return $result;
    }

    /**
     * 删除缓存
     *
     * @param $id 记录ID
     * @return bool 返回结果
     * @author admin
     * @date 2020-04-21
     */
    public function cacheDelete($id)
    {
        $cache_key = $this->getCacheKey("info", $id);
        $result = $this->deleteCache($cache_key);
        return $result;
    }

    /**
     * 获取缓存
     *
     * @param int $id 记录ID
     * @return array 返回结果
     * @author admin
     * @date 2020-04-21
     */
    public function cacheInfo($id)
    {
        if (!$id) {
            return false;
        }
        $data = $this->find((int)$id);
        // 获取对象原始数据,如果不存在指定字段返回false
        $data = !empty($data) ? $data->toArray() : [];
        return $data;
    }

    /**
     * 重置缓存函数
     *
     * @param string $funcName 方法名
     * @param string $id 记录ID
     * @return bool 返回结果true或false
     * @author admin
     * @date 2020-04-21
     */
    public function resetCacheFunc($funcName, $id = '')
    {
        $cache_key = $this->getCacheKey($funcName, $id);
        $result = $this->deleteCache($cache_key);
        return $result;
    }

    /**
     * 获取缓存函数
     *
     * @param string $funcName 方法名
     * @param int $id 记录ID
     * @return mixed 返回结果
     * @author admin
     * @date 2020-04-21
     */
    public function getCacheFunc($funcName, $id)
    {
        $arg_list = func_get_args();
//        $cache_key = $this->getCacheKey($funcName, $id);
//        $data = $this->getCache($cache_key);
//        if (!$data) {
            if ($this->name) {
                array_shift($arg_list);
            }
            $act = "cache" . ucfirst($funcName);
            $data = call_user_func_array(array($this, $act), $arg_list);
//            $this->setCache($cache_key, $data);yyy
//        }
        return $data;
    }

    /**
     * 获取缓存KEY
     *
     * @return string 返回缓存KEY
     * @author admin
     * @date 2020-04-21
     */
    private function getCacheKey()
    {
        $arg_list = func_get_args();
        if ($this->name) {
            array_unshift($arg_list, DB_PREFIX . $this->name);
        }
        foreach ($arg_list as $key => $val) {
            if (is_array($val)) {
                unset($arg_list[$key]);
            }
        }
        $cache_key = implode("_", $arg_list);
        return $cache_key;
    }

    /**
     * 设置缓存
     *
     * @param string $cache_key 缓存KEY
     * @param $data 缓存数据
     * @param int $ttl 缓存时间(默认永久)
     * @return mixed
     * @author admin
     * @date 2020-04-21
     */
    public function setCache($cache_key, $data, $ttl = 0)
    {
        // 设置缓存池
        if (isset($GLOBALS['trans']) && $GLOBALS['trans'] === true) {
            $GLOBALS['trans_keys'][] = $cache_key;
        }
        // 不设置缓存，直接返回
        if (!$this->is_cache) {
            return true;
        }
        if (!$data) {
            return Cache::set($cache_key, null);
        }
        $isGzcompress = gzcompress(json_encode($data));
        if ($isGzcompress) {
            $result = Cache::set($cache_key, $isGzcompress, $ttl);
        }
        return $result;
    }

    /**
     * 获取缓存
     *
     * @param string $cache_key 缓存KEY
     * @return mixed 返回结果
     * @author admin
     * @date 2020-04-21
     */
    public function getCache($cache_key)
    {
        $data = Cache::get($cache_key);
        if ($data) {
            $data = json_decode(gzuncompress($data), true);
        }
        return $data;
    }

    /**
     * 删除缓存
     *
     * @param string $cache_key 缓存KEY
     * @return bool 返回结果
     * @author admin
     * @date 2020-04-21
     */
    public function deleteCache($cache_key)
    {
        // 判断缓存KEY是否存在,存在则删除
        if (Cache::has($cache_key)) {
            return Cache::delete($cache_key);
        }
        return false;
    }

    /**
     * 获取整表缓存
     *
     * @param array $map 查询条件
     * @param bool $is_pri 是否只缓存主键true或false
     * @param bool $pri_key 是否以主键作为键值true或false
     * @return mixed 返回结果
     * @author admin
     * @date 2020-04-21
     */
    public function getAll($map = [], $is_pri = false, $pri_key = false)
    {
        $list = $this->getCacheFunc('all', $map, $is_pri, $pri_key);
        return $list;
    }

    /**
     * 设置整表缓存
     *
     * @param array $map 查询条件
     * @param bool $is_pri 是否只缓存主键true或false
     * @param bool $pri_key 是否以主键作为键值true或false
     * @return array 返回结果
     * @author admin
     * @date 2020-04-21
     */
    public function cacheAll($map = [], $is_pri = false, $pri_key = false)
    {
        // 格式化查询条件
        if (method_exists($this, 'formatQuery')) {
            $query = $this->formatQuery($this, $map);
        }

        // 是否缓存主键
        if ($is_pri) {
            if (is_array($is_pri)) {
                // 字段数组
                $query->field($is_pri);
            } elseif (is_string($is_pri)) {
                // 字段字符串
                $fields = explode(',', $is_pri);
                $query->field($fields);
            } else {
                // 默认主键ID
                $query->field($this->getPk());
            }
        }

        // 查询数据并转数组
        $result = $query->select();
        $list = [];
        if ($result) {
            foreach ($result as $val) {
                $list[] = $val->toArray();
            }
        }
        // 设置主键ID为数组键值
        if ($pri_key) {
            $list = array_column($list, null, $this->getPk());
        }

        return $list;
    }

    /**
     * 删除整体缓存
     * @author admin
     * @since 2021/1/30
     */
    public function cacheDAll()
    {
        $cache_key = $this->getCacheKey("all");
        $this->deleteCache($cache_key);
    }

    /**
     * 重置全表缓存
     *
     * @param array $map 查询条件
     * @param bool $is_pri 是否只缓存主键true或false
     * @param bool $pri_key 是否以主键作为键值true或false
     * @return bool 返回结果true(重置成功)或false(重置失败)
     * @author admin
     * @date 2020-04-21
     */
    public function cacheResetAll($map = [], $is_pri = false, $pri_key = false)
    {
        return $this->resetCacheFunc('all', $map, $is_pri, $pri_key);
    }

}