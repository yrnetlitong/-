<?php


namespace app\admin\controller;

use app\admin\service\NoticeService;
use app\admin\service\PermissionGuardService;
use think\exception\HttpResponseException;

/**
 * 通知公告-控制器
 * @author admin
 * @since 2020/11/15
 * Class Notice
 * @package app\admin\controller
 */
class Notice extends Backend
{
    /**
     * 初始化
     * @author admin
     * @since 2020/11/15
     */
    protected function initialize()
    {
        parent::initialize();
        $permResult = (new PermissionGuardService())->check($this->userId);
        if ($permResult !== true) {
            throw new HttpResponseException(response(message($permResult, false, [], 403), 403, [], 'json'));
        }
        $this->service = new NoticeService();
    }

    /**
     * 设置置顶
     * @author admin
     * @since 2020/11/21
     */
    public function setIsTop()
    {
        $result = $this->service->setIsTop();
        // Service 返回数组表示成功，返回字符串表示失败
        if (is_string($result)) {
            return message($result, false, [], 1);
        }
        return message('操作成功', true, $result, 0);
    }

}
