<?php
namespace app\common\model;
use think\Model;

class Equipment extends Model
{
    protected $schema = ['id'=>'int','user_id'=>'int','type'=>'int','brand'=>'string','model'=>'string','purchase_date'=>'date','mileage'=>'float','status'=>'int','note'=>'string','create_time'=>'datetime'];
}
