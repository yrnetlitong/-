<?php


declare (strict_types=1);

namespace app\admin\middleware;
use Jwt;
use think\Response;

/**
 * 登录校验中间件
 * @author admin
 * @since 2021/1/8
 * Class CheckLogin
 * @package app\admin\middleware
 */
class CheckLogin
{
    /**
     * 处理请求
     *
     * @param \think\Request $request
     * @param \Closure $next
     * @return Response
     */
    public function handle($request, \Closure $next)
    {
        // 登录校验
        if (!in_array(request()->controller(), ['Login'])) {
            // 获取Token
            $token = request()->header("Authorization");
            if ($token && strpos($token, 'Bearer ') !== false) {
                $token = str_replace("Bearer ", '', $token);
                // JWT解密token
                $jwt = new Jwt();
                $userId = $jwt->verifyToken($token);
                if (!$userId) {
                    // token解析失败跳转登录页面
                    return message("请登录", false, null, 401);
                }
            } else {
                // 跳转至登录页面
                return message("请登录", false, null, 401);
            }
        }
        return $next($request);
    }
}
