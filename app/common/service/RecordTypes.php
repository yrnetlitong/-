<?php
namespace app\common\service;

use InvalidArgumentException;
use think\facade\Db;

class RecordTypes
{
    public static function query()
    {
        return Db::name('dict_data')->where('dict_id', (int)Db::name('dict')->where('code', 'pet_record_types')->value('id'))->where('mark', 1);
    }

    public static function all(bool $active = false): array
    {
        $q = self::query();
        if ($active) { $q->where('status', 1); }
        $rows = $q->order('sort,id')->select()->toArray();
        foreach ($rows as &$row) { $row['fields'] = json_decode($row['pet_fields'] ?: '[]', true) ?: []; unset($row['pet_fields']); }
        return $rows;
    }

    public static function selected(array $input): array
    {
        $code = PetInput::text($input, 'type', 12, true);
        foreach (self::all(true) as $row) { if ($row['code'] === $code) { return $row; } }
        throw new InvalidArgumentException('记录类型不存在或已停用，请刷新后选择');
    }

    public static function fields(array $input): array
    {
        $fields = $input['fields'] ?? null;
        if (!is_array($fields) || count($fields) < 1 || count($fields) > 20) { throw new InvalidArgumentException('请设置1至20个记录字段'); }
        $result = []; $names = [];
        foreach ($fields as $field) {
            if (!is_array($field)) { throw new InvalidArgumentException('记录字段格式无效'); }
            $key = PetInput::text($field, 'key', 32, true);
            $label = PetInput::text($field, 'label', 40, true);
            if (!preg_match('/^[a-z][a-z0-9_]{0,31}$/', $key) || isset($result[$key]) || in_array($label, $names, true)) { throw new InvalidArgumentException('字段标识或名称无效、重复'); }
            $result[$key] = ['key' => $key, 'label' => $label, 'kind' => PetInput::choice($field, 'kind', ['text', 'textarea', 'number']), 'required' => is_bool($field['required'] ?? null) ? $field['required'] : (bool)PetInput::integer($field, 'required', 0, 1)];
            $names[] = $label;
        }
        return array_values($result);
    }

    public static function values(array $type, array $input): array
    {
        $values = $input['values'] ?? $input;
        if (!is_array($values)) { throw new InvalidArgumentException('记录内容格式无效'); }
        $result = [];
        foreach ($type['fields'] as $field) {
            $value = PetInput::text($values, $field['key'], $field['kind'] === 'textarea' ? 3000 : 120, $field['required']);
            if ($value !== '' && $field['kind'] === 'number' && (!is_numeric($value) || !is_finite((float)$value))) { throw new InvalidArgumentException($field['label'] . '请填写数字'); }
            $result[] = ['key' => $field['key'], 'label' => $field['label'], 'value' => $value];
        }
        return $result;
    }

    public static function operate(int $actor, array $input): array
    {
        return Db::transaction(function () use ($actor, $input) {
            $dict = Db::name('dict')->where('code', 'pet_record_types')->lock(true)->find();
            if (!$dict) { throw new InvalidArgumentException('请先升级记录类型配置'); }
            $id = (int)($input['id'] ?? 0);
            $old = $id ? self::query()->where('id', $id)->find() : null;
            if ($id && !$old) { throw new InvalidArgumentException('记录类型不存在'); }
            $action = PetInput::choice($input, 'action', ['save', 'status', 'remove']);
            if ($action === 'save') {
                $data = ['name' => PetInput::text($input, 'name', 40, true), 'status' => PetInput::integer($input, 'status', 1, 2), 'sort' => PetInput::integer($input, 'sort', 0, 65535), 'pet_fields' => json_encode(self::fields($input), JSON_UNESCAPED_UNICODE), 'update_user' => $actor, 'update_time' => time()];
                if (self::query()->where('name', $data['name'])->where('id', '<>', $id)->count()) { throw new InvalidArgumentException('记录类型名称已存在'); }
                if ($id) { self::query()->where('id', $id)->update($data); }
                else {
                    if (self::query()->count() >= 100) { throw new InvalidArgumentException('最多配置100个记录类型'); }
                    $id = Db::name('dict_data')->insertGetId($data + ['dict_id' => $dict['id'], 'code' => 'r' . bin2hex(random_bytes(5)), 'mark' => 1, 'create_user' => $actor, 'create_time' => time()]);
                }
            } else {
                if (!$old) { throw new InvalidArgumentException('记录类型不存在'); }
                if ($action === 'remove') {
                    if (Db::name('pet_record')->where('type', $old['code'])->count() || Db::name('pet_reminder')->where('type', $old['code'])->count()) { throw new InvalidArgumentException('该类型已有记录或提醒，请停用而非删除'); }
                    self::query()->where('id', $id)->update(['mark' => 0]);
                } else { self::query()->where('id', $id)->update(['status' => (int)$old['status'] === 1 ? 2 : 1, 'update_user' => $actor, 'update_time' => time()]); }
            }
            PetService::audit($actor, '管理记录类型', ['id' => $id, 'action' => $action, 'name' => $input['name'] ?? $old['name'], 'result' => 'success'], true);
            return ['id' => $id];
        });
    }
}
