<?php


namespace app\admin\service;

use app\admin\model\Member;

/**
 * 会员管理-服务类
 * @author admin
 * @since 2020/11/15
 * Class MemberService
 * @package app\admin\service
 */
class MemberService extends BaseService
{
    /**
     * 构造函数
     * @author admin
     * @since 2020/11/15
     * MemberService constructor.
     */
    public function __construct()
    {
        $this->model = new Member();
    }

    /**
     * 添加或编辑
     * @return array
     * @since 2020/11/21
     * @author admin
     */
    public function edit()
    {
        // 请求参数
        $data = request()->param();
        // 头像处理
        $avatar = getter($data, 'avatar');
        if (!empty($avatar)) {
            if (strpos($avatar, "temp") !== false) {
                $data['avatar'] = save_image($avatar, 'member');
            } else {
                $data['avatar'] = str_replace(IMG_URL, "", $avatar);
            }
        }

        // 出生日期
        if (isset($data['birthday']) && $data['birthday']) {
            $data['birthday'] = strtotime($data['birthday']);
        }

        // 城市数据处理
        $city = isset($data['city']) ? $data['city'] : [];
        if (!empty($city)) {
            $data['province_code'] = $city[0];
            $data['city_code'] = $city[1];
            $data['district_code'] = $city[2];

            unset($data['city']);
        } else {
            $data['province_code'] = 0;
            $data['city_code'] = 0;
            $data['district_code'] = 0;
        }
        return parent::edit($data);
    }

}