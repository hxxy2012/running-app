<?php
/**
 * 训练计划控制器
 */

namespace app\api\controller;

use app\common\model\TrainingPlan;
use app\common\model\UserTrainingPlan;
use think\facade\Db;

class Training extends Base
{
    /**
     * 获取训练计划列表
     * GET /api/training/plans
     */
    public function plans()
    {
        $level = $this->request->param('level', 0);

        $query = TrainingPlan::where('is_preset', 1);

        if ($level > 0) {
            $query->where('level', $level);
        }

        $list = $query->select()->toArray();

        return $this->success($list);
    }

    /**
     * 训练计划详情
     * GET /api/training/plan/:id
     */
    public function planDetail()
    {
        $id = $this->request->param('id', 0);

        $plan = TrainingPlan::find($id);

        if (!$plan) {
            return $this->error('计划不存在');
        }

        return $this->success($plan->toArray());
    }

    /**
     * 加入训练计划
     * POST /api/training/join/:id
     */
    public function joinPlan()
    {
        $planId = $this->request->param('id', 0);
        $startDate = $this->request->param('start_date', date('Y-m-d'));

        $plan = TrainingPlan::find($planId);
        if (!$plan) {
            return $this->error('计划不存在');
        }

        // 检查是否已加入
        $exists = UserTrainingPlan::where('user_id', $this->userId)
            ->where('status', 1)
            ->find();

        if ($exists) {
            return $this->error('你已经有进行中的训练计划了');
        }

        try {
            UserTrainingPlan::create([
                'user_id' => $this->userId,
                'plan_id' => $planId,
                'start_date' => $startDate,
                'status' => 1,
                'current_week' => 1,
                'completed_days' => 0,
            ]);

            return $this->success([], '加入成功');

        } catch (\Exception $e) {
            return $this->error('加入失败: ' . $e->getMessage());
        }
    }

    /**
     * 我的训练计划
     * GET /api/training/my-plan
     */
    public function myPlan()
    {
        $userPlan = UserTrainingPlan::where('user_id', $this->userId)
            ->where('status', 1)
            ->with(['plan'])
            ->find();

        if (!$userPlan) {
            return $this->success(null);
        }

        return $this->success($userPlan->toArray());
    }

    /**
     * 完成某天训练
     * PUT /api/training/complete-day
     */
    public function completeDay()
    {
        $userPlan = UserTrainingPlan::where('user_id', $this->userId)
            ->where('status', 1)
            ->find();

        if (!$userPlan) {
            return $this->error('你还没有训练计划');
        }

        $userPlan->completed_days += 1;
        $userPlan->save();

        return $this->success([], '打卡成功');
    }

    /**
     * 放弃计划
     * PUT /api/training/abandon
     */
    public function abandonPlan()
    {
        $userPlan = UserTrainingPlan::where('user_id', $this->userId)
            ->where('status', 1)
            ->find();

        if (!$userPlan) {
            return $this->error('你还没有训练计划');
        }

        $userPlan->status = 3; // 已放弃
        $userPlan->save();

        return $this->success([], '已放弃训练计划');
    }
}
