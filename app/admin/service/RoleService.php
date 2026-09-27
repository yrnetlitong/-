<?php


namespace app\admin\service;

use app\admin\model\Menu;
use app\admin\model\Role;
use app\admin\model\RoleMenu;

/**
 * 角色管理-服务类
 * @author admin
 * @since 2020/11/14
 * Class RoleService
 * @package app\admin\service
 */
class RoleService extends BaseService
{
    /**
     * 构造函数
     * @author admin
     * @since 2020/11/14
     * RoleService constructor.
     */
    public function __construct()
    {
        $this->model = new Role();
    }

    /**
     * 获取数据列表
     * @return array
     * @since 2020/11/20
     * @author admin
     */
    public function getList()
    {
        return parent::getList([], "id asc");
    }

    /**
     * 获取角色列表
     * @return array
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\DbException
     * @throws \think\db\exception\ModelNotFoundException
     * @author admin
     * @since 2020/11/14
     */
    public function getRoleList()
    {
        $list = $this->model->where([
            ['status', '=', 1],
            ['mark', '=', 1],
        ])->order("sort", "asc")
            ->select()
            ->toArray();
        // 返回数组数据，不返回 message() 格式
        return $list;
    }

    /**
     * 获取权限列表
     * @return array
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\DbException
     * @throws \think\db\exception\ModelNotFoundException
     * @author admin
     * @since 2020/11/20
     */
    public function getPermissionList()
    {
        // 请求参数
        $param = request()->param();
        // 角色ID
        $roleId = intval(getter($param, "role_id", 0));
        // 获取全部菜单
        $menuModel = new Menu();
        $menuList = $menuModel->where([
            ['status', '=', 1],
            ['mark', '=', 1],
        ])->order("sort", "asc")->select()->toArray();
        if (!empty($menuList)) {
            $roleMenuModel = new RoleMenu();
            $roleMenuList = $roleMenuModel
                ->field("menu_id")
                ->where("role_id", '=', $roleId)
                ->select()
                ->toArray();
            $menuIdList = array_key_value($roleMenuList, "menu_id");
            foreach ($menuList as &$val) {
                if (in_array($val['id'], $menuIdList)) {
                    $val['checked'] = true;
                    $val['open'] = true;
                }
            }
        }
        // 返回数组数据，不返回 message() 格式
        return $menuList;
    }

    /**
     * 保存权限
     * @return array
     * @since 2020/11/14
     * @author admin
     */
    public function savePermission(int $actor)
    {
        $roleId = (int)request()->post('role_id', 0);
        if (!$this->model->where(['id'=>$roleId,'mark'=>1])->count()) { return '角色不存在'; }
        $ids = request()->post('menu_id', []);
        if (!is_array($ids) || count($ids) > 1000) { return '权限参数无效'; }
        foreach ($ids as $id) {
            if (!is_scalar($id) || !ctype_digit((string)$id) || (int)$id <= 0) { return '权限参数无效'; }
        }
        $ids = array_values(array_unique(array_map('intval', $ids)));
        $menus = \think\facade\Db::name('menu')->where(['mark'=>1,'status'=>1])->column('*','id');
        foreach ($ids as $id) { if (!isset($menus[$id])) { return '包含已失效的菜单权限，请刷新'; } }
        // 勾选操作节点时一并保留页面及祖先目录，使授权后的菜单可以正常显示。
        foreach ($ids as $id) {
            $parent = (int)$menus[$id]['pid']; $seen = [$id];
            while ($parent) {
                if (!isset($menus[$parent]) || in_array($parent, $seen, true)) { return '菜单层级无效'; }
                $ids[] = $parent; $seen[] = $parent; $parent = (int)$menus[$parent]['pid'];
            }
        }
        $ids = array_values(array_unique($ids));
        if ($actor !== 1) {
            $owned = \think\facade\Db::name('role_menu')->alias('rm')->join('user_role ur','ur.role_id=rm.role_id')->join('role r','r.id=rm.role_id')->where(['ur.user_id'=>$actor,'r.mark'=>1,'r.status'=>1])->column('rm.menu_id');
            if (array_diff($ids, $owned)) { return '不能分配超出自身范围的权限'; }
        }
        return \think\facade\Db::transaction(function () use ($actor, $roleId, $ids) {
            $this->model->where('id', $roleId)->lock(true)->find();
            \think\facade\Db::name('role_menu')->where('role_id', $roleId)->delete();
            if ($ids) { \think\facade\Db::name('role_menu')->insertAll(array_map(function ($id) use ($roleId) { return ['role_id'=>$roleId,'menu_id'=>$id]; }, $ids)); }
            \app\common\service\PetService::audit($actor, '分配角色权限', ['role_id'=>$roleId,'menu_ids'=>$ids,'result'=>'success'], true);
            return ['role_id'=>$roleId,'menu_count'=>count($ids)];
        });
    }
}
