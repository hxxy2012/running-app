<?php
namespace app\common\model;
use think\Model;

class Message extends Model
{
    protected $schema = ['id'=>'int','user_id'=>'int','from_user_id'=>'int','type'=>'int','content'=>'string','related_type'=>'int','related_id'=>'int','is_read'=>'int','create_time'=>'datetime'];

    public function fromUser() {
        return $this->belongsTo(User::class, 'from_user_id');
    }
}
