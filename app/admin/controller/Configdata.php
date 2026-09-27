<?php


namespace app\admin\controller;

use app\admin\service\ConfigDataService;
use app\admin\service\PermissionGuardService;
use think\exception\HttpResponseException;

/**
 * 配置数据-控制器
 * @author admin
 * @since 2020/11/15
 * Class Config
 * @package app\admin\controller
 */
class Configdata extends Backend
{
    /**
     * 初始化
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
        $this->service = new ConfigDataService();
    }

}
