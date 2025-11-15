<?php
/**
 * 动态控制器
 */

namespace app\api\controller;

use app\common\model\Post as PostModel;
use app\common\model\Comment;
use app\common\model\Like;
use app\common\model\Follow;
use app\common\model\User;
use think\facade\Db;

class Post extends Base
{
    /**
     * 发布动态
     * POST /api/post
     */
    public function create()
    {
        $content = $this->request->param('content', '');
        $images = $this->request->param('images', []);
        $recordId = $this->request->param('record_id', 0);
        $location = $this->request->param('location', '');
        $type = $this->request->param('type', 1);

        try {
            $post = PostModel::create([
                'user_id' => $this->userId,
                'record_id' => $recordId > 0 ? $recordId : null,
                'content' => $content,
                'images' => $images,
                'location' => $location,
                'type' => $type,
                'is_public' => 1,
                'status' => 1,
            ]);

            return $this->success([
                'post' => $post->toArray(),
            ], '发布成功');

        } catch (\Exception $e) {
            return $this->error('发布失败: ' . $e->getMessage());
        }
    }

    /**
     * 动态流（关注的人）
     * GET /api/post/feed
     */
    public function feed()
    {
        $page = $this->request->param('page', 1);
        $pageSize = $this->request->param('page_size', 20);

        // 获取关注列表
        $followingIds = Follow::where('user_id', $this->userId)
            ->column('follow_user_id');

        if (empty($followingIds)) {
            return $this->paginate([], 0, $page, $pageSize);
        }

        // 查询动态
        $query = PostModel::whereIn('user_id', $followingIds)
            ->where('status', 1)
            ->where('is_public', 1);

        $total = $query->count();
        $list = $query->with(['user'])
            ->order('create_time', 'desc')
            ->page($page, $pageSize)
            ->select()
            ->each(function($item) {
                $item->is_liked = Like::isLiked($this->userId, 1, $item->id);
                return $item;
            })
            ->toArray();

        return $this->paginate($list, $total, $page, $pageSize);
    }

    /**
     * 广场（推荐）
     * GET /api/post/square
     */
    public function square()
    {
        $page = $this->request->param('page', 1);
        $pageSize = $this->request->param('page_size', 20);
        $city = $this->request->param('city', '');

        $query = PostModel::where('status', 1)
            ->where('is_public', 1);

        // 城市筛选
        if ($city) {
            $query->where('location', 'like', '%' . $city . '%');
        }

        // 按热度排序（简化版：点赞数*2 + 评论数*3）
        $total = $query->count();
        $list = $query->with(['user'])
            ->field('*, (like_count * 2 + comment_count * 3) as hot_score')
            ->order('hot_score', 'desc')
            ->order('create_time', 'desc')
            ->page($page, $pageSize)
            ->select()
            ->each(function($item) {
                $item->is_liked = Like::isLiked($this->userId, 1, $item->id);
                return $item;
            })
            ->toArray();

        return $this->paginate($list, $total, $page, $pageSize);
    }

    /**
     * 动态详情
     * GET /api/post/:id
     */
    public function detail()
    {
        $id = $this->request->param('id', 0);

        $post = PostModel::with(['user', 'runningRecord'])
            ->find($id);

        if (!$post || $post->status != 1) {
            return $this->error('动态不存在');
        }

        $data = $post->toArray();
        $data['is_liked'] = Like::isLiked($this->userId, 1, $id);

        return $this->success($data);
    }

    /**
     * 删除动态
     * DELETE /api/post/:id
     */
    public function delete()
    {
        $id = $this->request->param('id', 0);

        $post = PostModel::where('id', $id)
            ->where('user_id', $this->userId)
            ->find();

        if (!$post) {
            return $this->error('动态不存在');
        }

        $post->status = 0;
        $post->save();

        return $this->success([], '删除成功');
    }

    /**
     * 点赞
     * POST /api/post/:id/like
     */
    public function like()
    {
        $id = $this->request->param('id', 0);

        $post = PostModel::find($id);
        if (!$post) {
            return $this->error('动态不存在');
        }

        // 检查是否已点赞
        if (Like::isLiked($this->userId, 1, $id)) {
            return $this->error('已经点赞过了');
        }

        try {
            Db::startTrans();

            // 创建点赞记录
            Like::create([
                'user_id' => $this->userId,
                'target_type' => 1,
                'target_id' => $id,
            ]);

            // 更新点赞数
            $post->like_count += 1;
            $post->save();

            // TODO: 发送消息通知

            Db::commit();

            return $this->success([], '点赞成功');

        } catch (\Exception $e) {
            Db::rollback();
            return $this->error('点赞失败: ' . $e->getMessage());
        }
    }

    /**
     * 取消点赞
     * DELETE /api/post/:id/like
     */
    public function unlike()
    {
        $id = $this->request->param('id', 0);

        $post = PostModel::find($id);
        if (!$post) {
            return $this->error('动态不存在');
        }

        try {
            Db::startTrans();

            // 删除点赞记录
            $deleted = Like::where('user_id', $this->userId)
                ->where('target_type', 1)
                ->where('target_id', $id)
                ->delete();

            if ($deleted) {
                // 更新点赞数
                $post->like_count = max(0, $post->like_count - 1);
                $post->save();
            }

            Db::commit();

            return $this->success([], '取消点赞成功');

        } catch (\Exception $e) {
            Db::rollback();
            return $this->error('操作失败: ' . $e->getMessage());
        }
    }

    /**
     * 评论
     * POST /api/post/:id/comment
     */
    public function comment()
    {
        $id = $this->request->param('id', 0);
        $content = $this->request->param('content', '');
        $parentId = $this->request->param('parent_id', 0);
        $toUserId = $this->request->param('to_user_id', 0);

        if (empty($content)) {
            return $this->error('评论内容不能为空');
        }

        $post = PostModel::find($id);
        if (!$post) {
            return $this->error('动态不存在');
        }

        try {
            Db::startTrans();

            $comment = Comment::create([
                'user_id' => $this->userId,
                'post_id' => $id,
                'parent_id' => $parentId > 0 ? $parentId : null,
                'to_user_id' => $toUserId > 0 ? $toUserId : null,
                'content' => $content,
                'status' => 1,
            ]);

            // 更新评论数
            $post->comment_count += 1;
            $post->save();

            // TODO: 发送消息通知

            Db::commit();

            // 返回评论详情
            $commentData = Comment::with(['user'])->find($comment->id)->toArray();

            return $this->success($commentData, '评论成功');

        } catch (\Exception $e) {
            Db::rollback();
            return $this->error('评论失败: ' . $e->getMessage());
        }
    }

    /**
     * 评论列表
     * GET /api/post/:id/comments
     */
    public function comments()
    {
        $id = $this->request->param('id', 0);
        $page = $this->request->param('page', 1);
        $pageSize = $this->request->param('page_size', 20);

        $query = Comment::where('post_id', $id)
            ->where('status', 1)
            ->whereNull('parent_id');

        $total = $query->count();
        $list = $query->with(['user', 'toUser', 'children' => function($query) {
                $query->with(['user', 'toUser'])->limit(3);
            }])
            ->order('create_time', 'desc')
            ->page($page, $pageSize)
            ->select()
            ->toArray();

        return $this->paginate($list, $total, $page, $pageSize);
    }

    /**
     * 删除评论
     * DELETE /api/comment/:id
     */
    public function deleteComment()
    {
        $id = $this->request->param('id', 0);

        $comment = Comment::where('id', $id)
            ->where('user_id', $this->userId)
            ->find();

        if (!$comment) {
            return $this->error('评论不存在');
        }

        try {
            Db::startTrans();

            $comment->status = 0;
            $comment->save();

            // 更新动态评论数
            $post = PostModel::find($comment->post_id);
            if ($post) {
                $post->comment_count = max(0, $post->comment_count - 1);
                $post->save();
            }

            Db::commit();

            return $this->success([], '删除成功');

        } catch (\Exception $e) {
            Db::rollback();
            return $this->error('删除失败: ' . $e->getMessage());
        }
    }
}
