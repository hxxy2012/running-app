<?php

// +----------------------------------------------------------------------
// | 缓存配置
// +----------------------------------------------------------------------

return [
    // 默认缓存驱动
    'default' => env('cache.driver', 'file'),

    // 缓存连接方式配置
    'stores' => [
        'file' => [
            // 驱动方式
            'type'       => 'File',
            // 缓存保存目录
            'path'       => runtime_path() . 'cache/',
            // 缓存前缀
            'prefix'     => '',
            // 缓存有效期 0表示永久缓存
            'expire'     => 0,
            // 缓存标签前缀
            'tag_prefix' => 'tag:',
            // 序列化机制 例如 ['serialize', 'unserialize']
            'serialize'  => [],
        ],

        'redis' => [
            // 驱动方式
            'type'       => 'Redis',
            // 服务器地址
            'host'       => env('redis.host', '127.0.0.1'),
            // 端口
            'port'       => env('redis.port', 6379),
            // 密码
            'password'   => env('redis.password', ''),
            // 缓存前缀
            'prefix'     => env('redis.prefix', 'running_app:'),
            // 缓存有效期 0为永久缓存
            'expire'     => 0,
            // 数据库索引
            'select'     => env('redis.select', 0),
            // 超时时间
            'timeout'    => 0,
            // 长连接
            'persistent' => false,
            // 序列化机制
            'serialize'  => ['serialize', 'unserialize'],
            // 标签前缀
            'tag_prefix' => 'tag:',
        ],

        // Memcached配置
        'memcache' => [
            'type'   => 'Memcache',
            'host'   => env('memcache.host', '127.0.0.1'),
            'port'   => env('memcache.port', 11211),
            'prefix' => env('memcache.prefix', ''),
            'expire' => 0,
        ],

        // Memcached配置
        'memcached' => [
            'type'   => 'Memcached',
            'host'   => env('memcached.host', '127.0.0.1'),
            'port'   => env('memcached.port', 11211),
            'prefix' => env('memcached.prefix', ''),
            'expire' => 0,
        ],
    ],
];
