<?php

namespace app\middleware;

use think\Response;
use app\common\service\CacheService;

/**
 * API限流中间件
 *
 * 防止API被恶意调用或滥用
 * 支持基于IP、用户ID的限流
 */
class RateLimit
{
    /**
     * 默认限流配置
     */
    const DEFAULT_MAX_REQUESTS = 100; // 最大请求数
    const DEFAULT_TIME_WINDOW = 60;   // 时间窗口（秒）

    /**
     * 不同接口的限流配置
     */
    private $limitConfig = [
        // 登录接口：每分钟5次
        '/auth/login' => ['max' => 5, 'window' => 60],
        '/auth/register' => ['max' => 3, 'window' => 60],
        '/auth/send_sms' => ['max' => 3, 'window' => 60],

        // 写入接口：每分钟20次
        '/running/save' => ['max' => 20, 'window' => 60],
        '/post/publish' => ['max' => 10, 'window' => 60],
        '/comment/add' => ['max' => 30, 'window' => 60],

        // 读取接口：每分钟60次
        '/user/info' => ['max' => 60, 'window' => 60],
        '/running/list' => ['max' => 60, 'window' => 60],
        '/post/feed' => ['max' => 60, 'window' => 60],
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
        // 获取客户端标识
        $identifier = $this->getIdentifier($request);

        // 获取当前路径
        $path = $request->pathinfo();

        // 获取限流配置
        $config = $this->getLimitConfig($path);

        // 检查限流
        if (!$this->checkRateLimit($identifier, $path, $config)) {
            return $this->rateLimitExceeded($config);
        }

        // 添加限流响应头
        $response = $next($request);
        $this->addRateLimitHeaders($response, $identifier, $path, $config);

        return $response;
    }

    /**
     * 获取客户端标识
     *
     * @param \think\Request $request
     * @return string
     */
    private function getIdentifier($request)
    {
        // 优先使用用户ID（已登录用户）
        $userId = $request->userId ?? null;
        if ($userId) {
            return 'user:' . $userId;
        }

        // 使用IP地址（未登录用户）
        $ip = $request->ip();
        return 'ip:' . $ip;
    }

    /**
     * 获取限流配置
     *
     * @param string $path
     * @return array
     */
    private function getLimitConfig($path)
    {
        // 检查是否有特定配置
        foreach ($this->limitConfig as $pattern => $config) {
            if (strpos($path, $pattern) !== false) {
                return $config;
            }
        }

        // 返回默认配置
        return [
            'max' => self::DEFAULT_MAX_REQUESTS,
            'window' => self::DEFAULT_TIME_WINDOW
        ];
    }

    /**
     * 检查限流
     *
     * @param string $identifier
     * @param string $path
     * @param array $config
     * @return bool
     */
    private function checkRateLimit($identifier, $path, $config)
    {
        $maxRequests = $config['max'];
        $timeWindow = $config['window'];

        return CacheService::checkRateLimit(
            $identifier . ':' . $path,
            $maxRequests,
            $timeWindow
        );
    }

    /**
     * 获取当前请求次数
     *
     * @param string $identifier
     * @param string $path
     * @return int
     */
    private function getCurrentCount($identifier, $path)
    {
        $key = CacheService::PREFIX . 'rate_limit:' . $identifier . ':' . $path;
        return (int)CacheService::get($key, 0);
    }

    /**
     * 限流超出响应
     *
     * @param array $config
     * @return Response
     */
    private function rateLimitExceeded($config)
    {
        $retryAfter = $config['window'];

        return json([
            'code' => 429,
            'msg' => '请求过于频繁，请稍后再试',
            'data' => [
                'retry_after' => $retryAfter . '秒后重试'
            ]
        ], 429)->header([
            'Retry-After' => $retryAfter,
            'X-RateLimit-Limit' => $config['max'],
            'X-RateLimit-Remaining' => 0,
            'X-RateLimit-Reset' => time() + $retryAfter
        ]);
    }

    /**
     * 添加限流响应头
     *
     * @param Response $response
     * @param string $identifier
     * @param string $path
     * @param array $config
     * @return void
     */
    private function addRateLimitHeaders($response, $identifier, $path, $config)
    {
        $current = $this->getCurrentCount($identifier, $path);
        $remaining = max(0, $config['max'] - $current);

        $response->header([
            'X-RateLimit-Limit' => $config['max'],
            'X-RateLimit-Remaining' => $remaining,
            'X-RateLimit-Reset' => time() + $config['window']
        ]);
    }
}
