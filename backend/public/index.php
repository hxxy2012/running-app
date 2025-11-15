<?php
/**
 * Running App API 入口文件
 */

namespace think;

// 加载基础文件
require __DIR__ . '/../vendor/autoload.php';

// 执行HTTP应用并响应
$http = (new App())->http;

$response = $http->run();

$response->send();

$http->end($response);
