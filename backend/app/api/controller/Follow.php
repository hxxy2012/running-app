<?php
/**
 * 关注控制器
 */

namespace app\api\controller;

use app\common\model\Follow as FollowModel;
use app\common\model\User;
use app\common\service\NotificationService;
use think\facade\Db;

class Follow extends Base
{
    /**
     * 关注用户
     * POST /api/follow/:userId
     */
    public function follow()
    {
        $followUserId = $this->request->param('userId', 0);

        if ($followUserId == $this->userId) {
            return $this->error('不能关注自己');
        }

        // 检查用户是否存在
        $user = User::find($followUserId);
        if (!$user) {
            return $this->error('用户不存在');
        }

        // 检查是否已关注
        if (FollowModel::isFollowing($this->userId, $followUserId)) {
            return $this->error('已经关注过了');
        }

        try {
            FollowModel::create([
                'user_id' => $this->userId,
                'follow_user_id' => $followUserId,
            ]);

            // 发送消息通知
            NotificationService::sendFollowNotification($this->userId, $followUserId);

            return $this->success([], '关注成功');

        } catch (\Exception $e) {
            return $this->error('关注失败: ' . $e->getMessage());
        }
    }

    /**
     * 取消关注
     * DELETE /api/follow/:userId
     */
    public function unfollow()
    {
        $followUserId = $this->request->param('userId', 0);

        FollowModel::where('user_id', $this->userId)
            ->where('follow_user_id', $followUserId)
            ->delete();

        return $this->success([], '取消关注成功');
    }

    /**
     * 关注列表（我关注的人）
     * GET /api/follow/following
     */
    public function following()
    {
        $page = $this->request->param('page', 1);
        $pageSize = $this->request->param('page_size', 20);
        $userId = $this->request->param('user_id', $this->userId);

        $query = FollowModel::where('user_id', $userId);

        $total = $query->count();
        $list = $query->with(['followUser'])
            ->order('create_time', 'desc')
            ->page($page, $pageSize)
            ->select()
            ->each(function($item) {
                $user = $item->followUser;
                if ($user) {
                    $user->is_following = FollowModel::isFollowing($this->userId, $user->id);
                    $user->is_friend = FollowModel::isFriend($this->userId, $user->id);
                }
                return $user;
            })
            ->toArray();

        return $this->paginate($list, $total, $page, $pageSize);
    }

    /**
     * 粉丝列表（关注我的人）
     * GET /api/follow/followers
     */
    public function followers()
    {
        $page = $this->request->param('page', 1);
        $pageSize = $this->request->param('page_size', 20);
        $userId = $this->request->param('user_id', $this->userId);

        $query = FollowModel::where('follow_user_id', $userId);

        $total = $query->count();
        $list = $query->with(['user'])
            ->order('create_time', 'desc')
            ->page($page, $pageSize)
            ->select()
            ->each(function($item) {
                $user = $item->user;
                if ($user) {
                    $user->is_following = FollowModel::isFollowing($this->userId, $user->id);
                    $user->is_friend = FollowModel::isFriend($this->userId, $user->id);
                }
                return $user;
            })
            ->toArray();

        return $this->paginate($list, $total, $page, $pageSize);
    }

    /**
     * 互相关注列表（好友）
     * GET /api/follow/friends
     */
    public function friends()
    {
        $page = $this->request->param('page', 1);
        $pageSize = $this->request->param('page_size', 20);

        // 我关注的人
        $followingIds = FollowModel::where('user_id', $this->userId)
            ->column('follow_user_id');

        if (empty($followingIds)) {
            return $this->paginate([], 0, $page, $pageSize);
        }

        // 也关注我的人（互相关注）
        $friendIds = FollowModel::whereIn('user_id', $followingIds)
            ->where('follow_user_id', $this->userId)
            ->column('user_id');

        if (empty($friendIds)) {
            return $this->paginate([], 0, $page, $pageSize);
        }

        $total = count($friendIds);
        $list = User::whereIn('id', $friendIds)
            ->page($page, $pageSize)
            ->select()
            ->each(function($user) {
                $user->is_following = true;
                $user->is_friend = true;
                return $user;
            })
            ->toArray();

        return $this->paginate($list, $total, $page, $pageSize);
    }
}
