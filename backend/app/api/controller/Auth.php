<?php
/**
 * 认证控制器
 */

namespace app\api\controller;

use app\common\model\User;
use app\common\model\SmsCode;
use app\common\service\JwtService;
use app\common\service\SmsService;
use think\facade\Db;

class Auth extends Base
{
    /**
     * 发送验证码
     * POST /api/auth/send-code
     */
    public function sendCode()
    {
        $phone = $this->request->param('phone', '');
        $type = $this->request->param('type', 1); // 1:注册 2:登录 3:重置密码

        // 验证手机号
        if (!preg_match('/^1[3-9]\d{9}$/', $phone)) {
            return $this->error('手机号格式不正确');
        }

        // 检查发送频率（60秒内只能发送一次）
        $lastCode = SmsCode::where('phone', $phone)
            ->where('create_time', '>', date('Y-m-d H:i:s', time() - 60))
            ->find();

        if ($lastCode) {
            return $this->error('验证码发送过于频繁，请稍后再试');
        }

        // 生成6位随机验证码
        $code = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);

        // 保存验证码到数据库
        try {
            SmsCode::create([
                'phone' => $phone,
                'code' => $code,
                'type' => $type,
                'status' => 0,
                'expire_time' => date('Y-m-d H:i:s', time() + 300), // 5分钟过期
            ]);

            // 发送短信（这里简化处理，实际需要调用短信服务商API）
            // SmsService::send($phone, $code);

            // 开发环境下返回验证码（生产环境删除）
            $debugData = config('app.app_debug') ? ['code' => $code] : [];

            return $this->success($debugData, '验证码发送成功');

        } catch (\Exception $e) {
            return $this->error('发送失败: ' . $e->getMessage());
        }
    }

    /**
     * 注册
     * POST /api/auth/register
     */
    public function register()
    {
        $phone = $this->request->param('phone', '');
        $code = $this->request->param('code', '');
        $password = $this->request->param('password', '');
        $nickname = $this->request->param('nickname', '');

        // 参数验证
        if (!preg_match('/^1[3-9]\d{9}$/', $phone)) {
            return $this->error('手机号格式不正确');
        }

        if (strlen($password) < 6) {
            return $this->error('密码长度不能少于6位');
        }

        // 验证验证码
        $smsCode = SmsCode::where('phone', $phone)
            ->where('code', $code)
            ->where('type', 1)
            ->where('status', 0)
            ->where('expire_time', '>', date('Y-m-d H:i:s'))
            ->find();

        if (!$smsCode) {
            return $this->error('验证码错误或已过期');
        }

        // 检查手机号是否已注册
        if (User::where('phone', $phone)->find()) {
            return $this->error('该手机号已注册');
        }

        try {
            Db::startTrans();

            // 创建用户
            $user = User::create([
                'phone' => $phone,
                'password' => password_hash($password, PASSWORD_BCRYPT),
                'nickname' => $nickname ?: '跑友' . substr($phone, -4),
                'avatar' => config('app.upload.avatar_default', ''),
                'status' => 1,
            ]);

            // 标记验证码已使用
            $smsCode->status = 1;
            $smsCode->save();

            // 生成Token
            $token = JwtService::generate($user->id);

            Db::commit();

            return $this->success([
                'user' => [
                    'id' => $user->id,
                    'phone' => $user->phone,
                    'nickname' => $user->nickname,
                    'avatar' => $user->avatar,
                ],
                'token' => $token,
            ], '注册成功');

        } catch (\Exception $e) {
            Db::rollback();
            return $this->error('注册失败: ' . $e->getMessage());
        }
    }

    /**
     * 登录
     * POST /api/auth/login
     */
    public function login()
    {
        $phone = $this->request->param('phone', '');
        $password = $this->request->param('password', '');

        // 参数验证
        if (empty($phone) || empty($password)) {
            return $this->error('手机号和密码不能为空');
        }

        // 查询用户
        $user = User::where('phone', $phone)->find();

        if (!$user) {
            return $this->error('用户不存在');
        }

        // 验证密码
        if (!password_verify($password, $user->password)) {
            return $this->error('密码错误');
        }

        // 检查账号状态
        if ($user->status != 1) {
            return $this->error('账号已被禁用');
        }

        // 生成Token
        $token = JwtService::generate($user->id);

        // 更新最后登录时间
        $user->update_time = date('Y-m-d H:i:s');
        $user->save();

        return $this->success([
            'user' => [
                'id' => $user->id,
                'phone' => $user->phone,
                'nickname' => $user->nickname,
                'avatar' => $user->avatar,
                'gender' => $user->gender,
                'city' => $user->city,
                'level' => $user->level,
                'total_distance' => $user->total_distance,
                'total_time' => $user->total_time,
                'total_count' => $user->total_count,
            ],
            'token' => $token,
        ], '登录成功');
    }

    /**
     * 刷新Token
     * POST /api/auth/refresh-token
     */
    public function refreshToken()
    {
        $oldToken = $this->request->header('Authorization', '');

        if (stripos($oldToken, 'Bearer ') === 0) {
            $oldToken = substr($oldToken, 7);
        }

        if (empty($oldToken)) {
            return $this->error('Token不能为空', 401);
        }

        try {
            // 验证旧Token并获取用户ID
            $userId = JwtService::verify($oldToken);

            // 生成新Token
            $newToken = JwtService::generate($userId);

            return $this->success([
                'token' => $newToken,
            ], 'Token刷新成功');

        } catch (\Exception $e) {
            return $this->error('Token刷新失败: ' . $e->getMessage(), 401);
        }
    }

    /**
     * 第三方登录
     * POST /api/auth/oauth
     */
    public function oauth()
    {
        $type = $this->request->param('type', ''); // wechat/qq/apple
        $code = $this->request->param('code', '');
        $openid = $this->request->param('openid', '');

        // 这里简化处理，实际需要调用第三方API验证code获取openid
        // 然后查询或创建用户

        return $this->error('第三方登录功能开发中');
    }
}
