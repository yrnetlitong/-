<?php
// +----------------------------------------------------------------------
// | 控制台配置
// +----------------------------------------------------------------------
return [
    // 指令定义
    'commands' => [
        'pet:install' => \app\command\PetInstall::class,
        'pet:remind' => \app\command\PetRemind::class,
    ],
];
