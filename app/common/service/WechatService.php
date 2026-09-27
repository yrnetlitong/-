<?php
namespace app\common\service;

use RuntimeException;
use think\facade\Cache;

class WechatService
{
    public function call(string $path, array $data, bool $post = false): array
    {
        $url = 'https://api.weixin.qq.com/' . $path;
        $curl = curl_init($post ? $url : $url . '?' . http_build_query($data));
        curl_setopt_array($curl, [CURLOPT_RETURNTRANSFER => true, CURLOPT_CONNECTTIMEOUT => 8, CURLOPT_TIMEOUT => 20]);
        if ($post) {
            curl_setopt_array($curl, [CURLOPT_POST => true, CURLOPT_HTTPHEADER => ['Content-Type: application/json'], CURLOPT_POSTFIELDS => json_encode($data, JSON_UNESCAPED_UNICODE)]);
        }
        $body = curl_exec($curl);
        $status = curl_getinfo($curl, CURLINFO_HTTP_CODE);
        curl_close($curl);
        $result = json_decode((string)$body, true);
        if ($status !== 200 || !is_array($result)) {
            throw new RuntimeException('微信服务暂时不可用，请稍后重试');
        }
        if (!empty($result['errcode'])) {
            throw new RuntimeException('微信接口返回错误码：' . (int)$result['errcode']);
        }
        return $result;
    }

    public function credentials(): array
    {
        $appid = (string)env('wechat.appid');
        $secret = (string)env('wechat.appsecret');
        if (!$appid || !$secret) {
            throw new RuntimeException('尚未配置微信登录参数');
        }
        return ['appid' => $appid, 'secret' => $secret];
    }

    public function session(string $code): array
    {
        return $this->call('sns/jscode2session', $this->credentials() + ['js_code' => $code, 'grant_type' => 'authorization_code']);
    }

    public function accessToken(): string
    {
        $key = 'petknow_wechat_token_' . env('wechat.appid');
        $token = Cache::get($key);
        if (!$token) {
            $result = $this->call('cgi-bin/token', $this->credentials() + ['grant_type' => 'client_credential']);
            $token = $result['access_token'];
            Cache::set($key, $token, max(60, (int)$result['expires_in'] - 300));
        }
        return $token;
    }
}
