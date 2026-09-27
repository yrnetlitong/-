<?php


namespace app\admin\controller;

use app\admin\service\PermissionGuardService;
use app\admin\service\UserService;
use think\exception\HttpResponseException;

/**
 * 用户管理-控制器
 * @author admin
 * @since 2020/11/14
 * Class User
 * @package app\admin\controller
 */
class User extends Backend
{
    /**
     * 初始化
     * @author admin
     * @since 2020/11/14
     */
    protected function initialize()
    {
        parent::initialize();
        $permResult = (new PermissionGuardService())->check($this->userId);
        if ($permResult !== true) {
            throw new HttpResponseException(message($permResult, false, [], 403)->code(403));
        }
        $this->service = new UserService();
    }

    /**
     * 重置密码
     * @return mixed
     * @since 2020/11/11
     * @author admin
     */
    public function resetPwd()
    {
        $result = $this->service->resetPwd();
        // Service 返回数组表示成功，返回字符串表示失败
        if (is_string($result)) {
            return message($result, false, [], 1);
        }
        return message('重置密码成功', true, $result, 0);
    }

}
