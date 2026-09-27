<?php
namespace app\common\service;

use think\facade\Cache;
use think\facade\Db;

class PetSession
{
    public static function member(string $header): int
    {
        if (!preg_match('/^Bearer (pk_[a-f0-9]{64})$/', $header, $matches)) {
            return 0;
        }
        $id = (int)Cache::get('petknow_session_' . hash('sha256', $matches[1]), 0);
        return $id && Db::name('member')->where(['id' => $id, 'mark' => 1, 'status' => 1])->count() ? $id : 0;
    }

    public static function issue(int $id): array
    {
        $token = 'pk_' . bin2hex(random_bytes(32));
        Cache::set('petknow_session_' . hash('sha256', $token), $id, 604800);
        return ['token' => $token, 'expires_at' => time() + 604800];
    }

    public static function logout(string $header): void
    {
        Cache::delete('petknow_session_' . hash('sha256', substr($header, 7)));
    }
}
