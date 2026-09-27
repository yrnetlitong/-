<?php


namespace app\admin\controller;

use app\admin\service\DictService;
use app\admin\service\PermissionGuardService;
use think\exception\HttpResponseException;

/**
 * 字典-控制器
 * @author admin
 * @since 2020/11/15
 * Class Dicttype
 * @package app\admin\controller
 */
class Dict extends Backend
{
    /**
     * 构造函数
     * @author admin
     * @since 2020/11/15
     */
    protected function initialize()
    {
        parent::initialize();
        $permResult = (new PermissionGuardService())->check($this->userId);
        if ($permResult !== true) {
            throw new HttpResponseException(response(message($permResult, false, [], 403), 403, [], 'json'));
        }
        $this->service = new DictService();
    }

}
