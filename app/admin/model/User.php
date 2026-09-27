<?php


namespace app\admin\model;


use app\admin\service\UserRoleService;

/**
 * 用户-模型
 * @author admin
 * @since 2020/11/14
 * Class User
 * @package app\admin\model
 */
class User extends BaseModel
{
    // 设置数据表名称
    protected $name = "user";

    /**
     * 获取数据信息
     * @param int $id 用户ID
     * @return 数据信息|mixed
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @author admin
     * @since 2020/11/14
     */
    public function getInfo($id)
    {
        $info = parent::getInfo($id);
        if ($info) {
            $info = $this->formatUserFields($info);

            // 获取用户角色列表
            $userRoleService = new UserRoleService();
            $roleList = $userRoleService->getUserRoleList($id);
            $info['roles'] = $roleList;

        }
        return $info;
    }

    public function formatList(array $list)
    {
        $list = parent::formatList($list);
        $userIds = array_column($list, 'id');
        $roleMap = (new UserRoleService())->getUserRoleMap($userIds);
        foreach ($list as &$info) {
            $info['roles'] = isset($roleMap[$info['id']]) ? $roleMap[$info['id']] : [];
        }
        unset($info);
        return $list;
    }

    protected function formatListItem(array $info)
    {
        return $this->formatUserFields(parent::formatListItem($info));
    }

    private function formatUserFields(array $info)
    {
        if (!empty($info['avatar'])) {
            $info['avatar'] = get_image_url($info['avatar']);
        }
        if (!empty($info['gender'])) {
            $genderList = config('admin.gender_list');
            $info['gender_name'] = isset($genderList[$info['gender']])
                ? $genderList[$info['gender']]
                : '';
        }
        if (!empty($info['birthday'])) {
            $info['birthday'] = datetime($info['birthday']);
        }
        $info['city'] = [
            !empty($info['province_code']) ? strval($info['province_code']) : '',
            !empty($info['city_code']) ? strval($info['city_code']) : '',
            !empty($info['district_code']) ? strval($info['district_code']) : '',
        ];
        return $info;
    }

}
