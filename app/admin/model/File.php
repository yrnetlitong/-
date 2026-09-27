<?php


namespace app\admin\model;

/**
 * 文件-模型
 * @author admin
 * @since 2021/7/10
 * Class File
 * @package app\admin\model
 */
class File extends BaseModel
{
    // 设置数据表名
    protected $name = "file";

    /**
     * 获取记录信息
     * @param int $id
     * @return 数据信息|mixed
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @author admin
     * @since 2021/7/10
     */
    public function getInfo($id)
    {
        $info = parent::getInfo($id);
        if ($info) {
            // 图片地址
            if ($info['url']) {
                $info['url'] = get_image_url($info['url']);
            }

            // 缩略图
            if ($info['type'] == 1) {
                $info['thumbnail'] = $info['url'];
            }
        }
        return $info;
    }

}