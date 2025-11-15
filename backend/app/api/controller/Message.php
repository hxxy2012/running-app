<?php
/**
 * 消息控制器
 */

namespace app\api\controller;

use app\common\model\Message as MessageModel;

class Message extends Base
{
    /**
     * 消息列表
     * GET /api/message/list
     */
    public function list()
    {
        $page = $this->request->param('page', 1);
        $pageSize = $this->request->param('page_size', 20);
        $type = $this->request->param('type', 0);

        $query = MessageModel::where('user_id', $this->userId);

        if ($type > 0) {
            $query->where('type', $type);
        }

        $total = $query->count();
        $list = $query->with(['fromUser'])
            ->order('create_time', 'desc')
            ->page($page, $pageSize)
            ->select()
            ->toArray();

        return $this->paginate($list, $total, $page, $pageSize);
    }

    /**
     * 标记已读
     * PUT /api/message/read
     */
    public function markRead()
    {
        $ids = $this->request->param('ids', []);

        if (empty($ids)) {
            // 标记全部已读
            MessageModel::where('user_id', $this->userId)
                ->where('is_read', 0)
                ->update(['is_read' => 1]);
        } else {
            // 标记指定消息已读
            MessageModel::whereIn('id', $ids)
                ->where('user_id', $this->userId)
                ->update(['is_read' => 1]);
        }

        return $this->success([], '操作成功');
    }

    /**
     * 未读数
     * GET /api/message/unread-count
     */
    public function unreadCount()
    {
        $count = MessageModel::where('user_id', $this->userId)
            ->where('is_read', 0)
            ->count();

        return $this->success(['count' => $count]);
    }
}
