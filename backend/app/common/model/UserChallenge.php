<?php
namespace app\common\model;
use think\Model;

class UserChallenge extends Model
{
    protected $schema = ['id'=>'int','user_id'=>'int','challenge_id'=>'int','progress'=>'float','current_value'=>'float','status'=>'int','complete_time'=>'datetime','join_time'=>'datetime'];

    public function user() {
        return $this->belongsTo(User::class);
    }

    public function challenge() {
        return $this->belongsTo(Challenge::class);
    }
}
