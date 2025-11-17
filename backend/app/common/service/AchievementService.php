<?php
/**
 * 成就服务类
 */

namespace app\common\service;

use app\common\model\Achievement;
use app\common\model\UserAchievement;
use app\common\model\User;
use app\common\model\RunningRecord;
use think\facade\Db;

class AchievementService
{
    /**
     * 检查并解锁成就
     * @param int $userId 用户ID
     * @param RunningRecord $record 跑步记录
     * @return array 新解锁的成就列表
     */
    public static function checkAndUnlock(int $userId, RunningRecord $record): array
    {
        $user = User::find($userId);
        if (!$user) {
            return [];
        }

        $newAchievements = [];

        // 获取所有成就
        $achievements = Achievement::where('is_active', 1)->select();

        foreach ($achievements as $achievement) {
            // 检查是否已解锁
            $exists = UserAchievement::where('user_id', $userId)
                ->where('achievement_id', $achievement->id)
                ->find();

            if ($exists) {
                continue; // 已解锁，跳过
            }

            // 检查是否符合条件
            if (self::checkCondition($user, $record, $achievement)) {
                try {
                    // 创建用户成就记录
                    UserAchievement::create([
                        'user_id' => $userId,
                        'achievement_id' => $achievement->id,
                        'unlock_time' => date('Y-m-d H:i:s'),
                    ]);

                    $newAchievements[] = $achievement->toArray();
                } catch (\Exception $e) {
                    // 记录错误但不中断流程
                    trace('Achievement unlock failed: ' . $e->getMessage(), 'error');
                }
            }
        }

        return $newAchievements;
    }

    /**
     * 检查是否符合成就条件
     * @param User $user 用户
     * @param RunningRecord $record 跑步记录
     * @param Achievement $achievement 成就
     * @return bool
     */
    private static function checkCondition(User $user, RunningRecord $record, Achievement $achievement): bool
    {
        $condition = json_decode($achievement->condition, true);

        if (!$condition || !isset($condition['type'])) {
            return false;
        }

        switch ($condition['type']) {
            case 'total_distance':
                // 累计距离成就
                return $user->total_distance >= ($condition['value'] ?? 0);

            case 'total_count':
                // 累计次数成就
                return $user->total_count >= ($condition['value'] ?? 0);

            case 'total_time':
                // 累计时长成就
                return $user->total_time >= ($condition['value'] ?? 0);

            case 'single_distance':
                // 单次距离成就
                return $record->distance >= ($condition['value'] ?? 0);

            case 'single_duration':
                // 单次时长成就
                return $record->duration >= ($condition['value'] ?? 0);

            case 'avg_pace':
                // 平均配速成就（配速越小越好）
                return $record->avg_pace && $record->avg_pace <= ($condition['value'] ?? 999);

            case 'continuous_days':
                // 连续跑步天数成就
                $days = self::getContinuousDays($user->id);
                return $days >= ($condition['value'] ?? 0);

            case 'month_count':
                // 本月跑步次数
                $count = RunningRecord::where('user_id', $user->id)
                    ->whereMonth('start_time', date('m'))
                    ->count();
                return $count >= ($condition['value'] ?? 0);

            case 'month_distance':
                // 本月跑步距离
                $distance = RunningRecord::where('user_id', $user->id)
                    ->whereMonth('start_time', date('m'))
                    ->sum('distance');
                return $distance >= ($condition['value'] ?? 0);

            default:
                return false;
        }
    }

    /**
     * 获取连续跑步天数
     * @param int $userId
     * @return int
     */
    private static function getContinuousDays(int $userId): int
    {
        // 获取最近的记录，按日期分组
        $records = RunningRecord::where('user_id', $userId)
            ->field('DATE(start_time) as run_date')
            ->group('run_date')
            ->order('run_date', 'desc')
            ->limit(365)
            ->select()
            ->toArray();

        if (empty($records)) {
            return 0;
        }

        $continuousDays = 0;
        $currentDate = date('Y-m-d');
        $yesterday = date('Y-m-d', strtotime('-1 day'));

        // 检查今天或昨天是否有记录
        $firstRecordDate = $records[0]['run_date'];
        if ($firstRecordDate != $currentDate && $firstRecordDate != $yesterday) {
            return 0;
        }

        $continuousDays = 1;
        $expectedDate = date('Y-m-d', strtotime($firstRecordDate . ' -1 day'));

        for ($i = 1; $i < count($records); $i++) {
            if ($records[$i]['run_date'] == $expectedDate) {
                $continuousDays++;
                $expectedDate = date('Y-m-d', strtotime($expectedDate . ' -1 day'));
            } else {
                break;
            }
        }

        return $continuousDays;
    }

    /**
     * 获取用户成就进度
     * @param int $userId
     * @return array
     */
    public static function getProgress(int $userId): array
    {
        $user = User::find($userId);
        if (!$user) {
            return [];
        }

        $achievements = Achievement::where('is_active', 1)->select();
        $userAchievements = UserAchievement::where('user_id', $userId)->column('achievement_id');

        $result = [];
        foreach ($achievements as $achievement) {
            $unlocked = in_array($achievement->id, $userAchievements);
            $progress = 0;

            if (!$unlocked) {
                $progress = self::calculateProgress($user, $achievement);
            }

            $result[] = [
                'achievement' => $achievement->toArray(),
                'unlocked' => $unlocked,
                'progress' => $unlocked ? 100 : $progress,
            ];
        }

        return $result;
    }

    /**
     * 计算成就进度
     * @param User $user
     * @param Achievement $achievement
     * @return int 进度百分比
     */
    private static function calculateProgress(User $user, Achievement $achievement): int
    {
        $condition = json_decode($achievement->condition, true);
        if (!$condition || !isset($condition['type']) || !isset($condition['value'])) {
            return 0;
        }

        $target = $condition['value'];
        $current = 0;

        switch ($condition['type']) {
            case 'total_distance':
                $current = $user->total_distance;
                break;
            case 'total_count':
                $current = $user->total_count;
                break;
            case 'total_time':
                $current = $user->total_time;
                break;
            case 'continuous_days':
                $current = self::getContinuousDays($user->id);
                break;
        }

        if ($target == 0) {
            return 0;
        }

        return min(100, intval(($current / $target) * 100));
    }
}
