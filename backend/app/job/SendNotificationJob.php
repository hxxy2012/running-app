<?php

namespace app\job;

use think\queue\Job;
use app\common\service\NotificationService;

/**
 * 发送通知任务
 *
 * 异步发送各类通知（站内信、推送、短信等）
 */
class SendNotificationJob
{
    /**
     * 执行任务
     *
     * @param Job $job 任务对象
     * @param array $data 任务数据
     * @return void
     */
    public function fire(Job $job, $data)
    {
        // 检查任务执行次数
        if ($job->attempts() > 3) {
            // 超过3次失败，删除任务
            $job->delete();
            return;
        }

        try {
            $notificationService = new NotificationService();

            switch ($data['type']) {
                case 'in_app':
                    // 站内通知
                    $this->sendInAppNotification($data);
                    break;

                case 'push':
                    // 推送通知
                    $this->sendPushNotification($data);
                    break;

                case 'sms':
                    // 短信通知
                    $this->sendSmsNotification($data);
                    break;

                case 'email':
                    // 邮件通知
                    $this->sendEmailNotification($data);
                    break;

                default:
                    throw new \Exception('Unknown notification type: ' . $data['type']);
            }

            // 任务成功，删除任务
            $job->delete();

        } catch (\Exception $e) {
            // 任务失败，记录日志
            trace('Notification job failed: ' . $e->getMessage(), 'error');

            // 如果任务执行失败，延迟60秒后重试
            if ($job->attempts() < 3) {
                $job->release(60);
            } else {
                $job->delete();
            }
        }
    }

    /**
     * 发送站内通知
     */
    private function sendInAppNotification($data)
    {
        \think\facade\Db::name('notification')->insert([
            'user_id' => $data['user_id'],
            'title' => $data['title'],
            'content' => $data['content'],
            'type' => $data['notification_type'] ?? 'system',
            'create_time' => date('Y-m-d H:i:s'),
        ]);
    }

    /**
     * 发送推送通知
     */
    private function sendPushNotification($data)
    {
        // 调用推送服务（极光推送、Firebase等）
        // TODO: 实现推送逻辑
    }

    /**
     * 发送短信通知
     */
    private function sendSmsNotification($data)
    {
        $smsService = new \app\common\service\SmsService();
        $smsService->send($data['phone'], $data['template'], $data['params']);
    }

    /**
     * 发送邮件通知
     */
    private function sendEmailNotification($data)
    {
        // TODO: 实现邮件发送逻辑
    }

    /**
     * 任务失败处理
     *
     * @param array $data 任务数据
     * @return void
     */
    public function failed($data)
    {
        // 任务失败后的处理逻辑
        trace('Notification job permanently failed: ' . json_encode($data), 'error');
    }
}
