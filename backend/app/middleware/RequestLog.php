<?php

namespace app\middleware;

use think\Response;

/**
 * 请求日志中间件
 *
 * 记录所有API请求的详细信息，用于审计和问题排查
 */
class RequestLog
{
    /**
     * 需要记录完整请求体的路径
     */
    private $logBodyPaths = [
        '/auth/login',
        '/auth/register',
        '/running/save',
        '/post/publish',
    ];

    /**
     * 敏感字段（需要脱敏）
     */
    private $sensitiveFields = [
        'password',
        'oldPassword',
        'newPassword',
        'confirmPassword',
        'access_token',
        'refresh_token',
        'secret',
        'private_key',
    ];

    /**
     * 处理请求
     *
     * @param \think\Request $request
     * @param \Closure $next
     * @return Response
     */
    public function handle($request, \Closure $next)
    {
        // 记录请求开始时间
        $startTime = microtime(true);
        $startMemory = memory_get_usage();

        // 生成请求ID
        $requestId = $this->generateRequestId();
        $request->requestId = $requestId;

        // 执行请求
        $response = $next($request);

        // 记录请求结束时间
        $endTime = microtime(true);
        $endMemory = memory_get_usage();

        // 计算耗时和内存使用
        $duration = round(($endTime - $startTime) * 1000, 2); // 毫秒
        $memoryUsed = $endMemory - $startMemory;

        // 记录日志
        $this->logRequest($request, $response, $requestId, $duration, $memoryUsed);

        // 添加请求ID到响应头
        $response->header([
            'X-Request-ID' => $requestId,
            'X-Response-Time' => $duration . 'ms'
        ]);

        return $response;
    }

    /**
     * 生成请求ID
     *
     * @return string
     */
    private function generateRequestId()
    {
        return sprintf(
            '%s-%s',
            date('YmdHis'),
            substr(md5(uniqid(mt_rand(), true)), 0, 8)
        );
    }

    /**
     * 记录请求日志
     *
     * @param \think\Request $request
     * @param Response $response
     * @param string $requestId
     * @param float $duration
     * @param int $memoryUsed
     * @return void
     */
    private function logRequest($request, $response, $requestId, $duration, $memoryUsed)
    {
        $path = $request->pathinfo();
        $method = $request->method();
        $ip = $request->ip();
        $userId = $request->userId ?? 'guest';
        $statusCode = $response->getCode();

        // 基础日志信息
        $logData = [
            'request_id' => $requestId,
            'timestamp' => date('Y-m-d H:i:s'),
            'method' => $method,
            'path' => $path,
            'query' => $request->get(),
            'ip' => $ip,
            'user_agent' => $request->header('user-agent'),
            'user_id' => $userId,
            'status_code' => $statusCode,
            'duration_ms' => $duration,
            'memory_used_bytes' => $memoryUsed,
        ];

        // 是否记录请求体
        if ($this->shouldLogBody($path)) {
            $body = $request->post();
            $logData['request_body'] = $this->maskSensitiveData($body);
        }

        // 是否记录响应体（仅记录错误响应）
        if ($statusCode >= 400) {
            $responseBody = $response->getData();
            if (is_string($responseBody)) {
                $responseBody = json_decode($responseBody, true);
            }
            $logData['response_body'] = $responseBody;
        }

        // 记录到日志文件
        $this->writeLog($logData, $statusCode, $duration);
    }

    /**
     * 是否记录请求体
     *
     * @param string $path
     * @return bool
     */
    private function shouldLogBody($path)
    {
        foreach ($this->logBodyPaths as $pattern) {
            if (strpos($path, $pattern) !== false) {
                return true;
            }
        }
        return false;
    }

    /**
     * 脱敏敏感数据
     *
     * @param array $data
     * @return array
     */
    private function maskSensitiveData($data)
    {
        if (!is_array($data)) {
            return $data;
        }

        foreach ($data as $key => $value) {
            if (in_array($key, $this->sensitiveFields)) {
                $data[$key] = '***';
            } elseif (is_array($value)) {
                $data[$key] = $this->maskSensitiveData($value);
            }
        }

        return $data;
    }

    /**
     * 写入日志
     *
     * @param array $logData
     * @param int $statusCode
     * @param float $duration
     * @return void
     */
    private function writeLog($logData, $statusCode, $duration)
    {
        $logMessage = sprintf(
            "[%s] %s %s | Status: %d | Duration: %.2fms | IP: %s | User: %s",
            $logData['timestamp'],
            $logData['method'],
            $logData['path'],
            $statusCode,
            $duration,
            $logData['ip'],
            $logData['user_id']
        );

        // 根据状态码和响应时间选择日志级别
        if ($statusCode >= 500) {
            // 服务器错误
            \think\facade\Log::error($logMessage, $logData);
        } elseif ($statusCode >= 400) {
            // 客户端错误
            \think\facade\Log::warning($logMessage, $logData);
        } elseif ($duration > 1000) {
            // 慢请求（超过1秒）
            \think\facade\Log::warning('Slow Request: ' . $logMessage, $logData);
        } else {
            // 正常请求
            \think\facade\Log::info($logMessage, $logData);
        }

        // 性能监控：记录慢请求
        if ($duration > 500) {
            $this->logSlowRequest($logData);
        }
    }

    /**
     * 记录慢请求
     *
     * @param array $logData
     * @return void
     */
    private function logSlowRequest($logData)
    {
        $slowLogFile = runtime_path() . 'log/slow_requests.log';
        $logLine = sprintf(
            "[%s] %s %s - %.2fms - User: %s\n",
            $logData['timestamp'],
            $logData['method'],
            $logData['path'],
            $logData['duration_ms'],
            $logData['user_id']
        );

        file_put_contents($slowLogFile, $logLine, FILE_APPEND);
    }
}
