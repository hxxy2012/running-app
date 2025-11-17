<?php

namespace app\job;

use think\queue\Job;
use think\facade\Db;

/**
 * 更新统计数据任务
 *
 * 异步更新用户统计、排行榜等数据
 */
class UpdateStatisticsJob
{
    /**
     * 执行任务
     *
     * @param Job $job
     * @param array $data
     * @return void
     */
    public function fire(Job $job, $data)
    {
        try {
            switch ($data['action']) {
                case 'user_running_stats':
                    $this->updateUserRunningStats($data['user_id']);
                    break;

                case 'ranking':
                    $this->updateRanking($data['type'], $data['period']);
                    break;

                case 'achievement':
                    $this->checkUserAchievements($data['user_id']);
                    break;

                default:
                    throw new \Exception('Unknown action: ' . $data['action']);
            }

            $job->delete();

        } catch (\Exception $e) {
            trace('UpdateStatisticsJob failed: ' . $e->getMessage(), 'error');

            if ($job->attempts() < 3) {
                $job->release(30);
            } else {
                $job->delete();
            }
        }
    }

    /**
     * 更新用户跑步统计
     *
     * @param int $userId
     * @return void
     */
    private function updateUserRunningStats($userId)
    {
        $stats = Db::name('running_record')
            ->where('user_id', $userId)
            ->field([
                'COUNT(*) as total_count',
                'SUM(distance) as total_distance',
                'SUM(duration) as total_duration',
                'SUM(calories) as total_calories',
                'MAX(distance) as max_distance',
                'MIN(pace) as best_pace',
            ])
            ->find();

        Db::name('user')->where('id', $userId)->update([
            'total_runs' => $stats['total_count'],
            'total_distance' => $stats['total_distance'],
            'total_duration' => $stats['total_duration'],
            'total_calories' => $stats['total_calories'],
            'update_time' => date('Y-m-d H:i:s'),
        ]);
    }

    /**
     * 更新排行榜
     *
     * @param string $type
     * @param string $period
     * @return void
     */
    private function updateRanking($type, $period)
    {
        // 计算时间范围
        $timeRange = $this->getTimeRange($period);

        // 查询排行数据
        $rankings = Db::name('running_record')
            ->alias('r')
            ->join('user u', 'r.user_id = u.id')
            ->where('r.start_time', '>=', $timeRange['start'])
            ->where('r.start_time', '<=', $timeRange['end'])
            ->field([
                'r.user_id',
                'u.username',
                'u.avatar',
                'u.nickname',
                'SUM(r.distance) as total_distance',
                'SUM(r.duration) as total_duration',
                'COUNT(*) as total_runs',
            ])
            ->group('r.user_id')
            ->order('total_distance', 'desc')
            ->limit(100)
            ->select()
            ->toArray();

        // 清空旧数据
        Db::name('ranking')
            ->where('type', $type)
            ->where('period', $period)
            ->delete();

        // 插入新数据
        $rank = 1;
        foreach ($rankings as $item) {
            Db::name('ranking')->insert([
                'rank' => $rank++,
                'user_id' => $item['user_id'],
                'type' => $type,
                'period' => $period,
                'value' => $item['total_distance'],
                'extra_data' => json_encode([
                    'total_duration' => $item['total_duration'],
                    'total_runs' => $item['total_runs'],
                ]),
                'create_time' => date('Y-m-d H:i:s'),
            ]);
        }
    }

    /**
     * 检查用户成就
     *
     * @param int $userId
     * @return void
     */
    private function checkUserAchievements($userId)
    {
        $achievementService = new \app\common\service\AchievementService();
        $achievementService->checkAndUnlock($userId);
    }

    /**
     * 获取时间范围
     *
     * @param string $period
     * @return array
     */
    private function getTimeRange($period)
    {
        $now = time();

        switch ($period) {
            case 'daily':
                return [
                    'start' => date('Y-m-d 00:00:00'),
                    'end' => date('Y-m-d 23:59:59'),
                ];

            case 'weekly':
                $weekStart = strtotime('monday this week', $now);
                return [
                    'start' => date('Y-m-d 00:00:00', $weekStart),
                    'end' => date('Y-m-d 23:59:59', strtotime('+6 days', $weekStart)),
                ];

            case 'monthly':
                return [
                    'start' => date('Y-m-01 00:00:00'),
                    'end' => date('Y-m-t 23:59:59'),
                ];

            case 'yearly':
                return [
                    'start' => date('Y-01-01 00:00:00'),
                    'end' => date('Y-12-31 23:59:59'),
                ];

            default:
                return [
                    'start' => date('Y-m-d 00:00:00'),
                    'end' => date('Y-m-d 23:59:59'),
                ];
        }
    }

    /**
     * 任务失败处理
     */
    public function failed($data)
    {
        trace('UpdateStatisticsJob permanently failed: ' . json_encode($data), 'error');
    }
}
