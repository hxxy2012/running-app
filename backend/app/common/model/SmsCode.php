<?php
/**
 * 短信验证码模型
 */

namespace app\common\model;

use think\Model;

class SmsCode extends Model
{
    // 设置字段信息
    protected $schema = [
        'id' => 'int',
        'phone' => 'string',
        'code' => 'string',
        'type' => 'int',
        'status' => 'int',
        'expire_time' => 'datetime',
        'create_time' => 'datetime',
    ];

    /**
     * 类型文本
     */
    public function getTypeTextAttr($value, $data)
    {
        $types = [1 => '注册', 2 => '登录', 3 => '重置密码'];
        return $types[$data['type']] ?? '未知';
    }

    /**
     * 验证验证码
     * @param string $phone 手机号
     * @param string $code 验证码
     * @param int $type 类型
     * @return bool
     */
    public static function verify($phone, $code, $type = 1)
    {
        $smsCode = self::where('phone', $phone)
            ->where('code', $code)
            ->where('type', $type)
            ->where('status', 0)
            ->where('expire_time', '>', date('Y-m-d H:i:s'))
            ->find();

        if ($smsCode) {
            // 标记为已使用
            $smsCode->status = 1;
            $smsCode->save();
            return true;
        }

        return false;
    }
}
