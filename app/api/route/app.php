<?php
use think\facade\Route;

// 高德 SDK 会在 serviceHost 后追加固定路径；仅此业务路由交给受限代理。
Route::get('amap/:ticket/_AMapService/:path', 'Amap/proxy')
    ->pattern(['ticket' => '[a-f0-9]{48}', 'path' => '[a-zA-Z0-9/_-]+']);
