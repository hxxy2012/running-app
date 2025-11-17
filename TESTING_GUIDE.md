# 测试指南

本文档提供Running App的完整测试策略和实践指南。

## 目录

- [测试类型](#测试类型)
- [单元测试](#单元测试)
- [功能测试](#功能测试)
- [API测试](#api测试)
- [性能测试](#性能测试)
- [代码质量检查](#代码质量检查)
- [CI/CD集成](#cicd集成)

---

## 测试类型

### 测试金字塔

```
           /\
          /  \        E2E测试 (10%)
         /____\
        /      \      集成测试 (20%)
       /________\
      /          \    单元测试 (70%)
     /____________\
```

### 测试覆盖率目标

- **单元测试覆盖率**: ≥ 70%
- **关键业务逻辑**: ≥ 90%
- **API测试覆盖率**: ≥ 80%

---

## 单元测试

### 1. 安装PHPUnit

```bash
cd backend
composer require --dev phpunit/phpunit
```

### 2. 运行测试

```bash
# 运行所有测试
cd backend
vendor/bin/phpunit

# 运行特定测试套件
vendor/bin/phpunit --testsuite Unit

# 运行单个测试文件
vendor/bin/phpunit tests/Unit/JwtServiceTest.php

# 生成代码覆盖率报告
vendor/bin/phpunit --coverage-html tests/coverage
```

### 3. 编写单元测试

#### 测试JWT服务

**tests/Unit/JwtServiceTest.php**

```php
<?php

namespace Tests\Unit;

use PHPUnit\Framework\TestCase;
use app\common\service\JwtService;

class JwtServiceTest extends TestCase
{
    private $jwtService;

    protected function setUp(): void
    {
        parent::setUp();
        $this->jwtService = new JwtService();
    }

    public function testGenerateToken()
    {
        $token = $this->jwtService->createToken(1, 'testuser');

        $this->assertNotEmpty($token);
        $this->assertIsString($token);
        $this->assertCount(3, explode('.', $token));
    }

    public function testParseValidToken()
    {
        $token = $this->jwtService->createToken(123, 'john');
        $decoded = $this->jwtService->parseToken($token);

        $this->assertIsArray($decoded);
        $this->assertEquals(123, $decoded['user_id']);
        $this->assertEquals('john', $decoded['username']);
    }
}
```

#### 测试成就服务

**tests/Unit/AchievementServiceTest.php**

```php
<?php

namespace Tests\Unit;

use PHPUnit\Framework\TestCase;
use app\common\service\AchievementService;

class AchievementServiceTest extends TestCase
{
    public function testCalculateDistance()
    {
        $service = new AchievementService();

        // 测试5公里成就
        $this->assertTrue($service->shouldUnlock(5.0, 'distance_5k'));
        $this->assertFalse($service->shouldUnlock(4.9, 'distance_5k'));
    }

    public function testCalculatePace()
    {
        // 配速测试：5km in 20分钟 = 4分钟/km
        $pace = $this->calculatePace(5000, 1200);
        $this->assertLessThan(300, $pace); // 快于5分钟/km
    }

    private function calculatePace($distance, $duration)
    {
        return ($duration / ($distance / 1000));
    }
}
```

### 4. 测试数据库操作

```php
<?php

namespace Tests\Unit;

use PHPUnit\Framework\TestCase;
use think\facade\Db;

class UserModelTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        // 使用内存数据库或测试数据库
        $this->initTestDatabase();
    }

    public function testCreateUser()
    {
        $data = [
            'username' => 'testuser',
            'password' => password_hash('password', PASSWORD_DEFAULT),
            'phone' => '13800138000'
        ];

        $userId = Db::name('user')->insertGetId($data);

        $this->assertIsInt($userId);
        $this->assertGreaterThan(0, $userId);
    }

    public function testFindUserByPhone()
    {
        $user = Db::name('user')
            ->where('phone', '13800138000')
            ->find();

        $this->assertNotEmpty($user);
        $this->assertEquals('testuser', $user['username']);
    }
}
```

---

## 功能测试

### 1. 认证功能测试

**tests/Feature/AuthApiTest.php**

```php
<?php

namespace Tests\Feature;

use PHPUnit\Framework\TestCase;

class AuthApiTest extends TestCase
{
    private $apiBaseUrl = 'http://localhost:8000';

    public function testRegisterWithValidData()
    {
        $data = [
            'username' => 'newuser' . time(),
            'password' => 'SecurePass123',
            'phone' => '138' . mt_rand(10000000, 99999999)
        ];

        $response = $this->post('/auth/register', $data);

        $this->assertEquals(200, $response['code']);
        $this->assertArrayHasKey('token', $response['data']);
    }

    public function testLoginWithValidCredentials()
    {
        $data = [
            'account' => 'testuser',
            'password' => 'password123'
        ];

        $response = $this->post('/auth/login', $data);

        $this->assertEquals(200, $response['code']);
        $this->assertArrayHasKey('token', $response['data']);
        $this->assertArrayHasKey('user_info', $response['data']);
    }

    public function testLoginWithInvalidCredentials()
    {
        $data = [
            'account' => 'testuser',
            'password' => 'wrongpassword'
        ];

        $response = $this->post('/auth/login', $data);

        $this->assertEquals(400, $response['code']);
    }

    // Helper方法
    private function post($endpoint, $data)
    {
        $ch = curl_init($this->apiBaseUrl . $endpoint);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json'
        ]);

        $response = curl_exec($ch);
        curl_close($ch);

        return json_decode($response, true);
    }
}
```

---

## API测试

### 1. 使用Postman

**导出测试集合**

```json
{
  "info": {
    "name": "Running App API Tests",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Auth - Register",
      "request": {
        "method": "POST",
        "url": "{{base_url}}/auth/register",
        "body": {
          "mode": "raw",
          "raw": "{\n  \"username\": \"testuser\",\n  \"password\": \"password123\",\n  \"phone\": \"13800138000\"\n}"
        }
      },
      "event": [
        {
          "listen": "test",
          "script": {
            "exec": [
              "pm.test(\"Status is 200\", function() {",
              "    pm.response.to.have.status(200);",
              "});",
              "",
              "pm.test(\"Response has token\", function() {",
              "    var jsonData = pm.response.json();",
              "    pm.expect(jsonData.data).to.have.property('token');",
              "    pm.environment.set('token', jsonData.data.token);",
              "});"
            ]
          }
        }
      ]
    }
  ]
}
```

### 2. 使用cURL脚本

**tests/api/test_auth.sh**

```bash
#!/bin/bash

BASE_URL="http://localhost:8000"

# 测试注册
echo "Testing Registration..."
response=$(curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "testuser_'$(date +%s)'",
        "password": "SecurePass123",
        "phone": "138'$(shuf -i 10000000-99999999 -n 1)'"
    }')

echo "$response" | jq '.'

# 测试登录
echo -e "\nTesting Login..."
response=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{
        "account": "testuser",
        "password": "password123"
    }')

token=$(echo "$response" | jq -r '.data.token')
echo "Token: $token"

# 测试获取用户信息
echo -e "\nTesting Get User Info..."
curl -s -X GET "$BASE_URL/user/info" \
    -H "Authorization: Bearer $token" | jq '.'
```

### 3. 自动化API测试

**backend/tests/api_test.php**

```php
<?php

require __DIR__ . '/../vendor/autoload.php';

class ApiTester
{
    private $baseUrl;
    private $token;

    public function __construct($baseUrl)
    {
        $this->baseUrl = $baseUrl;
    }

    public function run()
    {
        echo "🚀 Running API Tests...\n\n";

        $this->testRegister();
        $this->testLogin();
        $this->testGetUserInfo();
        $this->testSaveRunningRecord();

        echo "\n✅ All tests passed!\n";
    }

    private function testRegister()
    {
        echo "Testing: Register... ";

        $data = [
            'username' => 'testuser_' . time(),
            'password' => 'SecurePass123',
            'phone' => '138' . mt_rand(10000000, 99999999)
        ];

        $response = $this->post('/auth/register', $data);

        assert($response['code'] == 200, 'Register failed');
        assert(isset($response['data']['token']), 'Token not found');

        echo "✓\n";
    }

    private function testLogin()
    {
        echo "Testing: Login... ";

        $response = $this->post('/auth/login', [
            'account' => 'testuser',
            'password' => 'password123'
        ]);

        assert($response['code'] == 200, 'Login failed');
        $this->token = $response['data']['token'];

        echo "✓\n";
    }

    private function post($endpoint, $data)
    {
        $ch = curl_init($this->baseUrl . $endpoint);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Authorization: Bearer ' . $this->token
        ]);

        $response = curl_exec($ch);
        curl_close($ch);

        return json_decode($response, true);
    }
}

// 运行测试
$tester = new ApiTester('http://localhost:8000');
$tester->run();
```

---

## 性能测试

### 1. 使用load_test.sh

```bash
# 快速测试
./scripts/load_test.sh quick

# 标准测试
./scripts/load_test.sh normal

# 压力测试
./scripts/load_test.sh stress

# 测试特定API
./scripts/load_test.sh api /user/info
```

### 2. 使用Apache Bench

```bash
# 测试单个端点
ab -n 1000 -c 50 -H "Authorization: Bearer TOKEN" \
    http://localhost:8000/user/info

# 带POST数据的测试
ab -n 1000 -c 50 -p data.json -T "application/json" \
    http://localhost:8000/auth/login
```

### 3. 使用JMeter

创建测试计划：
1. 添加线程组（用户数、循环次数）
2. 添加HTTP请求默认值
3. 添加HTTP请求采样器
4. 添加监听器（查看结果树、聚合报告）

运行测试：
```bash
jmeter -n -t tests/jmeter/load_test.jmx -l results.jtl -e -o reports/
```

---

## 代码质量检查

### 1. PHPStan静态分析

```bash
# 运行PHPStan
cd backend
vendor/bin/phpstan analyse

# 指定级别（0-9，9最严格）
vendor/bin/phpstan analyse --level=5

# 生成基线（忽略现有问题）
vendor/bin/phpstan analyse --generate-baseline
```

**phpstan.neon配置已创建**

### 2. PHP CodeSniffer

```bash
# 检查代码规范
vendor/bin/phpcs --standard=PSR12 app/

# 自动修复
vendor/bin/phpcbf --standard=PSR12 app/

# 检查特定文件
vendor/bin/phpcs app/api/controller/User.php
```

### 3. PHP CS Fixer

```bash
# 检查代码风格
vendor/bin/php-cs-fixer fix --dry-run --diff

# 自动修复
vendor/bin/php-cs-fixer fix

# 使用自定义配置
vendor/bin/php-cs-fixer fix --config=.php-cs-fixer.php
```

---

## CI/CD集成

### 1. GitHub Actions工作流

已创建 `.github/workflows/ci.yml`，包含：
- PHPUnit测试
- PHPStan静态分析
- PHP CodeSniffer检查
- Android构建
- 代码质量检查

### 2. 本地预提交检查

**创建 .git/hooks/pre-commit**

```bash
#!/bin/bash

echo "Running pre-commit checks..."

# 运行PHPUnit
cd backend
if ! vendor/bin/phpunit --testsuite Unit; then
    echo "❌ Tests failed"
    exit 1
fi

# 运行PHPStan
if ! vendor/bin/phpstan analyse --level=5; then
    echo "❌ PHPStan check failed"
    exit 1
fi

echo "✅ All checks passed"
exit 0
```

```bash
chmod +x .git/hooks/pre-commit
```

---

## 测试最佳实践

### 1. 测试命名

```php
// ✅ 好的命名
public function testUserCanRegisterWithValidData()
public function testLoginFailsWithInvalidPassword()
public function testRunningRecordIsSavedCorrectly()

// ❌ 不好的命名
public function test1()
public function testUser()
```

### 2. AAA模式

```php
public function testCalculateDistance()
{
    // Arrange（准备）
    $point1 = ['lat' => 39.9, 'lng' => 116.4];
    $point2 = ['lat' => 40.0, 'lng' => 116.5];

    // Act（执行）
    $distance = $this->calculateDistance($point1, $point2);

    // Assert（断言）
    $this->assertGreaterThan(0, $distance);
    $this->assertLessThan(100, $distance);
}
```

### 3. 使用数据提供器

```php
/**
 * @dataProvider phoneNumberProvider
 */
public function testPhoneValidation($phone, $expected)
{
    $result = $this->validator->validatePhone($phone);
    $this->assertEquals($expected, $result);
}

public function phoneNumberProvider()
{
    return [
        ['13800138000', true],
        ['12345678901', false],
        ['138001380', false],
    ];
}
```

---

## 测试报告

### 1. 生成覆盖率报告

```bash
vendor/bin/phpunit --coverage-html tests/coverage
open tests/coverage/index.html
```

### 2. 查看测试结果

```bash
# 详细输出
vendor/bin/phpunit --testdox

# 带颜色
vendor/bin/phpunit --colors=always
```

---

## 参考资源

- [PHPUnit文档](https://phpunit.de/documentation.html)
- [PHPStan文档](https://phpstan.org/user-guide/getting-started)
- [测试驱动开发](https://www.martinfowler.com/bliki/TestDrivenDevelopment.html)

---

**版本**: 1.0
**最后更新**: 2024-11-17
**维护**: Running App Team
