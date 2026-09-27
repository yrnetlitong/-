<?php


namespace app\admin\model;

/**
 * 通知公告-模型
 * @author admin
 * @since 2020/11/15
 * Class Notice
 * @package app\admin\model
 */
class Notice extends BaseModel
{
    protected $globalScope = ['publicNotice'];

    public function scopePublicNotice($query)
    {
        $query->where('pet_member_id', 0);
    }

    // 设置数据表名
    protected $name = "notice";

    /**
     * 获取通知信息
     * @param int $id 通知ID
     * @return 数据信息|mixed
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @author admin
     * @since 2021/6/5
     */
    public function getInfo($id)
    {
        $info = parent::getInfo($id);
        if ($info) {
            // 处理富文本编辑器
            if ($info['content']) {
                while (strstr($info['content'], "[IMG_URL]")) {
                    $info['content'] = str_replace("[IMG_URL]", IMG_URL, $info['content']);
                }
            }
        }
        return $info;
    }

}