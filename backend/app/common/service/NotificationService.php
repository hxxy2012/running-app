<?php
/**
 * 通知服务类
 */

namespace app\common\service;

use app\common\model\Notification;
use think\facade\Db;

class NotificationService
{
    // 通知类型常量
    const TYPE_LIKE = 1;           // 点赞
    const TYPE_COMMENT = 2;        // 评论
    const TYPE_FOLLOW = 3;         // 关注
    const TYPE_SYSTEM = 4;         // 系统通知
    const TYPE_ACHIEVEMENT = 5;    // 成就解锁
    const TYPE_CHALLENGE = 6;      // 挑战完成
    const TYPE_INVITE = 7;         // 邀请
    const TYPE_MENTION = 8;        // @提及

    /**
     * 发送点赞通知
     * @param int $userId 点赞用户ID
     * @param int $toUserId 被点赞用户ID
     * @param int $postId 动态ID
     * @return bool
     */
    public static function sendLikeNotification(int $userId, int $toUserId, int $postId): bool
    {
        // 不给自己发通知
        if ($userId == $toUserId) {
            return false;
        }

        return self::createNotification([
            'user_id' => $toUserId,
            'from_user_id' => $userId,
            'type' => self::TYPE_LIKE,
            'content' => '赞了你的动态',
            'related_id' => $postId,
            'related_type' => 'post',
        ]);
    }

    /**
     * 发送评论通知
     * @param int $userId 评论用户ID
     * @param int $toUserId 被评论用户ID
     * @param int $postId 动态ID
     * @param int $commentId 评论ID
     * @param string $content 评论内容
     * @return bool
     */
    public static function sendCommentNotification(int $userId, int $toUserId, int $postId, int $commentId, string $content): bool
    {
        // 不给自己发通知
        if ($userId == $toUserId) {
            return false;
        }

        // 截取评论内容前50个字符
        $shortContent = mb_substr($content, 0, 50);
        if (mb_strlen($content) > 50) {
            $shortContent .= '...';
        }

        return self::createNotification([
            'user_id' => $toUserId,
            'from_user_id' => $userId,
            'type' => self::TYPE_COMMENT,
            'content' => '评论了你：' . $shortContent,
            'related_id' => $commentId,
            'related_type' => 'comment',
            'extra_data' => json_encode(['post_id' => $postId]),
        ]);
    }

    /**
     * 发送关注通知
     * @param int $userId 关注用户ID
     * @param int $toUserId 被关注用户ID
     * @return bool
     */
    public static function sendFollowNotification(int $userId, int $toUserId): bool
    {
        return self::createNotification([
            'user_id' => $toUserId,
            'from_user_id' => $userId,
            'type' => self::TYPE_FOLLOW,
            'content' => '关注了你',
            'related_id' => $userId,
            'related_type' => 'user',
        ]);
    }

    /**
     * 发送成就解锁通知
     * @param int $userId 用户ID
     * @param int $achievementId 成就ID
     * @param string $achievementName 成就名称
     * @return bool
     */
    public static function sendAchievementNotification(int $userId, int $achievementId, string $achievementName): bool
    {
        return self::createNotification([
            'user_id' => $userId,
            'from_user_id' => 0, // 系统通知
            'type' => self::TYPE_ACHIEVEMENT,
            'content' => '恭喜你解锁成就：' . $achievementName,
            'related_id' => $achievementId,
            'related_type' => 'achievement',
        ]);
    }

    /**
     * 发送挑战完成通知
     * @param int $userId 用户ID
     * @param int $challengeId 挑战ID
     * @param string $challengeName 挑战名称
     * @return bool
     */
    public static function sendChallengeNotification(int $userId, int $challengeId, string $challengeName): bool
    {
        return self::createNotification([
            'user_id' => $userId,
            'from_user_id' => 0, // 系统通知
            'type' => self::TYPE_CHALLENGE,
            'content' => '恭喜你完成挑战：' . $challengeName,
            'related_id' => $challengeId,
            'related_type' => 'challenge',
        ]);
    }

    /**
     * 发送系统通知
     * @param int|array $userId 用户ID或用户ID数组
     * @param string $title 标题
     * @param string $content 内容
     * @param array $extraData 额外数据
     * @return bool|int 成功返回true或影响行数
     */
    public static function sendSystemNotification($userId, string $title, string $content, array $extraData = [])
    {
        if (is_array($userId)) {
            // 批量发送
            $data = [];
            foreach ($userId as $uid) {
                $data[] = [
                    'user_id' => $uid,
                    'from_user_id' => 0,
                    'type' => self::TYPE_SYSTEM,
                    'title' => $title,
                    'content' => $content,
                    'extra_data' => !empty($extraData) ? json_encode($extraData) : null,
                    'create_time' => date('Y-m-d H:i:s'),
                ];
            }
            return Db::name('notification')->insertAll($data);
        } else {
            // 单个发送
            return self::createNotification([
                'user_id' => $userId,
                'from_user_id' => 0,
                'type' => self::TYPE_SYSTEM,
                'title' => $title,
                'content' => $content,
                'extra_data' => !empty($extraData) ? json_encode($extraData) : null,
            ]);
        }
    }

    /**
     * 创建通知
     * @param array $data
     * @return bool
     */
    private static function createNotification(array $data): bool
    {
        try {
            Notification::create($data);
            return true;
        } catch (\Exception $e) {
            // 记录错误但不中断流程
            trace('Notification creation failed: ' . $e->getMessage(), 'error');
            return false;
        }
    }

    /**
     * 标记通知为已读
     * @param int $notificationId 通知ID
     * @param int $userId 用户ID
     * @return bool
     */
    public static function markAsRead(int $notificationId, int $userId): bool
    {
        return Notification::where('id', $notificationId)
            ->where('user_id', $userId)
            ->update(['is_read' => 1]) > 0;
    }

    /**
     * 批量标记为已读
     * @param array $notificationIds 通知ID数组
     * @param int $userId 用户ID
     * @return int 影响行数
     */
    public static function markMultipleAsRead(array $notificationIds, int $userId): int
    {
        return Notification::where('user_id', $userId)
            ->whereIn('id', $notificationIds)
            ->update(['is_read' => 1]);
    }

    /**
     * 标记所有通知为已读
     * @param int $userId 用户ID
     * @return int 影响行数
     */
    public static function markAllAsRead(int $userId): int
    {
        return Notification::where('user_id', $userId)
            ->where('is_read', 0)
            ->update(['is_read' => 1]);
    }

    /**
     * 删除通知
     * @param int $notificationId 通知ID
     * @param int $userId 用户ID
     * @return bool
     */
    public static function deleteNotification(int $notificationId, int $userId): bool
    {
        return Notification::where('id', $notificationId)
            ->where('user_id', $userId)
            ->delete() > 0;
    }

    /**
     * 获取未读通知数量
     * @param int $userId 用户ID
     * @param int|null $type 通知类型
     * @return int
     */
    public static function getUnreadCount(int $userId, ?int $type = null): int
    {
        $query = Notification::where('user_id', $userId)
            ->where('is_read', 0);

        if ($type !== null) {
            $query->where('type', $type);
        }

        return $query->count();
    }

    /**
     * 清理过期通知（保留最近30天）
     * @return int 删除的记录数
     */
    public static function cleanExpired(): int
    {
        $expireDate = date('Y-m-d H:i:s', strtotime('-30 days'));

        return Notification::where('create_time', '<', $expireDate)
            ->where('is_read', 1) // 只删除已读的
            ->delete();
    }
}
