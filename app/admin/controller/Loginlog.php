<?php


namespace app\admin\controller;

use app\admin\service\LoginLogService;
use app\admin\service\PermissionGuardService;
use think\exception\HttpResponseException;

/**
 * 登录日志-控制器
 * @author admin
 * @since 2020/11/15
 * Class Loginlog
 * @package app\admin\controller
 */
class Loginlog extends Backend
{
    /**
     * 初始化
     * @author admin
     * @since 2020/11/15
     */
    protected function initialize()
    {
        parent::initialize();
        if (!in_array(strtolower($this->request->action()), ['index','info','delete'], true)) {
            throw new HttpResponseException(message('接口不存在', false, [], 404)->code(404));
        }
        $permResult = (new PermissionGuardService())->check($this->userId);
        if ($permResult !== true) {
            throw new HttpResponseException(message($permResult, false, [], 403)->code(403));
        }
        $this->service = new LoginLogService();
    }
}
