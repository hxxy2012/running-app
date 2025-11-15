# Running App 数据库设计文档

## 数据库概览

**数据库名称**: `running_app`

**字符集**: `utf8mb4`

**排序规则**: `utf8mb4_unicode_ci`

**总表数**: 30+

---

## ER图说明

```
用户(User) 1---N 跑步记录(RunningRecord)
跑步记录(RunningRecord) 1---N 轨迹点(TrackPoint)
用户(User) 1---N 动态(Post)
用户(User) N---N 关注(Follow)
用户(User) N---N 跑团(RunningClub) [通过ClubMember]
用户(User) N---N 挑战(Challenge) [通过UserChallenge]
用户(User) N---N 成就(Achievement) [通过UserAchievement]
```

---

## 数据表详细设计

### 1. 用户相关表

#### 1.1 user (用户表)

**表名**: `user`

**说明**: 存储用户基本信息

| 字段 | 类型 | 空 | 默认值 | 说明 |
|------|------|-----|--------|------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | 用户ID（主键） |
| phone | VARCHAR(20) | NO | - | 手机号（唯一） |
| password | VARCHAR(255) | NO | - | 密码（bcrypt加密） |
| nickname | VARCHAR(50) | YES | NULL | 昵称 |
| avatar | VARCHAR(255) | YES | NULL | 头像URL |
| gender | TINYINT | YES | 0 | 性别：0未知 1男 2女 |
| birthday | DATE | YES | NULL | 生日 |
| height | DECIMAL(5,2) | YES | NULL | 身高(cm) |
| weight | DECIMAL(5,2) | YES | NULL | 体重(kg) |
| city | VARCHAR(50) | YES | NULL | 城市 |
| signature | VARCHAR(200) | YES | NULL | 个性签名 |
| real_name | VARCHAR(50) | YES | NULL | 真实姓名 |
| id_card | VARCHAR(18) | YES | NULL | 身份证号 |
| level | TINYINT | YES | 1 | 等级 |
| experience | INT | YES | 0 | 经验值 |
| total_distance | DECIMAL(10,2) | YES | 0 | 总里程(km) |
| total_time | INT | YES | 0 | 总时长(秒) |
| total_count | INT | YES | 0 | 总次数 |
| status | TINYINT | YES | 1 | 状态：0禁用 1正常 |
| create_time | DATETIME | YES | CURRENT_TIMESTAMP | 创建时间 |
| update_time | DATETIME | YES | CURRENT_TIMESTAMP | 更新时间 |

**索引**:
- PRIMARY KEY (`id`)
- UNIQUE KEY (`phone`)
- INDEX `idx_phone` (`phone`)
- INDEX `idx_city` (`city`)

**设计说明**:
- `password`字段使用bcrypt算法加密存储
- `total_distance`、`total_time`、`total_count`为冗余字段，用于快速查询统计数据
- `level`和`experience`用于用户等级系统

---

#### 1.2 user_oauth (第三方登录绑定表)

**表名**: `user_oauth`

**说明**: 存储用户第三方登录信息

| 字段 | 类型 | 空 | 默认值 | 说明 |
|------|------|-----|--------|------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | 主键 |
| user_id | INT UNSIGNED | NO | - | 用户ID |
| type | VARCHAR(20) | NO | - | 类型：wechat/qq/apple |
| openid | VARCHAR(100) | NO | - | 第三方唯一标识 |
| unionid | VARCHAR(100) | YES | NULL | 联合ID |
| access_token | VARCHAR(255) | YES | NULL | 访问令牌 |
| refresh_token | VARCHAR(255) | YES | NULL | 刷新令牌 |
| expires_in | INT | YES | NULL | 过期时间 |
| create_time | DATETIME | YES | CURRENT_TIMESTAMP | 创建时间 |

**索引**:
- PRIMARY KEY (`id`)
- UNIQUE KEY `uk_type_openid` (`type`, `openid`)
- INDEX `idx_user_id` (`user_id`)

---

#### 1.3 sms_code (短信验证码表)

**表名**: `sms_code`

**说明**: 存储短信验证码

| 字段 | 类型 | 空 | 默认值 | 说明 |
|------|------|-----|--------|------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | 主键 |
| phone | VARCHAR(20) | NO | - | 手机号 |
| code | VARCHAR(10) | NO | - | 验证码 |
| type | TINYINT | YES | 1 | 类型：1注册 2登录 3重置密码 |
| status | TINYINT | YES | 0 | 状态：0未使用 1已使用 |
| expire_time | DATETIME | NO | - | 过期时间 |
| create_time | DATETIME | YES | CURRENT_TIMESTAMP | 创建时间 |

**索引**:
- PRIMARY KEY (`id`)
- INDEX `idx_phone` (`phone`)

**设计说明**:
- `expire_time`默认为发送时间+5分钟
- 验证后将`status`设置为1，防止重复使用

---

### 2. 跑步记录相关表

#### 2.1 running_record (跑步记录表)

**表名**: `running_record`

**说明**: 存储每次跑步的记录

| 字段 | 类型 | 空 | 默认值 | 说明 |
|------|------|-----|--------|------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | 记录ID（主键） |
| user_id | INT UNSIGNED | NO | - | 用户ID |
| type | TINYINT | YES | 1 | 运动类型：1跑步 2骑行 3健走 4登山 5室内跑 |
| distance | DECIMAL(10,2) | NO | - | 距离(km) |
| duration | INT | NO | - | 时长(秒) |
| avg_pace | INT | YES | NULL | 平均配速(秒/公里) |
| best_pace | INT | YES | NULL | 最佳配速(秒/公里) |
| avg_speed | DECIMAL(5,2) | YES | NULL | 平均速度(km/h) |
| step_count | INT | YES | NULL | 步数 |
| step_frequency | INT | YES | NULL | 步频(步/分钟) |
| calories | INT | YES | NULL | 卡路里(kcal) |
| climb | DECIMAL(10,2) | YES | 0 | 累计爬升(m) |
| descent | DECIMAL(10,2) | YES | 0 | 累计下降(m) |
| avg_heart_rate | INT | YES | NULL | 平均心率 |
| max_heart_rate | INT | YES | NULL | 最大心率 |
| track_file | VARCHAR(255) | YES | NULL | 轨迹文件路径 |
| map_image | VARCHAR(255) | YES | NULL | 地图截图 |
| start_time | DATETIME | NO | - | 开始时间 |
| end_time | DATETIME | NO | - | 结束时间 |
| start_location | VARCHAR(100) | YES | NULL | 起点位置 |
| city | VARCHAR(50) | YES | NULL | 城市 |
| weather | VARCHAR(50) | YES | NULL | 天气 |
| temperature | INT | YES | NULL | 温度(℃) |
| feeling | TINYINT | YES | 0 | 感觉：0一般 1轻松 2良好 3困难 4痛苦 |
| note | TEXT | YES | NULL | 备注 |
| is_public | TINYINT | YES | 1 | 是否公开：0私密 1公开 |
| share_count | INT | YES | 0 | 分享次数 |
| like_count | INT | YES | 0 | 点赞数 |
| comment_count | INT | YES | 0 | 评论数 |
| create_time | DATETIME | YES | CURRENT_TIMESTAMP | 创建时间 |

**索引**:
- PRIMARY KEY (`id`)
- INDEX `idx_user_id` (`user_id`)
- INDEX `idx_start_time` (`start_time`)
- INDEX `idx_city` (`city`)

**设计说明**:
- `duration`存储秒数，方便计算
- `avg_pace`和`best_pace`也存储秒数
- `track_file`存储JSON格式的完整轨迹数据
- `like_count`、`comment_count`为冗余字段，减少关联查询

---

#### 2.2 track_point (轨迹坐标表)

**表名**: `track_point`

**说明**: 存储GPS轨迹坐标点

| 字段 | 类型 | 空 | 默认值 | 说明 |
|------|------|-----|--------|------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | 主键 |
| record_id | INT UNSIGNED | NO | - | 记录ID |
| latitude | DECIMAL(10,8) | NO | - | 纬度 |
| longitude | DECIMAL(11,8) | NO | - | 经度 |
| altitude | DECIMAL(8,2) | YES | NULL | 海拔(m) |
| accuracy | DECIMAL(5,2) | YES | NULL | 精度(m) |
| speed | DECIMAL(5,2) | YES | NULL | 瞬时速度(km/h) |
| heart_rate | INT | YES | NULL | 心率 |
| timestamp | BIGINT | NO | - | 时间戳(ms) |
| distance_from_start | DECIMAL(10,2) | YES | NULL | 距起点距离(km) |

**索引**:
- PRIMARY KEY (`id`)
- INDEX `idx_record_id` (`record_id`)

**设计说明**:
- 使用BIGINT主键，支持海量数据
- `timestamp`使用毫秒级时间戳
- `accuracy`表示GPS定位精度，用于数据过滤
- 建议定期归档历史数据

---

### 3. 训练计划相关表

#### 3.1 training_plan (训练计划模板表)

**表名**: `training_plan`

**说明**: 存储训练计划模板

| 字段 | 类型 | 空 | 默认值 | 说明 |
|------|------|-----|--------|------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | 主键 |
| name | VARCHAR(100) | NO | - | 计划名称 |
| description | TEXT | YES | NULL | 描述 |
| target_type | TINYINT | NO | - | 目标类型：1距离 2时间 3配速 |
| target_value | VARCHAR(50) | NO | - | 目标值 |
| duration_weeks | TINYINT | NO | - | 训练周数 |
| level | TINYINT | YES | 1 | 难度：1入门 2进阶 3高级 |
| is_preset | TINYINT | YES | 0 | 是否预设：0自定义 1系统预设 |
| create_time | DATETIME | YES | CURRENT_TIMESTAMP | 创建时间 |

---

### 4. 社交功能相关表

#### 4.1 post (动态表)

**表名**: `post`

**说明**: 存储用户动态

| 字段 | 类型 | 空 | 默认值 | 说明 |
|------|------|-----|--------|------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | 主键 |
| user_id | INT UNSIGNED | NO | - | 用户ID |
| record_id | INT UNSIGNED | YES | NULL | 关联跑步记录 |
| content | TEXT | YES | NULL | 内容 |
| images | TEXT | YES | NULL | 图片URL（JSON数组） |
| location | VARCHAR(100) | YES | NULL | 位置 |
| type | TINYINT | YES | 1 | 类型：1普通 2跑步分享 3话题 |
| topic_id | INT UNSIGNED | YES | NULL | 话题ID |
| like_count | INT | YES | 0 | 点赞数 |
| comment_count | INT | YES | 0 | 评论数 |
| share_count | INT | YES | 0 | 分享数 |
| is_public | TINYINT | YES | 1 | 是否公开 |
| status | TINYINT | YES | 1 | 状态：0删除 1正常 |
| create_time | DATETIME | YES | CURRENT_TIMESTAMP | 创建时间 |

**索引**:
- PRIMARY KEY (`id`)
- INDEX `idx_user_id` (`user_id`)
- INDEX `idx_create_time` (`create_time`)

---

#### 4.2 like (点赞表)

**表名**: `like`

**说明**: 存储点赞记录

| 字段 | 类型 | 空 | 默认值 | 说明 |
|------|------|-----|--------|------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | 主键 |
| user_id | INT UNSIGNED | NO | - | 用户ID |
| target_type | TINYINT | NO | - | 目标类型：1动态 2评论 |
| target_id | INT UNSIGNED | NO | - | 目标ID |
| create_time | DATETIME | YES | CURRENT_TIMESTAMP | 创建时间 |

**索引**:
- PRIMARY KEY (`id`)
- UNIQUE KEY `uk_user_target` (`user_id`, `target_type`, `target_id`)
- INDEX `idx_target` (`target_type`, `target_id`)

**设计说明**:
- 使用唯一索引防止重复点赞
- `target_type`和`target_id`组合表示点赞对象

---

#### 4.3 comment (评论表)

**表名**: `comment`

**说明**: 存储评论

| 字段 | 类型 | 空 | 默认值 | 说明 |
|------|------|-----|--------|------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | 主键 |
| user_id | INT UNSIGNED | NO | - | 用户ID |
| post_id | INT UNSIGNED | NO | - | 动态ID |
| parent_id | INT UNSIGNED | YES | NULL | 父评论ID |
| to_user_id | INT UNSIGNED | YES | NULL | 回复给谁 |
| content | TEXT | NO | - | 内容 |
| like_count | INT | YES | 0 | 点赞数 |
| status | TINYINT | YES | 1 | 状态 |
| create_time | DATETIME | YES | CURRENT_TIMESTAMP | 创建时间 |

**索引**:
- PRIMARY KEY (`id`)
- INDEX `idx_post_id` (`post_id`)
- INDEX `idx_user_id` (`user_id`)

---

#### 4.4 follow (关注表)

**表名**: `follow`

**说明**: 存储关注关系

| 字段 | 类型 | 空 | 默认值 | 说明 |
|------|------|-----|--------|------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | 主键 |
| user_id | INT UNSIGNED | NO | - | 关注者 |
| follow_user_id | INT UNSIGNED | NO | - | 被关注者 |
| create_time | DATETIME | YES | CURRENT_TIMESTAMP | 创建时间 |

**索引**:
- PRIMARY KEY (`id`)
- UNIQUE KEY `uk_user_follow` (`user_id`, `follow_user_id`)
- INDEX `idx_follow_user` (`follow_user_id`)

---

### 5. 其他表

#### 5.1 ranking (排行榜表)

**表名**: `ranking`

**说明**: 存储排行榜数据（由定时任务更新）

| 字段 | 类型 | 空 | 默认值 | 说明 |
|------|------|-----|--------|------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | 主键 |
| user_id | INT UNSIGNED | NO | - | 用户ID |
| type | VARCHAR(20) | NO | - | 类型：total/month/week |
| scope | VARCHAR(20) | YES | national | 范围：national/city/friends |
| scope_value | VARCHAR(50) | YES | NULL | 范围值（城市名等） |
| distance | DECIMAL(10,2) | YES | 0 | 距离 |
| rank | INT | NO | - | 排名 |
| update_time | DATETIME | YES | CURRENT_TIMESTAMP | 更新时间 |

**索引**:
- PRIMARY KEY (`id`)
- UNIQUE KEY `uk_ranking` (`type`, `scope`, `scope_value`, `user_id`)
- INDEX `idx_rank` (`type`, `scope`, `scope_value`, `rank`)

**设计说明**:
- 这是一个临时统计表，由定时任务每天更新
- 避免实时查询带来的性能问题

---

## 数据字典

### 运动类型
- 1: 跑步
- 2: 骑行
- 3: 健走
- 4: 登山
- 5: 室内跑

### 性别
- 0: 未知
- 1: 男
- 2: 女

### 感觉
- 0: 一般
- 1: 轻松
- 2: 良好
- 3: 困难
- 4: 痛苦

### 第三方登录类型
- wechat: 微信
- qq: QQ
- apple: Apple ID

---

## 性能优化建议

### 1. 索引优化
- 为常用查询字段添加索引
- 避免过多索引影响写入性能
- 定期分析慢查询并优化

### 2. 分区表
对于数据量大的表（如`track_point`），建议按时间分区:
```sql
ALTER TABLE track_point PARTITION BY RANGE (YEAR(FROM_UNIXTIME(timestamp/1000)))
(
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p2026 VALUES LESS THAN (2027)
);
```

### 3. 归档策略
- `sms_code`: 保留3个月数据
- `track_point`: 保留2年数据，超过2年的归档到历史表

### 4. 读写分离
- 主库负责写操作
- 从库负责读操作
- 使用中间件（如ProxySQL）实现

---

**更新日期**: 2025-11-15
**文档版本**: v1.0
