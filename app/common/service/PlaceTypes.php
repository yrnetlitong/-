<?php
namespace app\common\service;

use InvalidArgumentException;
use think\facade\Db;

class PlaceTypes
{
    public const DEFAULTS = ['restaurant' => '餐厅', 'hotel' => '酒店', 'park' => '公园', 'grooming' => '洗护', 'hospital' => '医院'];

    public static function query()
    {
        return Db::name('dict_data')->where('dict_id', (int)Db::name('dict')->where('code', 'pet_place_types')->value('id'))->where('mark', 1);
    }

    public static function labels(bool $active = false): array
    {
        $q = self::query();
        if ($active) { $q->where('status', 1); }
        return $q->order('sort,id')->column('name', 'code');
    }

    public static function operate(int $actor, array $input): array
    {
        return Db::transaction(function () use ($actor, $input) {
            $dict = Db::name('dict')->where('code', 'pet_place_types')->lock(true)->find();
            if (!$dict) { throw new InvalidArgumentException('请先升级点位类型配置'); }
            $id = (int)($input['id'] ?? 0);
            $row = $id ? self::query()->where('id', $id)->find() : null;
            if ($id && !$row) { throw new InvalidArgumentException('点位类型不存在'); }
            $action = PetInput::choice($input, 'action', ['save', 'status', 'remove']);
            $data = ['update_user' => $actor, 'update_time' => time()];
            if ($action === 'save') {
                $data += ['name' => PetInput::text($input, 'name', 40, true), 'sort' => PetInput::integer($input, 'sort', 0, 65535), 'status' => PetInput::integer($input, 'status', 1, 2)];
                if (self::query()->where('name', $data['name'])->where('id', '<>', $id)->count()) { throw new InvalidArgumentException('点位类型名称已存在'); }
                if (!$id) {
                    if (self::query()->count() >= 100) { throw new InvalidArgumentException('最多配置100个点位类型'); }
                    $id = Db::name('dict_data')->insertGetId($data + ['dict_id' => $dict['id'], 'code' => 'p' . bin2hex(random_bytes(5)), 'mark' => 1, 'create_user' => $actor, 'create_time' => time()]);
                } else { self::query()->where('id', $id)->update($data); }
            } else {
                if (!$row) { throw new InvalidArgumentException('点位类型不存在'); }
                if ($action === 'remove') {
                    if (Db::name('pet_place')->where('category', $row['code'])->count()) { throw new InvalidArgumentException('该类型下已有点位，请停用而非删除'); }
                    $data['mark'] = 0;
                } else { $data['status'] = (int)$row['status'] === 1 ? 2 : 1; }
                self::query()->where('id', $id)->update($data);
            }
            PetService::audit($actor, '管理点位类型', ['id' => $id, 'action' => $action, 'name' => $input['name'] ?? $row['name'], 'result' => 'success'], true);
            return ['id' => $id];
        });
    }
}
