<?php
namespace app\common\model;
use think\Model;

class ClubMember extends Model
{
    protected $schema = ['id'=>'int','club_id'=>'int','user_id'=>'int','role'=>'int','join_time'=>'datetime'];

    public function user() {
        return $this->belongsTo(User::class);
    }
}
