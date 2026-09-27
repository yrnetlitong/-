<?php
namespace app\admin\controller;

use app\admin\service\MenuService;
use app\admin\service\PetknowService;
use app\common\service\PetService;
use think\exception\HttpResponseException;

class Petknow extends Backend
{
    protected function initialize()
    {
        parent::initialize();
        $action = strtolower($this->request->action());
        $write = in_array($action, ['operate', 'settings'], true);
        if ($write ? !$this->request->isPost() : !$this->request->isGet()) {
            throw new HttpResponseException(message('请求方法无效', false, [], 405)->code(405));
        }
        $module = (string)($write ? $this->request->post('module', '') : $this->request->get('module', 'overview'));
        if (!defined('DB_PREFIX')) { define('DB_PREFIX', config('database.connections.mysql.prefix')); }
        new \app\admin\model\ActionLog();
        if (!in_array($module, array_merge(array_keys(PetknowService::TABLES), ['overview', 'settings']), true)) {
            throw new HttpResponseException(message('模块无效', false, [], 422)->code(422));
        }
        $action = strtolower($this->request->action());
        if (!in_array($action, ['index', 'detail', 'operate', 'settings', 'mapconfig'], true)) {
            throw new HttpResponseException(message('接口不存在', false, [], 404)->code(404));
        }
        $permissionAction = $action === 'detail' ? 'detail' : 'view';
        if ($action === 'index' && $this->request->get('export') === '1') { $permissionAction = 'export'; }
        if ($action === 'mapconfig' || $action === 'settings') { $permissionAction = 'edit'; }
        if ($action === 'operate') {
            $operation = (string)$this->request->post('action');
            $permissionAction = in_array($module, ['places','recordtypes','placetypes'], true) && $operation !== 'save' ? $operation : 'edit';
        }
        $permission = 'pet:' . $module . ':' . $permissionAction;
        if ((int)$this->userId !== 1 && !in_array($permission, (new MenuService())->getPermissionsList($this->userId), true)) {
            throw new HttpResponseException(message('无权限访问', false, [], 403)->code(403));
        }
        $this->service = new PetknowService();
    }

    private function respond(callable $callback)
    {
        try { return message('操作成功', true, $callback()); }
        catch (\InvalidArgumentException $e) { return message($e->getMessage(), false, [], 422); }
        catch (\Throwable $e) { \think\facade\Log::error('宠物后台：' . $e->getMessage()); return message('操作失败，请稍后重试', false, [], 500); }
    }

    public function index()
    {
        return $this->respond(function () {
            $module = (string)$this->request->get('module', 'overview');
            $types = array_column(\app\common\service\RecordTypes::all(), 'name', 'code');
            return ($module === 'settings' ? [] : ['record_types' => $types, 'categories' => \app\common\service\PlaceTypes::labels(), 'active_categories' => \app\common\service\PlaceTypes::labels(true)]) + ($module === 'overview' ? $this->service->overview() : ($module === 'settings' ? PetService::settings() : $this->service->listing($module, $this->request->get())));
        });
    }

    public function detail()
    {
        return $this->respond(function () {
            $module = (string)$this->request->get('module');
            if (!isset(PetknowService::TABLES[$module])) { throw new \InvalidArgumentException('模块无效'); }
            return $this->service->detail($module, (int)$this->request->get('id'), $this->request->get());
        });
    }

    public function operate()
    {
        if (!$this->request->isPost()) { return message('请使用POST请求', false, [], 405); }
        return $this->respond(function () {
            $module = (string)$this->request->post('module');
            if (!isset(PetknowService::TABLES[$module])) { throw new \InvalidArgumentException('模块无效'); }
            return $this->service->operate($module, (int)$this->userId, $this->request->post());
        });
    }

    public function mapconfig()
    {
        return $this->respond(function () {
            if ($this->request->get('module') !== 'places') { throw new \InvalidArgumentException('模块无效'); }
            return \app\common\service\AmapService::configuration((int)$this->userId);
        });
    }

    public function settings()
    {
        if (!$this->request->isPost() || $this->request->post('module') !== 'settings') { return message('请求无效', false, [], 405); }
        return $this->respond(function () { return $this->service->saveSettings((int)$this->userId, $this->request->post()); });
    }
}
