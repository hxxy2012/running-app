# Running App - 运维监控指南

本文档提供完整的运维和监控方案，确保应用稳定高效运行。

---

## 📋 目录

- [监控方案](#监控方案)
- [日志管理](#日志管理)
- [性能优化](#性能优化)
- [安全加固](#安全加固)
- [故障处理](#故障处理)
- [定期维护](#定期维护)

---

## 🔍 监控方案

### 1. 系统监控工具

#### monitor.sh - 性能监控脚本

**功能**:
- API性能监控
- 数据库性能监控
- 系统资源监控
- 生成监控报告

**使用方法**:
```bash
# 监控所有
./scripts/monitor.sh

# 只监控API
./scripts/monitor.sh --api

# 只监控数据库
./scripts/monitor.sh --db

# 只监控系统资源
./scripts/monitor.sh --system

# 生成报告
./scripts/monitor.sh --all --report
```

**定时任务**:
```cron
# 每小时API监控
0 * * * * /path/to/scripts/monitor.sh --api >> /var/log/monitor.log 2>&1

# 每天数据库监控
0 2 * * * /path/to/scripts/monitor.sh --db >> /var/log/monitor.log 2>&1

# 每15分钟系统监控
*/15 * * * * /path/to/scripts/monitor.sh --system >> /var/log/monitor.log 2>&1
```

**监控指标**:

| 指标 | 正常值 | 警告阈值 | 危险阈值 |
|------|--------|----------|----------|
| API响应时间 | < 0.5s | > 1s | > 2s |
| CPU使用率 | < 70% | > 80% | > 90% |
| 内存使用率 | < 70% | > 80% | > 90% |
| 磁盘使用率 | < 80% | > 90% | > 95% |
| 数据库连接数 | < 100 | > 150 | > 200 |
| 慢查询数 | 0 | > 10 | > 50 |

---

## 📊 日志管理

### 1. 日志分析工具

#### analyze_logs.sh - 日志分析脚本

**功能**:
- 错误日志分析
- 访问日志分析
- 慢查询分析
- 生成分析报告

**使用方法**:
```bash
# 分析所有日志
./scripts/analyze_logs.sh

# 只分析错误日志
./scripts/analyze_logs.sh --errors

# 只分析访问日志
./scripts/analyze_logs.sh --access

# 只分析慢查询
./scripts/analyze_logs.sh --slow

# 只分析今天的日志
./scripts/analyze_logs.sh --today

# 生成报告
./scripts/analyze_logs.sh --all --report
```

**定时任务**:
```cron
# 每天分析日志
0 1 * * * /path/to/scripts/analyze_logs.sh >> /var/log/log_analysis.log 2>&1
```

### 2. 日志轮转配置

创建 `/etc/logrotate.d/running-app`:
```bash
/var/www/running-app/backend/runtime/log/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
    sharedscripts
    postrotate
        # 通知应用重新打开日志文件
        systemctl reload php8.1-fpm
    endscript
}
```

### 3. 日志级别配置

**开发环境**:
```php
// backend/.env
APP_DEBUG = true
LOG_LEVEL = debug
```

**生产环境**:
```php
// backend/.env
APP_DEBUG = false
LOG_LEVEL = error
```

---

## 🚀 性能优化

### 1. 数据库优化

#### 应用优化脚本
```bash
mysql -u root -p running_app < backend/database/optimization_v1.5.9.sql
```

**优化内容**:
- ✅ 添加20+外键约束
- ✅ 添加14个性能索引
- ✅ 添加CHECK约束
- ✅ 创建统计视图

**效果**:
- 查询性能提升 5-10倍
- 数据完整性保证
- 复杂查询优化

#### 慢查询监控
```bash
# 启用慢查询日志
# 在 my.cnf 中添加:
slow_query_log = 1
slow_query_log_file = /var/log/mysql/mysql-slow.log
long_query_time = 1

# 分析慢查询
./scripts/analyze_logs.sh --slow
```

### 2. PHP优化

#### OPcache配置
```ini
; /etc/php/8.1/fpm/conf.d/10-opcache.ini
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=10000
opcache.revalidate_freq=2
opcache.fast_shutdown=1
```

#### PHP-FPM配置
```ini
; /etc/php/8.1/fpm/pool.d/www.conf
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500
```

### 3. Nginx优化

**使用优化配置**:
```bash
cp config/nginx.conf.example /etc/nginx/sites-available/running-app
# 编辑配置文件，修改域名和路径
nginx -t
systemctl reload nginx
```

**优化要点**:
- ✅ HTTP/2启用
- ✅ Gzip压缩
- ✅ 静态文件缓存
- ✅ FastCGI缓存
- ✅ 速率限制

### 4. Redis缓存

**安装Redis**:
```bash
sudo apt-get install redis-server
```

**配置**:
```php
// backend/.env
CACHE_TYPE = redis
REDIS_HOST = 127.0.0.1
REDIS_PORT = 6379
```

---

## 🔒 安全加固

### 1. 安全检查工具

#### security_check.sh - 安全检查脚本

**功能**:
- Composer依赖安全检查
- 配置文件安全检查
- 文件权限检查
- 代码安全检查
- SSL/TLS检查

**使用方法**:
```bash
./scripts/security_check.sh
```

**定时任务**:
```cron
# 每天安全检查
0 3 * * * /path/to/scripts/security_check.sh >> /var/log/security.log 2>&1
```

### 2. 安全清单

**必须配置**:
- [x] 修改默认JWT密钥
- [x] 使用强数据库密码
- [x] 关闭调试模式（生产环境）
- [x] 启用HTTPS
- [x] 配置防火墙
- [x] 设置文件权限

**推荐配置**:
- [x] 启用SSL证书
- [x] 配置安全Headers
- [x] 启用速率限制
- [x] 配置IP白名单
- [x] 定期更新依赖

### 3. 防火墙配置

```bash
# UFW配置
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable

# 限制SSH登录尝试
sudo ufw limit 22/tcp
```

### 4. 定期更新

```bash
# 检查过时的依赖
cd backend && composer outdated

# 更新依赖
composer update

# 安全审计
composer audit
```

---

## 🧹 系统清理

### cleanup.sh - 系统清理脚本

**功能**:
- 清理旧日志文件
- 清理缓存文件
- 清理临时文件
- 清理上传文件（可选）

**使用方法**:
```bash
# 默认清理（日志+缓存+临时文件）
./scripts/cleanup.sh

# 模拟模式（不实际删除）
./scripts/cleanup.sh --dry-run

# 清理所有
./scripts/cleanup.sh --all

# 清理指定类型
./scripts/cleanup.sh --logs
./scripts/cleanup.sh --cache
./scripts/cleanup.sh --tmp
```

**定时任务**:
```cron
# 每周清理一次
0 0 * * 0 /path/to/scripts/cleanup.sh >> /var/log/cleanup.log 2>&1
```

**保留策略**:
- 日志文件: 7天
- 缓存文件: 3天
- 临时文件: 1天
- 上传文件: 90天（需明确指定）

---

## 💾 备份与恢复

### 1. 备份策略

**使用backup.sh**:
```bash
# 手动备份
./scripts/backup.sh

# 备份到指定目录
./scripts/backup.sh /mnt/backup
```

**定时备份**:
```cron
# 每天凌晨2点自动备份
0 2 * * * /path/to/scripts/backup.sh >> /var/log/backup.log 2>&1
```

**备份内容**:
- ✅ 数据库完整备份
- ✅ 上传文件备份
- ✅ 配置文件备份
- ✅ 自动压缩
- ✅ 完整性验证
- ✅ 自动清理过期备份（7天）

### 2. 远程备份

**同步到远程服务器**:
```bash
# 备份后同步
./scripts/backup.sh && \
rsync -avz /var/backups/running-app/ user@remote:/backups/
```

**云存储备份**:
```bash
# 上传到AWS S3
aws s3 sync /var/backups/running-app/ s3://my-backup-bucket/

# 上传到阿里云OSS
ossutil cp -r /var/backups/running-app/ oss://my-bucket/backups/
```

### 3. 恢复流程

**恢复数据库**:
```bash
gunzip < backup.sql.gz | mysql -u root -p running_app
```

**恢复文件**:
```bash
tar -xzf uploads_backup.tar.gz -C backend/
tar -xzf config_backup.tar.gz -C backend/
```

---

## 🚨 故障处理

### 常见问题

#### 1. 服务器无响应

**检查步骤**:
```bash
# 1. 检查服务状态
systemctl status nginx
systemctl status php8.1-fpm
systemctl status mysql

# 2. 检查端口
netstat -tulpn | grep :80
netstat -tulpn | grep :443

# 3. 检查日志
tail -100 /var/log/nginx/error.log
tail -100 /var/log/php8.1-fpm.log
```

**解决方案**:
```bash
# 重启服务
systemctl restart nginx
systemctl restart php8.1-fpm
```

#### 2. 数据库连接失败

**检查步骤**:
```bash
# 检查MySQL状态
systemctl status mysql

# 检查连接
mysql -u root -p

# 运行数据库测试
php backend/test_db.php
```

**解决方案**:
```bash
# 重启MySQL
systemctl restart mysql

# 检查配置
cat backend/.env | grep DATABASE
```

#### 3. 磁盘空间不足

**检查**:
```bash
df -h
du -sh backend/runtime/*
```

**清理**:
```bash
./scripts/cleanup.sh --all
```

#### 4. 性能下降

**诊断**:
```bash
# 运行性能监控
./scripts/monitor.sh

# 分析慢查询
./scripts/analyze_logs.sh --slow

# 检查系统负载
top
htop
```

**优化**:
```bash
# 清理缓存
./scripts/cleanup.sh --cache

# 重启服务
systemctl restart php8.1-fpm
```

---

## 📅 定期维护

### 每日任务

```bash
# 自动化脚本
0 1 * * * /path/to/scripts/analyze_logs.sh  # 日志分析
0 2 * * * /path/to/scripts/backup.sh        # 数据备份
0 3 * * * /path/to/scripts/security_check.sh # 安全检查
```

### 每周任务

```bash
# 自动化脚本
0 0 * * 0 /path/to/scripts/cleanup.sh       # 系统清理
0 1 * * 0 /path/to/scripts/deploy_checklist.sh # 部署检查
```

### 每月任务

- [ ] 检查依赖更新
- [ ] 审查安全日志
- [ ] 测试备份恢复
- [ ] 性能压力测试
- [ ] 更新SSL证书（如需要）

### 季度任务

- [ ] 代码审计
- [ ] 数据库优化
- [ ] 服务器安全审计
- [ ] 灾难恢复演练

---

## 📊 监控面板

### 推荐工具

**1. Grafana + Prometheus**
- 实时性能监控
- 自定义仪表板
- 告警配置

**2. ELK Stack**
- 日志聚合
- 日志搜索
- 可视化分析

**3. New Relic / DataDog**
- APM监控
- 错误追踪
- 性能分析

### 简单监控方案

**使用脚本生成报告**:
```bash
# 生成每日报告
./scripts/monitor.sh --all --report
./scripts/analyze_logs.sh --today --report

# 发送邮件通知
mail -s "Daily Report" admin@example.com < report.txt
```

---

## 📞 告警配置

### 邮件告警

```bash
# 安装mailutils
sudo apt-get install mailutils

# 配置告警脚本
#!/bin/bash
THRESHOLD=90
USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

if [ $USAGE -gt $THRESHOLD ]; then
    echo "Disk usage is ${USAGE}%" | mail -s "Alert: High Disk Usage" admin@example.com
fi
```

### Slack/钉钉告警

```bash
# Webhook URL
WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# 发送告警
curl -X POST $WEBHOOK -H 'Content-type: application/json' \
    --data '{"text":"Alert: Service Down!"}'
```

---

## 📝 日志示例

### 成功的监控日志
```
2025-01-17 10:00:00 - [INFO] Monitor started
2025-01-17 10:00:01 - [OK] API response time: 0.3s
2025-01-17 10:00:02 - [OK] Database connections: 15
2025-01-17 10:00:03 - [OK] CPU usage: 45%
2025-01-17 10:00:04 - [OK] Memory usage: 60%
2025-01-17 10:00:05 - [INFO] Monitor completed successfully
```

### 告警日志
```
2025-01-17 15:30:00 - [WARN] API response time: 1.5s (> 1s)
2025-01-17 15:30:01 - [ERROR] Database connections: 210 (> 200)
2025-01-17 15:30:02 - [CRITICAL] Disk usage: 95% (> 90%)
2025-01-17 15:30:03 - [ACTION] Sending alert notification
```

---

## 🎯 最佳实践

1. **监控自动化** - 配置cron定时任务
2. **告警及时** - 设置合理的阈值和通知
3. **日志管理** - 定期清理和归档
4. **备份验证** - 定期测试恢复流程
5. **安全第一** - 定期安全审计
6. **文档更新** - 记录所有变更
7. **性能优化** - 持续监控和改进
8. **灾难准备** - 制定和演练应急预案

---

## 📚 相关文档

- [SCRIPTS_GUIDE.md](SCRIPTS_GUIDE.md) - 脚本使用指南
- [DEPLOYMENT.md](DEPLOYMENT.md) - 部署指南
- [backend/database/DB_OPTIMIZATION_v1.5.9.md](backend/database/DB_OPTIMIZATION_v1.5.9.md) - 数据库优化
- [TEST_SCRIPTS.md](TEST_SCRIPTS.md) - 测试脚本
- [ERROR_HANDLING.md](ERROR_HANDLING.md) - 错误处理

---

<div align="center">

**如有问题，请查看日志或联系运维团队**

Made with ❤️ by Running App Team

</div>
