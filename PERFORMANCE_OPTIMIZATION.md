# 性能优化指南

本文档提供Running App的全面性能优化指南和最佳实践。

## 目录

- [数据库优化](#数据库优化)
- [缓存策略](#缓存策略)
- [API性能优化](#api性能优化)
- [前端性能优化](#前端性能优化)
- [服务器配置优化](#服务器配置优化)
- [监控和诊断](#监控和诊断)
- [性能测试](#性能测试)

---

## 数据库优化

### 1. 索引优化

#### 已创建的关键索引

```sql
-- 用户表
CREATE INDEX idx_user_phone ON user(phone);
CREATE INDEX idx_user_username ON user(username);
CREATE INDEX idx_user_create_time ON user(create_time);

-- 跑步记录表
CREATE INDEX idx_running_user_id ON running_record(user_id);
CREATE INDEX idx_running_start_time ON running_record(start_time);
CREATE INDEX idx_running_distance ON running_record(distance);
CREATE INDEX idx_running_user_start ON running_record(user_id, start_time);

-- 帖子表
CREATE INDEX idx_post_user_id ON post(user_id);
CREATE INDEX idx_post_create_time ON post(create_time);
CREATE INDEX idx_post_user_create ON post(user_id, create_time);

-- 点赞表
CREATE INDEX idx_like_target ON like(target_type, target_id);
CREATE INDEX idx_like_user_target ON like(user_id, target_type, target_id);

-- 评论表
CREATE INDEX idx_comment_target ON comment(target_type, target_id);
CREATE INDEX idx_comment_user_id ON comment(user_id);
```

#### 索引使用建议

1. **查询优化原则**
   - WHERE子句中的列优先创建索引
   - ORDER BY和GROUP BY的列考虑索引
   - 联合查询的JOIN列必须有索引
   - 选择性高的列优先（值分布广泛）

2. **避免索引失效**
   ```php
   // ❌ 错误：在索引列上使用函数
   Db::name('user')->where('DATE(create_time)', '=', $date)->select();

   // ✅ 正确：使用范围查询
   Db::name('user')->whereBetweenTime('create_time', $date . ' 00:00:00', $date . ' 23:59:59')->select();

   // ❌ 错误：LIKE以%开头
   Db::name('user')->where('username', 'like', '%abc')->select();

   // ✅ 正确：LIKE不以%开头
   Db::name('user')->where('username', 'like', 'abc%')->select();
   ```

### 2. 查询优化

#### 使用EXPLAIN分析查询

```sql
EXPLAIN SELECT * FROM running_record WHERE user_id = 1 ORDER BY start_time DESC LIMIT 20;
```

**关键字段说明：**
- `type`: ALL表示全表扫描（最差），index、range、ref、const性能依次提升
- `key`: 实际使用的索引
- `rows`: 扫描的行数（越少越好）
- `Extra`:
  - `Using filesort` - 需要额外排序（性能差）
  - `Using temporary` - 使用临时表（性能差）
  - `Using index` - 覆盖索引（性能好）

#### 分页查询优化

```php
// ❌ 传统分页（大offset性能差）
$list = Db::name('running_record')
    ->where('user_id', $userId)
    ->order('id', 'desc')
    ->limit(1000, 20)  // offset=1000时很慢
    ->select();

// ✅ 延迟关联优化
$subQuery = Db::name('running_record')
    ->where('user_id', $userId)
    ->order('id', 'desc')
    ->limit(1000, 20)
    ->field('id')
    ->buildSql();

$list = Db::name('running_record')
    ->alias('r')
    ->join([$subQuery => 'ids'], 'r.id = ids.id')
    ->select();

// ✅ 游标分页（推荐）
$lastId = $request->param('last_id', 0);
$list = Db::name('running_record')
    ->where('user_id', $userId)
    ->where('id', '<', $lastId)
    ->order('id', 'desc')
    ->limit(20)
    ->select();
```

### 3. 连接池配置

**config/database.php**

```php
'mysql' => [
    // 连接池配置
    'pool' => [
        'min_connections' => 1,
        'max_connections' => 10,
        'connect_timeout' => 10.0,
        'wait_timeout'    => 3.0,
        'heartbeat'       => -1,
        'max_idle_time'   => 60.0,
    ],

    // 查询超时
    'timeout' => 5,

    // 断线重连
    'break_reconnect' => true,
],
```

### 4. 慢查询优化

#### 启用慢查询日志

**my.cnf配置：**

```ini
[mysqld]
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow-query.log
long_query_time = 1
log_queries_not_using_indexes = 1
```

#### 分析慢查询

```bash
# 使用analyze_logs.sh分析慢查询
./scripts/analyze_logs.sh

# 或使用mysqldumpslow
mysqldumpslow -s t -t 10 /var/log/mysql/slow-query.log
```

---

## 缓存策略

### 1. 多级缓存架构

```
请求 → 本地内存缓存 → Redis缓存 → 数据库
       (1-10ms)      (1-5ms)      (10-100ms)
```

### 2. Redis缓存使用

#### 用户信息缓存

```php
use app\common\service\CacheService;

// 获取用户信息（自动缓存）
$userInfo = CacheService::remember(
    CacheService::key(CacheService::KEY_USER, "info:{$userId}"),
    function() use ($userId) {
        return Db::name('user')->find($userId);
    },
    CacheService::LONG_TTL  // 24小时
);

// 更新用户信息后清除缓存
CacheService::deleteUserInfo($userId);
```

#### 列表数据缓存

```php
// 跑步记录列表缓存
$list = CacheService::getRunningList($userId, $page);

if ($list === null) {
    $list = Db::name('running_record')
        ->where('user_id', $userId)
        ->page($page, 20)
        ->order('start_time', 'desc')
        ->select();

    CacheService::setRunningList($userId, $page, $list);
}
```

#### 排行榜缓存

```php
// 缓存1小时
$ranking = CacheService::getRanking('distance', 'weekly');

if ($ranking === null) {
    $ranking = $this->calculateRanking('distance', 'weekly');
    CacheService::setRanking('distance', 'weekly', $ranking);
}
```

### 3. 缓存更新策略

#### Cache-Aside Pattern（旁路缓存）

```php
// 读取
public function getUserInfo($userId)
{
    // 1. 先读缓存
    $user = CacheService::getUserInfo($userId);

    if ($user) {
        return $user;
    }

    // 2. 缓存未命中，读数据库
    $user = Db::name('user')->find($userId);

    // 3. 写入缓存
    if ($user) {
        CacheService::setUserInfo($userId, $user);
    }

    return $user;
}

// 更新
public function updateUserInfo($userId, $data)
{
    // 1. 更新数据库
    Db::name('user')->where('id', $userId)->update($data);

    // 2. 删除缓存（让下次读取时重新加载）
    CacheService::deleteUserInfo($userId);
}
```

#### Write-Through Pattern（写透缓存）

```php
public function updateUserInfo($userId, $data)
{
    // 1. 更新数据库
    Db::name('user')->where('id', $userId)->update($data);

    // 2. 立即更新缓存
    $user = Db::name('user')->find($userId);
    CacheService::setUserInfo($userId, $user);
}
```

### 4. 缓存问题防护

#### 缓存穿透（查询不存在的数据）

```php
// 使用空值缓存
$user = CacheService::remember($key, function() use ($userId) {
    return Db::name('user')->find($userId);
}, 300);  // 空值缓存5分钟

// 或使用布隆过滤器
```

#### 缓存雪崩（大量缓存同时过期）

```php
// 随机TTL，避免同时过期
$ttl = CacheService::DEFAULT_TTL + mt_rand(0, 300);
CacheService::set($key, $value, $ttl);
```

#### 缓存击穿（热点数据过期）

```php
// 使用互斥锁
$lockKey = "lock:{$key}";

if (!CacheService::has($key)) {
    if (CacheService::set($lockKey, 1, 10)) {  // 10秒锁
        try {
            $value = $this->loadFromDatabase();
            CacheService::set($key, $value, 3600);
        } finally {
            CacheService::delete($lockKey);
        }
    } else {
        // 等待其他线程加载缓存
        sleep(0.1);
        return $this->getData();  // 递归重试
    }
}
```

---

## API性能优化

### 1. 响应时间目标

| 接口类型 | 响应时间目标 | 优化优先级 |
|---------|-------------|-----------|
| 核心读接口 | < 100ms | P0 |
| 列表查询 | < 200ms | P1 |
| 写入接口 | < 300ms | P1 |
| 复杂统计 | < 500ms | P2 |

### 2. 数据库查询优化

```php
// ❌ 避免N+1查询
$posts = Db::name('post')->select();
foreach ($posts as &$post) {
    $post['user'] = Db::name('user')->find($post['user_id']);  // N次查询
}

// ✅ 使用JOIN或预加载
$posts = Db::name('post')
    ->alias('p')
    ->join('user u', 'p.user_id = u.id')
    ->field('p.*, u.username, u.avatar')
    ->select();
```

### 3. 字段选择优化

```php
// ❌ 避免SELECT *
$users = Db::name('user')->select();

// ✅ 只查询需要的字段
$users = Db::name('user')
    ->field('id, username, avatar, nickname')
    ->select();
```

### 4. 批量操作

```php
// ❌ 逐条插入
foreach ($records as $record) {
    Db::name('running_record')->insert($record);
}

// ✅ 批量插入
Db::name('running_record')->insertAll($records);
```

### 5. 异步处理

```php
// 对于非核心业务，使用队列异步处理
Queue::push(function() use ($userId) {
    // 更新用户统计
    $this->updateUserStats($userId);

    // 检查成就
    $this->checkAchievements($userId);

    // 发送通知
    $this->sendNotifications($userId);
});
```

---

## 前端性能优化

### 1. 图片优化

```php
// 上传时自动压缩和生成多尺寸
public function uploadImage($file)
{
    // 原图
    $original = $this->saveImage($file);

    // 生成缩略图
    $this->generateThumbnail($original, 200, 200);  // 列表缩略图
    $this->generateThumbnail($original, 800, 800);  // 详情图

    // WebP格式
    $this->convertToWebP($original);

    return $urls;
}
```

### 2. 响应数据优化

```php
// ❌ 返回所有字段
return json([
    'code' => 200,
    'data' => $user  // 包含password等敏感字段
]);

// ✅ 只返回必要字段
return json([
    'code' => 200,
    'data' => [
        'id' => $user['id'],
        'username' => $user['username'],
        'avatar' => $user['avatar'],
        'nickname' => $user['nickname']
    ]
]);
```

### 3. 分页加载

```javascript
// 使用游标分页而不是页码分页
{
    "last_id": 12345,
    "limit": 20
}
```

---

## 服务器配置优化

### 1. Nginx配置

详见 `config/nginx.conf.example`

关键优化点：
- Gzip压缩
- HTTP/2支持
- 静态文件缓存
- FastCGI缓存
- 连接复用

### 2. PHP-FPM配置

**/etc/php/8.0/fpm/pool.d/www.conf**

```ini
; 进程管理模式
pm = dynamic

; 最大子进程数
pm.max_children = 50

; 启动时进程数
pm.start_servers = 5

; 最小空闲进程数
pm.min_spare_servers = 5

; 最大空闲进程数
pm.max_spare_servers = 10

; 每个子进程处理请求数后重启
pm.max_requests = 1000

; 慢请求日志
request_slowlog_timeout = 5s
slowlog = /var/log/php-fpm/slow.log
```

### 3. MySQL配置

**/etc/mysql/my.cnf**

```ini
[mysqld]
# 缓冲池大小（建议为物理内存的50-70%）
innodb_buffer_pool_size = 2G

# 日志文件大小
innodb_log_file_size = 256M

# 并发线程数
innodb_thread_concurrency = 8

# 查询缓存（MySQL 8.0已废弃）
# query_cache_size = 64M

# 最大连接数
max_connections = 200

# 临时表大小
tmp_table_size = 64M
max_heap_table_size = 64M

# 排序缓冲
sort_buffer_size = 2M

# JOIN缓冲
join_buffer_size = 2M
```

---

## 监控和诊断

### 1. 性能监控

```bash
# 实时监控
./scripts/monitor.sh

# 查看监控指标
curl http://localhost:8000/metrics

# Prometheus + Grafana
# 配置Prometheus抓取 /metrics 端点
```

### 2. 健康检查

```bash
# 基础健康检查
curl http://localhost:8000/health

# 详细健康检查
curl http://localhost:8000/health/detailed
```

### 3. 日志分析

```bash
# 分析错误日志和慢查询
./scripts/analyze_logs.sh
```

### 4. APM工具

推荐工具：
- **New Relic** - 全面的APM解决方案
- **Datadog** - 基础设施和应用监控
- **Elastic APM** - 开源APM方案
- **Sentry** - 错误追踪和性能监控

---

## 性能测试

### 1. 压力测试

```bash
# 快速测试
./scripts/load_test.sh quick

# 标准测试
./scripts/load_test.sh normal

# 压力测试
./scripts/load_test.sh stress
```

### 2. 基准测试

```bash
# 测试单个API
ab -n 1000 -c 50 http://localhost:8000/api/user/info

# 使用JMeter进行复杂场景测试
jmeter -n -t tests/jmeter/api_test.jmx -l results.jtl
```

### 3. 性能基准

| 接口 | QPS目标 | 平均响应时间 | P95响应时间 |
|-----|---------|------------|------------|
| /user/info | 1000 | 50ms | 100ms |
| /running/list | 500 | 80ms | 150ms |
| /post/feed | 500 | 100ms | 200ms |
| /running/save | 200 | 150ms | 300ms |

---

## 性能优化清单

### 高优先级 (P0)

- [x] 数据库索引优化
- [x] Redis缓存实现
- [x] 慢查询优化
- [x] N+1查询消除
- [ ] 图片CDN配置
- [ ] API响应压缩

### 中优先级 (P1)

- [x] Nginx配置优化
- [x] PHP-FPM调优
- [ ] MySQL配置优化
- [x] 分页查询优化
- [ ] 静态资源缓存
- [x] 监控告警配置

### 低优先级 (P2)

- [ ] 读写分离
- [ ] 数据库分库分表
- [ ] 全文搜索引擎(Elasticsearch)
- [ ] 消息队列(RabbitMQ/Kafka)
- [ ] 微服务拆分

---

## 性能问题排查流程

1. **确认问题**
   - 使用monitoring工具定位慢接口
   - 查看日志确认错误

2. **定位瓶颈**
   - 数据库慢查询？ → 优化SQL和索引
   - 缓存未命中？ → 检查缓存策略
   - CPU高？ → 检查代码逻辑
   - 内存高？ → 检查内存泄漏

3. **优化实施**
   - 添加索引
   - 增加缓存
   - 优化查询
   - 异步处理

4. **验证效果**
   - 压力测试
   - 监控指标对比
   - 用户反馈

---

## 参考资源

- [MySQL性能优化最佳实践](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)
- [Redis最佳实践](https://redis.io/docs/manual/patterns/)
- [Nginx性能优化](https://www.nginx.com/blog/tuning-nginx/)
- [PHP性能优化](https://www.php.net/manual/en/features.performance.php)

---

**版本**: 1.0
**最后更新**: 2024-11-17
**维护**: Running App Team
