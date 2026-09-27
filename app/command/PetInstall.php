<?php
namespace app\command;

use think\console\Command;
use think\console\Input;
use think\console\Output;
use think\facade\Db;

class PetInstall extends Command
{
    protected function configure()
    {
        $this->setName('pet:install')->setDescription('幂等升级宠物业务结构和菜单，不删除已有数据');
    }

    protected function execute(Input $input, Output $output)
    {
        $prefix = (string)config('database.connections.mysql.prefix');
        if (!preg_match('/^[a-zA-Z0-9_]*$/', $prefix)) {
            throw new \RuntimeException('数据库前缀无效');
        }
        $sql = file_get_contents(app()->getRootPath() . 'document/petknow.sql');
        foreach (explode(';', str_replace('think_', $prefix, $sql)) as $statement) {
            if (trim($statement)) {
                Db::execute($statement);
            }
        }
        if (!in_array('pet_member_id', Db::getFields($prefix . 'notice') ? array_keys(Db::getFields($prefix . 'notice')) : [], true)) {
            Db::execute("ALTER TABLE `{$prefix}notice` ADD pet_member_id INT UNSIGNED NOT NULL DEFAULT 0, ADD pet_object_id INT UNSIGNED NOT NULL DEFAULT 0, ADD pet_kind VARCHAR(20) NOT NULL DEFAULT '', ADD pet_read_at INT UNSIGNED NOT NULL DEFAULT 0, ADD INDEX idx_pet_member (pet_member_id, mark, id)");
        }
        foreach (['series_id', 'next_id'] as $column) {
            if (!array_key_exists($column, Db::getFields($prefix . 'pet_reminder'))) {
                Db::execute("ALTER TABLE `{$prefix}pet_reminder` ADD `{$column}` INT UNSIGNED NOT NULL DEFAULT 0");
            }
        }
        foreach (['dict_data' => ['pet_fields' => 'TEXT NULL'], 'pet_record' => ['field_values' => 'MEDIUMTEXT NULL', 'type_name' => "VARCHAR(40) NOT NULL DEFAULT ''"], 'pet_reminder' => ['type_name' => "VARCHAR(40) NOT NULL DEFAULT ''"]] as $table => $columns) {
            foreach ($columns as $column => $definition) {
                if (!array_key_exists($column, Db::getFields($prefix . $table))) { Db::execute("ALTER TABLE `{$prefix}{$table}` ADD `{$column}` {$definition}"); }
            }
            Db::connect()->getSchemaInfo($prefix . $table, true);
        }
        foreach (['pet', 'pet_record', 'pet_reminder', 'pet_place', 'pet_review', 'notice'] as $table) {
            Db::connect()->getSchemaInfo($prefix . $table, true);
        }
        Db::transaction(function () {
            \app\admin\service\PetMenuService::sync();
            $placeDict = Db::name('dict')->where('code', 'pet_place_types')->value('id');
            if (!$placeDict) {
                $placeDict = Db::name('dict')->insertGetId(['name' => '宠物点位类型', 'code' => 'pet_place_types', 'mark' => 1, 'create_time' => time()]);
                foreach (\app\common\service\PlaceTypes::DEFAULTS as $code => $name) {
                    Db::name('dict_data')->insert(['dict_id' => $placeDict, 'code' => $code, 'name' => $name, 'status' => 1, 'mark' => 1, 'create_time' => time()]);
                }
            }
            $dict = Db::name('dict')->where('code', 'pet_record_types')->value('id');
            if (!$dict) {
                $dict = Db::name('dict')->insertGetId(['name' => '宠物记录类型', 'code' => 'pet_record_types', 'mark' => 1, 'create_time' => time()]);
                $defaults = ['feed' => ['喂食', '食物内容', '喂食量', '喂食方式'], 'bath' => ['洗澡', '洗护用品', '用量', '洗澡方式'], 'internal' => ['内驱', '驱虫药品', '用药量'], 'external' => ['外驱', '驱虫药品', '用药量'], 'vaccine' => ['疫苗', '疫苗名称', '接种剂量'], 'exam' => ['体检', '体检项目', '检查结果'], 'custom' => ['自定义', '记录内容']];
                foreach ($defaults as $code => $labels) {
                    $name = array_shift($labels); $fields = [];
                    foreach ($labels as $i => $label) { $fields[] = ['key' => ['product', 'amount', 'method'][$i], 'label' => $label, 'kind' => 'text', 'required' => $i === 0]; }
                    Db::name('dict_data')->insert(['dict_id' => $dict, 'code' => $code, 'name' => $name, 'pet_fields' => json_encode($fields, JSON_UNESCAPED_UNICODE), 'status' => 1, 'mark' => 1, 'create_time' => time()]);
                }
            }
            foreach (\app\common\service\RecordTypes::all() as $type) {
                foreach (['pet_record', 'pet_reminder'] as $table) {
                    Db::name($table)->where(['type' => $type['code'], 'type_name' => ''])->update(['type_name' => $type['name']]);
                }
            }
            $defaults = ['pet_announcement' => ['首页寄语', '把每一天的陪伴，认真记下来。'], 'pet_about' => ['关于豆知', '豆知宠物，记录成长，照顾日常，一起发现友好去处。'], 'pet_reminder_template' => ['订阅模板ID', ''], 'pet_reminder_fields' => ['模板字段映射JSON', '{"thing1":"title","time2":"due_at"}'], 'pet_default_days' => ['提醒参考天数JSON', '{"bath":7,"internal":30,"external":30}'], 'pet_privacy' => ['隐私政策', ''], 'pet_agreement' => ['用户协议', '']];
            foreach ($defaults as $code => $item) {
                if (!Db::name('config_data')->where('code', $code)->count()) {
                    Db::name('config_data')->insert(['config_id' => 3, 'code' => $code, 'title' => $item[0], 'value' => $item[1], 'type' => 'textarea', 'options' => '', 'note' => '', 'status' => 1, 'mark' => 1]);
                }
            }
        });
        if (!defined('DB_PREFIX')) { define('DB_PREFIX', $prefix); }
        new \app\admin\model\ActionLog();
        $output->writeln('宠物业务结构、菜单和配置升级完成');
        return 0;
    }
}
