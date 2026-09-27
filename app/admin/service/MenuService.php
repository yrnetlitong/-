<?php


namespace app\admin\service;

use app\admin\model\Menu;

/**
 * 菜单管理-服务类
 * @author admin
 * @since 2020/11/14
 * Class MenuService
 * @package app\admin\service
 */
class MenuService extends BaseService
{
    /**
     * 构造函数
     * @author admin
     * @since 2020/11/14
     * MenuService constructor.
     */
    public function __construct()
    {
        $this->model = new Menu();
    }

    /**
     * 获取数据列表
     * @return array
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @since 2020/11/15
     * @author admin
     */
    public function getList()
    {
        // 请求参数
        $param = request()->param();

        // 查询条件
        $map = [];
        // 菜单标题
        $title = getter($param, "title");
        if ($title) {
            $map[] = ['title', 'like', "%{$title}%"];
        }
        $list = $this->model->getList($map, "sort asc");
        // 返回数组数据，不返回 message() 格式
        return $list;
    }

    /**
     * 获取菜单详情
     * @return array
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\DbException
     * @throws \think\db\exception\ModelNotFoundException
     * @author admin
     * @since 2021/3/24
     */
    public function info()
    {
        // 记录ID
        $id = request()->param("id", 0);
        $info = [];
        if ($id) {
            $info = $this->model->getInfo($id);
        }
        // 返回数组数据，不返回 message() 格式
        return $info ?: false;
    }

    /**
     * 添加或编辑
     * @return array
     * @since 2021/3/24
     * @author admin
     */
    public function edit()
    {
        // 参数
        $param = request()->param();
        // 权限节点
        unset($param['checkedList']);
        // 保存数据
        $result = $this->model->edit($param);
        if (!$result) {
            return '操作失败';
        }

        return ['id' => $result];
    }

    /**
     * 获取菜单权限列表
     * @param $userId
     * @return array
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\DbException
     * @throws \think\db\exception\ModelNotFoundException
     * @since 2020/11/20
     * @author admin
     */
    public function getPermissionList($userId)
    {
        $list = [];
        if ($userId == 1) {
            // 管理员拥有全部权限
            $list = $this->model->getChilds(0);
        } else {
            // 其他角色
            $list = $this->getPermissionMenu($userId, 0);
        }
        // 返回数组数据，不返回 message() 格式
        return $list;
    }

    /**
     * 获取权限菜单
     * @param $userId 用户ID
     * @param $pid 上级ID
     * @return mixed
     * @since 2020/11/20
     * @author admin
     */
    public function getPermissionMenu($userId, $pid)
    {
        $menuModel = new Menu();
        $menuList = $menuModel->alias('m')
            ->join(DB_PREFIX . 'role_menu rm', 'rm.menu_id=m.id')
            ->join(DB_PREFIX . 'user_role ur', 'ur.role_id=rm.role_id')
            ->join(DB_PREFIX . 'role r', 'r.id=rm.role_id')
            ->where('r.status', 1)->where('r.mark', 1)
            ->distinct(true)
            ->where('ur.user_id', '=', $userId)
            ->where('m.type', '=', 0)
            ->where('m.pid', '=', $pid)
            ->where('m.status', '=', 1)
            ->where('m.mark', '=', 1)
            ->order('m.pid ASC,m.sort ASC')
            ->field('m.*')
            ->select()->toArray();
        if (!empty($menuList)) {
            foreach ($menuList as &$val) {
                $childList = $this->getPermissionMenu($userId, $val['id']);
                if (is_array($childList) && !empty($childList)) {
                    $val['children'] = $childList;
                }
            }
        }
        return $menuList;
    }

    /**
     *
     * @param $userId
     * @return array
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\DbException
     * @throws \think\db\exception\ModelNotFoundException
     * @since 2021/3/23
     * @author admin
     */
    public function getPermissionsList($userId)
    {
        $list = [];
        if ($userId == 1) {
            // 管理员拥有全部权限
            $permissionList = $this->model
                ->where("type", "=", 1)
                ->where("mark", "=", 1)
                ->distinct(true)
                ->field("permission")
                ->select()
                ->toArray();
            $list = empty($permissionList) ? array() : array_key_value($permissionList, 'permission');
        } else {
            // 其他角色
            $menuModel = new Menu();
            $permissionList = $menuModel->alias('m')
                ->join(DB_PREFIX . 'role_menu rm', 'rm.menu_id=m.id')
                ->join(DB_PREFIX . 'user_role ur', 'ur.role_id=rm.role_id')
            ->join(DB_PREFIX . 'role r', 'r.id=rm.role_id')
            ->where('r.status', 1)->where('r.mark', 1)
                ->distinct(true)
                ->where('ur.user_id', '=', $userId)
                ->where('m.type', '=', 1)
                ->where('m.status', '=', 1)
                ->where('m.mark', '=', 1)
                ->field('m.permission')
                ->select()
                ->toArray();
            $list = empty($permissionList) ? array() : array_key_value($permissionList, 'permission');
        }
        return $list;
    }

}