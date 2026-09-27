<?php
declare(strict_types=1);

namespace app\api\middleware;

use Jwt;

/**
 * 前台API鉴权中间件（JWT）
 * - 默认要求 Authorization: Bearer <token>
 * - 支持白名单控制器跳过（可扩展到 action）
 */
class CheckAuth
{
    /**
     * @var string[]
     */
    protected array $whiteControllers = ['Index'];

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

    public function handle($request, \Closure $next)
    {
        if (in_array(request()->controller(), $this->whiteControllers, true)) {
            return $next($request);
        }

        if (\app\common\service\PetSession::member((string)$request->header('Authorization')) > 0) {
            return $next($request);
        }

        $token = request()->header('Authorization');
        if ($token && strpos($token, 'Bearer ') !== false) {
            $token = str_replace('Bearer ', '', $token);
            $jwt = new Jwt();
            $uid = (string)$jwt->verifyToken($token);
            $userId = $this->normalizeUid($uid);
            if ($userId <= 0) {
                return message('请登录', false, null, 401)->code(401);
            }
        } else {
            return message('请登录', false, null, 401)->code(401);
        }

        return $next($request);
    }
}

