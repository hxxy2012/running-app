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

        // TODO: 清理用户相关数据（可选）

        return $this->success([], '账号已注销');
    }
}
