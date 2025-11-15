<?php
namespace app\common\model;
use think\Model;

class Ranking extends Model
{
    protected $schema = ['id'=>'int','user_id'=>'int','type'=>'string','scope'=>'string','scope_value'=>'string','distance'=>'float','rank'=>'int','update_time'=>'datetime'];

    public function user() {
        return $this->belongsTo(User::class);
    }
}
