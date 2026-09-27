<?php
namespace app\common\service;

use InvalidArgumentException;

class PetInput
{

    public static function text(array $data, string $key, int $max, bool $required = false): string
    {
        if (isset($data[$key]) && !is_scalar($data[$key])) {
            throw new InvalidArgumentException('字段格式错误：' . $key);
        }
        $value = trim((string)($data[$key] ?? ''));
        if (($required && $value === '') || mb_strlen($value) > $max) {
            throw new InvalidArgumentException('请检查必填项或长度：' . $key);
        }
        return $value;
    }

    public static function number(array $data, string $key, float $min, float $max): float
    {
        $value = $data[$key] ?? null;
        if (!is_numeric($value) || !is_finite((float)$value) || $value < $min || $value > $max) {
            throw new InvalidArgumentException('数值超出范围：' . $key);
        }
        return (float)$value;
    }

    public static function integer(array $data, string $key, int $min, int $max): int
    {
        $value = self::number($data, $key, $min, $max);
        if (floor($value) !== $value) { throw new InvalidArgumentException('请填写整数：' . $key); }
        return (int)$value;
    }

    public static function choice(array $data, string $key, array $choices): string
    {
        $value = self::text($data, $key, 40, true);
        if (!in_array($value, $choices, true)) {
            throw new InvalidArgumentException('选项无效：' . $key);
        }
        return $value;
    }

    public static function date(array $data, string $key, bool $future = false): int
    {
        $value = self::text($data, $key, 19, true);
        $date = \DateTimeImmutable::createFromFormat('!Y-m-d H:i:s', strlen($value) === 16 ? $value . ':00' : $value);
        if (!$date || $date->format('Y-m-d H:i:s') !== (strlen($value) === 16 ? $value . ':00' : $value)) {
            throw new InvalidArgumentException('日期格式错误：' . $key);
        }
        $time = $date->getTimestamp();
        if ($time < strtotime('1970-01-02') || $time > strtotime('+20 years') || ($future ? $time <= time() : $time > time())) {
            throw new InvalidArgumentException($future ? '提醒时间必须晚于当前时间' : '记录时间不能晚于当前时间');
        }
        return $time;
    }

    public static function images(array $data): string
    {
        $images = $data['images'] ?? [];
        if (!is_array($images) || count($images) > 9) {
            throw new InvalidArgumentException('最多上传9张图片');
        }
        foreach ($images as $url) {
            if (!is_string($url) || strlen($url) > 500 || !preg_match('#^https?://#', $url) || strpos($url, '/uploads/') === false || parse_url($url, PHP_URL_HOST) !== parse_url((string)env('domain.siteurl'), PHP_URL_HOST)) {
                throw new InvalidArgumentException('请先上传图片');
            }
        }
        return json_encode(array_values($images), JSON_UNESCAPED_UNICODE);
    }
}
