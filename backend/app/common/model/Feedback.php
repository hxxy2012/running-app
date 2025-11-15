<?php
namespace app\common\model;
use think\Model;

class Feedback extends Model
{
    protected $schema = ['id'=>'int','user_id'=>'int','type'=>'int','content'=>'string','images'=>'string','contact'=>'string','status'=>'int','reply'=>'string','create_time'=>'datetime'];
}
