<?php


namespace app\admin\model;

/**
 * 菜单-模型
 * @author admin
 * @since 2020/11/14
 * Class Menu
 * @package app\admin\model
 */
class Menu extends BaseModel
{
    // 设置数据表名
    protected $name = "menu";

    /**
     * 获取子级菜单列表
     * @param $pid 上级ID
     * @return array
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\DbException
     * @throws \think\db\exception\ModelNotFoundException
     * @since 2020/11/14
     * @author admin
     */
    public function getChilds($pid)
    {
        $map = [
            ['type', '=', 0],
            ['pid', '=', $pid],
            ['status', '=', 1],
            ['mark', '=', 1],
        ];
        $list = $this->where($map)->order("sort asc")->select()->toArray();
        if (!empty($list)) {
            foreach ($list as &$val) {
                $val['children'] = $this->getChilds($val['id']);
            }
        }
        return $list;
    }

}