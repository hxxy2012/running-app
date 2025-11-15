<?php
namespace app\common\model;
use think\Model;

class Achievement extends Model
{
    protected $schema = ['id'=>'int','name'=>'string','description'=>'string','icon'=>'string','type'=>'string','condition_value'=>'int','level'=>'int','create_time'=>'datetime'];
}
