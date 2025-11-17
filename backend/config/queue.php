<?php

// +----------------------------------------------------------------------
// | 队列配置
// +----------------------------------------------------------------------

return [
    // 默认队列连接
    'default' => env('queue.driver', 'sync'),

    // 队列连接配置
    'connections' => [
        // 同步模式（仅用于开发测试）
        'sync' => [
            'type' => 'sync',
        ],

        // 数据库队列
        'database' => [
            'type'       => 'database',
            'queue'      => 'default',
            'table'      => 'jobs',
            'connection' => null,
        ],

        // Redis队列（推荐用于生产环境）
        'redis' => [
            'type'       => 'redis',
            'queue'      => 'default',
            'host'       => env('redis.host', '127.0.0.1'),
            'port'       => env('redis.port', 6379),
            'password'   => env('redis.password', ''),
            'select'     => env('redis.queue_select', 1),
            'timeout'    => 0,
            'persistent' => false,
        ],
    ],

    // 失败的任务配置
    'failed' => [
        'type'     => 'database',
        'database' => 'mysql',
        'table'    => 'failed_jobs',
    ],

    // 任务重试配置
    'retry_after' => 90, // 秒

    // 队列任务类命名空间
    'namespace' => 'app\\job\\',
];
