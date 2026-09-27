<?php
declare(strict_types=1);

namespace app\api\middleware;

/**
 * 前台API初始化中间件（与 admin 类似，避免 API 端缺少常量导致工具函数不可用）
 */
class InitApp
{
    public function handle($request, \Closure $next)
    {
        $this->initSystemConstant();
        $this->initDbInfo();
        return $next($request);
    }

    protected function initSystemConstant()
    {
        // 基础常量
        if (!defined('ROOT_PATH')) {
            define('ROOT_PATH', app()->getRootPath());
        }
        if (!defined('APP_PATH')) {
            define('APP_PATH', ROOT_PATH . "app");
        }
        if (!defined('ROUTE_PATH')) {
            define('ROUTE_PATH', ROOT_PATH . "route");
        }
        if (!defined('RUNTIME_PATH')) {
            define('RUNTIME_PATH', ROOT_PATH . "runtime");
        }
        if (!defined('EXTEND_PATH')) {
            define('EXTEND_PATH', ROOT_PATH . "extend");
        }
        if (!defined('VENDOR_PATH')) {
            define('VENDOR_PATH', ROOT_PATH . "vendor");
        }
        if (!defined('PUBLIC_PATH')) {
            define('PUBLIC_PATH', ROOT_PATH . 'public');
        }

        // 附件常量
        $upload_path = \think\facade\Filesystem::getDiskConfig(config('filesystem.default'), 'root');
        if (!defined('ATTACHMENT_PATH')) {
            define('ATTACHMENT_PATH', $upload_path);
        }
        if (!defined('IMG_PATH')) {
            define('IMG_PATH', ATTACHMENT_PATH . "/images");
        }
        if (!defined('UPLOAD_TEMP_PATH')) {
            define('UPLOAD_TEMP_PATH', ATTACHMENT_PATH . '/temp');
        }

        // 系统域名（可选）
        if (!defined('SITE_URL')) {
            define('SITE_URL', env('domain.siteurl'));
        }
        if (!defined('IMG_URL')) {
            define('IMG_URL', env('domain.img_url'));
        }
    }

    protected function initDbInfo()
    {
        if (!defined('DB_PREFIX')) {
            define('DB_PREFIX', env('database.prefix', ''));
        }
    }
}


