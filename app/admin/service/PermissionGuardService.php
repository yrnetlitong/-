<?php

namespace app\admin\service;

use app\admin\model\Menu;

/**
 * 后台权限守卫
 */
class PermissionGuardService
{
    /**
     * 校验当前请求权限
     * @param int|string $userId
     * @return true|string
     */
    public function check($userId)
    {
        $userId = intval($userId);
        if (!$userId) {
            return '请登录';
        }
        if ($userId === 1) {
            return true;
        }

        $route = strtolower(request()->controller() . '/' . request()->action());
        $authWhiteList = config('auth') ?: [];
        if (in_array($route, $authWhiteList, true)) {
            return true;
        }

        [$controller, $action] = explode('/', $route);
        if (in_array($controller, ['user','role','menu','loginlog','actionlog'], true)) {
            $module = $controller === 'actionlog' ? 'operlog' : $controller;
            $permissionAction = ['index'=>'view','info'=>'edit','getpermissionlist'=>'permission','savepermission'=>'permission','resetpwd'=>'resetPwd'][$action] ?? $action;
            if ($action === 'edit') { $permissionAction = request()->param('id') ? 'edit' : 'add'; }
            if ($action === 'delete' && is_array(request()->param('id'))) { $permissionAction = 'dall'; }
            if (in_array($controller, ['loginlog','actionlog'], true) && $action === 'info') { $permissionAction = 'detail'; }
            if ($action === 'index' && request()->param('export') === '1') { $permissionAction = 'export'; }
            $required = ['sys:'.$module.':'.$permissionAction];
            if ($controller === 'menu' && $action === 'edit' && !request()->param('id')) { $required[] = 'sys:menu:addz'; }
            if ($controller === 'role' && $action === 'getrolelist') { $required = ['sys:user:add','sys:user:edit','sys:role:view']; }
            $permissions = (new MenuService())->getPermissionsList($userId);
            return array_intersect($required, $permissions) ? true : '无权限访问';
        }

        $path = '/' . $route;
        $menuModel = new Menu();
        $menuInfo = $menuModel->getOne([
            ['path', '=', $path],
            ['type', '=', 1],
            ['mark', '=', 1],
            ['status', '=', 1],
        ]);
        if (!$menuInfo) {
            return true;
        }

        $permission = getter($menuInfo, 'permission', '');
        if (!$permission) {
            return true;
        }

        $permissionList = (new MenuService())->getPermissionsList($userId);
        if (!in_array($permission, $permissionList, true)) {
            return '无权限访问';
        }
        return true;
    }
}
