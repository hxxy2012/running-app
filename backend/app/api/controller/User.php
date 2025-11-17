<?php
/**
 * 用户控制器
 */

namespace app\api\controller;

use app\common\model\User as UserModel;
use think\facade\Filesystem;

class User extends Base
{
    /**
     * 获取个人信息
     * GET /api/user/profile
     */
    public function profile()
    {
        $userId = $this->request->param('user_id', $this->userId);

        $user = UserModel::find($userId);

        if (!$user) {
            return $this->error('用户不存在');
        }

        $data = $user->toArray();

        // 如果查看别人的信息，添加关注状态
        if ($userId != $this->userId) {
            $data['is_following'] = \app\common\model\Follow::isFollowing($this->userId, $userId);
            $data['is_friend'] = \app\common\model\Follow::isFriend($this->userId, $userId);
        }

        return $this->success($data);
    }

    /**
     * 更新个人信息
     * PUT /api/user/profile
     */
    public function updateProfile()
    {
        $data = $this->request->param();

        $user = UserModel::find($this->userId);

        if (!$user) {
            return $this->error('用户不存在');
        }

        // 允许更新的字段
        $allowFields = ['nickname', 'gender', 'birthday', 'height', 'weight',
                        'city', 'signature'];

        $updateData = [];
        foreach ($allowFields as $field) {
            if (isset($data[$field])) {
                $updateData[$field] = $data[$field];
            }
        }

        if (empty($updateData)) {
            return $this->error('没有要更新的信息');
        }

        try {
            $user->save($updateData);

            return $this->success($user->toArray(), '更新成功');

        } catch (\Exception $e) {
            return $this->error('更新失败: ' . $e->getMessage());
        }
    }

    /**
     * 上传头像
     * POST /api/user/avatar
     */
    public function uploadAvatar()
    {
        $file = $this->request->file('file');

        if (!$file) {
            return $this->error('请选择要上传的文件');
        }

        try {
            // 保存文件
            $savePath = 'avatar/' . date('Ymd');
            $fileName = Filesystem::disk('public')->putFile($savePath, $file);

            // 生成URL
            $domain = config('app.api_domain');
            $url = $domain . '/uploads/' . str_replace('\\', '/', $fileName);

            // 更新用户头像
            $user = UserModel::find($this->userId);
            $user->avatar = $url;
            $user->save();

            return $this->success([
                'url' => $url,
            ], '上传成功');

        } catch (\Exception $e) {
            return $this->error('上传失败: ' . $e->getMessage());
        }
    }

    /**
     * 修改密码
     * PUT /api/user/password
     */
    public function changePassword()
    {
        $oldPassword = $this->request->param('old_password', '');
        $newPassword = $this->request->param('new_password', '');

        if (empty($oldPassword) || empty($newPassword)) {
            return $this->error('参数错误');
        }

        if (strlen($newPassword) < 6) {
            return $this->error('新密码长度不能少于6位');
        }

        $user = UserModel::find($this->userId);

        // 验证旧密码
        if (!password_verify($oldPassword, $user->password)) {
            return $this->error('旧密码错误');
        }

        // 更新密码
        $user->password = password_hash($newPassword, PASSWORD_BCRYPT);
        $user->save();

        return $this->success([], '密码修改成功');
    }

    /**
     * 实名认证
     * POST /api/user/real-auth
     */
    public function realAuth()
    {
        $realName = $this->request->param('real_name', '');
        $idCard = $this->request->param('id_card', '');

        if (empty($realName) || empty($idCard)) {
            return $this->error('参数错误');
        }

        // 验证身份证号格式
        if (!preg_match('/^\d{17}[\dXx]$/', $idCard)) {
            return $this->error('身份证号格式不正确');
        }

        $user = UserModel::find($this->userId);

        if ($user->real_name) {
            return $this->error('已经实名认证过了');
        }

        // TODO: 调用第三方实名认证接口

        $user->real_name = $realName;
        $user->id_card = $idCard;
        $user->save();

        return $this->success([], '实名认证成功');
    }

    /**
     * 注销账号
     * DELETE /api/user/account
     */
    public function deleteAccount()
    {
        $password = $this->request->param('password', '');

        if (empty($password)) {
            return $this->error('请输入密码');
        }

        $user = UserModel::find($this->userId);

        // 验证密码
        if (!password_verify($password, $user->password)) {
            return $this->error('密码错误');
        }

        // 注销账号（设置状态为禁用）
        $user->status = 0;
        $user->save();

        // 清理用户相关数据
        $this->cleanUserData($this->userId);

        return $this->success([], '账号已注销');
    }

    /**
     * 清理用户相关数据
     * @param int $userId 用户ID
     */
    private function cleanUserData($userId)
    {
        try {
            // 1. 删除跑步记录和轨迹点
            $recordIds = \app\common\model\RunningRecord::where('user_id', $userId)->column('id');
            if (!empty($recordIds)) {
                // 删除轨迹点
                \app\common\model\TrackPoint::whereIn('record_id', $recordIds)->delete();
                // 删除跑步记录
                \app\common\model\RunningRecord::where('user_id', $userId)->delete();
            }

            // 2. 删除或匿名化动态（这里选择删除）
            $postIds = \app\common\model\Post::where('user_id', $userId)->column('id');
            if (!empty($postIds)) {
                // 删除动态的点赞
                \app\common\model\Like::whereIn('post_id', $postIds)->where('type', 'post')->delete();
                // 删除动态的评论
                \app\common\model\Comment::whereIn('post_id', $postIds)->delete();
                // 删除动态
                \app\common\model\Post::where('user_id', $userId)->delete();
            }

            // 3. 删除用户的点赞和评论
            \app\common\model\Like::where('user_id', $userId)->delete();
            \app\common\model\Comment::where('user_id', $userId)->delete();

            // 4. 删除关注关系
            \app\common\model\Follow::where('user_id', $userId)->delete();
            \app\common\model\Follow::where('follow_user_id', $userId)->delete();

            // 5. 删除装备
            \app\common\model\Equipment::where('user_id', $userId)->delete();

            // 6. 删除消息
            \app\common\model\Message::where('user_id', $userId)->delete();
            \app\common\model\Message::where('from_user_id', $userId)->delete();

            // 7. 删除反馈
            \app\common\model\Feedback::where('user_id', $userId)->delete();

            // 8. 删除用户训练计划
            \app\common\model\UserTrainingPlan::where('user_id', $userId)->delete();

            // 9. 删除用户挑战
            \app\common\model\UserChallenge::where('user_id', $userId)->delete();

            // 10. 删除用户成就
            \app\common\model\UserAchievement::where('user_id', $userId)->delete();

            // 11. 删除跑团成员关系
            \app\common\model\ClubMember::where('user_id', $userId)->delete();

            // 12. 删除第三方登录绑定
            \app\common\model\UserOauth::where('user_id', $userId)->delete();

            // 13. 从排行榜中删除
            \app\common\model\Ranking::where('user_id', $userId)->delete();

            return true;
        } catch (\Exception $e) {
            // 记录日志但不影响主流程
            trace('清理用户数据失败: ' . $e->getMessage(), 'error');
            return false;
        }
    }
}
