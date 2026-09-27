<?php
namespace app\api\controller;

class Upload extends PetBase
{
    public function uploadImage()
    {
        return $this->runAction(function () {
            $file = request()->file('file');
            if (!$file || is_array($file) || !@getimagesize($file->getPathname())) {
                throw new \InvalidArgumentException('请选择有效的图片');
            }
            $error = '';
            $result = upload_image('file', 'petknow', $error);
            if (!$result) { throw new \InvalidArgumentException($error ?: '上传失败'); }
            return rtrim((string)env('domain.img_url'), '/') . $result['filepath'];
        }, true);
    }
}
