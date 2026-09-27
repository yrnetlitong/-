<?php
namespace app\common\service;

use InvalidArgumentException;
use think\facade\Db;

class PetService
{
    public static function settings(): array
    {
        return Db::name('config_data')->where('code', 'like', 'pet_%')->where(['mark' => 1, 'status' => 1])->column('value', 'code');
    }

    public static function rows(array $rows): array
    {
        $needsTypes = array_filter($rows, function ($row) { return (isset($row['occurred_at']) || isset($row['due_at'])) && empty($row['type_name']); });
        $names = $needsTypes ? array_column(RecordTypes::all(), 'name', 'code') : [];
        $categories = array_filter($rows, function ($row) { return isset($row['category']); }) ? PlaceTypes::labels() : [];
        foreach ($rows as &$row) {
            if (isset($row['category'])) { $row['category_name'] = $categories[$row['category']] ?? $row['category']; }
            if (isset($row['type']) && (isset($row['occurred_at']) || isset($row['due_at']))) { $row['type_name'] = ($row['type_name'] ?? '') ?: ($names[$row['type']] ?? $row['type']); }
            if (array_key_exists('field_values', $row)) { $row['field_values'] = json_decode($row['field_values'] ?: '[]', true) ?: []; }
            if (array_key_exists('images', $row)) {
                $row['images'] = json_decode($row['images'] ?: '[]', true) ?: [];
            }
        }
        return $rows;
    }

    public static function paginate($query, array $input, string $order = 'id desc'): array
    {
        $page = max(1, (int)($input['page'] ?? 1));
        $limit = min(100, max(1, (int)($input['limit'] ?? 20)));
        $total = (clone $query)->count();
        $rows = $query->order($order)->page($page, $limit)->select()->toArray();
        return ['list' => self::rows($rows), 'total' => $total, 'page' => $page];
    }

    public static function owned(string $table, int $id, int $member, bool $lock = false): array
    {
        $row = Db::name($table)->where(['id' => $id, 'member_id' => $member])->lock($lock)->find();
        if (!$row) {
            throw new InvalidArgumentException('数据不存在或无权访问');
        }
        return $row;
    }

    public static function audit(int $actor, string $action, array $summary, bool $admin = false): void
    {
        if (!defined('DB_PREFIX')) {
            define('DB_PREFIX', config('database.connections.mysql.prefix'));
        }
        $model = new \app\admin\model\ActionLog();
        $model->save(['username' => ($admin ? '管理员#' : '用户#') . $actor, 'module' => 'petknow', 'method' => PHP_SAPI === 'cli' ? 'CLI' : request()->method(), 'url' => '', 'param' => '', 'title' => $action, 'type' => 3, 'content' => mb_substr(json_encode($summary, JSON_UNESCAPED_UNICODE), 0, 1000), 'create_user' => $actor, 'create_time' => time(), 'mark' => 1]);
    }

    public function profile(int $member): array
    {
        $row = Db::name('member')->where('id', $member)->field('id,nickname,avatar,create_time')->find();
        $row['pet_count'] = Db::name('pet')->where('member_id', $member)->count();
        $row['place_count'] = Db::name('pet_place')->where('member_id', $member)->count();
        $row['reminder_count'] = Db::name('pet_reminder')->where(['member_id' => $member, 'status' => 0, 'enabled' => 1])->count();
        return $row;
    }

    public function saveProfile(int $member, array $input): array
    {
        $data = ['nickname' => PetInput::text($input, 'nickname', 40, true), 'update_time' => time()];
        if (!empty($input['avatar'])) {
            PetInput::images(['images' => [$input['avatar']]]);
            $data['avatar'] = PetInput::text($input, 'avatar', 180, true);
        }
        Db::name('member')->where('id', $member)->update($data);
        return $this->profile($member);
    }

    public function savePet(int $member, array $input): array
    {
        $data = ['name' => PetInput::text($input, 'name', 40, true), 'type' => PetInput::choice($input, 'type', ['cat', 'dog', 'other']), 'gender' => PetInput::choice($input, 'gender', ['male', 'female', 'unknown']), 'neutered' => PetInput::choice($input, 'neutered', ['yes', 'no', 'unknown']), 'weight' => PetInput::number($input, 'weight', 0, 9999), 'images' => PetInput::images($input), 'update_time' => time()];
        foreach (['breed' => 80, 'color' => 60, 'vaccination' => 500, 'character_note' => 500, 'note' => 3000] as $key => $length) {
            $data[$key] = PetInput::text($input, $key, $length);
        }
        $birthday = PetInput::text($input, 'birthday', 10);
        if ($birthday) {
            PetInput::date(['birthday' => $birthday . ' 00:00:00'], 'birthday');
        }
        $data['birthday'] = $birthday ?: null;
        return Db::transaction(function () use ($member, $input, $data) {
            $id = (int)($input['id'] ?? 0);
            if ($id) {
                self::owned('pet', $id, $member, true);
                Db::name('pet')->where('id', $id)->update($data);
            } else {
                $id = Db::name('pet')->insertGetId($data + ['member_id' => $member, 'create_time' => time()]);
            }
            self::audit($member, '保存宠物档案', ['id' => $id, 'name' => $data['name']]);
            return ['id' => $id];
        });
    }

    public function deletePet(int $member, int $id, int $admin = 0): void
    {
        Db::transaction(function () use ($member, $id, $admin) {
            $pet = self::owned('pet', $id, $member, true);
            Db::name('pet_record')->where('pet_id', $id)->delete();
            Db::name('pet_reminder')->where('pet_id', $id)->delete();
            Db::name('notice')->where(['pet_member_id' => $member, 'pet_kind' => 'reminder', 'pet_object_id' => $id])->delete();
            Db::name('pet')->where('id', $id)->delete();
            self::audit($admin ?: $member, '删除宠物及关联养护记录和提醒', ['id' => $id, 'name' => $pet['name']], $admin > 0);
        });
    }

    public function saveRecord(int $member, array $input): array
    {
        $type = RecordTypes::selected($input);
        $values = RecordTypes::values($type, $input);
        $data = ['type_name' => $type['name'], 'field_values' => json_encode($values, JSON_UNESCAPED_UNICODE), 'member_id' => $member, 'pet_id' => (int)($input['pet_id'] ?? 0), 'type' => $type['code'], 'occurred_at' => PetInput::date($input, 'occurred_at'), 'images' => PetInput::images($input), 'create_time' => time()];
        $data['note'] = PetInput::text($input, 'note', 3000);
        $data['product'] = mb_substr(implode(' / ', array_filter(array_column($values, 'value'), 'strlen')), 0, 120);
        $data['next_at'] = empty($input['next_at']) ? 0 : PetInput::date($input, 'next_at', true);
        return Db::transaction(function () use ($data, $member) {
            self::owned('pet', $data['pet_id'], $member, true);
            $id = Db::name('pet_record')->insertGetId($data);
            self::audit($member, '新增养护记录', ['id' => $id, 'pet_id' => $data['pet_id'], 'type' => $data['type']]);
            return ['id' => $id];
        });
    }

    public function placeData(array $input): array
    {
        $categories = PlaceTypes::labels(true);
        if (!empty($input['id'])) {
            $existing = Db::name('pet_place')->where('id', (int)$input['id'])->value('category');
            if ($existing) { $categories[$existing] = $existing; }
        }
        $data = ['name' => PetInput::text($input, 'name', 100, true), 'category' => PetInput::choice($input, 'category', array_keys($categories)), 'address' => PetInput::text($input, 'address', 255, true), 'latitude' => PetInput::number($input, 'latitude', -90, 90), 'longitude' => PetInput::number($input, 'longitude', -180, 180), 'images' => PetInput::images($input), 'update_time' => time()];
        foreach (['phone' => 30, 'hours' => 100, 'rules' => 3000, 'note' => 3000] as $key => $max) {
            $data[$key] = PetInput::text($input, $key, $max, $key === 'rules');
        }
        if ($data['phone'] && !preg_match('/^[0-9+()\- ]{5,30}$/', $data['phone'])) {
            throw new InvalidArgumentException('联系电话格式错误');
        }
        return $data;
    }

    public function savePlace(int $member, array $input): array
    {
        $data = $this->placeData($input) + ['status' => 0, 'rejection' => '', 'reviewed_at' => 0, 'review_user' => 0];
        return Db::transaction(function () use ($member, $input, $data) {
            $id = (int)($input['id'] ?? 0);
            if ($id) {
                $old = self::owned('pet_place', $id, $member, true);
                if (!in_array((int)$old['status'], [0, 2], true)) {
                    throw new InvalidArgumentException('只能编辑待审核或已驳回的投稿');
                }
                Db::name('pet_place')->where('id', $id)->update($data);
            } else {
                $id = Db::name('pet_place')->insertGetId($data + ['member_id' => $member, 'source' => 'user', 'create_time' => time()]);
            }
            self::audit($member, '提交友好点位审核', ['id' => $id, 'name' => $data['name']]);
            return ['id' => $id];
        });
    }

    public function publicPlaces(array $input): array
    {
        $query = Db::name('pet_place')->where('status', 1);
        if (!empty($input['category'])) {
            $query->where('category', PetInput::text($input, 'category', 20, true));
        }
        if (!empty($input['keyword'])) {
            $query->whereLike('name', '%' . PetInput::text($input, 'keyword', 100) . '%');
        }
        if (isset($input['latitude'], $input['longitude']) && $input['latitude'] !== '') {
            $lat = PetInput::number($input, 'latitude', -90, 90);
            $lng = PetInput::number($input, 'longitude', -180, 180);
            $query->whereBetween('latitude', [max(-90, $lat - 0.5), min(90, $lat + 0.5)])->whereBetween('longitude', [max(-180, $lng - 0.7), min(180, $lng + 0.7)]);
        }
        return self::paginate($query->field('id,name,category,address,latitude,longitude,phone,hours,rules,images,source,is_top'), $input, 'is_top desc,id desc');
    }

    public function placeDetail(int $id, int $member = 0): array
    {
        $query = Db::name('pet_place')->where('id', $id);
        $query->where(function ($q) use ($member) {
            $q->where('status', 1);
            if ($member) {
                $q->whereOr('member_id', $member);
            }
        });
        $row = $query->find();
        if (!$row) {
            throw new InvalidArgumentException('点位不存在或尚未公开');
        }
        $row = self::rows([$row])[0];
        if ($member <= 0 || (int)$row['member_id'] !== $member) {
            unset($row['note'], $row['rejection'], $row['review_user'], $row['member_id']);
        }
        return $row;
    }

    public static function notify(int $member, string $title, string $content, string $kind, int $id): void
    {
        Db::name('notice')->insert(['title' => $title, 'content' => $content, 'source' => 1, 'status' => 2, 'mark' => 1, 'pet_member_id' => $member, 'pet_kind' => $kind, 'pet_object_id' => $id, 'create_time' => time(), 'update_time' => time()]);
    }
}
