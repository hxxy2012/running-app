<?php
/**
 * 成就控制器
 */

namespace app\api\controller;

use app\common\model\Achievement as AchievementModel;
use app\common\model\UserAchievement;

class Achievement extends Base
{
    /**
     * 成就列表
     * GET /api/achievement/list
     */
    public function list()
    {
        $list = AchievementModel::order('level', 'asc')
            ->order('condition_value', 'asc')
            ->select()
            ->toArray();

        return $this->success($list);
    }

    /**
     * 我的成就
     * GET /api/achievement/my
     */
    public function myAchievements()
    {
        $list = UserAchievement::where('user_id', $this->userId)
            ->with(['achievement'])
            ->order('unlock_time', 'desc')
            ->select()
            ->toArray();

        return $this->success($list);
    }
}
