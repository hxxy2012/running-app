<?php
/**
 * 点赞模型
 */

namespace app\common\model;

use think\Model;

class Like extends Model
{
    // 设置字段信息
    protected $schema = [
        'id' => 'int',
        'user_id' => 'int',
        'target_type' => 'int',
        'target_id' => 'int',
        'create_time' => 'datetime',
    ];

    /**
     * 关联用户
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * 检查是否已点赞
     */
    public static function isLiked($userId, $targetType, $targetId)
    {
        return self::where('user_id', $userId)
            ->where('target_type', $targetType)
            ->where('target_id', $targetId)
            ->count() > 0;
    }
}
