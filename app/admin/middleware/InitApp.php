<?php


declare (strict_types=1);

namespace app\admin\middleware;

class InitApp
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
        // 初始化系统常量
        $this->initSystemConstant();

        // 初始化消息中间件RabbitMQ常量
        $this->initRabbitMQ();

        // 初始化数据库常量
        $this->initDbInfo();
        return $next($request);
    }

    /**
     * 初始化系统常量
     *
     * @author admin
     * @since 2020-04-21
     */
    public function initSystemConstant()
    {
        // 基础常量
        define('ROOT_PATH', app()->getRootPath());
        define('APP_PATH', ROOT_PATH . "app");
        define('ROUTE_PATH', ROOT_PATH . "route");
        define('RUNTIME_PATH', ROOT_PATH . "runtime");
        define('EXTEND_PATH', ROOT_PATH . "extend");
        define('VENDOR_PATH', ROOT_PATH . "vendor");
        define('PUBLIC_PATH', ROOT_PATH . 'public');

        // 附件常量
        // 文件上传路径
        //$upload_parh = \think\Filesystem::getDiskConfig(config('filesystem.default'), 'root');
        define('ATTACHMENT_PATH', "./");
        define('IMG_PATH', ATTACHMENT_PATH . "/images");
        define('UPLOAD_TEMP_PATH', ATTACHMENT_PATH . '/temp');

        // 系统配置
        define('SITE_NAME', env('system.sitename'));
        define('NICK_NAME', env('system.nickname'));
        define('SYSTEM_VERSION', env('system.version'));

        // 系统域名
        define('SITE_URL', env('domain.siteurl'));
        define('IMG_URL', env('domain.img_url'));
        
        $page = max(1, (int)getter(request()->param(), "page", 1));
        $perPage = max(1, min(100, (int)getter(request()->param(), "limit", 20)));
        defined('PAGE') or define('PAGE', $page);
        defined('PERPAGE') or define('PERPAGE', $perPage);
    }

    /**
     * 初始化RabbitMQ
     *
     * @author admin
     * @since 2020-04-21
     */
    public function initRabbitMQ()
    {

    }

    /**
     * 初始化数据库常量
     *
     * @author admin
     * @since 2020-04-21
     */
    public function initDbInfo()
    {
        // 数据表前缀
        define('DB_PREFIX', env('database.prefix', ''));
    }

}
