<?php


namespace app\admin\controller;

use app\admin\model\File as FileModel;
use app\admin\service\FileService;
use app\admin\service\PermissionGuardService;
use think\exception\HttpResponseException;

/**
 * 文件管理-控制器
 * @author admin
 * @since 2021/7/10
 * Class File
 * @package app\admin\controller
 */
class File extends Backend
{
    /**
     * 初始化
     * @author admin
     * @since 2021/7/10
     */
    protected function initialize()
    {
        parent::initialize();
        $permResult = (new PermissionGuardService())->check($this->userId);
        if ($permResult !== true) {
            throw new HttpResponseException(response(message($permResult, false, [], 403), 403, [], 'json'));
        }
        $this->model = new FileModel();
        $this->service = new FileService();
    }

    /**
     * 创建文件夹
     * @return mixed
     * @since 2021/7/10
     * @author admin
     */
    public function saveDir()
    {
        $result = $this->service->saveDir();
        // Service 返回数组表示成功，返回字符串表示失败
        if (is_string($result)) {
            return message($result, false, [], 1);
        }
        return message('创建文件夹成功', true, $result, 0);
    }

    /**
     * 上传文件
     * @return mixed
     * @since 2021/7/10
     * @author admin
     */
    public function uploadFile()
    {
        // 参数
        $param = request()->param();
        // 目录文件夹名称
        $directoryId = getter($param, 'directoryId', 0);

        // 错误提示语
        $error = "";
        // 上传文件（使用规范的上传函数）
        $result = upload_file('file', '', $error);
        if (!$result) {
            return message($error ?: "文件上传失败", false);
        }

        // 处理上传结果（upload_file 返回数组格式）
        $fileInfo = is_array($result) && isset($result[0]) ? $result[0] : $result;
        
        // 判断是否为图片
        $isImage = 2;
        if (isset($fileInfo['filepath'])) {
            $filepath = $fileInfo['filepath'];
            // 根据文件扩展名判断是否为图片
            $ext = strtolower(pathinfo($filepath, PATHINFO_EXTENSION));
            $imageExts = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
            if (in_array($ext, $imageExts)) {
                $isImage = 1;
            }
        }

        // 存储文件信息到数据库
        $data = [
            'name' => isset($fileInfo['name']) ? $fileInfo['name'] : '',
            'pid' => $directoryId,
            'length' => isset($fileInfo['size']) ? $fileInfo['size'] : 0,
            'url' => isset($fileInfo['filepath']) ? '/' . $fileInfo['filepath'] : '',
            'thumbnail' => isset($fileInfo['filepath']) ? '/' . $fileInfo['filepath'] : '',
            'directory' => 1,
            'type' => $isImage,
        ];
        $res = $this->model->edit($data);
        if (!$res) {
            return message("文件保存失败", false);
        }
        return message("上传成功", true);
    }

}
