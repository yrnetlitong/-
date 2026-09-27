<?php


namespace app\admin\service;

use app\admin\model\Dict;
use app\admin\model\DictData;

/**
 * 字典数据-服务类
 * @author admin
 * @since 2020/11/15
 * Class DictService
 * @package app\admin\service
 */
class DictDataService extends BaseService
{
    /**
     * 构造函数
     * @author admin
     * @since 2020/11/15
     * DictService constructor.
     */
    public function __construct()
    {
        $this->model = new DictData();
    }

    /**
     * 获取字典列表
     * @return array
     * @since 2020/11/15
     * @author admin
     */
    public function getList()
    {
        $param = request()->param();
        // 查询条件
        $map = [];
        // 字典ID
        $dictId = getter($param, "dictId", 0);
        if ($dictId) {
            $map[] = ['dict_id', '=', $dictId];
        }
        // 字典名称
        $name = getter($param, "name");
        if ($name) {
            $map[] = ['name', 'like', "%{$name}%"];
        }
        // 字典编码
        $code = getter($param, 'code');
        if ($code) {
            $map[] = ['code', '=', $code];
        }
        return parent::getList($map, "sort asc");
    }

    /**
     * 根据编码获取字典
     * @return array
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\DbException
     * @throws \think\db\exception\ModelNotFoundException
     * @author admin
     * @since 2021/7/5
     */
    public function getDictByCode()
    {
        // 参数
        $param = request()->param();
        // Code码
        $code = getter($param, "code");
        if (!$code) {
            return '参数不能为空';
        }
        $dictModel = new Dict();
        $dictInfo = $dictModel->getOne([
            ['code', "=", $code],
        ]);
        if (!$dictInfo) {
            return '字典信息不存在';
        }
        // 获取字典项列表
        $list = $this->model->where("dict_id", "=", $dictInfo['id'])
            ->where("mark", "=", 1)
            ->select()
            ->toArray();
        // 返回数组数据，不返回 message() 格式
        return $list;
    }

}