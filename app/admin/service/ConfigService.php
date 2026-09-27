<?php


namespace app\admin\service;

use app\admin\model\Config;

/**
 * 配置-服务类
 * @author admin
 * @since 2020/11/15
 * Class ConfigGroupService
 * @package app\admin\service
 */
class ConfigService extends BaseService
{
    /**
     * 构造函数
     * @author admin
     * @since 2020/11/15
     * ConfigGroupService constructor.
     */
    public function __construct()
    {
        $this->model = new Config();
    }

    /**
     * 获取配置列表
     * @return array
     * @since 2021/6/26
     * @author admin
     */
    public function getList()
    {
        return parent::getList([], "sort asc");
    }
}