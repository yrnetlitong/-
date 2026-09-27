<?php


namespace app\admin\event;


use app\admin\model\ActionLog;

/**
 * 用户日志时间
 * @author admin
 * @since 2020/11/21
 * Class AdminLog
 * @package app\event
 */
class UserLog
{

    /**
     * 执行句柄
     * @author admin
     * @since 2020/11/21
     */
    public function handle()
    {
        if (request()->isPost()) {
            ActionLog::record();
        }
    }
}