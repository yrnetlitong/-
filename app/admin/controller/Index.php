<?php


namespace app\admin\controller;

use app\admin\service\MenuService;
use app\admin\service\PermissionGuardService;
use app\admin\service\UserService;
use think\exception\HttpResponseException;

/**
 * 系统主页-控制器
 * @author admin
 * @since 2020/11/14
 * Class Index
 * @package app\admin\controller
 */
class Index extends Backend
{

    /**
     * 初始化
     * @return array|void
     * @since 2021/1/8
     * @author admin
     */
    protected function initialize()
    {
        parent::initialize();
        $permResult = (new PermissionGuardService())->check($this->userId);
        if ($permResult !== true) {
            throw new HttpResponseException(response(message($permResult, false, [], 403), 403, [], 'json'));
        }
    }

    /**
     * 获取菜单列表
     * @author admin
     * @since 2020/11/14
     */
    public function getMenuList()
    {
        $menuService = new MenuService();
        $result = $menuService->getPermissionList($this->userId);
        // Service 返回数组表示成功，返回 false 或字符串表示失败
        if ($result === false || is_string($result)) {
            return message(is_string($result) ? $result : '获取菜单列表失败', false, [], 1);
        }
        return message('操作成功', true, $result, 0);
    }

    /**
     * 获取用户信息
     * @return array
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @since 2020/11/20
     * @author admin
     */
    public function getUserInfo()
    {
        $userService = new UserService();
        $result = $userService->getUserInfo($this->userId);
        // Service 返回数组表示成功，返回 false 表示失败
        if ($result === false) {
            return message('用户信息不存在', false, [], 1);
        }
        return message('操作成功', true, $result, 0);
    }

    /**
     * 更新个人资料
     * @return mixed
     * @since 2020/11/11
     * @author admin
     */
    public function updateUserInfo()
    {
        $userService = new UserService();
        $result = $userService->updateUserInfo($this->userId);
        // Service 返回数组表示成功，返回字符串表示失败
        if (is_string($result)) {
            return message($result, false, [], 1);
        }
        return message('更新资料信息成功', true, $result, 0);
    }

    /**
     * 更新密码
     * @return array
     * @throws \think\db\exception\BindParamException
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @author admin
     * @since 2020/11/15
     */
    public function updatePwd()
    {
        $userService = new UserService();
        $result = $userService->updatePwd($this->userId);
        // Service 返回数组表示成功，返回字符串表示失败
        if (is_string($result)) {
            return message($result, false, [], 1);
        }
        return message('修改成功', true, $result, 0);
    }

}
