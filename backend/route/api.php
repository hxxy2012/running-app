<?php
/**
 * API路由配置
 */
use think\facade\Route;

// ========== 认证相关（无需token） ==========
Route::group('auth', function () {
    Route::post('send-code', 'Auth/sendCode');           // 发送验证码
    Route::post('register', 'Auth/register');             // 注册
    Route::post('login', 'Auth/login');                   // 登录
    Route::post('oauth', 'Auth/oauth');                   // 第三方登录
    Route::post('refresh-token', 'Auth/refreshToken');    // 刷新Token
})->prefix('api.Auth/');

// ========== 需要认证的接口 ==========
Route::group(function () {

    // ========== 用户相关 ==========
    Route::group('user', function () {
        Route::get('profile', 'User/profile');            // 获取个人信息
        Route::put('profile', 'User/updateProfile');      // 更新个人信息
        Route::post('avatar', 'User/uploadAvatar');       // 上传头像
        Route::put('password', 'User/changePassword');    // 修改密码
        Route::post('real-auth', 'User/realAuth');        // 实名认证
        Route::delete('account', 'User/deleteAccount');   // 注销账号
    })->prefix('api.User/');

    // ========== 跑步记录 ==========
    Route::group('running', function () {
        Route::post('start', 'Running/start');                    // 开始跑步
        Route::post('upload-point', 'Running/uploadPoint');       // 上传轨迹点
        Route::post('finish', 'Running/finish');                  // 结束跑步
        Route::get('records', 'Running/records');                 // 获取记录列表
        Route::get('record/:id', 'Running/recordDetail');         // 记录详情
        Route::put('record/:id', 'Running/updateRecord');         // 编辑记录
        Route::delete('record/:id', 'Running/deleteRecord');      // 删除记录
        Route::get('statistics', 'Running/statistics');           // 统计数据
        Route::get('calendar', 'Running/calendar');               // 日历数据
        Route::get('pb', 'Running/pb');                           // PB记录
        Route::post('share', 'Running/share');                    // 生成分享海报
    })->prefix('api.Running/');

    // ========== 训练计划 ==========
    Route::group('training', function () {
        Route::get('plans', 'Training/plans');                    // 获取计划列表
        Route::get('plan/:id', 'Training/planDetail');            // 计划详情
        Route::post('plan', 'Training/createPlan');               // 创建自定义计划
        Route::post('join/:id', 'Training/joinPlan');             // 加入计划
        Route::get('my-plan', 'Training/myPlan');                 // 我的计划
        Route::put('complete-day', 'Training/completeDay');       // 完成某天训练
        Route::put('abandon', 'Training/abandonPlan');            // 放弃计划
    })->prefix('api.Training/');

    // ========== 社交动态 ==========
    Route::group('post', function () {
        Route::post('', 'Post/create');                           // 发布动态
        Route::get('feed', 'Post/feed');                          // 动态流
        Route::get('square', 'Post/square');                      // 广场
        Route::get(':id', 'Post/detail');                         // 动态详情
        Route::delete(':id', 'Post/delete');                      // 删除动态
        Route::post(':id/like', 'Post/like');                     // 点赞
        Route::delete(':id/like', 'Post/unlike');                 // 取消点赞
        Route::post(':id/comment', 'Post/comment');               // 评论
        Route::get(':id/comments', 'Post/comments');              // 评论列表
    })->prefix('api.Post/');

    Route::delete('comment/:id', 'api.Post/deleteComment');       // 删除评论

    // ========== 关注系统 ==========
    Route::group('follow', function () {
        Route::post(':userId', 'Follow/follow');                  // 关注
        Route::delete(':userId', 'Follow/unfollow');              // 取消关注
        Route::get('following', 'Follow/following');              // 关注列表
        Route::get('followers', 'Follow/followers');              // 粉丝列表
        Route::get('friends', 'Follow/friends');                  // 互相关注
    })->prefix('api.Follow/');

    // ========== 跑团 ==========
    Route::group('club', function () {
        Route::post('', 'Club/create');                           // 创建跑团
        Route::get('list', 'Club/list');                          // 跑团列表
        Route::get(':id', 'Club/detail');                         // 跑团详情
        Route::put(':id', 'Club/update');                         // 编辑跑团
        Route::post(':id/join', 'Club/join');                     // 加入跑团
        Route::delete(':id/quit', 'Club/quit');                   // 退出跑团
        Route::get(':id/members', 'Club/members');                // 成员列表
        Route::put(':id/member/:userId', 'Club/updateMemberRole');// 修改成员角色
        Route::get(':id/ranking', 'Club/ranking');                // 跑团排行
    })->prefix('api.Club/');

    // ========== 挑战赛 ==========
    Route::group('challenge', function () {
        Route::get('list', 'Challenge/list');                     // 挑战列表
        Route::get(':id', 'Challenge/detail');                    // 挑战详情
        Route::post(':id/join', 'Challenge/join');                // 参加挑战
        Route::get(':id/ranking', 'Challenge/ranking');           // 挑战排行
        Route::get('my', 'Challenge/myChallenges');               // 我的挑战
    })->prefix('api.Challenge/');

    // ========== 成就系统 ==========
    Route::group('achievement', function () {
        Route::get('list', 'Achievement/list');                   // 成就列表
        Route::get('my', 'Achievement/myAchievements');           // 我的成就
    })->prefix('api.Achievement/');

    // ========== 排行榜 ==========
    Route::group('ranking', function () {
        Route::get('total', 'Ranking/total');                     // 总排行
        Route::get('month', 'Ranking/month');                     // 月排行
        Route::get('week', 'Ranking/week');                       // 周排行
        Route::get('friends', 'Ranking/friends');                 // 好友排行
        Route::get('city', 'Ranking/city');                       // 城市排行
    })->prefix('api.Ranking/');

    // ========== 装备管理 ==========
    Route::group('equipment', function () {
        Route::post('', 'Equipment/create');                      // 添加装备
        Route::get('list', 'Equipment/list');                     // 装备列表
        Route::put(':id', 'Equipment/update');                    // 更新装备
        Route::delete(':id', 'Equipment/delete');                 // 删除装备
    })->prefix('api.Equipment/');

    // ========== 消息通知 ==========
    Route::group('message', function () {
        Route::get('list', 'Message/list');                       // 消息列表
        Route::put('read', 'Message/markRead');                   // 标记已读
        Route::get('unread-count', 'Message/unreadCount');        // 未读数
    })->prefix('api.Message/');

    // ========== 其他 ==========
    Route::get('common/weather', 'api.Common/weather');           // 获取天气
    Route::post('feedback', 'api.Feedback/create');               // 提交反馈
    Route::post('upload/image', 'api.Common/uploadImage');        // 上传图片

})->middleware(\app\api\middleware\Auth::class);

// ========== 无需认证的公共接口 ==========
Route::get('config', 'api.Common/config');                        // 获取配置
Route::get('version', 'api.Common/version');                      // 版本检测

// ========== 崩溃日志（无需认证） ==========
Route::group('crash', function () {
    Route::post('upload', 'Crash/upload');                        // 上传崩溃日志
    Route::post('upload-file', 'Crash/uploadFile');               // 上传崩溃日志文件
    Route::post('batch-upload', 'Crash/batchUpload');             // 批量上传崩溃日志
})->prefix('api.Crash/');
