<?php
declare(strict_types=1);

namespace app\api\controller;

use app\BaseController;
use Jwt;

/**
 * 前台API基类控制器
 * - 统一解析 Authorization: Bearer <token>
 * - 提供统一的成功/失败返回
 */
class Base extends BaseController
{
    protected $middleware = [\app\api\middleware\CheckAuth::class];
    /**
     * 当前登录用户ID（若未登录则为0）
     * @var int
     */
    protected $userId = 0;
    /**
     * JWT 原始 UID（支持复合格式，如 type:123）
     * @var string
     */
    protected $rawUid = '';

    protected function initialize()
    {
        parent::initialize();
        $this->userId = $this->parseUserIdFromJwt();
    }

    protected function parseUserIdFromJwt(): int
    {
        $token = request()->header('Authorization');
        if (!$token || strpos($token, 'Bearer ') === false) {
            $this->rawUid = '';
            return 0;
        }
        $token = str_replace('Bearer ', '', $token);
        $jwt = new Jwt();
        $uid = $jwt->verifyToken($token);
        if (!$uid) {
            $this->rawUid = '';
            return 0;
        }
        $this->rawUid = (string)$uid;
        return $this->normalizeUid($this->rawUid);
    }

    /**
     * 将 JWT UID 统一归一为 int 用户ID
     * 支持格式：
     * - "123"
     * - "type:123"
     */
    protected function normalizeUid(string $uid): int
    {
        if ($uid === '') {
            return 0;
        }
        if (is_numeric($uid)) {
            return (int)$uid;
        }
        $parts = explode(':', $uid);
        $last = end($parts);
        return is_numeric($last) ? (int)$last : 0;
    }

    protected function success($data = [], string $msg = '操作成功')
    {
        return message($msg, true, $data);
    }

    protected function fail(string $msg = '操作失败', int $code = -1, $data = [])
    {
        return message($msg, false, $data, $code);
    }
}

