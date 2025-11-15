<?php
namespace app\common\model;
use think\Model;

class RunningClub extends Model
{
    protected $schema = ['id'=>'int','name'=>'string','logo'=>'string','description'=>'string','city'=>'string','creator_id'=>'int','member_count'=>'int','total_distance'=>'float','status'=>'int','create_time'=>'datetime'];
}
