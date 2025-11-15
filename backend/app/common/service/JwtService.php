<?php
/**
 * JWT服务类
 */

namespace app\common\service;

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

class JwtService
{
    /**
     * 生成Token
     * @param int $userId 用户ID
     * @return string
     */
    public static function generate($userId)
    {
        $key = config('app.jwt_key');
        $expire = config('app.jwt_expire', 604800); // 默认7天

        $payload = [
            'iss' => 'running-app',                    // 签发者
            'iat' => time(),                           // 签发时间
            'exp' => time() + $expire,                 // 过期时间
            'uid' => $userId,                          // 用户ID
        ];

        return JWT::encode($payload, $key, 'HS256');
    }

    /**
     * 验证Token
     * @param string $token
     * @return int 返回用户ID
     * @throws \Exception
     */
    public static function verify($token)
    {
        try {
            $key = config('app.jwt_key');
            $decoded = JWT::decode($token, new Key($key, 'HS256'));

            return $decoded->uid;

        } catch (\Exception $e) {
            throw new \Exception('Token验证失败: ' . $e->getMessage());
        }
    }

    /**
     * 解析Token（不验证过期时间）
     * @param string $token
     * @return object
     */
    public static function parse($token)
    {
        $key = config('app.jwt_key');
        return JWT::decode($token, new Key($key, 'HS256'));
    }
}
