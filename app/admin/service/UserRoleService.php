<?php


namespace app\admin\service;

use app\admin\model\UserRole;

/**
 * 用户角色关系-服务类
 * @author admin
 * @since 2020/11/14
 * Class UserRoleService
 * @package app\admin\service
 */
class UserRoleService extends BaseService
{
    /**
     * 构造函数
     * @author admin
     * @since 2020/11/14
     * UserRoleService constructor.
     */
    public function __construct()
    {
        $this->model = new UserRole();
    }

    /**
     * 获取用户角色列表
     * @param $userId 用户ID
     * @return mixed
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\DbException
     * @throws \think\db\exception\ModelNotFoundException
     * @since 2020/11/14
     * @author admin
     */
    public function getUserRoleList($userId)
    {
        $roleList = $this->model->alias("ur")
            ->field('r.*')
            ->join(DB_PREFIX . 'role r', 'ur.role_id=r.id')
            ->distinct(true)
            ->where('ur.user_id', '=', $userId)
            ->where('r.status', '=', 1)
            ->where('r.mark', '=', 1)
            ->order('r.sort asc')
            ->select()->toArray();
        return $roleList;
    }

    /**
     * 批量获取用户角色，按用户 ID 分组。
     *
     * @param array $userIds
     * @return array
     */
    public function getUserRoleMap(array $userIds)
    {
        $userIds = array_values(array_unique(array_filter(array_map('intval', $userIds))));
        if (!$userIds) {
            return [];
        }

        $roleList = $this->model->alias('ur')
            ->field('ur.user_id,r.*')
            ->join(DB_PREFIX . 'role r', 'ur.role_id=r.id')
            ->whereIn('ur.user_id', $userIds)
            ->where('r.status', '=', 1)
            ->where('r.mark', '=', 1)
            ->order('r.sort asc')
            ->select()->toArray();
        $roleMap = [];
        foreach ($roleList as $role) {
            $userId = $role['user_id'];
            unset($role['user_id']);
            $roleMap[$userId][] = $role;
        }
        return $roleMap;
    }

    /**
     * 删除用户角色关系数据
     * @param $userId 用户ID
     * @since 2020/11/11
     * @author admin
     */
    public function deleteUserRole($userId)
    {
        $this->model->where("user_id", '=', $userId)->delete();
    }

    /**
     * 批量插入用户角色关系数据
     * @param $userId 用户ID
     * @param $roleIds 角色ID集合
     * @author admin
     * @since 2020/11/11
     */
    public function insertUserRole($userId, $roleIds)
    {
        if (!empty($roleIds)) {
            $list = [];
            foreach ($roleIds as $val) {
                $data = [
                    'user_id' => $userId,
                    'role_id' => $val,
                ];
                $list[] = $data;
            }
            $this->model->insertAll($list);
        }
    }

}
