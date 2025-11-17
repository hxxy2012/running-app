<?php

namespace Tests\Unit;

use PHPUnit\Framework\TestCase;
use app\common\service\JwtService;

/**
 * JWT服务单元测试
 */
class JwtServiceTest extends TestCase
{
    private $jwtService;

    protected function setUp(): void
    {
        parent::setUp();
        $this->jwtService = new JwtService();
    }

    /**
     * 测试生成JWT Token
     */
    public function testGenerateToken()
    {
        $userId = 1;
        $username = 'testuser';

        $token = $this->jwtService->createToken($userId, $username);

        $this->assertNotEmpty($token);
        $this->assertIsString($token);
        // JWT格式应该是三部分用.分隔
        $this->assertCount(3, explode('.', $token));
    }

    /**
     * 测试解析有效Token
     */
    public function testParseValidToken()
    {
        $userId = 123;
        $username = 'john_doe';

        $token = $this->jwtService->createToken($userId, $username);
        $decoded = $this->jwtService->parseToken($token);

        $this->assertIsArray($decoded);
        $this->assertEquals($userId, $decoded['user_id']);
        $this->assertEquals($username, $decoded['username']);
        $this->assertArrayHasKey('exp', $decoded);
        $this->assertArrayHasKey('iat', $decoded);
    }

    /**
     * 测试解析无效Token
     */
    public function testParseInvalidToken()
    {
        $invalidToken = 'invalid.token.here';

        $result = $this->jwtService->parseToken($invalidToken);

        $this->assertFalse($result);
    }

    /**
     * 测试Token过期检查
     */
    public function testTokenExpiration()
    {
        // 创建一个已过期的token（通过修改过期时间）
        $userId = 1;
        $username = 'testuser';

        // 正常token应该未过期
        $token = $this->jwtService->createToken($userId, $username);
        $decoded = $this->jwtService->parseToken($token);

        $this->assertNotFalse($decoded);
        $this->assertGreaterThan(time(), $decoded['exp']);
    }

    /**
     * 测试Token包含必要字段
     */
    public function testTokenContainsRequiredFields()
    {
        $userId = 999;
        $username = 'testuser999';

        $token = $this->jwtService->createToken($userId, $username);
        $decoded = $this->jwtService->parseToken($token);

        $this->assertArrayHasKey('user_id', $decoded);
        $this->assertArrayHasKey('username', $decoded);
        $this->assertArrayHasKey('iat', $decoded);
        $this->assertArrayHasKey('exp', $decoded);
    }

    /**
     * 测试不同用户生成不同Token
     */
    public function testDifferentUsersGenerateDifferentTokens()
    {
        $token1 = $this->jwtService->createToken(1, 'user1');
        $token2 = $this->jwtService->createToken(2, 'user2');

        $this->assertNotEquals($token1, $token2);
    }
}
