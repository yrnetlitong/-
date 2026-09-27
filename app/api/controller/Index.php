<?php
namespace app\api\controller;

use app\common\service\PetInput;
use app\common\service\PetService;
use app\common\service\PetSession;
use app\common\service\WechatService;
use think\facade\Cache;
use think\facade\Db;

class Index extends Base
{
    public function index()
    {
        return $this->success(['ping' => 'pong']);
    }

    public function config()
    {
        $settings = PetService::settings();
        $schemas = array_map(function ($row) { return array_intersect_key($row, array_flip(['code', 'name', 'fields'])); }, \app\common\service\RecordTypes::all(true));
        return $this->success(['name' => '豆知宠物', 'announcement' => $settings['pet_announcement'] ?? '', 'about' => $settings['pet_about'] ?? '', 'privacy' => $settings['pet_privacy'] ?? '', 'agreement' => $settings['pet_agreement'] ?? '', 'template_id' => $settings['pet_reminder_template'] ?? '', 'default_days' => json_decode($settings['pet_default_days'] ?? '{}', true), 'record_types' => array_column($schemas, 'name', 'code'), 'record_schemas' => $schemas, 'categories' => \app\common\service\PlaceTypes::labels(true)]);
    }

    public function login()
    {
        if (!$this->request->isPost()) {
            return $this->fail('请使用POST请求', 405);
        }
        try {
            $input = $this->request->post();
            $code = PetInput::text($input, 'code', 200, true);
            if (($input['agree'] ?? false) !== true) {
                return $this->fail('请同意使用微信身份创建账号', 422);
            }
            $limitKey = 'petknow_login_' . hash('sha256', $this->request->ip());
            $attempts = (int)Cache::get($limitKey, 0);
            if ($attempts >= 30) {
                return $this->fail('操作频繁，请稍后重试', 429);
            }
            Cache::set($limitKey, $attempts + 1, 60);
            $session = (new WechatService())->session($code);
            if (empty($session['openid'])) {
                return $this->fail('微信登录凭证无效', 401);
            }
            $username = 'wx' . substr(hash('sha256', $session['openid']), 0, 28);
            $member = Db::name('member')->where('username', $username)->find();
            if (!$member) {
                try {
                    $id = Db::name('member')->insertGetId(['username' => $username, 'openid' => $session['openid'], 'nickname' => '新朋友', 'status' => 1, 'mark' => 1, 'create_time' => time(), 'update_time' => time()]);
                } catch (\think\db\exception\PDOException $e) {
                    $id = (int)Db::name('member')->where('username', $username)->value('id');
                    if (!$id) {
                        throw $e;
                    }
                }
                $member = Db::name('member')->where('id', $id)->find();
            }
            if ((int)$member['status'] !== 1 || (int)$member['mark'] !== 1) {
                return $this->fail('账号已停用，请联系平台', 403);
            }
            $id = (int)$member['id'];
            Db::name('member')->where('id', $id)->inc('login_count')->update(['login_time' => time(), 'login_ip' => $this->request->ip()]);
            PetService::audit($id, '微信登录', ['result' => 'success']);
            return $this->success(PetSession::issue($id) + ['user' => (new PetService())->profile($id)]);
        } catch (\InvalidArgumentException $e) {
            return $this->fail($e->getMessage(), 422);
        } catch (\RuntimeException $e) {
            return $this->fail($e->getMessage(), 502);
        } catch (\Throwable $e) {
            \think\facade\Log::error('微信登录失败：' . $e->getMessage());
            return $this->fail('登录失败，请稍后重试', 500);
        }
    }

    public function places()
    {
        try {
            return $this->success((new PetService())->publicPlaces($this->request->get()));
        } catch (\InvalidArgumentException $e) {
            return $this->fail($e->getMessage(), 422);
        }
    }

    public function place()
    {
        try {
            return $this->success((new PetService())->placeDetail((int)$this->request->get('id'), PetSession::member((string)$this->request->header('Authorization'))));
        } catch (\InvalidArgumentException $e) {
            return $this->fail($e->getMessage(), 404);
        }
    }

    public function reviews()
    {
        $id = (int)$this->request->get('place_id');
        if (!Db::name('pet_place')->where(['id' => $id, 'status' => 1])->count()) {
            return $this->fail('点位不存在', 404);
        }
        $query = Db::name('pet_review')->alias('r')->leftJoin('member m', 'm.id=r.member_id')->where('r.place_id', $id)->field('r.id,r.rating,r.content,r.create_time,m.nickname,m.avatar');
        return $this->success(PetService::paginate($query, $this->request->get(), 'r.id desc'));
    }
}
