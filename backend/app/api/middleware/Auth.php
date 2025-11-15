<?php
/**
 * API认证中间件
 */

namespace app\api\middleware;

use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use think\Response;

class Auth
{
    /**
     * 处理请求
     *
     * @param \think\Request $request
     * @param \Closure $next
     * @return Response
     */
    public function handle($request, \Closure $next)
    {
        // 获取Token
        $token = $request->header('Authorization', '');

        // 移除Bearer前缀
        if (stripos($token, 'Bearer ') === 0) {
            $token = substr($token, 7);
        }

        if (empty($token)) {
            return json([
                'code' => 401,
                'message' => '未登录或登录已过期',
                'data' => [],
                'timestamp' => time(),
            ]);
        }

        try {
            // 验证Token
            $jwtKey = config('app.jwt_key');
            $decoded = JWT::decode($token, new Key($jwtKey, 'HS256'));

            // 将用户信息注入到请求对象
            $request->userId = $decoded->uid;

            // 可选：查询用户完整信息
            // $user = \app\common\model\User::find($decoded->uid);
            // if (!$user || $user->status != 1) {
            //     throw new \Exception('用户不存在或已被禁用');
            // }
            // $request->user = $user->toArray();

        } catch (\Exception $e) {
            return json([
                'code' => 401,
                'message' => 'Token验证失败: ' . $e->getMessage(),
                'data' => [],
                'timestamp' => time(),
            ]);
        }

        return $next($request);
    }
}
