<?php


namespace app\admin\controller;

use app\admin\service\PermissionGuardService;
use think\exception\HttpResponseException;
/**
 * 上传文件
 * @author admin
 * @since 2020/11/14
 * Class Upload
 * @package app\admin\controller
 */
class Upload extends Backend
{
    /**
     * 初始化
     */
    protected function initialize()
    {
        parent::initialize();
        $permResult = (new PermissionGuardService())->check($this->userId);
        if ($permResult !== true) {
            throw new HttpResponseException(response(message($permResult, false, [], 403), 403, [], 'json'));
        }
    }

    /**
     * 上传图片（支持多图片上传）
     * 备注：1、单文件：file
     *      2、多文件：file[],file[]
     *
     * @author admin
     * @since 2020-04-21
     */
    public function uploadImage()
    {
        // 错误提示语
        $error = "";
        // 上传图片
        $result = upload_image('file', '', $error);
        if (!$result) {
            return message($error, false);
        }
        // 结果处理
        $list = [];
        foreach ($result as $key => $value) {
            if (is_array($value)) {
                // 二维数组(多图上传)
                foreach ($result as $val) {
                    $list[] = IMG_URL . $val['filepath'];
                }
            } else {
                // 一维数组(单图上传)
                $list = IMG_URL . $result['filepath'];
            }
        }
        return message("上传成功", true, $list);
    }

    /**
     * 上传文件(支持多文件上传)
     * 备注：1、单文件：file
     *      2、多文件：file[],file[]
     *
     * @author admin
     * @since 2020-04-21
     */
    public function uploadFile()
    {
        $error = "";
        // 上传文件(非图片)
        $result = upload_file('file', '', $error);
        if (!$result) {
            return message($error);
        }
        return message("上传成功", true, $result);
    }
}
