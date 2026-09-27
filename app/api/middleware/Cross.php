<?php
declare(strict_types=1);

namespace app\api\middleware;

/**
 * 前台API跨域处理中间件
 */
class Cross
{
    public function handle($request, \Closure $next)
    {
        $response = $next($request);
        $origin = $request->header('Origin', '*');

        // OPTIONS 预检直接返回
        if ($request->method(true) === 'OPTIONS') {
            $response->code(204);
        }

        $response->header([
            'Access-Control-Allow-Origin' => $origin,
            'Access-Control-Allow-Methods' => 'GET,POST,PUT,DELETE,OPTIONS',
            'Access-Control-Allow-Credentials' => 'true',
            'Access-Control-Allow-Headers' => '*',
            // 允许前端读取响应头（如需要续期 token）
            'Access-Control-Expose-Headers' => 'Authorization',
        ]);

        return $response;
    }
}


