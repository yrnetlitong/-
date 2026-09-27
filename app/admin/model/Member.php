<?php


namespace app\admin\model;

/**
 * 会员-模型
 * @author admin
 * @since 2020/11/15
 * Class Member
 * @package app\admin\model
 */
class Member extends BaseModel
{
    // 设置数据表名
    protected $name = "member";

    /**
     * 获取会员信息
     * @param int $id 会员ID
     * @return 数据信息|mixed
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @author admin
     * @since 2020/11/15
     */
    public function getInfo($id)
    {
        $info = parent::getInfo($id);
        if ($info) {
            $info = $this->formatMemberFields($info);
        }
        return $info;
    }

    protected function formatListItem(array $info)
    {
        return $this->formatMemberFields(parent::formatListItem($info));
    }

    private function formatMemberFields(array $info)
    {
        if (!empty($info['avatar'])) {
            $info['avatar'] = get_image_url($info['avatar']);
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
