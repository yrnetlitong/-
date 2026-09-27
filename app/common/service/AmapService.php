<?php
namespace app\common\service;

use InvalidArgumentException;
use RuntimeException;
use think\facade\Cache;
use think\facade\Db;

class AmapService
{
    public static function configuration(int $actor): array
    {
        if (!env('amap.key') || !env('amap.security_code')) { throw new InvalidArgumentException('尚未配置高德地图参数'); }
        $ticket = bin2hex(random_bytes(24));
        Cache::set('pet_amap_' . $ticket, $actor, 3600);
        return ['key' => (string)env('amap.key'), 'service_host' => request()->domain() . '/api/amap/' . $ticket . '/_AMapService'];
    }

    public static function proxy(string $ticket, string $path, array $params): string
    {
        $actor = preg_match('/^[a-f0-9]{48}$/', $ticket) ? (int)Cache::get('pet_amap_' . $ticket, 0) : 0;
        if (!$actor || !Db::name('user')->where(['id' => $actor, 'status' => 1, 'mark' => 1])->count()) { throw new InvalidArgumentException('地图会话已失效，请关闭后重新选择位置'); }
        if ($actor !== 1 && !in_array('pet:places:edit', (new \app\admin\service\MenuService())->getPermissionsList($actor), true)) { throw new InvalidArgumentException('无地图选点权限'); }
        $paths = ['v3/place/text', 'v3/place/around', 'v3/place/detail', 'v3/assistant/inputtips', 'v3/geocode/regeo', 'v3/geocode/geo', 'v4/map/styles'];
        if (!in_array($path, $paths, true)) { throw new InvalidArgumentException('不支持的地图请求'); }
        if (!empty($params['callback']) && !preg_match('/^[a-zA-Z_$][\w.$]{0,100}$/', (string)$params['callback'])) { throw new InvalidArgumentException('回调参数无效'); }
        $counter = 'pet_amap_rate_' . $actor . '_' . date('YmdHi');
        $count = (int)Cache::get($counter, 0);
        if ($count >= 120) { throw new InvalidArgumentException('地图请求频繁，请稍后重试'); }
        Cache::set($counter, $count + 1, 90);
        unset($params['ticket'], $params['path']);
        $params['key'] = (string)env('amap.key');
        $params['jscode'] = (string)env('amap.security_code');
        $query = http_build_query($params);
        if (strlen($query) > 8000) { throw new InvalidArgumentException('地图请求参数过长'); }
        $host = $path === 'v4/map/styles' ? 'https://webapi.amap.com/' : 'https://restapi.amap.com/';
        $curl = curl_init($host . $path . '?' . $query);
        curl_setopt_array($curl, [CURLOPT_RETURNTRANSFER => true, CURLOPT_CONNECTTIMEOUT => 8, CURLOPT_TIMEOUT => 15, CURLOPT_SSL_VERIFYPEER => true, CURLOPT_SSL_VERIFYHOST => 2, CURLOPT_REFERER => (string)request()->header('referer', '')]);
        $body = curl_exec($curl); $status = curl_getinfo($curl, CURLINFO_HTTP_CODE); curl_close($curl);
        if ($body === false || $status !== 200) { throw new RuntimeException('地图服务暂时不可用，请重试'); }
        return $body;
    }
}
