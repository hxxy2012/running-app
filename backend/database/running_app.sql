-- ====================================
-- Running App Database Schema
-- MySQL 8.0+
-- ====================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ====================================
-- 用户相关表
-- ====================================

-- 用户表
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `phone` VARCHAR(20) UNIQUE NOT NULL COMMENT '手机号',
  `password` VARCHAR(255) NOT NULL COMMENT '密码（加密）',
  `nickname` VARCHAR(50) DEFAULT NULL COMMENT '昵称',
  `avatar` VARCHAR(255) DEFAULT NULL COMMENT '头像URL',
  `gender` TINYINT DEFAULT 0 COMMENT '性别：0未知 1男 2女',
  `birthday` DATE DEFAULT NULL COMMENT '生日',
  `height` DECIMAL(5,2) DEFAULT NULL COMMENT '身高(cm)',
  `weight` DECIMAL(5,2) DEFAULT NULL COMMENT '体重(kg)',
  `city` VARCHAR(50) DEFAULT NULL COMMENT '城市',
  `signature` VARCHAR(200) DEFAULT NULL COMMENT '个性签名',
  `real_name` VARCHAR(50) DEFAULT NULL COMMENT '真实姓名',
  `id_card` VARCHAR(18) DEFAULT NULL COMMENT '身份证号',
  `level` TINYINT DEFAULT 1 COMMENT '等级',
  `experience` INT DEFAULT 0 COMMENT '经验值',
  `total_distance` DECIMAL(10,2) DEFAULT 0 COMMENT '总里程(km)',
  `total_time` INT DEFAULT 0 COMMENT '总时长(秒)',
  `total_count` INT DEFAULT 0 COMMENT '总次数',
  `status` TINYINT DEFAULT 1 COMMENT '状态：0禁用 1正常',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_phone` (`phone`),
  INDEX `idx_city` (`city`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 第三方登录绑定表
DROP TABLE IF EXISTS `user_oauth`;
CREATE TABLE `user_oauth` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL COMMENT '用户ID',
  `type` VARCHAR(20) NOT NULL COMMENT '类型：wechat/qq/apple',
  `openid` VARCHAR(100) NOT NULL COMMENT '第三方唯一标识',
  `unionid` VARCHAR(100) DEFAULT NULL COMMENT '联合ID',
  `access_token` VARCHAR(255) DEFAULT NULL,
  `refresh_token` VARCHAR(255) DEFAULT NULL,
  `expires_in` INT DEFAULT NULL,
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_type_openid` (`type`, `openid`),
  INDEX `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='第三方登录绑定';

-- 短信验证码表
DROP TABLE IF EXISTS `sms_code`;
CREATE TABLE `sms_code` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `phone` VARCHAR(20) NOT NULL COMMENT '手机号',
  `code` VARCHAR(10) NOT NULL COMMENT '验证码',
  `type` TINYINT DEFAULT 1 COMMENT '类型：1注册 2登录 3重置密码',
  `status` TINYINT DEFAULT 0 COMMENT '状态：0未使用 1已使用',
  `expire_time` DATETIME NOT NULL COMMENT '过期时间',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='短信验证码';

-- ====================================
-- 跑步记录相关表
-- ====================================

-- 跑步记录表
DROP TABLE IF EXISTS `running_record`;
CREATE TABLE `running_record` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL COMMENT '用户ID',
  `type` TINYINT DEFAULT 1 COMMENT '运动类型：1跑步 2骑行 3健走 4登山 5室内跑',
  `distance` DECIMAL(10,2) NOT NULL COMMENT '距离(km)',
  `duration` INT NOT NULL COMMENT '时长(秒)',
  `avg_pace` INT DEFAULT NULL COMMENT '平均配速(秒/公里)',
  `best_pace` INT DEFAULT NULL COMMENT '最佳配速(秒/公里)',
  `avg_speed` DECIMAL(5,2) DEFAULT NULL COMMENT '平均速度(km/h)',
  `step_count` INT DEFAULT NULL COMMENT '步数',
  `step_frequency` INT DEFAULT NULL COMMENT '步频(步/分钟)',
  `calories` INT DEFAULT NULL COMMENT '卡路里(kcal)',
  `climb` DECIMAL(10,2) DEFAULT 0 COMMENT '累计爬升(m)',
  `descent` DECIMAL(10,2) DEFAULT 0 COMMENT '累计下降(m)',
  `avg_heart_rate` INT DEFAULT NULL COMMENT '平均心率',
  `max_heart_rate` INT DEFAULT NULL COMMENT '最大心率',
  `track_file` VARCHAR(255) DEFAULT NULL COMMENT '轨迹文件路径',
  `map_image` VARCHAR(255) DEFAULT NULL COMMENT '地图截图',
  `start_time` DATETIME NOT NULL COMMENT '开始时间',
  `end_time` DATETIME NOT NULL COMMENT '结束时间',
  `start_location` VARCHAR(100) DEFAULT NULL COMMENT '起点位置',
  `city` VARCHAR(50) DEFAULT NULL COMMENT '城市',
  `weather` VARCHAR(50) DEFAULT NULL COMMENT '天气',
  `temperature` INT DEFAULT NULL COMMENT '温度(℃)',
  `feeling` TINYINT DEFAULT 0 COMMENT '感觉：0一般 1轻松 2良好 3困难 4痛苦',
  `note` TEXT DEFAULT NULL COMMENT '备注',
  `is_public` TINYINT DEFAULT 1 COMMENT '是否公开：0私密 1公开',
  `share_count` INT DEFAULT 0 COMMENT '分享次数',
  `like_count` INT DEFAULT 0 COMMENT '点赞数',
  `comment_count` INT DEFAULT 0 COMMENT '评论数',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_user_id` (`user_id`),
  INDEX `idx_start_time` (`start_time`),
  INDEX `idx_city` (`city`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='跑步记录';

-- 轨迹坐标表
DROP TABLE IF EXISTS `track_point`;
CREATE TABLE `track_point` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `record_id` INT UNSIGNED NOT NULL COMMENT '记录ID',
  `latitude` DECIMAL(10,8) NOT NULL COMMENT '纬度',
  `longitude` DECIMAL(11,8) NOT NULL COMMENT '经度',
  `altitude` DECIMAL(8,2) DEFAULT NULL COMMENT '海拔(m)',
  `accuracy` DECIMAL(5,2) DEFAULT NULL COMMENT '精度(m)',
  `speed` DECIMAL(5,2) DEFAULT NULL COMMENT '瞬时速度(km/h)',
  `heart_rate` INT DEFAULT NULL COMMENT '心率',
  `timestamp` BIGINT NOT NULL COMMENT '时间戳(ms)',
  `distance_from_start` DECIMAL(10,2) DEFAULT NULL COMMENT '距起点距离(km)',
  INDEX `idx_record_id` (`record_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='轨迹坐标点';

-- ====================================
-- 训练计划相关表
-- ====================================

-- 训练计划模板表
DROP TABLE IF EXISTS `training_plan`;
CREATE TABLE `training_plan` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL COMMENT '计划名称',
  `description` TEXT COMMENT '描述',
  `target_type` TINYINT NOT NULL COMMENT '目标类型：1距离 2时间 3配速',
  `target_value` VARCHAR(50) NOT NULL COMMENT '目标值',
  `duration_weeks` TINYINT NOT NULL COMMENT '训练周数',
  `level` TINYINT DEFAULT 1 COMMENT '难度：1入门 2进阶 3高级',
  `is_preset` TINYINT DEFAULT 0 COMMENT '是否预设：0自定义 1系统预设',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='训练计划模板';

-- 用户训练计划表
DROP TABLE IF EXISTS `user_training_plan`;
CREATE TABLE `user_training_plan` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL,
  `plan_id` INT UNSIGNED NOT NULL,
  `start_date` DATE NOT NULL COMMENT '开始日期',
  `status` TINYINT DEFAULT 1 COMMENT '状态：1进行中 2已完成 3已放弃',
  `current_week` TINYINT DEFAULT 1 COMMENT '当前周数',
  `completed_days` INT DEFAULT 0 COMMENT '已完成天数',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户训练计划';

-- 训练计划详情表
DROP TABLE IF EXISTS `training_plan_detail`;
CREATE TABLE `training_plan_detail` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `plan_id` INT UNSIGNED NOT NULL,
  `week_num` TINYINT NOT NULL COMMENT '第几周',
  `day_num` TINYINT NOT NULL COMMENT '第几天',
  `type` TINYINT NOT NULL COMMENT '类型：1跑步 2休息 3交叉训练',
  `distance` DECIMAL(5,2) DEFAULT NULL COMMENT '距离(km)',
  `duration` INT DEFAULT NULL COMMENT '时长(分钟)',
  `pace` VARCHAR(20) DEFAULT NULL COMMENT '配速要求',
  `description` TEXT COMMENT '说明',
  INDEX `idx_plan_id` (`plan_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='训练计划详情';

-- ====================================
-- 社交功能相关表
-- ====================================

-- 动态表
DROP TABLE IF EXISTS `post`;
CREATE TABLE `post` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL,
  `record_id` INT UNSIGNED DEFAULT NULL COMMENT '关联跑步记录',
  `content` TEXT COMMENT '内容',
  `images` TEXT COMMENT '图片URL（JSON数组）',
  `location` VARCHAR(100) DEFAULT NULL COMMENT '位置',
  `type` TINYINT DEFAULT 1 COMMENT '类型：1普通 2跑步分享 3话题',
  `topic_id` INT UNSIGNED DEFAULT NULL COMMENT '话题ID',
  `like_count` INT DEFAULT 0,
  `comment_count` INT DEFAULT 0,
  `share_count` INT DEFAULT 0,
  `is_public` TINYINT DEFAULT 1 COMMENT '是否公开',
  `status` TINYINT DEFAULT 1 COMMENT '状态：0删除 1正常',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_user_id` (`user_id`),
  INDEX `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='动态';

-- 点赞表
DROP TABLE IF EXISTS `like`;
CREATE TABLE `like` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL,
  `target_type` TINYINT NOT NULL COMMENT '目标类型：1动态 2评论',
  `target_id` INT UNSIGNED NOT NULL,
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_user_target` (`user_id`, `target_type`, `target_id`),
  INDEX `idx_target` (`target_type`, `target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='点赞';

-- 评论表
DROP TABLE IF EXISTS `comment`;
CREATE TABLE `comment` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL,
  `post_id` INT UNSIGNED NOT NULL,
  `parent_id` INT UNSIGNED DEFAULT NULL COMMENT '父评论ID',
  `to_user_id` INT UNSIGNED DEFAULT NULL COMMENT '回复给谁',
  `content` TEXT NOT NULL,
  `like_count` INT DEFAULT 0,
  `status` TINYINT DEFAULT 1,
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_post_id` (`post_id`),
  INDEX `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='评论';

-- 关注表
DROP TABLE IF EXISTS `follow`;
CREATE TABLE `follow` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL COMMENT '关注者',
  `follow_user_id` INT UNSIGNED NOT NULL COMMENT '被关注者',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_user_follow` (`user_id`, `follow_user_id`),
  INDEX `idx_follow_user` (`follow_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='关注';

-- ====================================
-- 跑团相关表
-- ====================================

-- 跑团表
DROP TABLE IF EXISTS `running_club`;
CREATE TABLE `running_club` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `logo` VARCHAR(255) DEFAULT NULL,
  `description` TEXT,
  `city` VARCHAR(50) DEFAULT NULL,
  `creator_id` INT UNSIGNED NOT NULL,
  `member_count` INT DEFAULT 1,
  `total_distance` DECIMAL(10,2) DEFAULT 0,
  `status` TINYINT DEFAULT 1,
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_city` (`city`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='跑团';

-- 跑团成员表
DROP TABLE IF EXISTS `club_member`;
CREATE TABLE `club_member` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `club_id` INT UNSIGNED NOT NULL,
  `user_id` INT UNSIGNED NOT NULL,
  `role` TINYINT DEFAULT 1 COMMENT '角色：1成员 2管理员 3团长',
  `join_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_club_user` (`club_id`, `user_id`),
  INDEX `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='跑团成员';

-- ====================================
-- 挑战与成就相关表
-- ====================================

-- 挑战赛表
DROP TABLE IF EXISTS `challenge`;
CREATE TABLE `challenge` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT,
  `type` TINYINT NOT NULL COMMENT '类型：1距离 2次数 3连续天数',
  `target_value` INT NOT NULL COMMENT '目标值',
  `start_time` DATETIME NOT NULL,
  `end_time` DATETIME NOT NULL,
  `badge_image` VARCHAR(255) DEFAULT NULL COMMENT '徽章图片',
  `participant_count` INT DEFAULT 0,
  `status` TINYINT DEFAULT 1,
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_time` (`start_time`, `end_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='挑战赛';

-- 用户挑战表
DROP TABLE IF EXISTS `user_challenge`;
CREATE TABLE `user_challenge` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL,
  `challenge_id` INT UNSIGNED NOT NULL,
  `progress` DECIMAL(5,2) DEFAULT 0 COMMENT '完成进度(%)',
  `current_value` DECIMAL(10,2) DEFAULT 0 COMMENT '当前值',
  `status` TINYINT DEFAULT 1 COMMENT '状态：1进行中 2已完成 3失败',
  `complete_time` DATETIME DEFAULT NULL,
  `join_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_user_challenge` (`user_id`, `challenge_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户挑战';

-- 成就表
DROP TABLE IF EXISTS `achievement`;
CREATE TABLE `achievement` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) NOT NULL,
  `icon` VARCHAR(255) NOT NULL,
  `type` VARCHAR(50) NOT NULL COMMENT '类型标识',
  `condition_value` INT NOT NULL COMMENT '达成条件值',
  `level` TINYINT DEFAULT 1 COMMENT '等级',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='成就';

-- 用户成就表
DROP TABLE IF EXISTS `user_achievement`;
CREATE TABLE `user_achievement` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL,
  `achievement_id` INT UNSIGNED NOT NULL,
  `unlock_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_user_achievement` (`user_id`, `achievement_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户成就';

-- ====================================
-- 排行榜相关表
-- ====================================

-- 排行榜表（临时统计表，定时任务更新）
DROP TABLE IF EXISTS `ranking`;
CREATE TABLE `ranking` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL,
  `type` VARCHAR(20) NOT NULL COMMENT '类型：total/month/week',
  `scope` VARCHAR(20) DEFAULT 'national' COMMENT '范围：national/city/friends',
  `scope_value` VARCHAR(50) DEFAULT NULL COMMENT '范围值（城市名等）',
  `distance` DECIMAL(10,2) DEFAULT 0,
  `rank` INT NOT NULL,
  `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_ranking` (`type`, `scope`, `scope_value`, `user_id`),
  INDEX `idx_rank` (`type`, `scope`, `scope_value`, `rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='排行榜';

-- ====================================
-- 其他功能表
-- ====================================

-- 装备表
DROP TABLE IF EXISTS `equipment`;
CREATE TABLE `equipment` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL,
  `type` TINYINT DEFAULT 1 COMMENT '类型：1跑鞋 2手表 3其他',
  `brand` VARCHAR(50) DEFAULT NULL,
  `model` VARCHAR(100) DEFAULT NULL,
  `purchase_date` DATE DEFAULT NULL,
  `mileage` DECIMAL(10,2) DEFAULT 0 COMMENT '使用里程',
  `status` TINYINT DEFAULT 1 COMMENT '状态：1使用中 2已退役',
  `note` TEXT,
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='运动装备';

-- 消息表
DROP TABLE IF EXISTS `message`;
CREATE TABLE `message` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL COMMENT '接收者',
  `from_user_id` INT UNSIGNED DEFAULT NULL COMMENT '发送者',
  `type` TINYINT NOT NULL COMMENT '类型：1系统 2点赞 3评论 4关注 5私信',
  `content` TEXT,
  `related_type` TINYINT DEFAULT NULL COMMENT '关联类型',
  `related_id` INT UNSIGNED DEFAULT NULL COMMENT '关联ID',
  `is_read` TINYINT DEFAULT 0,
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_user_id` (`user_id`, `is_read`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='消息';

-- 反馈表
DROP TABLE IF EXISTS `feedback`;
CREATE TABLE `feedback` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL,
  `type` TINYINT NOT NULL COMMENT '类型：1功能建议 2Bug反馈 3其他',
  `content` TEXT NOT NULL,
  `images` TEXT COMMENT '截图',
  `contact` VARCHAR(100) DEFAULT NULL,
  `status` TINYINT DEFAULT 0 COMMENT '状态：0待处理 1已处理',
  `reply` TEXT DEFAULT NULL,
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户反馈';

-- 系统配置表
DROP TABLE IF EXISTS `config`;
CREATE TABLE `config` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `key` VARCHAR(100) UNIQUE NOT NULL,
  `value` TEXT,
  `description` VARCHAR(255) DEFAULT NULL,
  `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统配置';

-- ====================================
-- 插入初始数据
-- ====================================

-- 系统配置初始数据
INSERT INTO `config` (`key`, `value`, `description`) VALUES
('app_name', 'Running App', '应用名称'),
('version', '1.0.0', '当前版本'),
('jwt_key', 'your-secret-key-change-this', 'JWT密钥'),
('sms_provider', 'aliyun', '短信服务商'),
('upload_max_size', '5242880', '上传文件最大大小（字节）'),
('avatar_default', '/uploads/avatar/default.png', '默认头像');

-- 成就初始数据
INSERT INTO `achievement` (`name`, `description`, `icon`, `type`, `condition_value`, `level`) VALUES
('首次完成', '完成第一次跑步', '/images/badge/first_run.png', 'first_run', 1, 1),
('5公里达成', '单次完成5公里', '/images/badge/5km.png', 'distance_5km', 5, 1),
('10公里达成', '单次完成10公里', '/images/badge/10km.png', 'distance_10km', 10, 2),
('半程马拉松', '单次完成21.0975公里', '/images/badge/half_marathon.png', 'half_marathon', 21, 3),
('全程马拉松', '单次完成42.195公里', '/images/badge/full_marathon.png', 'full_marathon', 42, 4),
('累计100公里', '累计跑步100公里', '/images/badge/total_100km.png', 'total_distance', 100, 2),
('累计500公里', '累计跑步500公里', '/images/badge/total_500km.png', 'total_distance', 500, 3),
('累计1000公里', '累计跑步1000公里', '/images/badge/total_1000km.png', 'total_distance', 1000, 4),
('连续打卡7天', '连续7天跑步打卡', '/images/badge/streak_7.png', 'streak', 7, 1),
('连续打卡30天', '连续30天跑步打卡', '/images/badge/streak_30.png', 'streak', 30, 2),
('速度突破', '配速达到4分钟/公里', '/images/badge/speed.png', 'pace', 240, 3);

-- 训练计划初始数据
INSERT INTO `training_plan` (`name`, `description`, `target_type`, `target_value`, `duration_weeks`, `level`, `is_preset`) VALUES
('5公里入门计划', '适合零基础跑者，8周完成5公里', 1, '5', 8, 1, 1),
('10公里进阶计划', '适合有一定基础的跑者，12周完成10公里', 1, '10', 12, 2, 1),
('半程马拉松计划', '适合有10公里基础的跑者，16周完成半马', 1, '21', 16, 3, 1),
('全程马拉松计划', '适合有半马基础的跑者，20周完成全马', 1, '42', 20, 3, 1);

SET FOREIGN_KEY_CHECKS = 1;
