<?php
declare(strict_types=1);

namespace app\api\controller;

/**
 * 前台API通用基类
 */
class ApiBase extends Base
{
    /**
     * 要求登录
     */
    protected function requireLogin()
    {
        if ($this->userId <= 0) {
            return $this->fail('请登录', 401);
        }
        return null;
    }
}
