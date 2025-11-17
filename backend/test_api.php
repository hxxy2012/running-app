#!/usr/bin/env php
<?php
/**
 * Running App - API 快速测试脚本
 *
 * 用法: php test_api.php [base_url]
 * 示例: php test_api.php http://localhost:8000
 */

// 设置错误报告
error_reporting(E_ALL);
ini_set('display_errors', 1);

// 获取基础URL
$baseUrl = $argv[1] ?? 'http://localhost:8000';
$baseUrl = rtrim($baseUrl, '/');

echo "==========================================\n";
echo "Running App - API 测试脚本\n";
echo "==========================================\n";
echo "测试地址: {$baseUrl}\n";
echo "==========================================\n\n";

// 测试结果统计
$totalTests = 0;
$passedTests = 0;
$failedTests = 0;

/**
 * 发送HTTP请求
 */
function sendRequest($method, $url, $data = null, $token = null) {
    $ch = curl_init();

    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

    $headers = ['Content-Type: application/json'];
    if ($token) {
        $headers[] = 'Authorization: Bearer ' . $token;
    }
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

    if ($method === 'POST') {
        curl_setopt($ch, CURLOPT_POST, true);
        if ($data) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        }
    }

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);

    curl_close($ch);

    if ($error) {
        return ['error' => $error, 'http_code' => $httpCode];
    }

    return [
        'http_code' => $httpCode,
        'body' => json_decode($response, true) ?: $response
    ];
}

/**
 * 执行测试
 */
function runTest($name, $url, $method = 'GET', $data = null, $token = null, $expectedCode = 200) {
    global $totalTests, $passedTests, $failedTests, $baseUrl;

    $totalTests++;
    echo "测试 #{$totalTests}: {$name}\n";
    echo "  请求: {$method} {$url}\n";

    $result = sendRequest($method, $baseUrl . $url, $data, $token);

    if (isset($result['error'])) {
        echo "  ❌ 失败: {$result['error']}\n";
        $failedTests++;
        echo "\n";
        return null;
    }

    $httpCode = $result['http_code'];
    $body = $result['body'];

    if ($httpCode == $expectedCode) {
        echo "  ✅ 通过: HTTP {$httpCode}\n";
        if (is_array($body)) {
            echo "  响应: " . json_encode($body, JSON_UNESCAPED_UNICODE) . "\n";
        }
        $passedTests++;
    } else {
        echo "  ❌ 失败: HTTP {$httpCode} (期望 {$expectedCode})\n";
        if (is_array($body)) {
            echo "  响应: " . json_encode($body, JSON_UNESCAPED_UNICODE) . "\n";
        }
        $failedTests++;
    }

    echo "\n";
    return $body;
}

// ==========================================
// 测试用例
// ==========================================

// 1. 测试服务器是否可达
echo "【阶段 1】服务器连接测试\n";
echo "==========================================\n";

$result = sendRequest('GET', $baseUrl);
if (isset($result['error'])) {
    echo "❌ 无法连接到服务器: {$result['error']}\n";
    echo "请确保:\n";
    echo "  1. 后端服务已启动 (php think run)\n";
    echo "  2. 地址正确: {$baseUrl}\n";
    exit(1);
}
echo "✅ 服务器连接成功\n\n";

// 2. 测试用户相关接口
echo "【阶段 2】用户相关接口测试\n";
echo "==========================================\n";

// 生成随机手机号和密码
$testPhone = '13' . rand(100000000, 999999999);
$testPassword = 'Test123456';

// 2.1 发送验证码（应该返回成功或提示配置短信服务）
runTest(
    '发送验证码',
    '/user/sendCode',
    'POST',
    ['phone' => $testPhone, 'type' => 1]
);

// 2.2 注册（使用测试验证码：123456）
$registerResult = runTest(
    '用户注册',
    '/user/register',
    'POST',
    [
        'phone' => $testPhone,
        'password' => $testPassword,
        'code' => '123456'  // 测试验证码
    ]
);

// 2.3 登录
$loginResult = runTest(
    '用户登录',
    '/user/login',
    'POST',
    [
        'phone' => $testPhone,
        'password' => $testPassword
    ]
);

$token = null;
if (isset($loginResult['data']['token'])) {
    $token = $loginResult['data']['token'];
    echo "📝 获取到Token: " . substr($token, 0, 20) . "...\n\n";
}

// 2.4 获取用户信息（需要token）
if ($token) {
    runTest(
        '获取用户信息',
        '/user/info',
        'GET',
        null,
        $token
    );
}

// 3. 测试跑步记录接口
echo "【阶段 3】跑步记录接口测试\n";
echo "==========================================\n";

if ($token) {
    // 3.1 创建跑步记录
    $recordData = [
        'type' => 1,
        'distance' => 5.0,
        'duration' => 1800,
        'start_time' => date('Y-m-d H:i:s', strtotime('-30 minutes')),
        'end_time' => date('Y-m-d H:i:s'),
        'avg_pace' => 360,
        'calories' => 300
    ];

    $createResult = runTest(
        '创建跑步记录',
        '/running/create',
        'POST',
        $recordData,
        $token
    );

    // 3.2 获取跑步记录列表
    runTest(
        '获取跑步记录列表',
        '/running/list',
        'GET',
        null,
        $token
    );

    // 3.3 获取统计数据
    runTest(
        '获取统计数据',
        '/running/statistics',
        'GET',
        null,
        $token
    );
} else {
    echo "⚠️  跳过：需要登录token\n\n";
}

// 4. 测试挑战赛接口
echo "【阶段 4】挑战赛接口测试\n";
echo "==========================================\n";

if ($token) {
    // 4.1 获取挑战赛列表
    runTest(
        '获取挑战赛列表',
        '/challenge/list',
        'GET',
        null,
        $token
    );
} else {
    echo "⚠️  跳过：需要登录token\n\n";
}

// 5. 测试排行榜接口
echo "【阶段 5】排行榜接口测试\n";
echo "==========================================\n";

if ($token) {
    // 5.1 获取排行榜
    runTest(
        '获取排行榜',
        '/ranking/list?type=total',
        'GET',
        null,
        $token
    );
} else {
    echo "⚠️  跳过：需要登录token\n\n";
}

// 6. 测试社交接口
echo "【阶段 6】社交接口测试\n";
echo "==========================================\n";

if ($token) {
    // 6.1 获取动态列表
    runTest(
        '获取动态列表',
        '/post/feed',
        'GET',
        null,
        $token
    );

    // 6.2 发布动态
    $postResult = runTest(
        '发布动态',
        '/post/create',
        'POST',
        [
            'content' => '测试动态：' . date('Y-m-d H:i:s'),
            'type' => 1
        ],
        $token
    );
} else {
    echo "⚠️  跳过：需要登录token\n\n";
}

// ==========================================
// 测试结果汇总
// ==========================================

echo "==========================================\n";
echo "测试结果汇总\n";
echo "==========================================\n";
echo "总测试数: {$totalTests}\n";
echo "通过: {$passedTests} ✅\n";
echo "失败: {$failedTests} ❌\n";
echo "通过率: " . round(($passedTests / $totalTests) * 100, 2) . "%\n";
echo "==========================================\n";

if ($failedTests === 0) {
    echo "\n🎉 所有测试通过！\n";
    exit(0);
} else {
    echo "\n⚠️  有测试失败，请检查错误信息\n";
    exit(1);
}
