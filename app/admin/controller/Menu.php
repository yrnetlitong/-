<?php


namespace app\admin\controller;

use app\admin\service\MenuService;
use app\admin\service\PermissionGuardService;
use think\exception\HttpResponseException;

/**
 * 菜单管理-控制器
 * @author admin
 * @since 2020/11/15
 * Class Menu
 * @package app\admin\controller
 */
class Menu extends Backend
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
            throw new HttpResponseException(message($permResult, false, [], 403)->code(403));
        }
        $this->service = new MenuService();
    }

}
