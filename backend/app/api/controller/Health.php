<?php

namespace app\api\controller;

use think\facade\Db;
use think\facade\Cache;
use app\common\service\CacheService;

/**
 * 健康检查控制器
 *
 * 提供系统健康状态检查接口
 */
class Health extends Base
{
    /**
     * 基础健康检查
     *
     * @return \think\response\Json
     */
    public function index()
    {
        return json([
            'status' => 'healthy',
            'timestamp' => time(),
            'version' => '1.5.9',
            'service' => 'Running App API'
        ]);
    }

    /**
     * 详细健康检查
     *
     * 检查所有依赖服务的健康状态
     *
     * @return \think\response\Json
     */
    public function detailed()
    {
        $startTime = microtime(true);

        $checks = [
            'application' => $this->checkApplication(),
            'database' => $this->checkDatabase(),
            'cache' => $this->checkCache(),
            'filesystem' => $this->checkFilesystem(),
            'memory' => $this->checkMemory(),
        ];

        // 计算总体状态
        $overallStatus = 'healthy';
        foreach ($checks as $service => $result) {
            if ($result['status'] !== 'healthy') {
                $overallStatus = 'unhealthy';
                break;
            }
        }

        $responseTime = round((microtime(true) - $startTime) * 1000, 2);

        return json([
            'status' => $overallStatus,
            'timestamp' => time(),
            'response_time_ms' => $responseTime,
            'version' => '1.5.9',
            'checks' => $checks
        ]);
    }

    /**
     * 检查应用程序状态
     *
     * @return array
     */
    private function checkApplication()
    {
        try {
            $appStatus = [
                'status' => 'healthy',
                'php_version' => PHP_VERSION,
                'thinkphp_version' => app()->version(),
                'environment' => app()->isDebug() ? 'development' : 'production',
                'memory_limit' => ini_get('memory_limit'),
                'max_execution_time' => ini_get('max_execution_time') . 's'
            ];

            // 检查必要的PHP扩展
            $requiredExtensions = ['pdo', 'pdo_mysql', 'json', 'mbstring', 'openssl'];
            $missingExtensions = [];

            foreach ($requiredExtensions as $ext) {
                if (!extension_loaded($ext)) {
                    $missingExtensions[] = $ext;
                }
            }

            if (!empty($missingExtensions)) {
                $appStatus['status'] = 'unhealthy';
                $appStatus['missing_extensions'] = $missingExtensions;
            }

            return $appStatus;
        } catch (\Exception $e) {
            return [
                'status' => 'unhealthy',
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * 检查数据库连接
     *
     * @return array
     */
    private function checkDatabase()
    {
        try {
            $startTime = microtime(true);

            // 执行简单查询测试连接
            $result = Db::query('SELECT 1 as test');

            $responseTime = round((microtime(true) - $startTime) * 1000, 2);

            if ($result && isset($result[0]['test']) && $result[0]['test'] == 1) {
                // 获取数据库统计信息
                $stats = $this->getDatabaseStats();

                return [
                    'status' => 'healthy',
                    'response_time_ms' => $responseTime,
                    'connection' => 'active',
                    'stats' => $stats
                ];
            } else {
                return [
                    'status' => 'unhealthy',
                    'error' => 'Invalid database response'
                ];
            }
        } catch (\Exception $e) {
            return [
                'status' => 'unhealthy',
                'error' => $e->getMessage(),
                'connection' => 'failed'
            ];
        }
    }

    /**
     * 获取数据库统计信息
     *
     * @return array
     */
    private function getDatabaseStats()
    {
        try {
            // 获取数据库大小
            $dbName = config('database.connections.mysql.database');
            $sizeQuery = Db::query(
                "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS size_mb
                FROM information_schema.TABLES
                WHERE table_schema = ?",
                [$dbName]
            );

            // 获取连接数
            $connections = Db::query("SHOW STATUS LIKE 'Threads_connected'");

            return [
                'size_mb' => $sizeQuery[0]['size_mb'] ?? 0,
                'connections' => $connections[0]['Value'] ?? 0
            ];
        } catch (\Exception $e) {
            return [];
        }
    }

    /**
     * 检查缓存服务
     *
     * @return array
     */
    private function checkCache()
    {
        try {
            $startTime = microtime(true);

            // 测试写入
            $testKey = 'health_check_test_' . time();
            $testValue = 'test_value_' . mt_rand();

            $writeSuccess = CacheService::set($testKey, $testValue, 60);

            if (!$writeSuccess) {
                return [
                    'status' => 'unhealthy',
                    'error' => 'Cache write failed'
                ];
            }

            // 测试读取
            $readValue = CacheService::get($testKey);

            if ($readValue !== $testValue) {
                return [
                    'status' => 'unhealthy',
                    'error' => 'Cache read mismatch'
                ];
            }

            // 测试删除
            CacheService::delete($testKey);

            $responseTime = round((microtime(true) - $startTime) * 1000, 2);

            return [
                'status' => 'healthy',
                'response_time_ms' => $responseTime,
                'driver' => config('cache.default'),
                'operations' => 'read/write/delete successful'
            ];
        } catch (\Exception $e) {
            return [
                'status' => 'unhealthy',
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * 检查文件系统
     *
     * @return array
     */
    private function checkFilesystem()
    {
        try {
            $runtimePath = runtime_path();
            $uploadPath = public_path('uploads');

            $checks = [
                'runtime' => [
                    'path' => $runtimePath,
                    'writable' => is_writable($runtimePath),
                    'exists' => is_dir($runtimePath)
                ],
                'upload' => [
                    'path' => $uploadPath,
                    'writable' => is_writable($uploadPath),
                    'exists' => is_dir($uploadPath)
                ]
            ];

            // 检查磁盘空间
            $diskFree = disk_free_space($runtimePath);
            $diskTotal = disk_total_space($runtimePath);
            $diskUsedPercent = round((1 - ($diskFree / $diskTotal)) * 100, 2);

            $allWritable = $checks['runtime']['writable'] && $checks['upload']['writable'];
            $allExists = $checks['runtime']['exists'] && $checks['upload']['exists'];

            $status = ($allWritable && $allExists && $diskUsedPercent < 90) ? 'healthy' : 'unhealthy';

            return [
                'status' => $status,
                'paths' => $checks,
                'disk' => [
                    'free_mb' => round($diskFree / 1024 / 1024, 2),
                    'total_mb' => round($diskTotal / 1024 / 1024, 2),
                    'used_percent' => $diskUsedPercent
                ]
            ];
        } catch (\Exception $e) {
            return [
                'status' => 'unhealthy',
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * 检查内存使用情况
     *
     * @return array
     */
    private function checkMemory()
    {
        try {
            $memoryUsage = memory_get_usage(true);
            $memoryPeak = memory_get_peak_usage(true);
            $memoryLimit = ini_get('memory_limit');

            // 转换memory_limit为字节
            $memoryLimitBytes = $this->convertToBytes($memoryLimit);

            $memoryUsedPercent = round(($memoryUsage / $memoryLimitBytes) * 100, 2);

            $status = $memoryUsedPercent < 80 ? 'healthy' : 'warning';

            return [
                'status' => $status,
                'current_mb' => round($memoryUsage / 1024 / 1024, 2),
                'peak_mb' => round($memoryPeak / 1024 / 1024, 2),
                'limit' => $memoryLimit,
                'used_percent' => $memoryUsedPercent
            ];
        } catch (\Exception $e) {
            return [
                'status' => 'unhealthy',
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * 转换内存大小字符串为字节
     *
     * @param string $size
     * @return int
     */
    private function convertToBytes($size)
    {
        $size = trim($size);
        $last = strtolower($size[strlen($size) - 1]);
        $size = (int)$size;

        switch ($last) {
            case 'g':
                $size *= 1024;
                // no break
            case 'm':
                $size *= 1024;
                // no break
            case 'k':
                $size *= 1024;
        }

        return $size;
    }

    /**
     * 就绪检查（Readiness Probe）
     *
     * 用于Kubernetes等容器编排系统
     *
     * @return \think\response\Json
     */
    public function ready()
    {
        try {
            // 检查关键服务是否就绪
            $dbCheck = $this->checkDatabase();
            $cacheCheck = $this->checkCache();

            $isReady = ($dbCheck['status'] === 'healthy' && $cacheCheck['status'] === 'healthy');

            if ($isReady) {
                return json([
                    'status' => 'ready',
                    'timestamp' => time()
                ]);
            } else {
                return json([
                    'status' => 'not ready',
                    'timestamp' => time(),
                    'issues' => [
                        'database' => $dbCheck['status'],
                        'cache' => $cacheCheck['status']
                    ]
                ], 503);
            }
        } catch (\Exception $e) {
            return json([
                'status' => 'not ready',
                'error' => $e->getMessage()
            ], 503);
        }
    }

    /**
     * 存活检查（Liveness Probe）
     *
     * 用于Kubernetes等容器编排系统
     *
     * @return \think\response\Json
     */
    public function alive()
    {
        // 简单检查应用是否还在运行
        return json([
            'status' => 'alive',
            'timestamp' => time()
        ]);
    }
}
