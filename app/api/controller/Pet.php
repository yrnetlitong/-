<?php
namespace app\api\controller;

use app\common\service\PetInput;
use app\common\service\PetService;
use app\common\service\PetSession;
use app\common\service\ReminderService;
use think\facade\Db;

class Pet extends PetBase
{
    public function profile()
    {
        return $this->runAction(function () { return (new PetService())->profile($this->userId); });
    }

    public function saveProfile()
    {
        return $this->runAction(function () { return (new PetService())->saveProfile($this->userId, $this->request->post()); }, true);
    }

    public function logout()
    {
        return $this->runAction(function () { PetSession::logout((string)$this->request->header('Authorization')); return []; }, true);
    }

    public function pets()
    {
        return $this->runAction(function () { return PetService::paginate(Db::name('pet')->where('member_id', $this->userId), $this->request->get()); });
    }

    public function detail()
    {
        return $this->runAction(function () { return PetService::rows([PetService::owned('pet', (int)$this->request->get('id'), $this->userId)])[0]; });
    }

    public function save()
    {
        return $this->runAction(function () { return (new PetService())->savePet($this->userId, $this->request->post()); }, true);
    }

    public function remove()
    {
        return $this->runAction(function () { (new PetService())->deletePet($this->userId, (int)$this->request->post('id')); return []; }, true);
    }

    public function records()
    {
        return $this->runAction(function () {
            $input = $this->request->get();
            $q = Db::name('pet_record')->where('member_id', $this->userId);
            if (!empty($input['pet_id'])) { $q->where('pet_id', (int)$input['pet_id']); }
            if (!empty($input['type'])) { $q->where('type', PetInput::text($input, 'type', 12, true)); }
            return PetService::paginate($q, $input, 'occurred_at desc,id desc');
        });
    }

    public function record()
    {
        return $this->runAction(function () { return PetService::rows([PetService::owned('pet_record', (int)$this->request->get('id'), $this->userId)])[0]; });
    }

    public function saveRecord()
    {
        return $this->runAction(function () { return (new PetService())->saveRecord($this->userId, $this->request->post()); }, true);
    }

    public function removeRecord()
    {
        return $this->runAction(function () {
            $id = (int)$this->request->post('id');
            return Db::transaction(function () use ($id) {
                PetService::owned('pet_record', $id, $this->userId, true);
                Db::name('pet_record')->where('id', $id)->delete();
                PetService::audit($this->userId, '删除养护记录', ['id' => $id]);
                return [];
            });
        }, true);
    }

    public function reminders()
    {
        return $this->runAction(function () {
            $input = $this->request->get();
            $q = Db::name('pet_reminder')->alias('r')->leftJoin('pet p', 'p.id=r.pet_id')->where('r.member_id', $this->userId)->field('r.*,p.name as pet_name');
            if (!empty($input['pet_id'])) { $q->where('r.pet_id', (int)$input['pet_id']); }
            if (($input['status'] ?? '') === 'done') { $q->where('r.status', 1); }
            elseif (($input['status'] ?? '') === 'expired') { $q->where('r.status', 0)->where('r.due_at', '<', time()); }
            elseif (($input['status'] ?? '') === 'pending') { $q->where('r.status', 0)->where('r.due_at', '>=', time()); }
            return PetService::paginate($q, $input, 'r.due_at desc,r.id desc');
        });
    }

    public function reminder()
    {
        return $this->runAction(function () { return PetService::owned('pet_reminder', (int)$this->request->get('id'), $this->userId); });
    }

    public function saveReminder()
    {
        return $this->runAction(function () { return (new ReminderService())->save($this->userId, $this->request->post()); }, true);
    }

    public function reminderAction()
    {
        return $this->runAction(function () {
            $input = $this->request->post(); $id = (int)($input['id'] ?? 0);
            $action = PetInput::choice($input, 'action', ['complete', 'toggle', 'remove', 'subscribe']);
            if ($action === 'complete') { (new ReminderService())->complete($this->userId, $id); return []; }
            return Db::transaction(function () use ($id, $action) {
                $row = PetService::owned('pet_reminder', $id, $this->userId, true);
                $q = Db::name('pet_reminder')->where('id', $id);
                if ($action === 'remove') {
                    if ($row['next_id'] && Db::name('pet_reminder')->where('id', $row['next_id'])->count()) { throw new \InvalidArgumentException('请先删除本周期的后续提醒'); }
                    $q->delete();
                }
                elseif ($action === 'toggle') {
                    if ($row['status'] || $row['next_id']) { throw new \InvalidArgumentException('只能操作最新一期未完成提醒'); }
                    $q->update(['enabled' => $row['enabled'] ? 0 : 1, 'update_time' => time()]); }
                else {
                    if ($row['status'] || $row['sent_at'] || !$row['enabled']) { throw new \InvalidArgumentException('当前提醒不能订阅'); }
                    $q->update(['subscribed' => 1, 'update_time' => time()]); }
                PetService::audit($this->userId, '提醒操作', ['id' => $id, 'action' => $action]);
                return [];
            });
        }, true);
    }

    public function submissions()
    {
        return $this->runAction(function () { return PetService::paginate(Db::name('pet_place')->where('member_id', $this->userId), $this->request->get()); });
    }

    public function savePlace()
    {
        return $this->runAction(function () { return (new PetService())->savePlace($this->userId, $this->request->post()); }, true);
    }

    public function review()
    {
        return $this->runAction(function () {
            $input = $this->request->post(); $id = (int)($input['place_id'] ?? 0);
            if (!Db::name('pet_place')->where(['id' => $id, 'status' => 1])->count()) { throw new \InvalidArgumentException('点位不存在'); }
            $data = ['place_id' => $id, 'member_id' => $this->userId, 'rating' => PetInput::integer($input, 'rating', 1, 5), 'content' => PetInput::text($input, 'content', 1000, true), 'create_time' => time()];
            if (Db::name('pet_review')->where(['place_id' => $id, 'member_id' => $this->userId])->count()) { throw new \InvalidArgumentException('你已经评价过该点位'); }
            Db::name('pet_review')->insert($data);
            return [];
        }, true);
    }

    public function messages()
    {
        return $this->runAction(function () { return PetService::paginate(Db::name('notice')->where(['pet_member_id' => $this->userId, 'mark' => 1]), $this->request->get()); });
    }

    public function readMessage()
    {
        return $this->runAction(function () {
            Db::name('notice')->where(['id' => (int)$this->request->post('id'), 'pet_member_id' => $this->userId])->update(['pet_read_at' => time()]);
            return [];
        }, true);
    }
}
