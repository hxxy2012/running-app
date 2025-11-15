<?php
namespace app\common\model;
use think\Model;

class UserAchievement extends Model
{
    protected $schema = ['id'=>'int','user_id'=>'int','achievement_id'=>'int','unlock_time'=>'datetime'];

    public function achievement() {
        return $this->belongsTo(Achievement::class);
    }
}
