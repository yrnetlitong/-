<?php


namespace app\admin\controller;

use app\admin\service\DictDataService;
use app\admin\service\PermissionGuardService;
use think\exception\HttpResponseException;

/**
 * 字典数据管理-控制器
 * @author admin
 * @since 2020/11/15
 * Class Dict
 * @package app\admin\controller
 */
class Dictdata extends Backend
{
    /**
     * 初始化
     * @author admin
     * @since 2020/11/15
     */
    protected function initialize()
    {
        parent::initialize();
        $permResult = (new PermissionGuardService())->check($this->userId);
        if ($permResult !== true) {
            throw new HttpResponseException(response(message($permResult, false, [], 403), 403, [], 'json'));
        }
        $this->service = new DictDataService();
    }

    /**
     * 根据Code获取字典信息
     * @return mixed
     * @since 2021/7/5
     * @author admin
     */
    public function getDictByCode()
    {
        $result = $this->service->getDictByCode();
        // Service 返回数组表示成功，返回字符串表示失败
        if (is_string($result)) {
            return message($result, false, [], 1);
        }
        return message('操作成功', true, $result, 0);
    }

}
