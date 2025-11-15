<?php
/**
 * 轨迹点模型
 */

namespace app\common\model;

use think\Model;

class TrackPoint extends Model
{
    // 设置字段信息
    protected $schema = [
        'id' => 'int',
        'record_id' => 'int',
        'latitude' => 'float',
        'longitude' => 'float',
        'altitude' => 'float',
        'accuracy' => 'float',
        'speed' => 'float',
        'heart_rate' => 'int',
        'timestamp' => 'int',
        'distance_from_start' => 'float',
    ];

    /**
     * 关联跑步记录
     */
    public function record()
    {
        return $this->belongsTo(RunningRecord::class, 'record_id');
    }
}
