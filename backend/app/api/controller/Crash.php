<?php
namespace app\api\controller;

use app\common\controller\ApiBase;
use think\facade\Filesystem;

/**
 * 崩溃日志控制器
 */
class Crash extends ApiBase
{
    /**
     * 上传崩溃日志
     * POST /crash/upload
     */
    public function upload()
    {
        // 获取参数
        $platform = $this->request->param('platform', ''); // android/ios
        $appVersion = $this->request->param('app_version', '');
        $osVersion = $this->request->param('os_version', '');
        $deviceModel = $this->request->param('device_model', '');
        $crashTime = $this->request->param('crash_time', '');
        $logContent = $this->request->param('log_content', '');

        // 验证必填参数
        if (empty($platform) || empty($logContent)) {
            return $this->error('参数不完整');
        }

        try {
            // 创建日志目录
            $logDir = runtime_path() . 'crash_logs/' . $platform . '/' . date('Y-m-d');
            if (!is_dir($logDir)) {
                mkdir($logDir, 0755, true);
            }

            // 生成文件名
            $fileName = date('His') . '_' . ($this->userId ?? 'guest') . '_' . uniqid() . '.log';
            $filePath = $logDir . '/' . $fileName;

            // 构建日志内容
            $content = "========== 崩溃日志 ==========\n";
            $content .= "平台: " . $platform . "\n";
            $content .= "应用版本: " . $appVersion . "\n";
            $content .= "系统版本: " . $osVersion . "\n";
            $content .= "设备型号: " . $deviceModel . "\n";
            $content .= "崩溃时间: " . $crashTime . "\n";
            $content .= "用户ID: " . ($this->userId ?? '未登录') . "\n";
            $content .= "上传时间: " . date('Y-m-d H:i:s') . "\n";
            $content .= "========== 日志内容 ==========\n";
            $content .= $logContent;

            // 写入文件
            file_put_contents($filePath, $content);

            // 记录到数据库（可选）
            // 可以创建一个crash_log表来存储崩溃记录的元信息

            return $this->success([
                'log_id' => basename($fileName, '.log')
            ], '日志上传成功');

        } catch (\Exception $e) {
            return $this->error('上传失败: ' . $e->getMessage());
        }
    }

    /**
     * 上传崩溃日志文件
     * POST /crash/upload-file
     */
    public function uploadFile()
    {
        $file = $this->request->file('file');
        $platform = $this->request->param('platform', '');
        $appVersion = $this->request->param('app_version', '');

        if (!$file) {
            return $this->error('请选择文件');
        }

        if (empty($platform)) {
            return $this->error('请指定平台');
        }

        try {
            // 验证文件类型和大小
            $ext = strtolower($file->extension());
            $allowedExt = ['log', 'txt', 'zip'];

            if (!in_array($ext, $allowedExt)) {
                return $this->error('只支持 log、txt、zip 格式');
            }

            // 限制文件大小为10MB
            if ($file->getSize() > 10 * 1024 * 1024) {
                return $this->error('文件大小不能超过10MB');
            }

            // 保存文件
            $savePath = 'crash_logs/' . $platform . '/' . date('Y-m-d');
            $fileName = date('His') . '_' . ($this->userId ?? 'guest') . '_' . uniqid() . '.' . $ext;

            $path = $file->move($savePath, $fileName);

            return $this->success([
                'file_path' => $savePath . '/' . $fileName,
                'file_size' => $file->getSize()
            ], '文件上传成功');

        } catch (\Exception $e) {
            return $this->error('上传失败: ' . $e->getMessage());
        }
    }

    /**
     * 批量上传崩溃日志
     * POST /crash/batch-upload
     */
    public function batchUpload()
    {
        $logs = $this->request->param('logs', []);
        $platform = $this->request->param('platform', '');

        if (empty($logs) || !is_array($logs)) {
            return $this->error('日志列表不能为空');
        }

        if (count($logs) > 50) {
            return $this->error('单次最多上传50条日志');
        }

        try {
            $successCount = 0;
            $failedCount = 0;
            $results = [];

            foreach ($logs as $log) {
                $logContent = $log['content'] ?? '';
                $crashTime = $log['crash_time'] ?? '';

                if (empty($logContent)) {
                    $failedCount++;
                    continue;
                }

                // 创建日志目录
                $logDir = runtime_path() . 'crash_logs/' . $platform . '/' . date('Y-m-d');
                if (!is_dir($logDir)) {
                    mkdir($logDir, 0755, true);
                }

                // 生成文件名
                $fileName = date('His') . '_' . ($this->userId ?? 'guest') . '_' . uniqid() . '.log';
                $filePath = $logDir . '/' . $fileName;

                // 写入文件
                file_put_contents($filePath, $logContent);
                $successCount++;

                $results[] = [
                    'crash_time' => $crashTime,
                    'log_id' => basename($fileName, '.log'),
                    'status' => 'success'
                ];
            }

            return $this->success([
                'total' => count($logs),
                'success' => $successCount,
                'failed' => $failedCount,
                'results' => $results
            ], "成功上传 {$successCount} 条日志");

        } catch (\Exception $e) {
            return $this->error('批量上传失败: ' . $e->getMessage());
        }
    }
}
