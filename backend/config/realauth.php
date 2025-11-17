<?php
/**
 * 实名认证配置
 */
return [
    // 服务商: aliyun, tencent
    'provider' => env('realauth.provider', 'aliyun'),

    // 阿里云实名认证配置
    'aliyun' => [
        'access_key_id' => env('realauth.aliyun.access_key_id', ''),
        'access_key_secret' => env('realauth.aliyun.access_key_secret', ''),
        'region_id' => env('realauth.aliyun.region_id', 'cn-hangzhou'),
    ],

    // 腾讯云实名认证配置
    'tencent' => [
        'secret_id' => env('realauth.tencent.secret_id', ''),
        'secret_key' => env('realauth.tencent.secret_key', ''),
        'region' => env('realauth.tencent.region', 'ap-guangzhou'),
    ],

    // 默认配置
    'access_key_id' => env('realauth.aliyun.access_key_id', ''),
    'access_key_secret' => env('realauth.aliyun.access_key_secret', ''),
];
