<?php


namespace app\admin\controller;
use Jwt;
use app\admin\middleware\CheckLogin;
use app\BaseController;

/**
 * 后台-控制器
 * @author admin
 * @since 2020/11/14
 * Class Backend
 * @package app\admin\controller
 */
class Backend extends BaseController
{
    // 模型
    protected $model;
    // 服务
    protected $service;
    // 用户ID
    protected $userId;
    // 登录信息
    protected $userInfo;
    // 中间件
    protected $middleware = [
        CheckLogin::class
    ];

    /**
     * 初始化
     * @author admin
     * @since 2020/11/14
     */
    protected function initialize()
    {
        parent::initialize();

        // 获取Token
        $token = request()->header("Authorization");
        if ($token && strpos($token, 'Bearer ') !== false) {
            $token = str_replace("Bearer ", '', $token);
            // JWT解密token
            $jwt = new Jwt();
            $this->userId = $jwt->verifyToken($token);
        }

        // 初始化配置
        $this->initConfig();
    }

    /**
     * 初始化配置
     * @author admin
     * @since 2020/11/14
     */
    public function initConfig()
    {
        // 定义是否GET请求
        defined('IS_GET') or define('IS_GET', $this->request->isGet());

        // 定义是否POST请求
        defined('IS_POST') or define('IS_POST', $this->request->isPost());

        // 定义是否AJAX请求
        defined('IS_AJAX') or define('IS_AJAX', $this->request->isAjax());

        // 定义是否PAJAX请求
        defined('IS_PJAX') or define('IS_PJAX', $this->request->isPjax());

        // 定义是否PUT请求
        defined('IS_PUT') or define('IS_PUT', $this->request->isPut());

        // 定义是否DELETE请求
        defined('IS_DELETE') or define('IS_DELETE', $this->request->isDelete());

        // 定义是否HEAD请求
        defined('IS_HEAD') or define('IS_HEAD', $this->request->isHead());

        // 定义是否PATCH请求
        defined('IS_PATCH') or define('IS_PATCH', $this->request->isPatch());

        // 定义是否为手机访问
        defined('IS_MOBILE') or define('IS_MOBILE', $this->request->isMobile());

        // 定义是否为cli
        defined('IS_CLI') or define('IS_CLI', $this->request->isCli());

        // 定义是否为cgi
        defined('IS_CGI') or define('IS_CGI', $this->request->isCgi());

        // 分页参数，限制单页数量以避免异常请求拖垮列表接口
        $page = max(1, (int)getter(request()->param(), "page", 1));
        $perPage = max(1, min(100, (int)getter(request()->param(), "limit", 20)));
        defined('PAGE') or define('PAGE', $page);
        defined('PERPAGE') or define('PERPAGE', $perPage);

    }

    /**
     * 获取数据列表
     * @return mixed
     * @since 2020/11/11
     * @author admin
     */
    public function index()
    {
        $result = $this->service->getList();
        // Service 返回数组数据（['list' => [], 'total' => 0] 格式）
        return message("操作成功", true, $result, 0);
    }

    /**
     * 获取数据详情
     * @return mixed
     * @since 2020/11/11
     * @author admin
     */
    public function info()
    {
        $result = $this->service->info();
        // Service 返回数组表示成功，返回 false 表示失败
        if ($result === false) {
            return message("数据不存在", false, [], 1);
        }
        return message("操作成功", true, $result, 0);
    }

    /**
     * 添加或编辑
     * @return mixed
     * @since 2020/11/11
     * @author admin
     */
    public function edit()
    {
        $result = $this->service->edit();
        // Service 返回数组表示成功，返回字符串表示失败
        if (is_string($result)) {
            return message($result, false, [], 1);
        }
        return message("操作成功", true, $result, 0);
    }

    /**
     * 删除数据
     * @return mixed
     * @since 2020/11/11
     * @author admin
     */
    public function delete()
    {
        $result = $this->service->delete();
        // Service 返回数组表示成功，返回字符串表示失败
        if (is_string($result)) {
            return message($result, false, [], 1);
        }
        return message("删除成功", true, $result, 0);
    }

    /**
     * 设置状态
     * @return mixed
     * @since 2020/11/21
     * @author admin
     */
    public function status()
    {
        $result = $this->service->status();
        // Service 返回数组表示成功，返回字符串表示失败
        if (is_string($result)) {
            return message($result, false, [], 1);
        }
        return message("操作成功", true, $result, 0);
    }

}
