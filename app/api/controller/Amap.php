<?php
namespace app\api\controller;

use app\common\service\AmapService;

class Amap extends Base
{
    // SDK 的 JSONP 请求不能携带 Authorization；仅接受后台授权签发的短期选点会话。
    protected $middleware = [];

    public function proxy()
    {
        if (!$this->request->isGet()) { return $this->fail('请求方式无效', 405); }
        try {
            $body = AmapService::proxy((string)$this->request->route('ticket'), (string)$this->request->route('path'), $this->request->get());
            return response($body)->contentType('application/javascript')->header(['Cache-Control' => 'no-store', 'X-Content-Type-Options' => 'nosniff']);
        } catch (\InvalidArgumentException $e) { return $this->fail($e->getMessage(), 403)->code(403); }
        catch (\RuntimeException $e) { return $this->fail($e->getMessage(), 502)->code(502); }
    }
}
