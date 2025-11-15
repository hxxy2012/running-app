<?php
/**
 * 评论模型
 */

namespace app\common\model;

use think\Model;

class Comment extends Model
{
    // 设置字段信息
    protected $schema = [
        'id' => 'int',
        'user_id' => 'int',
        'post_id' => 'int',
        'parent_id' => 'int',
        'to_user_id' => 'int',
        'content' => 'string',
        'like_count' => 'int',
        'status' => 'int',
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
     * 关联回复对象
     */
    public function toUser()
    {
        return $this->belongsTo(User::class, 'to_user_id');
    }

    /**
     * 关联动态
     */
    public function post()
    {
        return $this->belongsTo(Post::class);
    }

    /**
     * 子评论
     */
    public function children()
    {
        return $this->hasMany(Comment::class, 'parent_id');
    }
}
