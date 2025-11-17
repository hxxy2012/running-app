# 数据库优化报告 v1.5.9

## 📊 优化概述

本文档记录了对 Running App 数据库架构的全面审查和优化建议。

**审查日期**: 2025-11-17
**数据库版本**: MySQL 8.0+
**优化类别**: 5个主要类别
**发现问题**: 15个问题
**严重程度**: 3个高严重性，8个中严重性，4个低严重性

---

## ⚠️ 发现的问题

### 1. 【高严重性】缺少外键约束

**影响**: 数据完整性无法保证，可能导致数据不一致

**问题描述**:
当前数据库schema中没有定义任何外键约束（FOREIGN KEY），这意味着：
- 可以插入不存在的user_id
- 删除用户时，相关记录不会自动处理
- 数据库层面无法保证引用完整性

**受影响的表**:
- `user_oauth` - user_id没有外键
- `running_record` - user_id没有外键
- `track_point` - record_id没有外键
- `user_training_plan` - user_id, plan_id没有外键
- `post` - user_id, record_id没有外键
- `like` - user_id没有外键
- `comment` - user_id, post_id没有外键
- `follow` - user_id, follow_user_id没有外键
- `club_member` - club_id, user_id没有外键
- `user_challenge` - user_id, challenge_id没有外键
- `user_achievement` - user_id, achievement_id没有外键
- `equipment` - user_id没有外键
- `message` - user_id, from_user_id没有外键

**修复方案**: 添加外键约束（见优化脚本）

---

### 2. 【高严重性】默认JWT密钥不安全

**影响**: 安全漏洞，JWT令牌可被伪造

**问题描述**:
```sql
INSERT INTO `config` (`key`, `value`, `description`) VALUES
('jwt_key', 'your-secret-key-change-this', 'JWT密钥'),
```

默认的JWT密钥是明文且容易被猜到，攻击者可以伪造合法的JWT令牌。

**修复方案**:
1. 从初始化SQL中移除默认JWT密钥
2. 在应用首次启动时自动生成随机密钥
3. 或通过环境变量配置

---

### 3. 【高严重性】sms_code表缺少过期时间索引

**影响**: 定时清理任务性能差

**问题描述**:
`sms_code`表用于存储短信验证码，需要定期清理过期记录：
```sql
DELETE FROM sms_code WHERE expire_time < NOW();
```

但是`expire_time`字段没有索引，大量数据时会导致全表扫描。

**修复方案**: 添加索引 `INDEX idx_expire_time (expire_time)`

---

### 4. 【中严重性】track_point表缺少复合索引

**影响**: 轨迹查询性能差

**问题描述**:
`track_point`表存储GPS轨迹点，是数据量最大的表。常见查询：
```sql
SELECT * FROM track_point
WHERE record_id = ?
ORDER BY timestamp;
```

当前只有`idx_record_id`索引，排序操作无法使用索引。

**修复方案**: 添加复合索引 `INDEX idx_record_time (record_id, timestamp)`

---

### 5. 【中严重性】running_record表缺少is_public索引

**影响**: 公开动态查询性能差

**问题描述**:
查询公开的跑步记录时需要过滤`is_public`：
```sql
SELECT * FROM running_record
WHERE is_public = 1
ORDER BY start_time DESC;
```

当前没有`is_public`索引，无法高效过滤。

**修复方案**: 添加复合索引 `INDEX idx_public_time (is_public, start_time)`

---

### 6. 【中严重性】post表缺少状态索引

**影响**: 动态列表查询需要全表扫描已删除的记录

**问题描述**:
查询正常状态的动态：
```sql
SELECT * FROM post
WHERE status = 1
ORDER BY create_time DESC;
```

`status`字段没有索引。

**修复方案**: 添加复合索引 `INDEX idx_status_time (status, create_time)`

---

### 7. 【中严重性】challenge表缺少状态索引

**影响**: 查询活跃挑战时性能差

**问题描述**:
```sql
SELECT * FROM challenge
WHERE status = 1
AND start_time <= NOW()
AND end_time >= NOW();
```

需要联合索引优化此类查询。

**修复方案**: 添加复合索引 `INDEX idx_status_time (status, start_time, end_time)`

---

### 8. 【中严重性】user_challenge表缺少状态索引

**影响**: 查询用户进行中的挑战性能差

**问题描述**:
```sql
SELECT * FROM user_challenge
WHERE user_id = ? AND status = 1;
```

当前只有`uk_user_challenge (user_id, challenge_id)`唯一索引。

**修复方案**: 添加复合索引 `INDEX idx_user_status (user_id, status)`

---

### 9. 【中严重性】ranking表缺少更新时间索引

**影响**: 清理过期排行榜数据时性能差

**问题描述**:
定时任务需要清理过期的排行榜缓存：
```sql
DELETE FROM ranking
WHERE update_time < DATE_SUB(NOW(), INTERVAL 7 DAY);
```

`update_time`没有索引。

**修复方案**: 添加索引 `INDEX idx_update_time (update_time)`

---

### 10. 【中严重性】message表索引不够优化

**影响**: 查询未读消息性能可优化

**问题描述**:
当前有`INDEX idx_user_id (user_id, is_read)`，但常见查询还需要按时间排序：
```sql
SELECT * FROM message
WHERE user_id = ? AND is_read = 0
ORDER BY create_time DESC;
```

**修复方案**: 改为复合索引 `INDEX idx_user_read_time (user_id, is_read, create_time)`

---

### 11. 【中严重性】follow表缺少双向查询索引

**影响**: 查询粉丝列表性能差

**问题描述**:
当前有：
- `uk_user_follow (user_id, follow_user_id)` - 用于查询"我关注的人"
- `idx_follow_user (follow_user_id)` - 用于查询"关注我的人"

但查询粉丝数时需要：
```sql
SELECT COUNT(*) FROM follow WHERE follow_user_id = ?;
```

虽然有索引，但如果需要分页查询粉丝列表并按时间排序，则需要复合索引。

**修复方案**: 改为 `INDEX idx_follow_user_time (follow_user_id, create_time)`

---

### 12. 【低严重性】user表phone索引重复

**影响**: 轻微的存储浪费

**问题描述**:
```sql
`phone` VARCHAR(20) UNIQUE NOT NULL COMMENT '手机号',
...
INDEX `idx_phone` (`phone`),
```

`phone`字段已经有UNIQUE约束（会自动创建唯一索引），不需要再添加普通索引。

**修复方案**: 删除`idx_phone`索引

---

### 13. 【低严重性】缺少复合索引优化复杂查询

**影响**: 某些复杂查询性能可优化

**问题描述**:
某些表的常见查询模式需要复合索引：

1. `training_plan_detail` - 按计划和周数查询
2. `club_member` - 按跑团和角色查询
3. `equipment` - 按用户和状态查询

**修复方案**: 添加复合索引（见优化脚本）

---

### 14. 【低严重性】user_training_plan表缺少状态索引

**影响**: 查询进行中的训练计划时可优化

**问题描述**:
```sql
SELECT * FROM user_training_plan
WHERE user_id = ? AND status = 1;
```

**修复方案**: 添加复合索引 `INDEX idx_user_status (user_id, status)`

---

### 15. 【低严重性】feedback表缺少状态索引

**影响**: 管理后台查询待处理反馈时可优化

**问题描述**:
```sql
SELECT * FROM feedback
WHERE status = 0
ORDER BY create_time DESC;
```

**修复方案**: 添加复合索引 `INDEX idx_status_time (status, create_time)`

---

## 🔧 优化统计

| 类别 | 问题数 | 严重性 |
|------|--------|--------|
| 外键约束缺失 | 1 | 🔴 高 |
| 安全问题 | 1 | 🔴 高 |
| 性能索引缺失 | 10 | 🟡 中 |
| 索引优化 | 3 | 🟢 低 |
| **总计** | **15** | - |

---

## 📝 数据完整性约束建议

### ON DELETE 策略选择

| 表名 | 外键字段 | ON DELETE 策略 | 原因 |
|------|----------|----------------|------|
| `user_oauth` | user_id | CASCADE | 用户删除时，第三方绑定应一并删除 |
| `running_record` | user_id | CASCADE | 用户删除时，跑步记录应保留或软删除 |
| `track_point` | record_id | CASCADE | 记录删除时，轨迹点应一并删除 |
| `post` | user_id | SET NULL | 用户删除时，动态保留但标记为"用户已删除" |
| `like` | user_id | CASCADE | 用户删除时，点赞记录应删除 |
| `comment` | user_id | SET NULL | 用户删除时，评论保留 |
| `follow` | user_id | CASCADE | 用户删除时，关注关系删除 |
| `message` | user_id | CASCADE | 用户删除时，消息删除 |

**注意**: 在生产环境中，建议使用**软删除**而不是真正的DELETE操作。

---

## 🚀 优化脚本

见 `database/optimization_v1.5.9.sql`

---

## ✅ 测试建议

### 1. 外键约束测试

```sql
-- 测试1: 尝试插入不存在的user_id（应失败）
INSERT INTO running_record (user_id, type, distance, duration, start_time, end_time)
VALUES (99999, 1, 5.0, 1800, NOW(), NOW());
-- Expected: ERROR 1452 (23000): Cannot add or update a child row

-- 测试2: 删除有关联数据的用户（应级联删除或失败）
DELETE FROM user WHERE id = 1;
-- 检查关联表的数据是否按预期处理
```

### 2. 索引性能测试

```sql
-- 测试前：查看执行计划
EXPLAIN SELECT * FROM track_point WHERE record_id = 1 ORDER BY timestamp;

-- 添加索引后：再次查看执行计划
-- 应该看到 "Using index" 而不是 "Using filesort"
```

### 3. 安全性测试

```sql
-- 确认JWT密钥不是默认值
SELECT value FROM config WHERE `key` = 'jwt_key';
-- 应该是随机生成的强密钥，不是 'your-secret-key-change-this'
```

---

## 📈 预期性能提升

| 查询类型 | 优化前 | 优化后 | 提升 |
|---------|--------|--------|------|
| 轨迹点查询（10万条） | ~500ms | ~50ms | 10x |
| 公开记录列表 | ~200ms | ~20ms | 10x |
| 未读消息查询 | ~100ms | ~10ms | 10x |
| 过期验证码清理 | ~1000ms | ~100ms | 10x |
| 排行榜缓存清理 | ~500ms | ~50ms | 10x |

**注**: 具体性能提升取决于数据量和硬件配置。

---

## ⚠️ 应用建议

### 对现有数据的影响

1. **添加外键约束前**，必须先清理不一致的数据：
```sql
-- 检查是否存在无效的user_id
SELECT DISTINCT user_id FROM running_record
WHERE user_id NOT IN (SELECT id FROM user);
```

2. **在生产环境应用外键约束时**，建议：
   - 选择低峰期执行
   - 先在从库测试
   - 准备回滚方案

3. **添加索引时**，大表可能需要较长时间：
   - `track_point`表（可能有百万级数据）
   - 使用 `ALGORITHM=INPLACE` 减少锁表时间
   - 或使用pt-online-schema-change工具

### 部署步骤

1. **备份数据库**
```bash
mysqldump -u root -p running_app > backup_before_optimization.sql
```

2. **在测试环境执行优化脚本**
```bash
mysql -u root -p running_app < optimization_v1.5.9.sql
```

3. **运行测试用例**

4. **在生产环境分阶段应用**
   - 第一阶段：添加索引（影响小）
   - 第二阶段：修复数据不一致
   - 第三阶段：添加外键约束（影响大）
   - 第四阶段：更新应用配置（JWT密钥）

---

## 📚 相关文档

- [MySQL 8.0 外键约束文档](https://dev.mysql.com/doc/refman/8.0/en/create-table-foreign-keys.html)
- [MySQL 索引优化最佳实践](https://dev.mysql.com/doc/refman/8.0/en/optimization-indexes.html)
- [pt-online-schema-change 工具](https://www.percona.com/doc/percona-toolkit/LATEST/pt-online-schema-change.html)

---

## 📊 总结

本次数据库优化主要解决了以下问题：

✅ **数据完整性**: 添加外键约束，保证引用完整性
✅ **性能优化**: 添加12个索引，优化常见查询
✅ **安全加固**: 移除默认JWT密钥
✅ **最佳实践**: 遵循MySQL 8.0最佳实践

**预计整体查询性能提升**: 5-10倍（对于涉及优化索引的查询）

**风险评估**: 中等（需要在生产环境小心应用外键约束）

**建议执行时间**: 系统维护窗口期
