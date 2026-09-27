<?php


namespace app\admin\controller;

use app\admin\service\LoginService;

/**
 * 登录-控制器
 * @author admin
 * @since 2020/11/14
 * Class Login
 * @package app\admin\controller
 */
class Login extends Backend
{
    /**
     * 初始化
     * @author admin
     * @since 2020/11/14
     */
    protected function initialize()
    {
        parent::initialize();
        $this->service = new LoginService();
    }

    /**
     * 验证码
     * @return mixed
     * @since 2020/11/14
     * @author admin
     */
    public function captcha()
    {
        $result = $this->service->captcha();
        // Service 返回数组表示成功
        return message('操作成功', true, $result, 0);
    }

    /**
     * 登录
     * @return mixed
     * @since 2020/11/14
     * @author admin
     */
    public function login()
    {
        $result = $this->service->login();
        // Service 返回数组表示成功，返回字符串表示失败
        if (is_string($result)) {
            return message($result, false, [], 1);
        }
        return message('登录成功', true, $result, 0);
    }

    /**
     * 退出系统
     * @return mixed
     * @since 2020/11/14
     * @author admin
     */
    public function logout()
    {
        $result = $this->service->logout();
        // Service 返回 true 表示成功
        if ($result === true) {
            return message('退出成功', true, [], 0);
        }
        return message('退出失败', false, [], 1);
    }

}