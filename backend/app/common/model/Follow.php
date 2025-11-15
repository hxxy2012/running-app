<?php
/**
 * 关注模型
 */

namespace app\common\model;

use think\Model;

class Follow extends Model
{
    // 设置字段信息
    protected $schema = [
        'id' => 'int',
        'user_id' => 'int',
        'follow_user_id' => 'int',
        'create_time' => 'datetime',
    ];

    /**
     * 关注者
     */
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * 被关注者
     */
    public function followUser()
    {
        return $this->belongsTo(User::class, 'follow_user_id');
    }

    /**
     * 检查是否已关注
     */
    public static function isFollowing($userId, $followUserId)
    {
        return self::where('user_id', $userId)
            ->where('follow_user_id', $followUserId)
            ->count() > 0;
    }

    /**
     * 检查是否互相关注
     */
    public static function isFriend($userId, $targetUserId)
    {
        return self::isFollowing($userId, $targetUserId) &&
               self::isFollowing($targetUserId, $userId);
    }
}
