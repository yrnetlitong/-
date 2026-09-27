<?php


namespace app\admin\service;

use app\admin\model\Notice;

/**
 * 通知公告-服务类
 * @author admin
 * @since 2020/11/15
 * Class NoticeService
 * @package app\admin\service
 */
class NoticeService extends BaseService
{
    /**
     * 构造函数
     * @author admin
     * @since 2020/11/15
     * NoticeService constructor.
     */
    public function __construct()
    {
        $this->model = new Notice();
    }

    /**
     * 添加或编辑
     * @return array
     * @since 2021/6/8
     * @author admin
     */
    public function edit()
    {
        // 获取参数
        $data = request()->param();
        //内容处理
        save_image_content($data['content'], $data['title'], "notice");
        return parent::edit($data);
    }

    /**
     * 设置置顶
     * @return array
     * @throws \think\db\exception\BindParamException
     * @author admin
     * @since 2020/11/21
     */
    public function setIsTop()
    {
        // 参数
        $data = request()->param();
        // 记录ID
        $id = getter($data, "id", 0);
        if (!$id) {
            return '记录ID不能为空';
        }
        // 是否置顶
        $isTop = getter($data, "is_top", 0);
        if (!$isTop) {
            return '是否置顶不能为空';
        }
        $error = '';
        $item = [
            'id' => $id,
            'is_top' => $isTop
        ];
        $rowId = $this->model->edit($item, $error);
        if (!$rowId) {
            return $error ?: '设置置顶失败';
        }
        return ['id' => $rowId, 'is_top' => $isTop];
    }

}