<?php
namespace app\common\model;
use think\Model;

class TrainingPlan extends Model
{
    protected $schema = ['id'=>'int','name'=>'string','description'=>'string','target_type'=>'int','target_value'=>'string','duration_weeks'=>'int','level'=>'int','is_preset'=>'int','create_time'=>'datetime'];
}
