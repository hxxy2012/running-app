<?php
/**
 * 排行榜控制器
 */

namespace app\api\controller;

use app\common\model\Ranking as RankingModel;
use app\common\model\RunningRecord;
use app\common\model\Follow;

class Ranking extends Base
{
    /**
     * 总排行
     * GET /api/ranking/total
     */
    public function total()
    {
        $page = $this->request->param('page', 1);
        $pageSize = $this->request->param('page_size', 20);

        $query = RankingModel::where('type', 'total')
            ->where('scope', 'national');

        $total = $query->count();
        $list = $query->with(['user'])
            ->order('rank', 'asc')
            ->page($page, $pageSize)
            ->select()
            ->toArray();

        return $this->paginate($list, $total, $page, $pageSize);
    }

    /**
     * 月排行
     * GET /api/ranking/month
     */
    public function month()
    {
        $page = $this->request->param('page', 1);
        $pageSize = $this->request->param('page_size', 20);

        $query = RankingModel::where('type', 'month')
            ->where('scope', 'national');

        $total = $query->count();
        $list = $query->with(['user'])
            ->order('rank', 'asc')
            ->page($page, $pageSize)
            ->select()
            ->toArray();

        return $this->paginate($list, $total, $page, $pageSize);
    }

    /**
     * 周排行
     * GET /api/ranking/week
     */
    public function week()
    {
        $page = $this->request->param('page', 1);
        $pageSize = $this->request->param('page_size', 20);

        $query = RankingModel::where('type', 'week')
            ->where('scope', 'national');

        $total = $query->count();
        $list = $query->with(['user'])
            ->order('rank', 'asc')
            ->page($page, $pageSize)
            ->select()
            ->toArray();

        return $this->paginate($list, $total, $page, $pageSize);
    }

    /**
     * 好友排行
     * GET /api/ranking/friends
     */
    public function friends()
    {
        // 获取关注列表
        $followingIds = Follow::where('user_id', $this->userId)
            ->column('follow_user_id');

        $followingIds[] = $this->userId; // 包含自己

        // 统计本月数据
        $startTime = date('Y-m-01 00:00:00');
        $endTime = date('Y-m-t 23:59:59');

        $list = RunningRecord::whereIn('user_id', $followingIds)
            ->where('start_time', '>=', $startTime)
            ->where('start_time', '<=', $endTime)
            ->field('user_id, SUM(distance) as total_distance')
            ->group('user_id')
            ->order('total_distance', 'desc')
            ->with(['user'])
            ->select()
            ->toArray();

        return $this->success($list);
    }

    /**
     * 城市排行
     * GET /api/ranking/city
     */
    public function city()
    {
        $city = $this->request->param('city', '');
        $page = $this->request->param('page', 1);
        $pageSize = $this->request->param('page_size', 20);

        if (empty($city)) {
            return $this->error('请指定城市');
        }

        $query = RankingModel::where('type', 'month')
            ->where('scope', 'city')
            ->where('scope_value', $city);

        $total = $query->count();
        $list = $query->with(['user'])
            ->order('rank', 'asc')
            ->page($page, $pageSize)
            ->select()
            ->toArray();

        return $this->paginate($list, $total, $page, $pageSize);
    }
}
