<?php
/**
 * 跑步记录模型
 */

namespace app\common\model;

use think\Model;

class RunningRecord extends Model
{
    // 设置字段信息
    protected $schema = [
        'id' => 'int',
        'user_id' => 'int',
        'type' => 'int',
        'distance' => 'float',
        'duration' => 'int',
        'avg_pace' => 'int',
        'best_pace' => 'int',
        'avg_speed' => 'float',
        'step_count' => 'int',
        'step_frequency' => 'int',
        'calories' => 'int',
        'climb' => 'float',
        'descent' => 'float',
        'avg_heart_rate' => 'int',
        'max_heart_rate' => 'int',
        'track_file' => 'string',
        'map_image' => 'string',
        'start_time' => 'datetime',
        'end_time' => 'datetime',
        'start_location' => 'string',
        'city' => 'string',
        'weather' => 'string',
        'temperature' => 'int',
        'feeling' => 'int',
        'note' => 'string',
        'is_public' => 'int',
        'share_count' => 'int',
        'like_count' => 'int',
        'comment_count' => 'int',
        'create_time' => 'datetime',
    ];

    // 追加字段
    protected $append = ['type_text', 'feeling_text', 'duration_text'];

    /**
     * 运动类型文本
     */
    public function getTypeTextAttr($value, $data)
    {
        $types = [1 => '跑步', 2 => '骑行', 3 => '健走', 4 => '登山', 5 => '室内跑'];
        return $types[$data['type']] ?? '未知';
    }

    /**
     * 感觉文本
     */
    public function getFeelingTextAttr($value, $data)
    {
        $feelings = [0 => '一般', 1 => '轻松', 2 => '良好', 3 => '困难', 4 => '痛苦'];
        return $feelings[$data['feeling']] ?? '一般';
    }

    /**
     * 时长文本（格式化为HH:MM:SS）
     */
    public function getDurationTextAttr($value, $data)
    {
        $duration = $data['duration'] ?? 0;
        $hours = floor($duration / 3600);
        $minutes = floor(($duration % 3600) / 60);
        $seconds = $duration % 60;
        return sprintf('%02d:%02d:%02d', $hours, $minutes, $seconds);
    }

    /**
     * 关联用户
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * 关联轨迹点
     */
    public function trackPoints()
    {
        return $this->hasMany(TrackPoint::class, 'record_id');
    }
}
