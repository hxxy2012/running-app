<?php
/**
 * 挑战服务类
 */

namespace app\common\service;

use app\common\model\Challenge;
use app\common\model\ChallengeParticipant;
use app\common\model\RunningRecord;
use think\facade\Db;

class ChallengeService
{
    /**
     * 更新挑战进度
     * @param int $userId 用户ID
     * @param RunningRecord $record 跑步记录
     * @return array 更新的挑战列表
     */
    public static function updateProgress(int $userId, RunningRecord $record): array
    {
        // 获取用户参与的进行中的挑战
        $participants = ChallengeParticipant::alias('cp')
            ->join('challenge c', 'cp.challenge_id = c.id')
            ->where('cp.user_id', $userId)
            ->where('cp.status', 1) // 进行中
            ->where('c.status', 1) // 挑战进行中
            ->where('c.start_time', '<=', date('Y-m-d H:i:s'))
            ->where('c.end_time', '>=', date('Y-m-d H:i:s'))
            ->field('cp.*, c.type, c.target_value')
            ->select();

        $updatedChallenges = [];

        foreach ($participants as $participant) {
            try {
                $challenge = Challenge::find($participant->challenge_id);
                if (!$challenge) {
                    continue;
                }

                // 根据挑战类型计算进度
                $progress = self::calculateChallengeProgress(
                    $userId,
                    $challenge,
                    $record
                );

                // 更新参与记录
                $oldProgress = $participant->current_value;
                $participant->current_value = $progress['current'];
                $participant->progress = $progress['percentage'];

                // 检查是否完成
                if ($progress['percentage'] >= 100 && $participant->status == 1) {
                    $participant->status = 2; // 已完成
                    $participant->complete_time = date('Y-m-d H:i:s');
                }

                $participant->save();

                // 如果进度有变化，记录到返回数组
                if ($participant->current_value != $oldProgress) {
                    $updatedChallenges[] = [
                        'challenge' => $challenge->toArray(),
                        'participant' => $participant->toArray(),
                        'is_newly_completed' => $participant->status == 2 && $oldProgress < $challenge->target_value,
                    ];
                }

            } catch (\Exception $e) {
                // 记录错误但不中断流程
                trace('Challenge progress update failed: ' . $e->getMessage(), 'error');
            }
        }

        return $updatedChallenges;
    }

    /**
     * 计算挑战进度
     * @param int $userId
     * @param Challenge $challenge
     * @param RunningRecord $newRecord 新记录（用于实时更新）
     * @return array ['current' => 当前值, 'percentage' => 百分比]
     */
    private static function calculateChallengeProgress(int $userId, Challenge $challenge, RunningRecord $newRecord = null): array
    {
        $current = 0;

        // 查询条件：挑战期间的记录
        $query = RunningRecord::where('user_id', $userId)
            ->where('start_time', '>=', $challenge->start_time)
            ->where('end_time', '<=', $challenge->end_time);

        switch ($challenge->type) {
            case 1: // 总距离挑战
                $current = $query->sum('distance');
                break;

            case 2: // 总次数挑战
                $current = $query->count();
                break;

            case 3: // 总时长挑战
                $current = $query->sum('duration');
                break;

            case 4: // 单次距离挑战
                $maxDistance = $query->max('distance');
                $current = max($maxDistance, $newRecord ? $newRecord->distance : 0);
                break;

            case 5: // 单次时长挑战
                $maxDuration = $query->max('duration');
                $current = max($maxDuration, $newRecord ? $newRecord->duration : 0);
                break;

            case 6: // 平均配速挑战（配速越小越好）
                $avgPace = $query->where('avg_pace', '>', 0)->avg('avg_pace');
                $current = $avgPace ?: 0;
                break;

            case 7: // 连续天数挑战
                $current = self::getContinuousDaysInPeriod(
                    $userId,
                    $challenge->start_time,
                    $challenge->end_time
                );
                break;

            default:
                $current = 0;
        }

        // 计算百分比
        $percentage = 0;
        if ($challenge->target_value > 0) {
            // 配速类型的挑战，进度计算方式相反
            if ($challenge->type == 6) {
                $percentage = $current > 0 ? min(100, ($challenge->target_value / $current) * 100) : 0;
            } else {
                $percentage = min(100, ($current / $challenge->target_value) * 100);
            }
        }

        return [
            'current' => $current,
            'percentage' => round($percentage, 2),
        ];
    }

    /**
     * 获取指定时间段内的连续跑步天数
     * @param int $userId
     * @param string $startTime
     * @param string $endTime
     * @return int
     */
    private static function getContinuousDaysInPeriod(int $userId, string $startTime, string $endTime): int
    {
        $records = RunningRecord::where('user_id', $userId)
            ->where('start_time', '>=', $startTime)
            ->where('end_time', '<=', $endTime)
            ->field('DATE(start_time) as run_date')
            ->group('run_date')
            ->order('run_date', 'desc')
            ->select()
            ->toArray();

        if (empty($records)) {
            return 0;
        }

        $maxContinuous = 1;
        $currentContinuous = 1;

        for ($i = 1; $i < count($records); $i++) {
            $prevDate = $records[$i - 1]['run_date'];
            $currDate = $records[$i]['run_date'];

            $expectedDate = date('Y-m-d', strtotime($prevDate . ' -1 day'));

            if ($currDate == $expectedDate) {
                $currentContinuous++;
                $maxContinuous = max($maxContinuous, $currentContinuous);
            } else {
                $currentContinuous = 1;
            }
        }

        return $maxContinuous;
    }

    /**
     * 检查挑战是否过期并更新状态
     * @return int 更新的记录数
     */
    public static function checkExpired(): int
    {
        $now = date('Y-m-d H:i:s');

        // 更新过期的挑战
        $count = Challenge::where('status', 1)
            ->where('end_time', '<', $now)
            ->update(['status' => 3]); // 已结束

        // 更新过期未完成的参与记录
        $participants = ChallengeParticipant::alias('cp')
            ->join('challenge c', 'cp.challenge_id = c.id')
            ->where('cp.status', 1)
            ->where('c.end_time', '<', $now)
            ->field('cp.id')
            ->select();

        foreach ($participants as $participant) {
            ChallengeParticipant::where('id', $participant->id)
                ->update(['status' => 3]); // 已过期
        }

        return $count;
    }

    /**
     * 获取挑战排行榜
     * @param int $challengeId
     * @param int $limit
     * @return array
     */
    public static function getRanking(int $challengeId, int $limit = 50): array
    {
        return ChallengeParticipant::alias('cp')
            ->join('user u', 'cp.user_id = u.id')
            ->where('cp.challenge_id', $challengeId)
            ->field('cp.*, u.nickname, u.avatar, u.gender')
            ->order('cp.current_value', 'desc')
            ->order('cp.complete_time', 'asc')
            ->limit($limit)
            ->select()
            ->toArray();
    }
}
