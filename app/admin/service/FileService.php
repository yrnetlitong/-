<?php


namespace app\admin\service;

use app\admin\model\File;

/**
 * 文件管理-服务类
 * @author admin
 * @since 2021/7/10
 * Class FileService
 * @package app\admin\service
 */
class FileService extends BaseService
{
    /**
     * 构造函数
     * @author admin
     * @since 2021/7/10
     * FileService constructor.
     */
    public function __construct()
    {
        $this->model = new File();
    }

    /**
     * 获取文件列表
     * @return array
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\DbException
     * @throws \think\db\exception\ModelNotFoundException
     * @author admin
     * @since 2021/7/10
     */
    public function getList()
    {
        // 参数
        $param = request()->param();

        // 查询条件
        $map = [];

        // 文件夹
        $directoryId = getter($param, 'directoryId', 0);
        if ($directoryId) {
            $map[] = ["pid", "=", $directoryId];
        } else {
            // 查询一级文件
            $map[] = ['pid', "=", 0];
        }
        $list = $this->model->getList($map, "id asc");
        // 返回数组数据，不返回 message() 格式
        return $list;
    }

    /**
     * 创建文件夹
     * @return array
     * @throws \think\db\exception\BindParamException
     * @author admin
     * @since 2021/7/10
     */
    public function saveDir()
    {
        // 参数
        $param = request()->param();
        // 文件夹名称
        $name = trim(getter($param, 'name', ''));
        if (!$name) {
            return '文件夹名称不能为空';
        }
        // 目录ID
        $directoryId = getter($param, "directoryId", 0);
        $data = [
            'pid' => $directoryId,
            'name' => $name,
            'directory' => 0,
        ];
        $result = $this->model->edit($data);
        if (!$result) {
            return '创建文件夹失败';
        }
        return ['id' => $result];
    }

}