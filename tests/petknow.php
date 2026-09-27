<?php
require dirname(__DIR__) . '/vendor/autoload.php';
$app = new \think\App(dirname(__DIR__));
$app->initialize();
use app\common\service\PetService;
use app\common\service\PetInput;
use app\common\service\ReminderService;
use app\admin\service\PetknowService;
use think\facade\Db;

function check($condition, string $message): void {
    if (!$condition) { throw new RuntimeException($message); }
}
function rejects(callable $callback, string $message): void {
    try { $callback(); } catch (InvalidArgumentException $e) { return; }
    throw new RuntimeException($message);
}
if (!in_array(config('database.connections.mysql.hostname'), ['127.0.0.1', 'localhost'], true)) {
    throw new RuntimeException('业务测试仅允许本地数据库');
}
if (!defined('DB_PREFIX')) { define('DB_PREFIX', config('database.connections.mysql.prefix')); }
new \app\admin\model\ActionLog();
$masked = (new \app\admin\model\ActionLog())->formatInfo(['param'=>'{"password":"private","nested":{"token":"private","name":"keep"}}','url'=>'/login?password=private']);
check(strpos($masked['param'], 'private') === false && strpos($masked['url'], 'private') === false && strpos($masked['param'], 'keep') !== false, '日志敏感参数未脱敏');

Db::startTrans();
try {
    $service = new PetService(); $admin = new PetknowService(); $reminders = new ReminderService();
    $member = Db::name('member')->insertGetId(['username' => 'test_' . bin2hex(random_bytes(8)), 'nickname' => '测试用户', 'create_time' => time()]);
    $other = Db::name('member')->insertGetId(['username' => 'test_' . bin2hex(random_bytes(8)), 'nickname' => '其他用户', 'create_time' => time()]);
    $pet = $service->savePet($member, ['name' => '测试猫咪', 'type' => 'cat', 'gender' => 'unknown', 'neutered' => 'no', 'weight' => 3.5, 'images' => []]);
    rejects(function () use ($pet, $other) { PetService::owned('pet', $pet['id'], $other); }, '跨用户读取未被拒绝');
    rejects(function () { PetInput::date(['d' => '2025-02-30 10:00:00'], 'd'); }, '错误日期未被拒绝');
    rejects(function () { PetInput::images(['images' => ['wxfile://tmp.png']]); }, '临时图片路径未被拒绝');
    $record = $service->saveRecord($member, ['pet_id' => $pet['id'], 'type' => 'feed', 'occurred_at' => date('Y-m-d H:i:s', time() - 60), 'product' => '猫粮', 'amount' => '20g']);
    rejects(function () use ($service, $pet, $other) { $service->saveRecord($other, ['pet_id' => $pet['id'], 'type' => 'feed', 'occurred_at' => date('Y-m-d H:i:s', time() - 60), 'product' => '猫粮']); }, '跨用户添加记录未被拒绝');
    $definition = ['module' => 'recordtypes', 'action' => 'save', 'name' => '测试动态类型', 'status' => 1, 'sort' => 10, 'fields' => [['key' => 'food', 'label' => '食物内容', 'kind' => 'text', 'required' => 1], ['key' => 'quantity', 'label' => '喂食量', 'kind' => 'number', 'required' => 1]]];
    $typeId = $admin->operate('recordtypes', 1, $definition)['id'];
    $type = Db::name('dict_data')->where('id', $typeId)->find();
    $dynamic = ['pet_id' => $pet['id'], 'type' => $type['code'], 'occurred_at' => date('Y-m-d H:i:s', time() - 60), 'values' => ['food' => '鸡肉', 'quantity' => '30']];
    $dynamicId = $service->saveRecord($member, $dynamic)['id'];
    $recordRows = $admin->listing('records', ['member_id'=>$member])['list'];
    check($recordRows[0]['pet_name'] === '测试猫咪' && $recordRows[0]['pet_type'] === 'cat', '养护列表缺少关联宠物');
    check(!array_key_exists('field_values', $recordRows[0]) && !array_key_exists('product', $recordRows[0]), '养护列表不应包含填报字段');
    $recordDetail = $admin->detail('records', $dynamicId, []);
    check($recordDetail['pet']['id'] == $pet['id'] && $recordDetail['item']['field_values'][0]['value'] === '鸡肉', '记录详情缺少宠物或填报内容');
    check($admin->listing('records', ['keyword'=>'测试猫咪'])['total'] >= 2, '按宠物名搜索失败');

    foreach ([['food' => '鸡肉'], ['food' => '鸡肉', 'quantity' => 'abc'], ['food' => [], 'quantity' => '30']] as $bad) {
        rejects(function () use ($service, $member, $dynamic, $bad) { $service->saveRecord($member, array_merge($dynamic, ['values' => $bad])); }, '动态字段非法内容未拒绝');
    }
    $definition['id'] = $typeId; $definition['name'] = '测试修改类型'; $definition['fields'][0]['label'] = '新字段名称';
    $admin->operate('recordtypes', 1, $definition);
    $snapshot = PetService::rows([Db::name('pet_record')->where('id', $dynamicId)->find()])[0];
    check($snapshot['type_name'] === '测试动态类型' && $snapshot['field_values'][0]['label'] === '食物内容' && $snapshot['field_values'][1]['value'] === '30', '修改配置破坏历史快照');
    $dynamicReminder = ['pet_id' => $pet['id'], 'title' => '动态提醒', 'type' => $type['code'], 'cycle' => 'once', 'interval_days' => 1, 'advance_days' => 0, 'enabled' => 1, 'due_at' => date('Y-m-d H:i:s', time() + 3600)];
    $reminderId = $reminders->save($member, $dynamicReminder)['id'];
    check(Db::name('pet_reminder')->where('id', $reminderId)->value('type_name') === '测试修改类型', '提醒没有使用同一类型');
    rejects(function () use ($admin, $typeId) { $admin->operate('recordtypes', 1, ['id' => $typeId, 'action' => 'remove']); }, '引用中类型允许删除');
    $admin->operate('recordtypes', 1, ['id' => $typeId, 'action' => 'status']);
    rejects(function () use ($service, $member, $dynamic) { $service->saveRecord($member, $dynamic); }, '停用类型允许新增记录');
    rejects(function () use ($reminders, $member, $dynamicReminder) { $reminders->save($member, $dynamicReminder); }, '停用类型允许新增提醒');
    $reminders->save($member, $dynamicReminder + ['id' => $reminderId]);
    check(count($admin->detail('members', $member, [])['pets']['list'][0]) >= 16, '关联宠物字段不完整');
    $duplicate = $definition; $duplicate['fields'][] = $duplicate['fields'][0];
    rejects(function () use ($admin, $duplicate) { $admin->operate('recordtypes', 1, $duplicate); }, '重复字段未拒绝');
    $empty = $definition; $empty['fields'] = [];
    rejects(function () use ($admin, $empty) { $admin->operate('recordtypes', 1, $empty); }, '空字段未拒绝');
    $admin->operate('records', 1, ['action'=>'remove','id'=>$dynamicId,'reason'=>'验收删除']);
    check(!Db::name('pet_record')->where('id', $dynamicId)->count(), '记录删除未生效');
    Db::name('pet_reminder')->where('id', $reminderId)->delete();
    $admin->operate('recordtypes', 1, ['id' => $typeId, 'action' => 'remove']);
    $reminder = $reminders->save($member, ['pet_id' => $pet['id'], 'title' => '吃饭', 'type' => 'feed', 'cycle' => 'daily', 'interval_days' => 1, 'advance_days' => 0, 'enabled' => 1, 'due_at' => date('Y-m-d H:i:s', time() + 3600)]);
    $reminders->complete($member, $reminder['id']);
    rejects(function () use ($reminders, $member, $reminder) { $reminders->complete($member, $reminder['id']); }, '重复完成未被拒绝');
    check(Db::name('pet_reminder')->where(['member_id' => $member, 'status' => 0])->count() === 1, '周期提醒未正确生成');
    // 月末经过短月后，仍使用原始日期，避免 31 日永久漂移到 28 日。
    $leapYear = (int)date('Y') + 1;
    while (!checkdate(2, 29, $leapYear)) { $leapYear++; }
    rejects(function () { PetInput::integer(['days' => 1.5], 'days', 1, 3650); }, '周期天数不得接受小数');
    $monthly = $reminders->save($member, ['pet_id' => $pet['id'], 'title' => '月末提醒', 'type' => 'bath', 'cycle' => 'monthly', 'interval_days' => 1, 'advance_days' => 0, 'enabled' => 1, 'due_at' => $leapYear . '-01-31 09:00:00']);
    $reminders->complete($member, $monthly['id']);
    $feb = Db::name('pet_reminder')->where('id', Db::name('pet_reminder')->where('id', $monthly['id'])->value('next_id'))->find();
    check(date('Y-m-d', $feb['due_at']) === $leapYear . '-02-29', '月末必须兼容闰年');
    $reminders->complete($member, $feb['id']);
    $march = Db::name('pet_reminder')->where('id', Db::name('pet_reminder')->where('id', $feb['id'])->value('next_id'))->find();
    check(date('Y-m-d', $march['due_at']) === $leapYear . '-03-31', '短月后应恢复原始月末日期');
    foreach (['once', 'weekly', 'custom'] as $cycle) {
        $entry = $reminders->save($member, ['pet_id' => $pet['id'], 'title' => $cycle, 'type' => 'custom', 'cycle' => $cycle, 'interval_days' => 3, 'advance_days' => 0, 'enabled' => 1, 'due_at' => date('Y-m-d H:i:s', time() + 86400)]);
        $reminders->complete($member, $entry['id']);
        $row = Db::name('pet_reminder')->where('id', $entry['id'])->find();
        if ($cycle === 'once') { check(!$row['next_id'], '单次提醒不能生成后续'); }
        else {
            $next = Db::name('pet_reminder')->where('id', $row['next_id'])->find();
            check($next['due_at'] - $row['due_at'] === ($cycle === 'weekly' ? 7 : 3) * 86400, '周期计算错误');
        }
    }
    $placeTypeId = $admin->operate('placetypes', 1, ['action' => 'save', 'name' => '验收点位类型', 'sort' => 9, 'status' => 1])['id'];
    $placeCode = Db::name('dict_data')->where('id', $placeTypeId)->value('code');
    check(isset(\app\common\service\PlaceTypes::labels(true)[$placeCode]), '新点位类型未提供给小程序');
    $pointInput = ['name' => '验收点位', 'category' => $placeCode, 'address' => '验收地址', 'latitude' => 31, 'longitude' => 121, 'rules' => '验收规则', 'images' => []];
    $pointId = $admin->operate('places', 1, $pointInput + ['action' => 'save'])['id'];
    check($service->placeDetail($pointId)['category_name'] === '验收点位类型', '点位类型名称未联动');
    foreach ([0, $member] as $viewer) {
        check(!array_intersect(['note', 'rejection', 'review_user', 'member_id'], array_keys($service->placeDetail($pointId, $viewer))), '官方点位向访客泄露内部字段');
    }
    rejects(function () use ($admin, $placeTypeId) { $admin->operate('placetypes', 1, ['id' => $placeTypeId, 'action' => 'remove']); }, '引用中点位类型可被删除');
    $admin->operate('placetypes', 1, ['id' => $placeTypeId, 'action' => 'status']);
    check(!isset(\app\common\service\PlaceTypes::labels(true)[$placeCode]), '停用点位类型仍可选择');
    rejects(function () use ($admin, $pointInput) { $admin->operate('places', 1, $pointInput + ['action' => 'save']); }, '停用点位类型允许新增');
    $admin->operate('places', 1, $pointInput + ['action' => 'save', 'id' => $pointId]);
    Db::name('pet_place')->where('id', $pointId)->delete();
    $admin->operate('placetypes', 1, ['id' => $placeTypeId, 'action' => 'remove']);
    $place = $service->savePlace($member, ['name' => '测试公园', 'category' => 'park', 'address' => '测试地址', 'latitude' => 31, 'longitude' => 121, 'rules' => '牵绳', 'images' => []]);
    rejects(function () use ($service, $place) { $service->placeDetail($place['id']); }, '未审核点位被公开');
    $admin->operate('places', 1, ['id' => $place['id'], 'action' => 'reject', 'reason' => '补充说明']);
    $service->savePlace($member, ['id' => $place['id'], 'name' => '测试公园', 'category' => 'park', 'address' => '测试地址', 'latitude' => 31, 'longitude' => 121, 'rules' => '请牵绳，清理排泄物', 'images' => []]);
    $admin->operate('places', 1, ['id' => $place['id'], 'action' => 'approve']);
    rejects(function () use ($admin, $place) { $admin->operate('places', 1, ['id' => $place['id'], 'action' => 'approve']); }, '重复审核未被拒绝');
    check($service->placeDetail($place['id'])['status'] === 1, '已审核点位未公开');
    check(!isset($service->placeDetail($place['id'])['note']), '内部投稿备注泄露');
    foreach (array_keys(PetknowService::TABLES) as $module) { check(isset($admin->listing($module, [])['list']), '后台列表异常：' . $module); }
    check(isset($admin->overview()['counts']), '统计异常');
    $service->deletePet($member, $pet['id']);
    check(!Db::name('pet_record')->where('id', $record['id'])->count(), '删除宠物后残留记录');
    check(!Db::name('pet_reminder')->where('pet_id', $pet['id'])->count(), '删除宠物后残留提醒');
    echo "通过：归属隔离、字段校验、记录、周期提醒、重复操作、投稿审核、私密字段、后台查询和级联清理\n";
} finally {
    Db::rollback();
}
