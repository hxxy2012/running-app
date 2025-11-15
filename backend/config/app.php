<?php
/**
 * 应用配置
 */
return [
    // 应用名称
    'app_name' => env('app.name', 'Running App'),

    // 应用调试模式
    'app_debug' => env('app.debug', true),

    // 应用Trace
    'app_trace' => env('app.trace', false),

    // 应用模式状态
    'app_status' => env('app.status', ''),

    // 默认时区
    'default_timezone' => env('app.timezone', 'Asia/Shanghai'),

    // 默认语言
    'default_lang' => env('app.lang', 'zh-cn'),

    // JWT配置
    'jwt_key' => env('jwt.key', 'running-app-secret-key-please-change-this'),
    'jwt_expire' => env('jwt.expire', 604800), // 7天

    // API域名
    'api_domain' => env('app.api_domain', 'http://localhost'),

    // 文件上传配置
    'upload' => [
        'max_size' => 5 * 1024 * 1024, // 5MB
        'allowed_ext' => ['jpg', 'jpeg', 'png', 'gif', 'webp'],
        'save_path' => 'uploads/',
    ],

    // 短信配置
    'sms' => [
        'provider' => env('sms.provider', 'aliyun'),
        'access_key' => env('sms.access_key', ''),
        'access_secret' => env('sms.access_secret', ''),
        'sign_name' => env('sms.sign_name', 'Running App'),
        'template' => [
            'register' => 'SMS_123456789',
            'login' => 'SMS_123456789',
            'reset_password' => 'SMS_123456789',
        ],
        'code_length' => 6,
        'code_expire' => 300, // 5分钟
    ],

    // 第三方登录配置
    'oauth' => [
        'wechat' => [
            'app_id' => env('oauth.wechat.app_id', ''),
            'app_secret' => env('oauth.wechat.app_secret', ''),
        ],
        'qq' => [
            'app_id' => env('oauth.qq.app_id', ''),
            'app_key' => env('oauth.qq.app_key', ''),
        ],
    ],

    // 异常页面的模板文件
    'exception_tmpl' => app()->getThinkPath() . 'tpl/think_exception.tpl',

    // 错误显示信息,非调试模式有效
    'error_message' => '页面错误！请稍后再试～',

    // 显示错误信息
    'show_error_msg' => false,
];
