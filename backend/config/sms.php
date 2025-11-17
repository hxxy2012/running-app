<?php
/**
 * 短信配置
 */
return [
    // 短信服务商: aliyun, tencent, huawei
    'provider' => env('sms.provider', 'aliyun'),

    // 阿里云短信配置
    'aliyun' => [
        'access_key_id' => env('sms.aliyun.access_key_id', ''),
        'access_key_secret' => env('sms.aliyun.access_key_secret', ''),
        'sign_name' => env('sms.aliyun.sign_name', 'Running App'),
        'template_code' => env('sms.aliyun.template_code', 'SMS_123456789'),
    ],

    // 腾讯云短信配置
    'tencent' => [
        'secret_id' => env('sms.tencent.secret_id', ''),
        'secret_key' => env('sms.tencent.secret_key', ''),
        'sdk_app_id' => env('sms.tencent.sdk_app_id', ''),
        'sign_name' => env('sms.tencent.sign_name', 'Running App'),
        'template_id' => env('sms.tencent.template_id', '123456'),
    ],

    // 华为云短信配置
    'huawei' => [
        'app_key' => env('sms.huawei.app_key', ''),
        'app_secret' => env('sms.huawei.app_secret', ''),
        'sender' => env('sms.huawei.sender', ''),
        'template_id' => env('sms.huawei.template_id', ''),
    ],

    // 默认配置（从对应服务商读取）
    'access_key_id' => env('sms.aliyun.access_key_id', ''),
    'access_key_secret' => env('sms.aliyun.access_key_secret', ''),
    'sign_name' => env('sms.aliyun.sign_name', 'Running App'),
    'template_code' => env('sms.aliyun.template_code', 'SMS_123456789'),
];
