<?php
/**
 * 动态模型
 */

namespace app\common\model;

use think\Model;

class Post extends Model
{
    // 设置字段信息
    protected $schema = [
        'id' => 'int',
        'user_id' => 'int',
        'record_id' => 'int',
        'content' => 'string',
        'images' => 'string',
        'location' => 'string',
        'type' => 'int',
        'topic_id' => 'int',
        'like_count' => 'int',
        'comment_count' => 'int',
        'share_count' => 'int',
        'is_public' => 'int',
        'status' => 'int',
        'create_time' => 'datetime',
    ];

    // 追加字段
    protected $append = ['images_array', 'type_text'];

    /**
     * 图片数组
     */
    public function getImagesArrayAttr($value, $data)
    {
        if (empty($data['images'])) {
            return [];
        }
        return json_decode($data['images'], true) ?: [];
    }

    /**
     * 类型文本
     */
    public function getTypeTextAttr($value, $data)
    {
        $types = [1 => '普通', 2 => '跑步分享', 3 => '话题'];
        return $types[$data['type']] ?? '普通';
    }

    /**
     * 设置图片（自动转JSON）
     */
    public function setImagesAttr($value)
    {
        return is_array($value) ? json_encode($value) : $value;
    }

    /**
     * 关联用户
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * 关联跑步记录
     */
    public function runningRecord()
    {
        return $this->belongsTo(RunningRecord::class, 'record_id');
    }

    /**
     * 关联评论
     */
    public function comments()
    {
        return $this->hasMany(Comment::class);
    }
}
