<?php


namespace app\admin\service;

use app\admin\model\ActionLog;

/**
 * 登录日志-服务类
 * @author admin
 * @since 2020/11/15
 * Class LoginLogService
 * @package app\admin\service
 */
class LoginLogService extends BaseService
{
    /**
     * 构造函数
     * @author admin
     * @since 2020/11/15
     * LoginLogService constructor.
     */
    public function __construct()
    {
        $this->model = new ActionLog();
    }

    /**
     * 获取登录日志列表
     * @return array
     * @since 2020/11/15
     * @author admin
     */
    public function getList()
    {
        $param = request()->param();
        // 查询条件
        $map = [];

        // 只取登录日志
        $map[] = ['type', "<=", 2];

        // 用户账号
        $username = getter($param, "username");
        if ($username) {
            $map[] = ["username", "=", $username];
        }
        return parent::getList($map);
    }
    public function info()
    {
        $info = parent::info();
        return $info && (int)$info['mark'] === 1 && in_array((int)$info['type'], [1,2], true) ? $info : false;
    }

    public function delete()
    {
        if (!request()->isPost() && !request()->isDelete()) { return '请使用POST或DELETE请求'; }
        $ids = request()->param('id');
        $ids = is_array($ids) ? $ids : [$ids];
        foreach ($ids as $id) { if (!is_scalar($id) || !ctype_digit((string)$id) || (int)$id <= 0) { return '日志编号无效'; } }
        $ids = array_unique(array_map('intval', $ids));
        if (!$ids || $this->model->whereIn('id', $ids)->whereIn('type', [1,2])->where('mark',1)->count() !== count($ids)) { return '登录日志不存在'; }
        return parent::delete();
    }
}