<?php
/**
 * 公共控制器
 */

namespace app\api\controller;

use think\facade\Filesystem;

class Common extends Base
{
    /**
     * 上传图片
     * POST /api/upload/image
     */
    public function uploadImage()
    {
        $file = $this->request->file('file');
        $type = $this->request->param('type', 'post'); // avatar/post/track

        if (!$file) {
            return $this->error('请选择要上传的文件');
        }

        // 验证文件
        $allowedExt = config('app.upload.allowed_ext', ['jpg', 'jpeg', 'png', 'gif', 'webp']);
        $maxSize = config('app.upload.max_size', 5 * 1024 * 1024);

        try {
            validate(['file' => [
                'fileSize' => $maxSize,
                'fileExt' => implode(',', $allowedExt),
            ]])->check(['file' => $file]);
        } catch (\Exception $e) {
            return $this->error($e->getMessage());
        }

        try {
            // 保存文件
            $savePath = $type . '/' . date('Ymd');
            $fileName = Filesystem::disk('public')->putFile($savePath, $file);

            // 生成URL
            $domain = config('app.api_domain');
            $url = $domain . '/uploads/' . str_replace('\\', '/', $fileName);

            // 如果是头像，生成缩略图（这里简化处理）
            if ($type === 'avatar') {
                // 可以使用intervention/image等库生成缩略图
            }

            return $this->success([
                'url' => $url,
                'path' => $fileName,
                'size' => $file->getSize(),
                'ext' => $file->extension(),
            ], '上传成功');

        } catch (\Exception $e) {
            return $this->error('上传失败: ' . $e->getMessage());
        }
    }

    /**
     * 获取配置
     * GET /api/config
     */
    public function config()
    {
        return $this->success([
            'app_name' => config('app.app_name'),
            'version' => '1.0.0',
            'upload_max_size' => config('app.upload.max_size'),
        ]);
    }

    /**
     * 版本检测
     * GET /api/version
     */
    public function version()
    {
        $platform = $this->request->param('platform', 'android'); // android/ios
        $currentVersion = $this->request->param('version', '1.0.0');

        // 这里可以查询数据库获取最新版本信息
        $latestVersion = '1.0.0';
        $forceUpdate = false;
        $downloadUrl = '';

        return $this->success([
            'latest_version' => $latestVersion,
            'current_version' => $currentVersion,
            'need_update' => version_compare($currentVersion, $latestVersion, '<'),
            'force_update' => $forceUpdate,
            'download_url' => $downloadUrl,
            'update_log' => [
                '修复已知问题',
                '优化性能',
                '新增功能',
            ],
        ]);
    }

    /**
     * 获取天气信息
     * GET /api/common/weather
     */
    public function weather()
    {
        $city = $this->request->param('city', '北京');
        $lat = $this->request->param('lat', '');
        $lon = $this->request->param('lon', '');

        // 这里应该调用第三方天气API（如高德、和风天气等）
        // 简化处理，返回模拟数据

        return $this->success([
            'city' => $city,
            'temperature' => 20,
            'weather' => '晴',
            'wind' => '东南风 2级',
            'humidity' => '60%',
            'running_index' => '适宜',
            'running_index_desc' => '天气晴朗，适合户外运动',
        ]);
    }
}
