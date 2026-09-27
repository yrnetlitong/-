<?php


namespace app\admin\service;

use app\admin\model\ActionLog;
use app\admin\model\User;
use Carbon\Carbon;
use Ramsey\Uuid\Uuid;
use Verify;
use Jwt;
use think\facade\Cache;

/**
 * 登录-服务类
 * @author admin
 * @since 2020/11/14
 * Class LoginService
 * @package app\admin\service
 */
class LoginService extends BaseService
{
    /**
     * 构造函数
     * @author admin
     * @since 2020/11/14
     * LoginService constructor.
     */
    public function __construct()
    {
        $this->model = new User();
    }

    /**
     * 获取验证码
     * @return array
     * @since 2020/11/14
     * @author admin
     */
    public function captcha()
    {
        // 生成会话标识并绑定验证码
        $key = get_guid_v4();
        // 生成图片验证码（纯数字、无干扰，降低误识别）
        $verify = new Verify([
            'length' => 4,
            'codeSet' => '0123456789',
            'useCurve' => false,
            'useNoise' => false,
        ]);
        // 验证码图片
        $img = $verify->entry($key);
        // cache 兜底（防止线上会话偶发丢失）
        Cache::set('login_captcha_' . $key, strtoupper($verify->getCode()), 10 * 60);

        // 返回结果（只返回数组，不返回 message() 格式）
        return [
            'key' => $key,
            'captcha' => "data:image/png;base64," . base64_encode($img)
        ];
    }

    /**
     * 登录系统
     * @return array
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @since 2020/11/15
     * @author admin
     */
    public function login()
    {
        // 请求参数
        $param = request()->param();
        // 登录账号
        $username = trim(getter($param, 'username', ''));
        if (!$username) {
            return '登录账号不能为空';
        }
        // 登录密码
        $password = trim(getter($param, 'password', ''));
        if (!$password) {
            return '登录密码不能为空';
        }
        // 验证码校验
        $key = trim(getter($param, 'key', ''));
        // 验证码
        $captcha = trim(getter($param, 'captcha', ''));
        if (!$key) {
            return '验证码已失效，请刷新后重试';
        }
        $verify = new Verify([
            'codeSet' => '0123456789',
            'useCurve' => false,
            'useNoise' => false,
        ]);
        $captcha = strtoupper($captcha);
        $sessionPass = $verify->check($captcha, $key);
        $cacheCode = strtoupper((string)Cache::get('login_captcha_' . $key, ''));
        $cachePass = $cacheCode !== '' && $captcha === $cacheCode;
        if (!$sessionPass && !$cachePass) {
            return '验证码错误或已过期';
        }
        // 校验通过后立即失效（单次使用）
        Cache::delete('login_captcha_' . $key);

        // 用户验证
        $info = $this->model->getOne([
            ['username', '=', $username],
        ]);
        if (!$info) {
            return '登录账号不存在';
        }
        // 密码校验
        $password = get_password($password . $username);
        if ($password != $info['password']) {
            return '登录密码不正确';
        }
        // 使用状态校验
        if ($info['status'] != 1) {
            return '帐号已被禁用';
        }

        // 设置日志标题
        ActionLog::setTitle("登录系统");

        // JWT生成token
        $jwt = new Jwt();
        $token = $jwt->getToken($info['id']);
        $expiresIn = 7 * 24 * 60 * 60;

        // 结果返回（只返回数组，不返回 message() 格式）
        return [
            'access_token' => $token,
            'expires_in' => $expiresIn,
            'expires_at' => time() + $expiresIn,
        ];
    }

    /**
     * 注销系统
     * @return array
     * @since 2020/11/12
     * @author admin
     */
    public function logout()
    {
//        // 清空SESSION值
//        session()->put("userId", null);
        // 记录退出日志
        ActionLog::setTitle("注销系统");
        // 创建退出日志
        ActionLog::record();
        // 返回成功标识（只返回数组，不返回 message() 格式）
        return true;
    }

}
