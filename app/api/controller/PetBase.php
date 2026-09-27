<?php
namespace app\api\controller;

use app\common\service\PetSession;
use think\exception\HttpResponseException;

abstract class PetBase extends ApiBase
{
    protected function initialize()
    {
        parent::initialize();
        new \app\admin\model\ActionLog();
        $this->userId = PetSession::member((string)$this->request->header('Authorization'));
        if (!$this->userId) {
            throw new HttpResponseException($this->fail('请重新登录', 401)->code(401));
        }
    }

    protected function runAction(callable $callback, bool $write = false)
    {
        if ($write && !$this->request->isPost()) {
            return $this->fail('请使用POST请求', 405);
        }
        try {
            return $this->success($callback());
        } catch (\InvalidArgumentException $e) {
            return $this->fail($e->getMessage(), 422);
        } catch (\Throwable $e) {
            \think\facade\Log::error('宠物业务失败：' . $e->getMessage());
            return $this->fail('操作失败，请稍后重试', 500);
        }
    }
}
