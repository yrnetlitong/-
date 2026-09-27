<?php


namespace app\admin\service;

use app\admin\model\ConfigData;

/**
 * 配置数据-服务类
 * @author admin
 * @since 2020/11/15
 * Class ConfigService
 * @package app\admin\service
 */
class ConfigDataService extends BaseService
{
    /**
     * 构造函数
     * @author admin
     * @since 2020/11/15
     * ConfigService constructor.
     */
    public function __construct()
    {
        $this->model = new ConfigData();
    }

    /**
     * 获取数据列表
     * @return array
     * @since 2021/5/26
     * @author admin
     */
    public function getList()
    {
        $param = request()->param();
        // 查询条件
        $map = [];
        // 配置ID
        $configId = getter($param, "configId", 0);
        if ($configId) {
            $map[] = ['config_id', '=', $configId];
        }
        // 字典名称
        $name = getter($param, "name");
        if ($name) {
            $map[] = ['name', 'like', "%{$name}%"];
        }
        // 字典编码
        $code = getter($param, 'code');
        if ($code) {
            $map[] = ['code', '=', $code];
        }
        return parent::getList($map, "sort asc");
    }

}