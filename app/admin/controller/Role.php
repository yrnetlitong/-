<?php


namespace app\admin\controller;

use app\admin\service\PermissionGuardService;
use app\admin\service\RoleService;
use think\exception\HttpResponseException;

/**
 * 角色管理-控制器
 * @author admin
 * @since 2020/11/14
 * Class Role
 * @package app\admin\controller
 */
class Role extends Backend
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
        $this->service = new RoleService();
    }

    /**
     * 获取角色列表
     * @return mixed
     * @since 2020/11/14
     * @author admin
     */
    public function getRoleList()
    {
        $result = $this->service->getRoleList();
        // Service 返回数组数据
        return message('操作成功', true, $result, 0);
    }

    /**
     * 获取权限列表
     * @return mixed
     * @since 2020/11/14
     * @author admin
     */
    public function getPermissionList()
    {
        $result = $this->service->getPermissionList();
        // Service 返回数组数据
        return message('操作成功', true, $result, 0);
    }

    /**
     * 保存权限
     * @return mixed
     * @since 2020/11/14
     * @author admin
     */
    public function savePermission()
    {
        if (!$this->request->isPost()) { return message('请使用POST请求', false, [], 405)->code(405); }
        $result = $this->service->savePermission((int)$this->userId);
        // Service 返回数组表示成功，返回字符串表示失败
        if (is_string($result)) {
            return message($result, false, [], 1);
        }
        return message('保存权限成功', true, $result, 0);
    }

}
