<?php
namespace app\common\model;
use think\Model;

class UserTrainingPlan extends Model
{
    protected $schema = ['id'=>'int','user_id'=>'int','plan_id'=>'int','start_date'=>'date','status'=>'int','current_week'=>'int','completed_days'=>'int','create_time'=>'datetime'];

    public function plan() {
        return $this->belongsTo(TrainingPlan::class);
    }
}
