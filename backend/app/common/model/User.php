<?php
/**
 * 用户模型
 */

namespace app\common\model;

use think\Model;

class User extends Model
{
    // 设置字段信息
    protected $schema = [
        'id' => 'int',
        'phone' => 'string',
        'password' => 'string',
        'nickname' => 'string',
        'avatar' => 'string',
        'gender' => 'int',
        'birthday' => 'date',
        'height' => 'float',
        'weight' => 'float',
        'city' => 'string',
        'signature' => 'string',
        'real_name' => 'string',
        'id_card' => 'string',
        'level' => 'int',
        'experience' => 'int',
        'total_distance' => 'float',
        'total_time' => 'int',
        'total_count' => 'int',
        'status' => 'int',
        'create_time' => 'datetime',
        'update_time' => 'datetime',
    ];

    // 隐藏字段
    protected $hidden = ['password'];

    // 追加字段
    protected $append = ['gender_text'];

    /**
     * 性别文本
     */
    public function getGenderTextAttr($value, $data)
    {
        $genders = [0 => '未知', 1 => '男', 2 => '女'];
        return $genders[$data['gender']] ?? '未知';
    }

    /**
     * 关联跑步记录
     */
    public function runningRecords()
    {
        return $this->hasMany(RunningRecord::class);
    }

    /**
     * 关联动态
     */
    public function posts()
    {
        return $this->hasMany(Post::class);
    }

    /**
     * 关注的人
     */
    public function following()
    {
        return $this->hasMany(Follow::class, 'user_id');
    }

    /**
     * 粉丝
     */
    public function followers()
    {
        return $this->hasMany(Follow::class, 'follow_user_id');
    }
}
