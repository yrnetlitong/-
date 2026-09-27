<?php
namespace app\admin\service;

use think\facade\Db;

/** 项目菜单迁移：复用原菜单 ID，角色授权随父级调整。 */
class PetMenuService
{
    public static function sync(): void
    {
        if (Db::name('config_data')->where('code', 'pet_menu_revision')->value('value') === '20260924') { return; }
        $groups = [
            '/system' => ['系统管理', 'el-icon-setting', ['/system/user' => '用户管理', '/system/role' => '角色管理', '/system/menu' => '菜单管理', '/system/loginlog' => '登录日志', '/system/operlog' => '操作日志']],
            '/pet-users' => ['用户信息', 'el-icon-user', ['/petknow/members' => '注册用户', '/petknow/pets' => '宠物档案']],
            '/pet-records' => ['记录管理', 'el-icon-notebook-2', ['/petknow/recordtypes' => '记录类型', '/petknow/records' => '养护记录', '/petknow/reminders' => '提醒与推送']],
            '/pet-places' => ['友好点位', 'el-icon-location', ['/petknow/placetypes' => '点位类型', '/petknow/places' => '友好点位']],
        ];
        $buttons = [
            'user' => ['view'=>'查询用户','add'=>'添加用户','edit'=>'修改用户','delete'=>'删除用户','dall'=>'批量删除','status'=>'启用/停用','resetPwd'=>'重置密码'],
            'role' => ['view'=>'查询角色','add'=>'添加角色','edit'=>'修改角色','delete'=>'删除角色','dall'=>'批量删除','status'=>'启用/停用','permission'=>'分配权限'],
            'menu' => ['view'=>'查询菜单','add'=>'添加菜单','addz'=>'添加子级','edit'=>'修改菜单','delete'=>'删除菜单','status'=>'启用/停用'],
            'loginlog' => ['view'=>'查询登录日志','detail'=>'详情','delete'=>'删除','export'=>'导出'],
            'operlog' => ['view'=>'查询操作日志','detail'=>'详情','export'=>'导出'],
            'members' => ['view'=>'查询','detail'=>'详情','export'=>'导出','edit'=>'启用/停用'],
            'pets' => ['view'=>'查询','detail'=>'详情','export'=>'导出','edit'=>'异常清理'],
            'records' => ['view'=>'查询','detail'=>'详情','export'=>'导出','edit'=>'删除'],
            'reminders' => ['view'=>'查询','detail'=>'详情','export'=>'导出'],
            'recordtypes' => ['view'=>'查询','edit'=>'新增/编辑','status'=>'启用/停用','remove'=>'删除'],
            'placetypes' => ['view'=>'查询','edit'=>'新增/编辑','status'=>'启用/停用','remove'=>'删除'],
            'places' => ['view'=>'查询','detail'=>'详情','export'=>'导出','edit'=>'新增/编辑与地图选点','approve'=>'审核通过','reject'=>'驳回','status'=>'上架/下架','top'=>'置顶/取消置顶'],
        ];
        $keep = []; $sort = 0;
        // 历史数据里的授权标识与页面不一致，改名时保留 ID 和既有授权。
        Db::name('menu')->where(['permission'=>'sys:role:auth','type'=>1])->update(['permission'=>'sys:role:permission']);
        foreach ($groups as $path => [$title, $icon, $pages]) {
            $parent = self::menu(['path'=>$path,'type'=>0], ['pid'=>0,'title'=>$title,'icon'=>$icon,'component'=>'','permission'=>'','sort'=>++$sort]);
            $keep[] = $parent; $pageSort = 0;
            foreach ($pages as $page => $name) {
                $key = basename($page); $prefix = strpos($page, '/system/') === 0 ? 'sys:' : 'pet:';
                $id = self::menu(['path'=>$page,'type'=>0], ['pid'=>$parent,'title'=>$name,'component'=>$page . ($prefix === 'sys:' ? '/index' : ''),'permission'=>$prefix.$key.':view','sort'=>++$pageSort]);
                $keep[] = $id; $buttonSort = 0;
                foreach ($buttons[$key] as $action => $label) {
                    $permission = $prefix.$key.':'.$action;
                    $old = Db::name('menu')->where(['permission'=>$permission,'type'=>1])->find();
                    $endpoint = '';
                    if ($prefix === 'sys:') {
                        $controller = $key === 'operlog' ? 'actionlog' : $key;
                        $method = ['view'=>'index','add'=>'edit','addz'=>'edit','dall'=>'delete','detail'=>'info','permission'=>'savepermission'][$action] ?? strtolower($action);
                        $endpoint = '/'.$controller.'/'.$method;
                    }
                    $button = self::menu(['permission'=>$permission,'type'=>1], ['pid'=>$id,'title'=>$label,'path'=>$endpoint,'component'=>'','sort'=>++$buttonSort]);
                    $keep[] = $button;
                    // 新拆分的操作继承原查询/操作权限，不扩大历史角色能力。
                    if (!$old && $prefix === 'pet:') {
                        $source = in_array($action, ['detail','export'], true) ? 'view' : 'edit';
                        $sourceId = Db::name('menu')->where(['permission'=>$prefix.$key.':'.$source,'type'=>1])->value('id');
                        if ($sourceId && $sourceId !== $button) {
                            foreach (Db::name('role_menu')->where('menu_id', $sourceId)->column('role_id') as $role) { self::grant($role, $button); }
                        }
                    }
                }
                foreach (Db::name('role_menu')->where('menu_id', $id)->column('role_id') as $role) { self::grant($role, $parent); }
            }
        }
        // 退役模板入口及旧按钮，不删除业务表、配置和角色。
        $obsolete = Db::name('menu')->whereNotIn('id', $keep)->where('path', '<>', '/user/profile')->column('id');
        if ($obsolete) { Db::name('menu')->whereIn('id', $obsolete)->update(['mark'=>0,'status'=>2,'hide'=>1]); }
        $revision = Db::name('config_data')->where('code', 'pet_menu_revision')->value('id');
        if ($revision) { Db::name('config_data')->where('id', $revision)->update(['value'=>'20260924']); }
        else { Db::name('config_data')->insert(['config_id'=>3,'code'=>'pet_menu_revision','title'=>'后台菜单迁移版本','value'=>'20260924','type'=>'text','options'=>'','note'=>'','status'=>1,'mark'=>1]); }
    }

    private static function menu(array $match, array $data): int
    {
        $id = (int)Db::name('menu')->where($match)->value('id');
        $data += ['hide'=>0,'status'=>1,'mark'=>1];
        if ($id) { Db::name('menu')->where('id', $id)->update($data); }
        else { $id = Db::name('menu')->insertGetId($data + $match); }
        return $id;
    }

    private static function grant(int $role, int $menu): void
    {
        if (!Db::name('role_menu')->where(['role_id'=>$role,'menu_id'=>$menu])->count()) {
            Db::name('role_menu')->insert(['role_id'=>$role,'menu_id'=>$menu]);
        }
    }
}
