<?php
namespace app\common\service;

use InvalidArgumentException;
use think\facade\Db;

class ReminderService
{
    public function save(int $member, array $input): array
    {
        $old = empty($input['id']) ? null : PetService::owned('pet_reminder', (int)$input['id'], $member);
        $type = $old && $old['type'] === ($input['type'] ?? '') ? ['code' => $old['type'], 'name' => $old['type_name']] : RecordTypes::selected($input);
        $data = ['type_name' => $type['name'], 'pet_id' => (int)($input['pet_id'] ?? 0), 'title' => PetInput::text($input, 'title', 80, true), 'type' => $type['code'], 'cycle' => PetInput::choice($input, 'cycle', ['once', 'daily', 'weekly', 'monthly', 'custom']), 'interval_days' => PetInput::integer($input, 'interval_days', 1, 3650), 'due_at' => PetInput::date($input, 'due_at', true), 'advance_days' => PetInput::integer($input, 'advance_days', 0, 365), 'enabled' => PetInput::integer($input, 'enabled', 0, 1), 'status' => 0, 'sent_at' => 0, 'push_status' => 'waiting', 'push_error' => '', 'update_time' => time()];
        if ($data['due_at'] - $data['advance_days'] * 86400 <= time()) {
            throw new InvalidArgumentException('提前提醒时间必须晚于当前时间');
        }
        return Db::transaction(function () use ($member, $input, $data) {
            PetService::owned('pet', $data['pet_id'], $member, true);
            $id = (int)($input['id'] ?? 0);
            if ($id) {
                $old = PetService::owned('pet_reminder', $id, $member, true);
                if ($old['status'] || $old['next_id']) { throw new InvalidArgumentException('请编辑当前最新一期提醒'); }
                Db::name('pet_reminder')->where('id', $id)->update($data);
            } else {
                $id = Db::name('pet_reminder')->insertGetId($data + ['member_id' => $member, 'create_time' => time()]);
                Db::name('pet_reminder')->where('id', $id)->update(['series_id' => $id]);
            }
            PetService::audit($member, '保存提醒规则', ['id' => $id, 'title' => $data['title'], 'due_at' => $data['due_at']]);
            return ['id' => $id];
        });
    }

    public static function nextDue(array $row): int
    {
        $time = (int)$row['due_at'];
        do {
            if ($row['cycle'] === 'monthly') {
                $next = new \DateTimeImmutable(date('Y-m-01 H:i:s', $time));
                $next = $next->modify('+1 month');
                $time = $next->setDate((int)$next->format('Y'), (int)$next->format('m'), min((int)($row['anchor_day'] ?? date('d', (int)$row['due_at'])), (int)$next->format('t')))->getTimestamp();
            } else {
                $days = ['daily' => 1, 'weekly' => 7, 'custom' => max(1, (int)$row['interval_days'])][$row['cycle']];
                $time += $days * 86400;
            }
        } while ($time <= time() + (int)$row['advance_days'] * 86400);
        return $time;
    }

    public function complete(int $member, int $id): void
    {
        Db::transaction(function () use ($member, $id) {
            $row = PetService::owned('pet_reminder', $id, $member, true);
            if ((int)$row['status'] === 1) {
                throw new InvalidArgumentException('该提醒已完成');
            }
            Db::name('pet_reminder')->where('id', $id)->update(['status' => 1, 'completed_at' => time(), 'update_time' => time()]);
            $this->scheduleNext($row);
            PetService::audit($member, '完成提醒', ['id' => $id]);
        });
    }

    private function scheduleNext(array $row): void
    {
        if ($row['cycle'] === 'once' || !$row['enabled'] || $row['next_id']) { return; }
        $id = $row['id'];
        unset($row['id']);
        $row['series_id'] = $row['series_id'] ?: $id;
        $origin = Db::name('pet_reminder')->where('id', $row['series_id'])->value('due_at');
        $row['due_at'] = self::nextDue($row + ['anchor_day' => (int)date('d', (int)($origin ?: $row['due_at']))]);
        $row['create_time'] = $row['update_time'] = time();
        $row['next_id'] = $row['sent_at'] = $row['completed_at'] = $row['status'] = $row['subscribed'] = 0;
        $row['push_status'] = 'waiting';
        $row['push_error'] = '';
        $next = Db::name('pet_reminder')->insertGetId($row);
        Db::name('pet_reminder')->where('id', $id)->update(['next_id' => $next]);
    }

    public function dispatch(): int
    {
        if (!defined('DB_PREFIX')) { define('DB_PREFIX', config('database.connections.mysql.prefix')); }
        new \app\admin\model\ActionLog();
        $settings = PetService::settings();
        $rows = Db::name('pet_reminder')->where(['enabled' => 1, 'status' => 0, 'sent_at' => 0])->whereRaw('due_at - advance_days * 86400 <= ?', [time()])->order('due_at')->limit(100)->select()->toArray();
        $count = 0;
        foreach ($rows as $row) {
            $claimed = Db::transaction(function () use ($row) {
                $current = Db::name('pet_reminder')->where('id', $row['id'])->lock(true)->find();
                if (!$current || $current['sent_at'] || $current['status'] || !$current['enabled']) {
                    return false;
                }
                Db::name('pet_reminder')->where('id', $row['id'])->update(['sent_at' => time(), 'push_status' => 'sending']);
                PetService::notify((int)$row['member_id'], $row['title'], '养护事项到期：' . date('Y-m-d H:i', $row['due_at']), 'reminder', (int)$row['pet_id']);
                return true;
            });
            if (!$claimed) {
                continue;
            }
            $state = 'in_app';
            $error = '';
            try {
                $member = Db::name('member')->where(['id' => $row['member_id'], 'status' => 1, 'mark' => 1])->find();
                if ($member && $row['subscribed'] && !empty($settings['pet_reminder_template'])) {
                    $mapping = json_decode($settings['pet_reminder_fields'] ?? '{}', true);
                    $data = [];
                    foreach ($mapping as $key => $field) {
                        $data[$key] = ['value' => $field === 'due_at' ? date('Y-m-d H:i', $row['due_at']) : mb_substr($row['title'], 0, 20)];
                    }
                    $wechat = new WechatService();
                    $wechat->call('cgi-bin/message/subscribe/send?access_token=' . urlencode($wechat->accessToken()), ['touser' => $member['openid'], 'template_id' => $settings['pet_reminder_template'], 'page' => 'pages/reminders/index', 'data' => $data], true);
                    $state = 'sent';
                }
            } catch (\Throwable $e) {
                $state = 'failed';
                $error = mb_substr($e->getMessage(), 0, 250);
            }
            Db::name('pet_reminder')->where('id', $row['id'])->update(['push_status' => $state, 'push_error' => $error, 'subscribed' => 0]);
            PetService::audit(0, '提醒推送结果', ['id' => $row['id'], 'result' => $state, 'error' => $error]);
            $count++;
        }
        $due = Db::name('pet_reminder')->where(['enabled' => 1, 'status' => 0, 'next_id' => 0])->where('cycle', '<>', 'once')->where('due_at', '<=', time())->limit(100)->select()->toArray();
        foreach ($due as $item) {
            Db::transaction(function () use ($item) {
                $row = Db::name('pet_reminder')->where('id', $item['id'])->lock(true)->find();
                if ($row && !$row['status']) { $this->scheduleNext($row); }
            });
        }
        return $count;
    }
}
