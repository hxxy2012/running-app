-- ====================================
-- Running App - 示例数据脚本
-- ====================================
-- 用途: 生成测试/演示数据
-- 注意: 仅用于开发和演示环境，请勿在生产环境执行
-- ====================================

SET NAMES utf8mb4;

-- ====================================
-- 1. 创建示例用户
-- ====================================

INSERT INTO `user` (`id`, `phone`, `password`, `nickname`, `avatar`, `gender`, `birthday`, `height`, `weight`, `city`, `signature`, `level`, `experience`, `total_distance`, `total_time`, `total_count`, `status`, `create_time`, `update_time`) VALUES
(1, '13800138001', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '跑步达人', '/uploads/avatar/user1.jpg', 1, '1990-01-01', 175.00, 70.00, '北京', '热爱跑步，享受生活', 5, 5000, 500.00, 180000, 100, 1, NOW(), NOW()),
(2, '13800138002', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '马拉松选手', '/uploads/avatar/user2.jpg', 1, '1992-03-15', 180.00, 68.00, '上海', '目标：破三！', 6, 8000, 1200.00, 360000, 200, 1, NOW(), NOW()),
(3, '13800138003', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '健身爱好者', '/uploads/avatar/user3.jpg', 2, '1995-06-20', 165.00, 55.00, '深圳', '跑步让我更自信', 4, 3000, 300.00, 120000, 60, 1, NOW(), NOW()),
(4, '13800138004', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '晨跑者', '/uploads/avatar/user4.jpg', 1, '1988-09-10', 178.00, 75.00, '杭州', '每天早晨6点，不见不散', 3, 2000, 200.00, 90000, 50, 1, NOW(), NOW()),
(5, '13800138005', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '夜跑女王', '/uploads/avatar/user5.jpg', 2, '1993-12-25', 168.00, 52.00, '成都', '夜跑才是真浪漫', 5, 4500, 450.00, 150000, 90, 1, NOW(), NOW());

-- 密码均为: password

-- ====================================
-- 2. 创建关注关系
-- ====================================

INSERT INTO `follow` (`user_id`, `follow_user_id`, `create_time`) VALUES
(1, 2, NOW()),
(1, 3, NOW()),
(1, 5, NOW()),
(2, 1, NOW()),
(2, 4, NOW()),
(3, 1, NOW()),
(3, 2, NOW()),
(4, 1, NOW()),
(5, 1, NOW()),
(5, 2, NOW());

-- ====================================
-- 3. 创建跑步记录
-- ====================================

-- 用户1的记录
INSERT INTO `running_record` (`user_id`, `type`, `distance`, `duration`, `avg_pace`, `best_pace`, `avg_speed`, `step_count`, `step_frequency`, `calories`, `climb`, `descent`, `start_time`, `end_time`, `start_location`, `city`, `weather`, `temperature`, `feeling`, `note`, `is_public`, `like_count`, `comment_count`, `create_time`) VALUES
(1, 1, 5.12, 1800, 351, 330, 10.24, 6500, 180, 320, 15.5, 12.3, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY) + INTERVAL 30 MINUTE, '北京朝阳公园', '北京', '晴', 22, 2, '今天状态不错，完成了5公里', 1, 5, 2, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(1, 1, 10.05, 3600, 358, 340, 10.05, 13000, 180, 650, 30.2, 28.5, DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY) + INTERVAL 1 HOUR, '北京奥林匹克公园', '北京', '多云', 20, 1, '轻松跑10公里，很舒服', 1, 8, 3, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(1, 1, 3.50, 1200, 343, 320, 10.50, 4500, 185, 230, 8.5, 7.2, DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 5 DAY) + INTERVAL 20 MINUTE, '北京大学校园', '北京', '晴', 25, 3, '速度训练，感觉有点累', 1, 3, 1, DATE_SUB(NOW(), INTERVAL 5 DAY));

-- 用户2的记录
INSERT INTO `running_record` (`user_id`, `type`, `distance`, `duration`, `avg_pace`, `best_pace`, `avg_speed`, `step_count`, `step_frequency`, `calories`, `climb`, `descent`, `start_time`, `end_time`, `start_location`, `city`, `weather`, `temperature`, `feeling`, `note`, `is_public`, `like_count`, `comment_count`, `create_time`) VALUES
(2, 1, 21.10, 6300, 299, 280, 12.05, 27000, 175, 1400, 50.5, 48.2, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY) + INTERVAL 105 MINUTE, '上海滨江大道', '上海', '晴', 24, 2, '半马拉练，状态良好！', 1, 15, 5, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(2, 1, 15.50, 4500, 290, 275, 12.40, 20000, 178, 980, 35.8, 33.5, DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY) + INTERVAL 75 MINUTE, '上海世纪公园', '上海', '多云', 22, 1, '15公里长距离，轻松愉快', 1, 12, 4, DATE_SUB(NOW(), INTERVAL 4 DAY));

-- 用户3的记录
INSERT INTO `running_record` (`user_id`, `type`, `distance`, `duration`, `avg_pace`, `best_pace`, `avg_speed`, `step_count`, `step_frequency`, `calories`, `climb`, `descent`, `start_time`, `end_time`, `start_location`, `city`, `weather`, `temperature`, `feeling`, `note`, `is_public`, `like_count`, `comment_count`, `create_time`) VALUES
(3, 1, 5.00, 2100, 420, 400, 8.57, 7000, 170, 280, 12.0, 11.5, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY) + INTERVAL 35 MINUTE, '深圳莲花山公园', '深圳', '晴', 28, 2, '坚持就是胜利！', 1, 6, 2, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(3, 2, 8.20, 2400, 293, 280, 12.30, 0, 0, 350, 85.5, 82.3, DATE_SUB(NOW(), INTERVAL 6 DAY), DATE_SUB(NOW(), INTERVAL 6 DAY) + INTERVAL 40 MINUTE, '深圳湾公园', '深圳', '多云', 26, 1, '骑行看海景，心情超好', 1, 4, 1, DATE_SUB(NOW(), INTERVAL 6 DAY));

-- ====================================
-- 4. 创建动态
-- ====================================

INSERT INTO `post` (`user_id`, `record_id`, `content`, `images`, `location`, `type`, `like_count`, `comment_count`, `share_count`, `is_public`, `status`, `create_time`) VALUES
(1, 1, '今天完成了5公里跑步，感觉棒极了！#跑步打卡 #健康生活', '[]', '北京朝阳公园', 2, 5, 2, 1, 1, 1, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(2, 4, '半马拉练顺利完成，向全马进发！💪 #马拉松训练', '[]', '上海滨江大道', 2, 15, 5, 3, 1, 1, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(3, NULL, '加油！每天进步一点点！ #跑步日记', '[]', NULL, 1, 6, 2, 0, 1, 1, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(1, 2, '10公里轻松跑，享受跑步的乐趣 🏃', '[]', '北京奥林匹克公园', 2, 8, 3, 2, 1, 1, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(5, NULL, '夜跑真的太爽了！城市的夜晚别有一番风味 🌙', '[]', '成都人民公园', 1, 10, 4, 1, 1, 1, DATE_SUB(NOW(), INTERVAL 4 DAY));

-- ====================================
-- 5. 创建点赞记录
-- ====================================

INSERT INTO `like` (`user_id`, `target_type`, `target_id`, `create_time`) VALUES
(2, 1, 1, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(3, 1, 1, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(4, 1, 1, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(5, 1, 1, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(1, 1, 2, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(3, 1, 2, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(4, 1, 2, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(5, 1, 2, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(1, 1, 4, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(2, 1, 4, DATE_SUB(NOW(), INTERVAL 3 DAY));

-- ====================================
-- 6. 创建评论
-- ====================================

INSERT INTO `comment` (`user_id`, `post_id`, `parent_id`, `to_user_id`, `content`, `like_count`, `status`, `create_time`) VALUES
(2, 1, NULL, NULL, '加油！继续保持！', 2, 1, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(3, 1, NULL, NULL, '好棒！我也要努力', 1, 1, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(1, 2, NULL, NULL, '太强了！向你学习', 3, 1, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(3, 2, NULL, NULL, '半马太厉害了', 2, 1, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(4, 2, NULL, NULL, '请问怎么训练的？', 1, 1, DATE_SUB(NOW(), INTERVAL 2 DAY));

-- ====================================
-- 7. 创建挑战赛
-- ====================================

INSERT INTO `challenge` (`name`, `description`, `type`, `target_value`, `start_time`, `end_time`, `badge_image`, `participant_count`, `status`, `create_time`) VALUES
('30天跑步挑战', '30天内完成100公里跑步', 1, 100, DATE_SUB(NOW(), INTERVAL 15 DAY), DATE_ADD(NOW(), INTERVAL 15 DAY), '/images/badge/challenge_30day.png', 50, 1, DATE_SUB(NOW(), INTERVAL 15 DAY)),
('周末马拉松', '周末完成一次半程马拉松或全程马拉松', 1, 21, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_ADD(NOW(), INTERVAL 5 DAY), '/images/badge/weekend_marathon.png', 30, 1, DATE_SUB(NOW(), INTERVAL 2 DAY)),
('连续打卡7天', '连续7天跑步打卡，每次至少3公里', 3, 7, DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_ADD(NOW(), INTERVAL 2 DAY), '/images/badge/streak_7.png', 100, 1, DATE_SUB(NOW(), INTERVAL 5 DAY));

-- ====================================
-- 8. 用户参加挑战
-- ====================================

INSERT INTO `user_challenge` (`user_id`, `challenge_id`, `progress`, `current_value`, `status`, `join_time`) VALUES
(1, 1, 65.00, 65.00, 1, DATE_SUB(NOW(), INTERVAL 14 DAY)),
(2, 1, 85.50, 85.50, 1, DATE_SUB(NOW(), INTERVAL 13 DAY)),
(3, 1, 45.00, 45.00, 1, DATE_SUB(NOW(), INTERVAL 12 DAY)),
(1, 3, 85.71, 6.00, 1, DATE_SUB(NOW(), INTERVAL 4 DAY)),
(2, 2, 100.00, 21.10, 2, DATE_SUB(NOW(), INTERVAL 2 DAY));

-- ====================================
-- 9. 用户成就
-- ====================================

INSERT INTO `user_achievement` (`user_id`, `achievement_id`, `unlock_time`) VALUES
(1, 1, DATE_SUB(NOW(), INTERVAL 30 DAY)),
(1, 2, DATE_SUB(NOW(), INTERVAL 25 DAY)),
(1, 3, DATE_SUB(NOW(), INTERVAL 20 DAY)),
(1, 6, DATE_SUB(NOW(), INTERVAL 10 DAY)),
(2, 1, DATE_SUB(NOW(), INTERVAL 60 DAY)),
(2, 2, DATE_SUB(NOW(), INTERVAL 55 DAY)),
(2, 3, DATE_SUB(NOW(), INTERVAL 50 DAY)),
(2, 4, DATE_SUB(NOW(), INTERVAL 30 DAY)),
(2, 6, DATE_SUB(NOW(), INTERVAL 25 DAY)),
(2, 7, DATE_SUB(NOW(), INTERVAL 15 DAY)),
(3, 1, DATE_SUB(NOW(), INTERVAL 20 DAY)),
(3, 2, DATE_SUB(NOW(), INTERVAL 15 DAY));

-- ====================================
-- 10. 创建跑团
-- ====================================

INSERT INTO `running_club` (`name`, `logo`, `description`, `city`, `creator_id`, `member_count`, `total_distance`, `status`, `create_time`) VALUES
(1, '北京晨跑团', '/uploads/club/beijing_morning.jpg', '每天早上6点北京朝阳公园集合，欢迎所有热爱跑步的朋友加入！', '北京', 1, 15, 2500.50, 1, DATE_SUB(NOW(), INTERVAL 60 DAY)),
(2, '上海马拉松俱乐部', '/uploads/club/shanghai_marathon.jpg', '专注马拉松训练，帮助跑友实现PB梦想', '上海', 2, 5000.00, 1, DATE_SUB(NOW(), INTERVAL 90 DAY)),
(3, '深圳夜跑联盟', '/uploads/club/shenzhen_night.jpg', '夜跑爱好者的聚集地，每周三次夜跑活动', '深圳', 5, 1800.00, 1, DATE_SUB(NOW(), INTERVAL 45 DAY));

-- ====================================
-- 11. 跑团成员
-- ====================================

INSERT INTO `club_member` (`club_id`, `user_id`, `role`, `join_time`) VALUES
(1, 1, 3, DATE_SUB(NOW(), INTERVAL 60 DAY)),
(1, 4, 2, DATE_SUB(NOW(), INTERVAL 55 DAY)),
(1, 3, 1, DATE_SUB(NOW(), INTERVAL 50 DAY)),
(2, 2, 3, DATE_SUB(NOW(), INTERVAL 90 DAY)),
(2, 1, 1, DATE_SUB(NOW(), INTERVAL 80 DAY)),
(3, 5, 3, DATE_SUB(NOW(), INTERVAL 45 DAY)),
(3, 3, 2, DATE_SUB(NOW(), INTERVAL 40 DAY));

-- ====================================
-- 12. 消息通知
-- ====================================

INSERT INTO `message` (`user_id`, `from_user_id`, `type`, `content`, `related_type`, `related_id`, `is_read`, `create_time`) VALUES
(1, 2, 2, '赞了你的动态', 1, 1, 0, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(1, 3, 3, '评论了你的动态："加油！继续保持！"', 1, 1, 0, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(2, 1, 4, '关注了你', NULL, NULL, 1, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(1, NULL, 1, '恭喜你完成30天跑步挑战！', NULL, NULL, 1, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(2, NULL, 1, '你解锁了新成就：累计500公里', NULL, NULL, 1, DATE_SUB(NOW(), INTERVAL 5 DAY));

-- ====================================
-- 13. 装备记录
-- ====================================

INSERT INTO `equipment` (`user_id`, `type`, `brand`, `model`, `purchase_date`, `mileage`, `status`, `note`, `create_time`) VALUES
(1, 1, 'Nike', 'Zoom Pegasus 39', DATE_SUB(NOW(), INTERVAL 180 DAY), 450.50, 1, '很舒服的跑鞋，推荐！', DATE_SUB(NOW(), INTERVAL 180 DAY)),
(1, 2, 'Garmin', 'Forerunner 945', DATE_SUB(NOW(), INTERVAL 365 DAY), 1200.00, 1, '功能强大，续航给力', DATE_SUB(NOW(), INTERVAL 365 DAY)),
(2, 1, 'Adidas', 'Adizero Boston 10', DATE_SUB(NOW(), INTERVAL 90 DAY), 280.00, 1, '轻便的比赛鞋', DATE_SUB(NOW(), INTERVAL 90 DAY)),
(3, 1, 'Brooks', 'Ghost 14', DATE_SUB(NOW(), INTERVAL 120 DAY), 320.00, 1, '缓震不错', DATE_SUB(NOW(), INTERVAL 120 DAY));

-- ====================================
-- 14. 用户反馈
-- ====================================

INSERT INTO `feedback` (`user_id`, `type`, `content`, `images`, `contact`, `status`, `reply`, `create_time`) VALUES
(1, 2, 'GPS定位有时候会漂移，希望能优化一下', NULL, '13800138001', 1, '感谢反馈，我们会在下个版本优化GPS算法', DATE_SUB(NOW(), INTERVAL 10 DAY)),
(2, 1, '建议增加跑步音乐播放功能', NULL, '13800138002', 0, NULL, DATE_SUB(NOW(), INTERVAL 5 DAY)),
(3, 3, '界面很美观，使用体验很好！', NULL, NULL, 1, '感谢支持！', DATE_SUB(NOW(), INTERVAL 3 DAY));

-- ====================================
-- 15. 更新用户统计数据
-- ====================================

UPDATE `user` SET
    `total_distance` = (SELECT COALESCE(SUM(distance), 0) FROM running_record WHERE user_id = user.id),
    `total_time` = (SELECT COALESCE(SUM(duration), 0) FROM running_record WHERE user_id = user.id),
    `total_count` = (SELECT COUNT(*) FROM running_record WHERE user_id = user.id)
WHERE id IN (1, 2, 3, 4, 5);

-- ====================================
-- 完成
-- ====================================

SELECT '示例数据导入完成！' as message;
SELECT CONCAT('创建用户数: ', COUNT(*)) as user_count FROM user WHERE id BETWEEN 1 AND 5;
SELECT CONCAT('创建跑步记录数: ', COUNT(*)) as record_count FROM running_record;
SELECT CONCAT('创建动态数: ', COUNT(*)) as post_count FROM post;
SELECT CONCAT('创建挑战赛数: ', COUNT(*)) as challenge_count FROM challenge;
SELECT CONCAT('创建跑团数: ', COUNT(*)) as club_count FROM running_club;
