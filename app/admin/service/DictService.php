<?php


namespace app\admin\service;

use app\admin\model\Dict;

/**
 * 字典-服务类
 * @author admin
 * @since 2020/11/15
 * Class DictTypeService
 * @package app\admin\service
 */
class DictService extends BaseService
{
    /**
     * 构造函数
     * @author admin
     * @since 2020/11/15
     * DictTypeService constructor.
     */
    public function __construct()
    {
        $this->model = new Dict();
    }

    /**
     * 获取字典列表
     * @return array
     * @since 2021/6/26
     * @author admin
     */
    public function getList()
    {
        return parent::getList([], "sort asc");
    }

}