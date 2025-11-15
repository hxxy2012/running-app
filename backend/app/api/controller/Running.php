<?php
/**
 * 跑步记录控制器
 */

namespace app\api\controller;

use app\common\model\RunningRecord;
use app\common\model\TrackPoint;
use app\common\model\User;
use think\facade\Db;

class Running extends Base
{
    /**
     * 开始跑步
     * POST /api/running/start
     */
    public function start()
    {
        $type = $this->request->param('type', 1); // 运动类型

        try {
            // 创建跑步记录
            $record = RunningRecord::create([
                'user_id' => $this->userId,
                'type' => $type,
                'distance' => 0,
                'duration' => 0,
                'start_time' => date('Y-m-d H:i:s'),
                'end_time' => date('Y-m-d H:i:s'),
                'is_public' => 1,
            ]);

            return $this->success([
                'record_id' => $record->id,
            ], '开始跑步');

        } catch (\Exception $e) {
            return $this->error('创建失败: ' . $e->getMessage());
        }
    }

    /**
     * 上传轨迹点（批量）
     * POST /api/running/upload-point
     */
    public function uploadPoint()
    {
        $recordId = $this->request->param('record_id', 0);
        $points = $this->request->param('points', []);

        if (!$recordId || empty($points)) {
            return $this->error('参数错误');
        }

        // 验证记录是否属于当前用户
        $record = RunningRecord::where('id', $recordId)
            ->where('user_id', $this->userId)
            ->find();

        if (!$record) {
            return $this->error('记录不存在');
        }

        try {
            // 批量插入轨迹点
            $insertData = [];
            foreach ($points as $point) {
                $insertData[] = [
                    'record_id' => $recordId,
                    'latitude' => $point['latitude'] ?? 0,
                    'longitude' => $point['longitude'] ?? 0,
                    'altitude' => $point['altitude'] ?? null,
                    'accuracy' => $point['accuracy'] ?? null,
                    'speed' => $point['speed'] ?? null,
                    'heart_rate' => $point['heart_rate'] ?? null,
                    'timestamp' => $point['timestamp'] ?? time() * 1000,
                    'distance_from_start' => $point['distance_from_start'] ?? 0,
                ];
            }

            if (!empty($insertData)) {
                Db::name('track_point')->insertAll($insertData);
            }

            // 计算当前统计数据（简化处理）
            $totalPoints = TrackPoint::where('record_id', $recordId)->count();
            $latestPoint = TrackPoint::where('record_id', $recordId)
                ->order('timestamp', 'desc')
                ->find();

            return $this->success([
                'total_points' => $totalPoints,
                'distance' => $latestPoint ? $latestPoint->distance_from_start : 0,
            ], '上传成功');

        } catch (\Exception $e) {
            return $this->error('上传失败: ' . $e->getMessage());
        }
    }

    /**
     * 结束跑步
     * POST /api/running/finish
     */
    public function finish()
    {
        $recordId = $this->request->param('record_id', 0);
        $data = $this->request->param();

        $record = RunningRecord::where('id', $recordId)
            ->where('user_id', $this->userId)
            ->find();

        if (!$record) {
            return $this->error('记录不存在');
        }

        try {
            Db::startTrans();

            // 更新记录
            $record->distance = $data['distance'] ?? 0;
            $record->duration = $data['duration'] ?? 0;
            $record->avg_pace = $data['avg_pace'] ?? null;
            $record->best_pace = $data['best_pace'] ?? null;
            $record->avg_speed = $data['avg_speed'] ?? null;
            $record->step_count = $data['step_count'] ?? null;
            $record->step_frequency = $data['step_frequency'] ?? null;
            $record->calories = $data['calories'] ?? null;
            $record->climb = $data['climb'] ?? 0;
            $record->descent = $data['descent'] ?? 0;
            $record->avg_heart_rate = $data['avg_heart_rate'] ?? null;
            $record->max_heart_rate = $data['max_heart_rate'] ?? null;
            $record->end_time = $data['end_time'] ?? date('Y-m-d H:i:s');
            $record->start_location = $data['start_location'] ?? null;
            $record->city = $data['city'] ?? null;
            $record->weather = $data['weather'] ?? null;
            $record->temperature = $data['temperature'] ?? null;
            $record->save();

            // 更新用户总数据
            $user = User::find($this->userId);
            $user->total_distance += $record->distance;
            $user->total_time += $record->duration;
            $user->total_count += 1;
            $user->save();

            // TODO: 检查成就解锁
            // TODO: 检查挑战进度

            Db::commit();

            return $this->success([
                'record' => $record->toArray(),
            ], '跑步完成');

        } catch (\Exception $e) {
            Db::rollback();
            return $this->error('保存失败: ' . $e->getMessage());
        }
    }

    /**
     * 获取记录列表
     * GET /api/running/records
     */
    public function records()
    {
        $page = $this->request->param('page', 1);
        $pageSize = $this->request->param('page_size', 20);
        $type = $this->request->param('type', 0);
        $startDate = $this->request->param('start_date', '');
        $endDate = $this->request->param('end_date', '');

        $query = RunningRecord::where('user_id', $this->userId);

        if ($type > 0) {
            $query->where('type', $type);
        }

        if ($startDate) {
            $query->where('start_time', '>=', $startDate . ' 00:00:00');
        }

        if ($endDate) {
            $query->where('start_time', '<=', $endDate . ' 23:59:59');
        }

        $total = $query->count();
        $list = $query->order('start_time', 'desc')
            ->page($page, $pageSize)
            ->select()
            ->toArray();

        return $this->paginate($list, $total, $page, $pageSize);
    }

    /**
     * 记录详情
     * GET /api/running/record/:id
     */
    public function recordDetail()
    {
        $id = $this->request->param('id', 0);

        $record = RunningRecord::where('id', $id)
            ->where('user_id', $this->userId)
            ->find();

        if (!$record) {
            return $this->error('记录不存在');
        }

        // 获取轨迹点
        $trackPoints = TrackPoint::where('record_id', $id)
            ->order('timestamp', 'asc')
            ->select()
            ->toArray();

        $data = $record->toArray();
        $data['track_points'] = $trackPoints;

        return $this->success($data);
    }

    /**
     * 编辑记录
     * PUT /api/running/record/:id
     */
    public function updateRecord()
    {
        $id = $this->request->param('id', 0);
        $note = $this->request->param('note', '');
        $feeling = $this->request->param('feeling', 0);
        $isPublic = $this->request->param('is_public', 1);

        $record = RunningRecord::where('id', $id)
            ->where('user_id', $this->userId)
            ->find();

        if (!$record) {
            return $this->error('记录不存在');
        }

        $record->note = $note;
        $record->feeling = $feeling;
        $record->is_public = $isPublic;
        $record->save();

        return $this->success([], '更新成功');
    }

    /**
     * 删除记录
     * DELETE /api/running/record/:id
     */
    public function deleteRecord()
    {
        $id = $this->request->param('id', 0);

        $record = RunningRecord::where('id', $id)
            ->where('user_id', $this->userId)
            ->find();

        if (!$record) {
            return $this->error('记录不存在');
        }

        try {
            Db::startTrans();

            // 删除轨迹点
            TrackPoint::where('record_id', $id)->delete();

            // 删除记录
            $record->delete();

            // 更新用户总数据
            $user = User::find($this->userId);
            $user->total_distance -= $record->distance;
            $user->total_time -= $record->duration;
            $user->total_count -= 1;
            $user->save();

            Db::commit();

            return $this->success([], '删除成功');

        } catch (\Exception $e) {
            Db::rollback();
            return $this->error('删除失败: ' . $e->getMessage());
        }
    }

    /**
     * 统计数据
     * GET /api/running/statistics
     */
    public function statistics()
    {
        $type = $this->request->param('type', 'today'); // today/week/month/year

        $startTime = '';
        $endTime = date('Y-m-d 23:59:59');

        switch ($type) {
            case 'today':
                $startTime = date('Y-m-d 00:00:00');
                break;
            case 'week':
                $startTime = date('Y-m-d 00:00:00', strtotime('this week'));
                break;
            case 'month':
                $startTime = date('Y-m-01 00:00:00');
                break;
            case 'year':
                $startTime = date('Y-01-01 00:00:00');
                break;
        }

        // 统计数据
        $stats = RunningRecord::where('user_id', $this->userId)
            ->where('start_time', '>=', $startTime)
            ->where('start_time', '<=', $endTime)
            ->field([
                'COUNT(*) as count',
                'SUM(distance) as total_distance',
                'SUM(duration) as total_duration',
                'AVG(avg_pace) as avg_pace',
                'MIN(best_pace) as best_pace',
            ])
            ->find();

        return $this->success([
            'count' => $stats->count ?? 0,
            'total_distance' => $stats->total_distance ?? 0,
            'total_duration' => $stats->total_duration ?? 0,
            'avg_pace' => $stats->avg_pace ?? 0,
            'best_pace' => $stats->best_pace ?? 0,
        ]);
    }

    /**
     * 日历数据
     * GET /api/running/calendar
     */
    public function calendar()
    {
        $year = $this->request->param('year', date('Y'));
        $month = $this->request->param('month', date('m'));

        $startDate = $year . '-' . $month . '-01 00:00:00';
        $endDate = date('Y-m-t 23:59:59', strtotime($startDate));

        $records = RunningRecord::where('user_id', $this->userId)
            ->where('start_time', '>=', $startDate)
            ->where('start_time', '<=', $endDate)
            ->field('DATE(start_time) as date, SUM(distance) as distance, COUNT(*) as count')
            ->group('DATE(start_time)')
            ->select()
            ->toArray();

        return $this->success($records);
    }

    /**
     * PB记录（Personal Best）
     * GET /api/running/pb
     */
    public function pb()
    {
        // 最快配速
        $fastestPace = RunningRecord::where('user_id', $this->userId)
            ->where('best_pace', '>', 0)
            ->order('best_pace', 'asc')
            ->find();

        // 最长距离
        $longestDistance = RunningRecord::where('user_id', $this->userId)
            ->order('distance', 'desc')
            ->find();

        // 最长时间
        $longestDuration = RunningRecord::where('user_id', $this->userId)
            ->order('duration', 'desc')
            ->find();

        return $this->success([
            'fastest_pace' => $fastestPace ? $fastestPace->toArray() : null,
            'longest_distance' => $longestDistance ? $longestDistance->toArray() : null,
            'longest_duration' => $longestDuration ? $longestDuration->toArray() : null,
        ]);
    }

    /**
     * 生成分享海报
     * POST /api/running/share
     */
    public function share()
    {
        $recordId = $this->request->param('record_id', 0);

        // 这里应该生成精美的分享海报图片
        // 简化处理，返回记录信息

        $record = RunningRecord::where('id', $recordId)
            ->where('user_id', $this->userId)
            ->find();

        if (!$record) {
            return $this->error('记录不存在');
        }

        return $this->success([
            'share_url' => config('app.api_domain') . '/share/running/' . $recordId,
            'share_image' => config('app.api_domain') . '/share/poster/' . $recordId . '.png',
        ], '生成成功');
    }
}
