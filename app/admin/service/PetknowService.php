<?php
namespace app\admin\service;

use app\common\service\PetInput;
use app\common\service\PetService;
use think\facade\Db;

class PetknowService extends BaseService
{
    public const TABLES = ['placetypes' => 'dict_data', 'recordtypes' => 'dict_data', 'members' => 'member', 'pets' => 'pet', 'records' => 'pet_record', 'places' => 'pet_place', 'reminders' => 'pet_reminder'];

    public function listing(string $module, array $input): array
    {
        if (in_array($module, ['recordtypes', 'placetypes'], true)) {
            $q = $module === 'recordtypes' ? \app\common\service\RecordTypes::query() : \app\common\service\PlaceTypes::query();
            if (!empty($input['keyword'])) { $q->whereLike('name', '%' . PetInput::text($input, 'keyword', 100) . '%'); }
            if (isset($input['status']) && $input['status'] !== '') { $q->where('status', PetInput::integer($input, 'status', 1, 2)); }
            $result = PetService::paginate($q, $input, 'sort,id');
            foreach ($result['list'] as &$row) { $row['fields'] = json_decode($row['pet_fields'] ?: '[]', true) ?: []; unset($row['pet_fields']); }
            return $result;
        }
        $q = Db::name(self::TABLES[$module])->alias('b');
        if ($module === 'members') {
            $q->where('b.mark', 1)->field('b.id,b.nickname,b.avatar,b.status,b.create_time,b.login_time');
        } elseif ($module !== 'records') {
            $q->leftJoin('member m', 'm.id=b.member_id')->field('b.*,m.nickname as member_name');
        }
        if ($module === 'records') {
            $q->leftJoin('member m', 'm.id=b.member_id')->leftJoin('pet p', 'p.id=b.pet_id')->field('b.id,b.member_id,b.pet_id,b.type,b.type_name,b.occurred_at,b.create_time,m.nickname as member_name,p.name as pet_name,p.type as pet_type,p.breed as pet_breed,p.gender as pet_gender,p.birthday as pet_birthday,p.weight as pet_weight');
        }
        if (!empty($input['keyword'])) {
            $field = ['members' => 'b.nickname', 'pets' => 'b.name', 'records' => 'p.name|m.nickname|b.type_name', 'places' => 'b.name', 'reminders' => 'b.title'][$module];
            $q->whereLike($field, '%' . PetInput::text($input, 'keyword', 100) . '%');
        }
        foreach (['member_id', 'pet_id', 'type', 'status', 'category', 'source'] as $key) {
            if (!isset($input[$key]) || $input[$key] === '') { continue; }
            $allowed = ['members' => ['status'], 'pets' => ['member_id', 'type'], 'records' => ['member_id', 'pet_id', 'type'], 'places' => ['member_id', 'category', 'status', 'source'], 'reminders' => ['member_id', 'pet_id', 'type', 'status']];
            if (in_array($key, $allowed[$module], true)) { $q->where('b.' . $key, $input[$key]); }
        }
        foreach (['start' => '>=', 'end' => '<='] as $key => $operator) {
            if (!empty($input[$key])) {
                $time = strtotime(PetInput::text($input, $key, 19));
                if (!$time) { throw new \InvalidArgumentException('时间范围无效'); }
                $q->where('b.' . ($module === 'records' ? 'occurred_at' : 'create_time'), $operator, $time);
            }
        }
        $result = PetService::paginate($q, $input, 'b.id desc');
        if ($module === 'members' && $result['list']) {
            $ids = array_column($result['list'], 'id');
            $pets = Db::name('pet')->whereIn('member_id', $ids)->group('member_id')->column('COUNT(*)', 'member_id');
            $places = Db::name('pet_place')->whereIn('member_id', $ids)->group('member_id')->column('COUNT(*)', 'member_id');
            foreach ($result['list'] as &$row) { $row['pet_count'] = $pets[$row['id']] ?? 0; $row['place_count'] = $places[$row['id']] ?? 0; }
        }
        return $result;
    }

    public function detail(string $module, int $id, array $input): array
    {
        if (in_array($module, ['recordtypes', 'placetypes'], true)) { throw new \InvalidArgumentException('请从列表编辑类型'); }
        $row = Db::name(self::TABLES[$module])->where('id', $id)->find();
        if (!$row) { throw new \InvalidArgumentException('数据不存在'); }
        if ($module === 'members') {
            $row = (new PetService())->profile($id) + ['status' => $row['status']];
        }
        $result = ['item' => PetService::rows([$row])[0]];
        if ($module === 'records') {
            $pet = Db::name('pet')->where('id', $row['pet_id'])->find();
            $result['pet'] = $pet ? PetService::rows([$pet])[0] : null;
            if (!$result['item']['field_values']) {
                foreach (['product'=>'记录内容','amount'=>'用量 / 规格','method'=>'方式'] as $key => $label) {
                    if ($row[$key] !== '') { $result['item']['field_values'][] = ['key'=>$key,'label'=>$label,'value'=>$row[$key]]; }
                }
            }
        }
        if ($module === 'pets') {
            $result['records'] = PetService::paginate(Db::name('pet_record')->where('pet_id', $id), $input, 'occurred_at desc,id desc');
            $result['reminders'] = PetService::paginate(Db::name('pet_reminder')->where('pet_id', $id), $input);
        }
        if ($module === 'members') {
            $result['pets'] = PetService::paginate(Db::name('pet')->where('member_id', $id), $input);
            $result['places'] = PetService::paginate(Db::name('pet_place')->where('member_id', $id), $input);
        }
        if ($module === 'places') {
            $result['reviews'] = PetService::paginate(Db::name('pet_review')->where('place_id', $id), $input);
        }
        return $result;
    }

    public function overview(): array
    {
        $counts = [];
        foreach (self::TABLES as $key => $table) {
            if ($key === 'placetypes') { $counts[$key] = \app\common\service\PlaceTypes::query()->count(); }
            elseif ($key === 'recordtypes') { $counts[$key] = \app\common\service\RecordTypes::query()->count(); }
            else { $counts[$key] = Db::name($table)->count(); }
        }
        $counts['pending'] = Db::name('pet_place')->where('status', 0)->count();
        $counts['completed'] = Db::name('pet_reminder')->where('status', 1)->count();
        $counts['failed'] = Db::name('pet_reminder')->where('push_status', 'failed')->count();
        $growth = Db::name('member')->where('create_time', '>=', strtotime('-29 days midnight'))->field("FROM_UNIXTIME(create_time,'%Y-%m-%d') as day,COUNT(*) as total")->group('day')->order('day')->select()->toArray();
        $types = Db::name('pet_reminder')->field('type,COUNT(*) as total,SUM(status=1) as completed,SUM(sent_at>0) as triggered')->group('type')->select()->toArray();
        return ['counts' => $counts, 'growth' => $growth, 'types' => $types];
    }

    public function operate(string $module, int $actor, array $input): array
    {
        if ($module === 'placetypes') { return \app\common\service\PlaceTypes::operate($actor, $input); }
        if ($module === 'recordtypes') { return \app\common\service\RecordTypes::operate($actor, $input); }
        $action = PetInput::choice($input, 'action', ['status', 'remove', 'save', 'approve', 'reject', 'top']);
        $id = (int)($input['id'] ?? 0);
        return Db::transaction(function () use ($module, $actor, $input, $action, $id) {
            if ($module === 'places' && $action === 'save') {
                $data = (new PetService())->placeData($input);
                $data['status'] = 1;
                $data['source'] = 'official';
                if ($id) {
                    $old = Db::name('pet_place')->where('id', $id)->lock(true)->find();
                    if (!$old || $old['source'] !== 'official') { throw new \InvalidArgumentException('只能编辑官方点位'); }
                    Db::name('pet_place')->where('id', $id)->update($data);
                } else {
                    $id = Db::name('pet_place')->insertGetId($data + ['member_id' => 0, 'create_time' => time()]);
                }
            } else {
                $row = Db::name(self::TABLES[$module])->where('id', $id)->lock(true)->find();
                if (!$row) { throw new \InvalidArgumentException('数据不存在'); }
                if ($module === 'members' && $action === 'status') {
                    Db::name('member')->where('id', $id)->update(['status' => (int)$row['status'] === 1 ? 2 : 1, 'update_user' => $actor, 'update_time' => time()]);
                } elseif (in_array($module, ['pets', 'records'], true) && $action === 'remove') {
                    $reason = PetInput::text($input, 'reason', 500, true);
                    if ($module === 'pets') { (new PetService())->deletePet((int)$row['member_id'], $id, $actor); }
                    else { Db::name('pet_record')->where('id', $id)->delete(); }
                    PetService::audit($actor, $module === 'records' ? '删除养护记录' : '异常数据清理', ['module' => $module, 'id' => $id, 'reason' => $reason], true);
                } elseif ($module === 'places') {
                    $data = ['update_time' => time(), 'review_user' => $actor, 'reviewed_at' => time()];
                    if (in_array($action, ['approve', 'reject'], true)) {
                        if ((int)$row['status'] !== 0 || $row['source'] !== 'user') { throw new \InvalidArgumentException('投稿已被处理，请刷新'); }
                        $data['status'] = $action === 'approve' ? 1 : 2;
                        $data['rejection'] = $action === 'reject' ? PetInput::text($input, 'reason', 500, true) : '';
                        PetService::notify((int)$row['member_id'], $action === 'approve' ? '投稿审核通过' : '投稿需要调整', $row['name'] . ($data['rejection'] ? '：' . $data['rejection'] : ' 已展示在友好地图'), 'place', $id);
                    } elseif ($action === 'status' && in_array((int)$row['status'], [1, 3], true)) {
                        $data['status'] = (int)$row['status'] === 1 ? 3 : 1;
                    } elseif ($action === 'top' && $row['source'] === 'official') {
                        $data['is_top'] = $row['is_top'] ? 0 : 1;
                    } else { throw new \InvalidArgumentException('不允许的点位操作'); }
                    Db::name('pet_place')->where('id', $id)->update($data);
                } else { throw new \InvalidArgumentException('不支持该操作'); }
            }
            PetService::audit($actor, '后台宠物业务操作', ['module' => $module, 'id' => $id, 'action' => $action, 'result' => 'success'], true);
            return ['id' => $id];
        });
    }

    public function saveSettings(int $actor, array $input): array
    {
        $current = PetService::settings();
        $data = [];
        foreach ($current as $key => $value) { $data[$key] = PetInput::text($input, $key, 20000); }
        foreach (['pet_default_days', 'pet_reminder_fields'] as $key) {
            $value = json_decode($data[$key], true);
            if (!is_array($value) || !$value) { throw new \InvalidArgumentException('请填写正确的JSON配置'); }
            foreach ($value as $field => $item) {
                if ($key === 'pet_reminder_fields' && (!preg_match('/^(thing|time|date|character_string|phrase)\d+$/', $field) || !in_array($item, ['title', 'due_at'], true))) { throw new \InvalidArgumentException('模板字段映射无效'); }
                if ($key === 'pet_default_days' && (!is_numeric($item) || $item < 1 || $item > 3650)) { throw new \InvalidArgumentException('提醒天数为1至3650'); }
            }
        }
        Db::transaction(function () use ($data, $actor) {
            foreach ($data as $key => $value) { Db::name('config_data')->where('code', $key)->update(['value' => $value, 'update_user' => $actor, 'update_time' => time()]); }
            PetService::audit($actor, '修改豆知配置', ['keys' => array_keys($data)], true);
        });
        return [];
    }
}
