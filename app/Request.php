<?php
namespace app;

// 应用请求对象类
class Request extends \think\Request
{
    public function pathinfo(): string
    {
        // 高德 JS SDK 的 s=rsv3 与框架的 s 路由参数同名；仅地图代理按真实路径路由。
        $path = (string)parse_url($this->server('REQUEST_URI', ''), PHP_URL_PATH);
        if ($this->pathinfo === null && preg_match('#^/api/amap/[a-f0-9]{48}/_AMapService/[a-zA-Z0-9/_-]+$#', $path)) {
            $this->setPathinfo(ltrim($path, '/'));
        }
        return parent::pathinfo();
    }
}
