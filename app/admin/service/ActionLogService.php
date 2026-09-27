<?php


namespace app\admin\service;

use app\admin\model\ActionLog;

/**
 * 行为日志-服务类
 * @author admin
 * @since 2020/11/15
 * Class ActionLogService
 * @package app\admin\service
 */
class ActionLogService extends BaseService
{
    /**
     * 构造函数
     * @author admin
     * @since 2020/11/15
     * ActionLogService constructor.
     */
    public function __construct()
    {
        $this->model = new ActionLog();
    }

    /**
     * 获取数据列表
     * @return array
     * @since 2020/11/20
     * @author admin
     */
    public function getList()
    {
        $param = request()->param();

        // 查询条件
        $map[] = ['type', '=', 3];

        // 用户账号
        $username = getter($param, "username");
        if ($username) {
            $map[] = ["username", '=', $username];
        }
        if (!empty($param['module'])) { $map[] = ['module', '=', $param['module']]; }
        return parent::getList($map);
    }

    public function info()
    {
        $info = parent::info();
        return $info && (int)$info['mark'] === 1 && (int)$info['type'] === 3 ? $info : false;
    }
}