-- ====================================
-- Running App 数据库优化脚本 v1.5.9
-- ====================================
-- 执行前请先备份数据库！
-- mysqldump -u root -p running_app > backup_before_optimization.sql
-- ====================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ====================================
-- 第一部分：删除重复索引
-- ====================================

-- user表：删除重复的phone索引（UNIQUE已经创建了索引）
ALTER TABLE `user` DROP INDEX `idx_phone`;

-- ====================================
-- 第二部分：添加性能优化索引
-- ====================================

-- 1. sms_code表：添加过期时间索引（用于定时清理）
ALTER TABLE `sms_code` ADD INDEX `idx_expire_time` (`expire_time`);

-- 2. track_point表：添加复合索引（record_id + timestamp）
-- 注意：这个表数据量可能很大，建议使用pt-online-schema-change工具
ALTER TABLE `track_point` DROP INDEX `idx_record_id`;
ALTER TABLE `track_point` ADD INDEX `idx_record_time` (`record_id`, `timestamp`);

-- 3. running_record表：添加公开状态+时间复合索引
ALTER TABLE `running_record` ADD INDEX `idx_public_time` (`is_public`, `start_time`);

-- 4. post表：添加状态+时间复合索引
ALTER TABLE `post` DROP INDEX `idx_create_time`;
ALTER TABLE `post` ADD INDEX `idx_status_time` (`status`, `create_time`);

-- 5. challenge表：添加状态+时间复合索引
ALTER TABLE `challenge` DROP INDEX `idx_time`;
ALTER TABLE `challenge` ADD INDEX `idx_status_time` (`status`, `start_time`, `end_time`);

-- 6. user_challenge表：添加用户+状态复合索引
ALTER TABLE `user_challenge` ADD INDEX `idx_user_status` (`user_id`, `status`);

-- 7. ranking表：添加更新时间索引（用于清理过期数据）
ALTER TABLE `ranking` ADD INDEX `idx_update_time` (`update_time`);

-- 8. message表：优化索引（用户+已读+时间）
ALTER TABLE `message` DROP INDEX `idx_user_id`;
ALTER TABLE `message` ADD INDEX `idx_user_read_time` (`user_id`, `is_read`, `create_time`);

-- 9. follow表：优化被关注者索引（添加时间字段）
ALTER TABLE `follow` DROP INDEX `idx_follow_user`;
ALTER TABLE `follow` ADD INDEX `idx_follow_user_time` (`follow_user_id`, `create_time`);

-- 10. user_training_plan表：添加用户+状态复合索引
ALTER TABLE `user_training_plan` ADD INDEX `idx_user_status` (`user_id`, `status`);

-- 11. training_plan_detail表：添加计划+周数复合索引
ALTER TABLE `training_plan_detail` ADD INDEX `idx_plan_week` (`plan_id`, `week_num`, `day_num`);

-- 12. club_member表：添加用户+角色复合索引
ALTER TABLE `club_member` ADD INDEX `idx_user_role` (`user_id`, `role`);

-- 13. equipment表：添加用户+状态复合索引
ALTER TABLE `equipment` ADD INDEX `idx_user_status` (`user_id`, `status`);

-- 14. feedback表：添加状态+时间复合索引
ALTER TABLE `feedback` ADD INDEX `idx_status_time` (`status`, `create_time`);

-- ====================================
-- 第三部分：数据清理（为添加外键做准备）
-- ====================================

-- 注意：以下语句会删除不一致的数据，请谨慎执行！
-- 建议先检查是否存在不一致数据：

-- 检查user_oauth中无效的user_id
SELECT COUNT(*) as invalid_count FROM user_oauth
WHERE user_id NOT IN (SELECT id FROM user);

-- 检查running_record中无效的user_id
SELECT COUNT(*) as invalid_count FROM running_record
WHERE user_id NOT IN (SELECT id FROM user);

-- 检查track_point中无效的record_id
SELECT COUNT(*) as invalid_count FROM track_point
WHERE record_id NOT IN (SELECT id FROM running_record);

-- 如果发现不一致数据，取消注释以下语句进行清理：
-- DELETE FROM user_oauth WHERE user_id NOT IN (SELECT id FROM user);
-- DELETE FROM running_record WHERE user_id NOT IN (SELECT id FROM user);
-- DELETE FROM track_point WHERE record_id NOT IN (SELECT id FROM running_record);
-- DELETE FROM user_training_plan WHERE user_id NOT IN (SELECT id FROM user);
-- DELETE FROM user_training_plan WHERE plan_id NOT IN (SELECT id FROM training_plan);
-- DELETE FROM post WHERE user_id NOT IN (SELECT id FROM user);
-- DELETE FROM like WHERE user_id NOT IN (SELECT id FROM user);
-- DELETE FROM comment WHERE user_id NOT IN (SELECT id FROM user);
-- DELETE FROM comment WHERE post_id NOT IN (SELECT id FROM post);
-- DELETE FROM follow WHERE user_id NOT IN (SELECT id FROM user);
-- DELETE FROM follow WHERE follow_user_id NOT IN (SELECT id FROM user);
-- DELETE FROM club_member WHERE club_id NOT IN (SELECT id FROM running_club);
-- DELETE FROM club_member WHERE user_id NOT IN (SELECT id FROM user);
-- DELETE FROM user_challenge WHERE user_id NOT IN (SELECT id FROM user);
-- DELETE FROM user_challenge WHERE challenge_id NOT IN (SELECT id FROM challenge);
-- DELETE FROM user_achievement WHERE user_id NOT IN (SELECT id FROM user);
-- DELETE FROM user_achievement WHERE achievement_id NOT IN (SELECT id FROM achievement);
-- DELETE FROM equipment WHERE user_id NOT IN (SELECT id FROM user);
-- DELETE FROM message WHERE user_id NOT IN (SELECT id FROM user);
-- DELETE FROM feedback WHERE user_id NOT IN (SELECT id FROM user);

-- ====================================
-- 第四部分：添加外键约束
-- ====================================

-- 注意：添加外键前必须确保数据一致性！
-- 外键约束会强制引用完整性，防止数据不一致

-- 1. user_oauth表
ALTER TABLE `user_oauth`
ADD CONSTRAINT `fk_user_oauth_user`
FOREIGN KEY (`user_id`) REFERENCES `user`(`id`)
ON DELETE CASCADE ON UPDATE CASCADE;

-- 2. sms_code表（不需要外键，手机号可能未注册）

-- 3. running_record表
ALTER TABLE `running_record`
ADD CONSTRAINT `fk_running_record_user`
FOREIGN KEY (`user_id`) REFERENCES `user`(`id`)
ON DELETE CASCADE ON UPDATE CASCADE;

-- 4. track_point表
ALTER TABLE `track_point`
ADD CONSTRAINT `fk_track_point_record`
FOREIGN KEY (`record_id`) REFERENCES `running_record`(`id`)
ON DELETE CASCADE ON UPDATE CASCADE;

-- 5. user_training_plan表
ALTER TABLE `user_training_plan`
ADD CONSTRAINT `fk_user_training_plan_user`
FOREIGN KEY (`user_id`) REFERENCES `user`(`id`)
ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT `fk_user_training_plan_plan`
FOREIGN KEY (`plan_id`) REFERENCES `training_plan`(`id`)
ON DELETE CASCADE ON UPDATE CASCADE;

-- 6. training_plan_detail表
ALTER TABLE `training_plan_detail`
ADD CONSTRAINT `fk_training_plan_detail_plan`
FOREIGN KEY (`plan_id`) REFERENCES `training_plan`(`id`)
ON DELETE CASCADE ON UPDATE CASCADE;

-- 7. post表（用户删除时保留动态，但user_id设为NULL）
-- 先修改user_id字段允许NULL
ALTER TABLE `post` MODIFY `user_id` INT UNSIGNED DEFAULT NULL;
ALTER TABLE `post`
ADD CONSTRAINT `fk_post_user`
FOREIGN KEY (`user_id`) REFERENCES `user`(`id`)
ON DELETE SET NULL ON UPDATE CASCADE;

-- post表的record_id外键
ALTER TABLE `post`
ADD CONSTRAINT `fk_post_record`
FOREIGN KEY (`record_id`) REFERENCES `running_record`(`id`)
ON DELETE SET NULL ON UPDATE CASCADE;

-- 8. like表
ALTER TABLE `like`
ADD CONSTRAINT `fk_like_user`
FOREIGN KEY (`user_id`) REFERENCES `user`(`id`)
ON DELETE CASCADE ON UPDATE CASCADE;

-- 9. comment表（用户删除时保留评论）
ALTER TABLE `comment` MODIFY `user_id` INT UNSIGNED DEFAULT NULL;
ALTER TABLE `comment`
ADD CONSTRAINT `fk_comment_user`
FOREIGN KEY (`user_id`) REFERENCES `user`(`id`)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT `fk_comment_post`
FOREIGN KEY (`post_id`) REFERENCES `post`(`id`)
ON DELETE CASCADE ON UPDATE CASCADE;

-- 10. follow表
ALTER TABLE `follow`
ADD CONSTRAINT `fk_follow_user`
FOREIGN KEY (`user_id`) REFERENCES `user`(`id`)
ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT `fk_follow_follow_user`
FOREIGN KEY (`follow_user_id`) REFERENCES `user`(`id`)
ON DELETE CASCADE ON UPDATE CASCADE;

-- 11. running_club表
ALTER TABLE `running_club`
ADD CONSTRAINT `fk_running_club_creator`
FOREIGN KEY (`creator_id`) REFERENCES `user`(`id`)
ON DELETE RESTRICT ON UPDATE CASCADE;

-- 12. club_member表
ALTER TABLE `club_member`
ADD CONSTRAINT `fk_club_member_club`
FOREIGN KEY (`club_id`) REFERENCES `running_club`(`id`)
ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT `fk_club_member_user`
FOREIGN KEY (`user_id`) REFERENCES `user`(`id`)
ON DELETE CASCADE ON UPDATE CASCADE;

-- 13. challenge表（不需要外键）

-- 14. user_challenge表
ALTER TABLE `user_challenge`
ADD CONSTRAINT `fk_user_challenge_user`
FOREIGN KEY (`user_id`) REFERENCES `user`(`id`)
ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT `fk_user_challenge_challenge`
FOREIGN KEY (`challenge_id`) REFERENCES `challenge`(`id`)
ON DELETE CASCADE ON UPDATE CASCADE;

-- 15. achievement表（不需要外键）

-- 16. user_achievement表
ALTER TABLE `user_achievement`
ADD CONSTRAINT `fk_user_achievement_user`
FOREIGN KEY (`user_id`) REFERENCES `user`(`id`)
ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT `fk_user_achievement_achievement`
FOREIGN KEY (`achievement_id`) REFERENCES `achievement`(`id`)
ON DELETE CASCADE ON UPDATE CASCADE;

-- 17. ranking表（不添加外键，因为是临时统计表）

-- 18. equipment表
ALTER TABLE `equipment`
ADD CONSTRAINT `fk_equipment_user`
FOREIGN KEY (`user_id`) REFERENCES `user`(`id`)
ON DELETE CASCADE ON UPDATE CASCADE;

-- 19. message表（from_user_id允许为NULL）
ALTER TABLE `message`
ADD CONSTRAINT `fk_message_user`
FOREIGN KEY (`user_id`) REFERENCES `user`(`id`)
ON DELETE CASCADE ON UPDATE CASCADE;

-- message表的from_user_id外键（用户删除时设为NULL）
ALTER TABLE `message`
ADD CONSTRAINT `fk_message_from_user`
FOREIGN KEY (`from_user_id`) REFERENCES `user`(`id`)
ON DELETE SET NULL ON UPDATE CASCADE;

-- 20. feedback表
ALTER TABLE `feedback`
ADD CONSTRAINT `fk_feedback_user`
FOREIGN KEY (`user_id`) REFERENCES `user`(`id`)
ON DELETE CASCADE ON UPDATE CASCADE;

-- ====================================
-- 第五部分：安全优化
-- ====================================

-- 移除不安全的默认JWT密钥
DELETE FROM `config` WHERE `key` = 'jwt_key';

-- 添加说明：JWT密钥应通过环境变量或首次启动时自动生成
INSERT INTO `config` (`key`, `value`, `description`) VALUES
('jwt_key', '', 'JWT密钥（应通过env('jwt.secret')配置或自动生成）');

-- ====================================
-- 第六部分：数据完整性增强
-- ====================================

-- 为某些字段添加CHECK约束（MySQL 8.0.16+支持）

-- user表：性别只能是0,1,2
ALTER TABLE `user`
ADD CONSTRAINT `chk_user_gender`
CHECK (`gender` IN (0, 1, 2));

-- user表：状态只能是0,1
ALTER TABLE `user`
ADD CONSTRAINT `chk_user_status`
CHECK (`status` IN (0, 1));

-- running_record表：距离必须大于0
ALTER TABLE `running_record`
ADD CONSTRAINT `chk_record_distance`
CHECK (`distance` > 0);

-- running_record表：时长必须大于0
ALTER TABLE `running_record`
ADD CONSTRAINT `chk_record_duration`
CHECK (`duration` > 0);

-- running_record表：公开状态只能是0,1
ALTER TABLE `running_record`
ADD CONSTRAINT `chk_record_public`
CHECK (`is_public` IN (0, 1));

-- challenge表：目标值必须大于0
ALTER TABLE `challenge`
ADD CONSTRAINT `chk_challenge_target`
CHECK (`target_value` > 0);

-- challenge表：结束时间必须大于开始时间
ALTER TABLE `challenge`
ADD CONSTRAINT `chk_challenge_time`
CHECK (`end_time` > `start_time`);

-- ====================================
-- 第七部分：添加有用的视图
-- ====================================

-- 创建用户统计视图
CREATE OR REPLACE VIEW `view_user_stats` AS
SELECT
    u.id,
    u.nickname,
    u.avatar,
    u.level,
    u.total_distance,
    u.total_time,
    u.total_count,
    COUNT(DISTINCT f1.follow_user_id) as following_count,
    COUNT(DISTINCT f2.user_id) as follower_count,
    COUNT(DISTINCT p.id) as post_count
FROM user u
LEFT JOIN follow f1 ON u.id = f1.user_id
LEFT JOIN follow f2 ON u.id = f2.follow_user_id
LEFT JOIN post p ON u.id = p.user_id AND p.status = 1
WHERE u.status = 1
GROUP BY u.id;

-- 创建跑步记录统计视图（含点赞评论数）
CREATE OR REPLACE VIEW `view_record_with_stats` AS
SELECT
    r.*,
    u.nickname,
    u.avatar,
    r.like_count,
    r.comment_count
FROM running_record r
LEFT JOIN user u ON r.user_id = u.id
WHERE r.is_public = 1;

-- ====================================
-- 完成
-- ====================================

SET FOREIGN_KEY_CHECKS = 1;

-- 优化完成后，建议执行以下命令优化表：
-- OPTIMIZE TABLE user, running_record, track_point, post, comment;

-- 查看表的索引情况：
-- SHOW INDEX FROM running_record;

-- 查看表的外键约束：
-- SELECT
--   TABLE_NAME,
--   COLUMN_NAME,
--   CONSTRAINT_NAME,
--   REFERENCED_TABLE_NAME,
--   REFERENCED_COLUMN_NAME
-- FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
-- WHERE TABLE_SCHEMA = 'running_app' AND REFERENCED_TABLE_NAME IS NOT NULL;

SELECT '数据库优化脚本执行完成！' as message;
SELECT '请检查以上执行结果，确保没有错误。' as reminder;
SELECT '建议在应用层面配置JWT密钥通过环境变量读取。' as security_tip;
