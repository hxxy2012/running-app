<?php
namespace app\common\model;
use think\Model;

class Challenge extends Model
{
    protected $schema = ['id'=>'int','name'=>'string','description'=>'string','type'=>'int','target_value'=>'int','start_time'=>'datetime','end_time'=>'datetime','badge_image'=>'string','participant_count'=>'int','status'=>'int','create_time'=>'datetime'];
}
