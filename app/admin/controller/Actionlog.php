<?php


namespace app\admin\controller;

use app\admin\service\ActionLogService;
use app\admin\service\PermissionGuardService;
use think\exception\HttpResponseException;

/**
 * 行为日志-控制器
 * @author admin
 * @since 2020/11/15
 * Class Actionlog
 * @package app\admin\controller
 */
class Actionlog extends Backend
{
    /**
     * 构造函数
     * @author admin
     * @since 2020/11/15
     */
    protected function initialize()
    {
        parent::initialize();
        if (!in_array(strtolower($this->request->action()), ['index','info'], true)) {
            throw new HttpResponseException(message('接口不存在', false, [], 404)->code(404));
        }
        $permResult = (new PermissionGuardService())->check($this->userId);
        if ($permResult !== true) {
            throw new HttpResponseException(message($permResult, false, [], 403)->code(403));
        }
        $this->service = new ActionLogService();
    }
}
