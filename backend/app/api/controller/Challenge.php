<?php
/**
 * 挑战赛控制器
 */

namespace app\api\controller;

use app\common\model\Challenge as ChallengeModel;
use app\common\model\UserChallenge;
use think\facade\Db;

class Challenge extends Base
{
    /**
     * 挑战列表
     * GET /api/challenge/list
     */
    public function list()
    {
        $status = $this->request->param('status', 'ongoing'); // ongoing/upcoming/finished

        $query = ChallengeModel::where('status', 1);

        $now = date('Y-m-d H:i:s');

        switch ($status) {
            case 'ongoing':
                $query->where('start_time', '<=', $now)
                      ->where('end_time', '>=', $now);
                break;
            case 'upcoming':
                $query->where('start_time', '>', $now);
                break;
            case 'finished':
                $query->where('end_time', '<', $now);
                break;
        }

        $list = $query->select()->toArray();

        return $this->success($list);
    }

    /**
     * 挑战详情
     * GET /api/challenge/:id
     */
    public function detail()
    {
        $id = $this->request->param('id', 0);

        $challenge = ChallengeModel::find($id);

        if (!$challenge) {
            return $this->error('挑战不存在');
        }

        $data = $challenge->toArray();

        // 检查是否已参加
        $userChallenge = UserChallenge::where('user_id', $this->userId)
            ->where('challenge_id', $id)
            ->find();

        $data['is_joined'] = $userChallenge ? true : false;
        $data['my_progress'] = $userChallenge ? $userChallenge->toArray() : null;

        return $this->success($data);
    }

    /**
     * 参加挑战
     * POST /api/challenge/:id/join
     */
    public function join()
    {
        $id = $this->request->param('id', 0);

        $challenge = ChallengeModel::find($id);

        if (!$challenge) {
            return $this->error('挑战不存在');
        }

        // 检查是否已参加
        $exists = UserChallenge::where('user_id', $this->userId)
            ->where('challenge_id', $id)
            ->find();

        if ($exists) {
            return $this->error('你已经参加过这个挑战了');
        }

        try {
            Db::startTrans();

            UserChallenge::create([
                'user_id' => $this->userId,
                'challenge_id' => $id,
                'progress' => 0,
                'current_value' => 0,
                'status' => 1,
            ]);

            // 更新参与人数
            $challenge->participant_count += 1;
            $challenge->save();

            Db::commit();

            return $this->success([], '参加成功');

        } catch (\Exception $e) {
            Db::rollback();
            return $this->error('参加失败: ' . $e->getMessage());
        }
    }

    /**
     * 挑战排行榜
     * GET /api/challenge/:id/ranking
     */
    public function ranking()
    {
        $id = $this->request->param('id', 0);
        $page = $this->request->param('page', 1);
        $pageSize = $this->request->param('page_size', 20);

        $query = UserChallenge::where('challenge_id', $id);

        $total = $query->count();
        $list = $query->with(['user'])
            ->order('current_value', 'desc')
            ->page($page, $pageSize)
            ->select()
            ->toArray();

        return $this->paginate($list, $total, $page, $pageSize);
    }

    /**
     * 我的挑战
     * GET /api/challenge/my
     */
    public function myChallenges()
    {
        $status = $this->request->param('status', 1); // 1进行中 2已完成

        $list = UserChallenge::where('user_id', $this->userId)
            ->where('status', $status)
            ->with(['challenge'])
            ->select()
            ->toArray();

        return $this->success($list);
    }
}
