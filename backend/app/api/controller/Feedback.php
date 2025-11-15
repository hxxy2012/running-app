<?php
/**
 * 反馈控制器
 */

namespace app\api\controller;

use app\common\model\Feedback as FeedbackModel;

class Feedback extends Base
{
    /**
     * 提交反馈
     * POST /api/feedback
     */
    public function create()
    {
        $type = $this->request->param('type', 1);
        $content = $this->request->param('content', '');
        $images = $this->request->param('images', []);
        $contact = $this->request->param('contact', '');

        if (empty($content)) {
            return $this->error('反馈内容不能为空');
        }

        try {
            $feedback = FeedbackModel::create([
                'user_id' => $this->userId,
                'type' => $type,
                'content' => $content,
                'images' => json_encode($images),
                'contact' => $contact,
                'status' => 0,
            ]);

            return $this->success($feedback->toArray(), '提交成功');

        } catch (\Exception $e) {
            return $this->error('提交失败: ' . $e->getMessage());
        }
    }
}
