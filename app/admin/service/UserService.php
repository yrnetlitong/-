<?php


namespace app\admin\service;

use app\admin\model\User;

/**
 * 用户管理-服务类
 * @author admin
 * @since 2020/11/14
 * Class UserService
 * @package app\admin\service
 */
class UserService extends BaseService
{
    /**
     * 构造函数
     * @author admin
     * @since 2020/11/14
     * UserService constructor.
     */
    public function __construct()
    {
        $this->model = new User();
    }

    /**
     * 获取用户列表
     * @return array
     * @since 2020/11/14
     * @author admin
     */
    public function getList()
    {
        // 参数
        $param = request()->param();

        // 查询条件
        $map = [];
        // 部门ID（已删除部门表，不再支持按部门查询）
        // $deptId = getter($param, "deptId", 0);
        // if ($deptId) {
        //     $map[] = ["dept_id", '=', $deptId];
        // }

        // 用户账号
        $username = getter($param, "username");
        if ($username) {
            $map[] = ["username", 'like', "%{$username}%"];
        }
        // 用户姓名
        $realname = getter($param, "realname");
        if ($realname) {
            $map[] = ['realname', 'like', "%{$realname}%"];
        }
        // 用户性别
        $gender = getter($param, "gender");
        if ($gender) {
            $map[] = ['gender', '=', $gender];
        }
        return parent::getList($map, "id asc");
    }

    /**
     * 添加或编辑
     * @return array
     * @throws \think\db\exception\BindParamException
     * @author admin
     * @since 2020/11/15
     */
    public function edit()
    {
        // 请求参数
        $data = array_intersect_key(request()->param(), array_flip(['id', 'realname', 'username', 'role_ids', 'password', 'status']));
        if (!preg_match('/^[A-Za-z0-9_]{3,20}$/', (string)($data['username'] ?? ''))) { return '账号为3至20位字母、数字或下划线'; }
        $data['realname'] = trim((string)($data['realname'] ?? ''));
        if ($data['realname'] === '' || mb_strlen($data['realname']) > 20) { return '请输入1至20字用户姓名'; }
        if (!in_array((int)($data['status'] ?? 0), [1, 2], true)) { return '用户状态无效'; }
        $roles = $data['role_ids'] ?? [];
        if (!is_array($roles) || !$roles || count(array_filter($roles, function ($id) { return !ctype_digit((string)$id) || (int)$id < 1; }))) { return '请选择有效角色'; }
        $data['role_ids'] = array_values(array_unique(array_map('intval', $roles)));
        if (\think\facade\Db::name('role')->whereIn('id', $data['role_ids'])->where('mark', 1)->count() !== count($data['role_ids'])) { return '角色不存在'; }
        if ((empty($data['id']) || !empty($data['password'])) && !preg_match('/^\S{6,20}$/', (string)($data['password'] ?? ''))) { return '密码为6至20位非空白字符'; }
        // 用户名
        $username = getter($data, "username");
        // 密码
        $password = getter($data, "password");
        // 用户ID
        $id = getter($data, "id", 0);
        // 添加时设置密码
        if (empty($id)) {
            // 设置密码
            $data['password'] = get_password($password . $username);
            // 用户名重复性验证
            $count = $this->model
                ->where("username", '=', $username)
                ->where("mark", "=", 1)
                ->count();
            if ($count > 0) {
                return '系统中已存在相同的用户名';
            }
        } else {
            // 用户名重复性验证
            $count = $this->model
                ->where("username", '=', $username)
                ->where("id", "<>", $id)
                ->where("mark", "=", 1)
                ->count();
            if ($count > 0) {
                return '系统中已存在相同的用户名';
            }
            // 获取用户信息
            $info = $this->model->getInfo($id);
            if (!$info) {
                return '用户信息不存在';
            }
            if ($username !== $info['username']) { return '用户账号不可修改'; }
            $data['password'] = $password !== '' && $password !== null ? get_password($password . $username) : $info['password'];
        }

        $error = "";
        $result = $this->model->edit($data, $error);
        if (!$result) {
            return $error ?: '操作失败';
        }

        // 删除用户整体缓存
        $this->model->cacheDAll();

        // 删除已存在的用户角色关系数据
        $userRoleService = new UserRoleService();
        $userRoleService->deleteUserRole($result);
        // 插入用户角色关系数据
        $roleIds = isset($data['role_ids']) ? $data['role_ids'] : [];
        $userRoleService->insertUserRole($result, $roleIds);
        return ['id' => $result];
    }

    /**
     * 获取用户信息
     * @param $userId 用户ID
     * @return array
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @author admin
     * @since 2020/11/14
     */
    public function getUserInfo($userId)
    {
        $userInfo = $this->model->getInfo($userId);
        // 返回参数
        $result = array();
        $result['id'] = $userInfo['id'];
        $result['avatar'] = $userInfo['avatar'];
        $result['realname'] = $userInfo['realname'];
        $result['nickname'] = $userInfo['nickname'];
        $result['gender'] = $userInfo['gender'];
        $result['mobile'] = $userInfo['mobile'];
        $result['email'] = $userInfo['email'];
        $result['address'] = $userInfo['address'];
        $result['intro'] = $userInfo['intro'];
        $result['roles'] = getter($userInfo, 'roles', []);
        $result['authorities'] = [];
        // 权限节点列表
        $menuService = new MenuService();
        $permissionList = $menuService->getPermissionsList($userId);
        if (!empty($permissionList)) {
            foreach ($permissionList as $permission) {
                $result['authorities'][] = ['permission' => $permission];
            }
        }
        $result['permissionList'] = $permissionList;
        // 返回数组数据，不返回 message() 格式
        return $result;
    }

    /**
     * 更新个人资料
     * @param $userId 用户ID
     * @return array
     * @throws \think\db\exception\BindParamException
     * @since 2021/3/25
     * @author admin
     */
    public function updateUserInfo($userId)
    {
        // 参数
        $param = request()->param();
        // 个人信息
        $data = [
            'id' => $userId,
            'realname' => getter($param, 'realname', ''),
            'nickname' => getter($param, 'nickname', ''),
            'gender' => getter($param, 'gender', 0),
            'mobile' => getter($param, 'mobile', ''),
            'email' => getter($param, 'email', ''),
            'intro' => getter($param, 'intro', ''),
        ];

        // 头像处理
        $avatar = getter($param, 'avatar');
        if (!empty($avatar)) {
            if (strpos($avatar, "temp") !== false) {
                $data['avatar'] = save_image($avatar, 'user');
            } else {
                $data['avatar'] = str_replace(IMG_URL, "", $avatar);
            }
        }
        $result = $this->model->edit($data);
        if (!$result) {
            return '更新资料信息失败';
        }
        return ['id' => $result];
    }

    /**
     * 更新密码
     * @param $userId 用户ID
     * @return array
     * @throws \think\db\exception\BindParamException
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @since 2020/11/15
     * @author admin
     */
    public function updatePwd($userId)
    {
        // 获取参数
        $param = request()->param();
        // 原始密码
        $oldPassword = trim(getter($param, "oldPassword"));
        if (!$oldPassword) {
            return '旧密码不能为空';
        }
        // 新密码
        $newPassword = trim(getter($param, "newPassword"));
        if (!$newPassword) {
            return '新密码不能为空';
        }
        $userInfo = $this->model->getInfo($userId);
        if (!$userInfo) {
            return '用户信息不存在';
        }
        if ($userInfo['password'] != get_password($oldPassword . $userInfo['username'])) {
            return '旧密码输入不正确';
        }
        $item = [
            'id' => $userId,
            'password' => get_password($newPassword . $userInfo['username']),
        ];
        $result = $this->model->edit($item);
        if (!$result) {
            return '修改失败';
        }
        return ['id' => $result];
    }

    /**
     * 重置密码
     * @return array
     * @throws \think\db\exception\BindParamException
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @author admin
     * @since 2020/11/15
     */
    public function resetPwd()
    {
        // 获取参数
        $param = request()->param();
        // 用户ID
        $userId = getter($param, "id");
        if (!$userId) {
            return '用户ID不能为空';
        }
        $userInfo = $this->model->getInfo($userId);
        if (!$userInfo) {
            return '用户信息不存在';
        }
        $item = [
            'id' => getter($param, 'id', 0),
            'password' => get_password("123456" . $userInfo['username']),
        ];
        $result = $this->model->edit($item);
        if (!$result) {
            return '重置密码失败';
        }
        return ['id' => $result];
    }

}
