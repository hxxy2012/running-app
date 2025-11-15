<?php
/**
 * 跑团控制器
 */

namespace app\api\controller;

use app\common\model\RunningClub;
use app\common\model\ClubMember;
use think\facade\Db;

class Club extends Base
{
    /**
     * 创建跑团
     * POST /api/club
     */
    public function create()
    {
        $name = $this->request->param('name', '');
        $description = $this->request->param('description', '');
        $city = $this->request->param('city', '');

        if (empty($name)) {
            return $this->error('跑团名称不能为空');
        }

        try {
            Db::startTrans();

            // 创建跑团
            $club = RunningClub::create([
                'name' => $name,
                'description' => $description,
                'city' => $city,
                'creator_id' => $this->userId,
                'member_count' => 1,
                'status' => 1,
            ]);

            // 添加创建者为团长
            ClubMember::create([
                'club_id' => $club->id,
                'user_id' => $this->userId,
                'role' => 3, // 团长
            ]);

            Db::commit();

            return $this->success($club->toArray(), '创建成功');

        } catch (\Exception $e) {
            Db::rollback();
            return $this->error('创建失败: ' . $e->getMessage());
        }
    }

    /**
     * 跑团列表
     * GET /api/club/list
     */
    public function list()
    {
        $page = $this->request->param('page', 1);
        $pageSize = $this->request->param('page_size', 20);
        $city = $this->request->param('city', '');

        $query = RunningClub::where('status', 1);

        if ($city) {
            $query->where('city', $city);
        }

        $total = $query->count();
        $list = $query->order('create_time', 'desc')
            ->page($page, $pageSize)
            ->select()
            ->toArray();

        return $this->paginate($list, $total, $page, $pageSize);
    }

    /**
     * 跑团详情
     * GET /api/club/:id
     */
    public function detail()
    {
        $id = $this->request->param('id', 0);

        $club = RunningClub::find($id);

        if (!$club || $club->status != 1) {
            return $this->error('跑团不存在');
        }

        $data = $club->toArray();

        // 检查是否已加入
        $member = ClubMember::where('club_id', $id)
            ->where('user_id', $this->userId)
            ->find();

        $data['is_joined'] = $member ? true : false;
        $data['my_role'] = $member ? $member->role : 0;

        return $this->success($data);
    }

    /**
     * 加入跑团
     * POST /api/club/:id/join
     */
    public function join()
    {
        $id = $this->request->param('id', 0);

        $club = RunningClub::find($id);

        if (!$club || $club->status != 1) {
            return $this->error('跑团不存在');
        }

        // 检查是否已加入
        $exists = ClubMember::where('club_id', $id)
            ->where('user_id', $this->userId)
            ->find();

        if ($exists) {
            return $this->error('你已经是该跑团成员了');
        }

        try {
            Db::startTrans();

            ClubMember::create([
                'club_id' => $id,
                'user_id' => $this->userId,
                'role' => 1, // 普通成员
            ]);

            // 更新成员数
            $club->member_count += 1;
            $club->save();

            Db::commit();

            return $this->success([], '加入成功');

        } catch (\Exception $e) {
            Db::rollback();
            return $this->error('加入失败: ' . $e->getMessage());
        }
    }

    /**
     * 退出跑团
     * DELETE /api/club/:id/quit
     */
    public function quit()
    {
        $id = $this->request->param('id', 0);

        $member = ClubMember::where('club_id', $id)
            ->where('user_id', $this->userId)
            ->find();

        if (!$member) {
            return $this->error('你不是该跑团成员');
        }

        if ($member->role == 3) {
            return $this->error('团长不能退出跑团');
        }

        try {
            Db::startTrans();

            $member->delete();

            // 更新成员数
            $club = RunningClub::find($id);
            $club->member_count = max(0, $club->member_count - 1);
            $club->save();

            Db::commit();

            return $this->success([], '退出成功');

        } catch (\Exception $e) {
            Db::rollback();
            return $this->error('退出失败: ' . $e->getMessage());
        }
    }

    /**
     * 成员列表
     * GET /api/club/:id/members
     */
    public function members()
    {
        $id = $this->request->param('id', 0);
        $page = $this->request->param('page', 1);
        $pageSize = $this->request->param('page_size', 20);

        $query = ClubMember::where('club_id', $id);

        $total = $query->count();
        $list = $query->with(['user'])
            ->order('role', 'desc')
            ->order('join_time', 'asc')
            ->page($page, $pageSize)
            ->select()
            ->toArray();

        return $this->paginate($list, $total, $page, $pageSize);
    }
}
