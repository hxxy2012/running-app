# Running App - 脚本使用指南

本文档详细介绍项目中所有实用脚本的使用方法。

---

## 📋 脚本列表

| 脚本 | 用途 | 推荐度 |
|------|------|--------|
| [quick_start.sh](#quick_startsh) | 一键启动开发环境 | ⭐⭐⭐⭐⭐ |
| [health_check.sh](#health_checksh) | 综合健康检查 | ⭐⭐⭐⭐⭐ |
| [deploy_checklist.sh](#deploy_checklistsh) | 部署前检查清单 | ⭐⭐⭐⭐⭐ |
| [backup.sh](#backupsh) | 数据库和文件备份 | ⭐⭐⭐⭐ |
| [test_api.php](#test_apiphp) | API接口测试 | ⭐⭐⭐⭐ |
| [test_db.php](#test_dbphp) | 数据库测试 | ⭐⭐⭐⭐ |

---

## 🚀 quick_start.sh

### 功能描述

一键启动完整的开发环境，自动完成环境检查、依赖安装、数据库配置、优化应用和服务启动。

### 适用场景

- ✅ 首次部署项目
- ✅ 快速搭建开发环境
- ✅ 新成员加入团队
- ✅ 重置开发环境

### 使用方法

```bash
./scripts/quick_start.sh
```

### 执行流程

```
1. 检查环境依赖 (PHP/MySQL/Composer)
   ↓
2. 安装后端依赖 (composer install)
   ↓
3. 配置环境文件 (.env + JWT密钥自动生成)
   ↓
4. 创建数据库
   ↓
5. 导入数据库结构
   ↓
6. 应用数据库优化 (可选)
   ↓
7. 启动后端服务 (默认端口8000)
```

### 特色功能

- ✅ **自动生成JWT密钥** - 使用OpenSSL生成32位随机密钥
- ✅ **智能端口选择** - 如果8000端口占用，自动使用其他端口
- ✅ **交互式配置** - 可选择是否现在配置数据库密码
- ✅ **自动运行健康检查** - 启动前自动验证环境

### 示例输出

```
╔════════════════════════════════════════╗
║   Running App - 一键启动脚本           ║
║   Quick Start Development Environment  ║
╔════════════════════════════════════════╗

【步骤 1/7】检查环境依赖
========================================
✅ PHP已安装: 8.1.0
✅ Composer已安装: 2.5.0
✅ MySQL已安装: 8.0.28

【步骤 2/7】安装后端依赖
========================================
   依赖已存在，跳过安装

【步骤 3/7】配置环境文件
========================================
✅ .env文件已创建
⚠️  JWT密钥已自动生成: abcd1234...

...

╔════════════════════════════════════════╗
║  🎉 备份成功完成！                    ║
╚════════════════════════════════════════╝
```

### 常见问题

**Q: 提示MySQL密码错误？**
- 编辑 `backend/.env` 文件，修改 `PASSWORD` 配置

**Q: 端口8000被占用？**
- 脚本会自动提示使用其他端口
- 或手动停止占用8000端口的进程

**Q: 数据库已存在怎么办？**
- 脚本会询问是否重新导入
- 选择 `n` 跳过导入，保留现有数据

---

## 🏥 health_check.sh

### 功能描述

全面检查应用的所有组件，包括环境、文件、数据库、服务、安全配置等。

### 适用场景

- ✅ 首次部署后验证
- ✅ 定期健康检查
- ✅ CI/CD流水线集成
- ✅ 生产环境监控

### 使用方法

```bash
./scripts/health_check.sh
```

### 检查项目

**环境检查** (3项):
- PHP版本和安装状态
- MySQL版本和安装状态
- Composer版本和安装状态

**文件检查** (5项):
- 后端目录存在性
- Composer依赖安装
- 数据库配置文件
- .env配置文件
- Runtime目录权限

**数据库检查** (1项):
- 连接测试和表结构

**服务检查** (2项):
- 后端服务运行状态
- API可访问性

**优化检查** (1项):
- 数据库优化状态

**安全检查** (2项):
- JWT密钥配置
- 调试模式状态

**客户端检查** (2项):
- Android项目配置
- iOS项目配置

### 返回值

- `0` - 所有检查通过
- `1` - 有检查失败

### CI/CD集成

```yaml
# .gitlab-ci.yml
test:
  script:
    - ./scripts/health_check.sh

# GitHub Actions
- name: Health Check
  run: ./scripts/health_check.sh
```

### Cron定时任务

```bash
# 每小时运行一次
0 * * * * cd /path/to/running-app && ./scripts/health_check.sh >> /var/log/health.log 2>&1
```

---

## ✅ deploy_checklist.sh

### 功能描述

部署前的完整检查清单，包含60+检查项，确保生产环境部署安全可靠。

### 适用场景

- ✅ 生产环境首次部署
- ✅ 重大版本上线
- ✅ 安全审计
- ✅ 合规检查

### 使用方法

```bash
./scripts/deploy_checklist.sh
```

### 检查分类

**1. 安全配置** (10项):
- JWT密钥修改
- 数据库密码强度
- 调试模式关闭
- HTTPS配置
- 防火墙设置
- 等...

**2. 数据库优化** (6项):
- 数据库结构导入
- 优化脚本应用
- 备份配置
- 从库配置
- 等...

**3. 性能优化** (6项):
- Redis缓存
- OPcache
- Gzip压缩
- CDN配置
- 等...

**4. 环境配置** (6项):
- PHP/MySQL版本
- 扩展安装
- 时区配置
- 文件权限
- 等...

**5. 第三方服务** (6项):
- 短信服务
- 实名认证
- 对象存储
- 地图服务
- 等...

**6. 监控与日志** (6项):
- 服务器监控
- 日志收集
- 错误告警
- APM配置
- 等...

**7. 备份与恢复** (5项):
- 自动备份配置
- 恢复流程测试
- 灾难恢复方案
- 异地备份
- 等...

**8. 代码与文档** (7项):
- 测试通过
- 健康检查
- 文档准备
- 等...

**9. 客户端配置** (4项):
- API地址配置
- 应用签名
- 发布材料
- 等...

**10. 运维准备** (6项):
- 回滚方案
- 应急联系人
- 自动重启
- 压力测试
- 等...

**11. 合规与法律** (5项):
- 隐私政策
- 用户协议
- 数据加密
- 安全措施
- 等...

### 完成率评估

- **100%** - 完美！可以部署
- **90-99%** - 良好，有少量待完成项
- **< 90%** - 不建议部署，请完成更多检查项

### 示例输出

```
【1】安全配置检查
═══════════════════════════════════════
   JWT密钥已修改（不是默认值） (y/n): y
✅ JWT密钥已修改（不是默认值）

   数据库密码已修改为强密码 (y/n): y
✅ 数据库密码已修改为强密码

...

检查结果汇总
═══════════════════════════════════════
总检查项: 61
已完成: 58 ✅
未完成: 3 ❌
完成率: 95.08%

╔════════════════════════════════════════╗
║  ⚠️  还有少量检查项未完成             ║
║  建议完成所有检查项后再部署          ║
╚════════════════════════════════════════╝
```

---

## 💾 backup.sh

### 功能描述

完整的备份解决方案，包括数据库、上传文件、配置文件的备份，以及自动清理过期备份。

### 适用场景

- ✅ 定期数据备份
- ✅ 部署前备份
- ✅ 重要操作前备份
- ✅ 灾难恢复准备

### 使用方法

```bash
# 使用默认备份目录 (/var/backups/running-app)
./scripts/backup.sh

# 使用自定义备份目录
./scripts/backup.sh /path/to/backup
```

### 备份内容

**1. 数据库备份**:
- 完整的MySQL数据库dump
- 包含存储过程、触发器、事件
- 自动压缩（gzip）

**2. 上传文件备份**:
- public/uploads目录
- 包含所有用户上传的文件

**3. 配置文件备份**:
- .env环境配置
- config/目录下所有配置文件

### 特色功能

- ✅ **自动压缩** - 节省存储空间
- ✅ **完整性验证** - 验证备份文件是否损坏
- ✅ **自动清理** - 删除7天前的旧备份
- ✅ **备份报告** - 生成详细的备份报告
- ✅ **磁盘空间检查** - 确保有足够空间

### 备份文件命名

```
db_running_app_20250117_143022.sql.gz     # 数据库备份
uploads_20250117_143022.tar.gz             # 上传文件备份
config_20250117_143022.tar.gz              # 配置文件备份
backup_report_20250117_143022.txt          # 备份报告
```

### 恢复备份

**恢复数据库**:
```bash
gunzip < db_running_app_20250117_143022.sql.gz | mysql -u root -p running_app
```

**恢复上传文件**:
```bash
tar -xzf uploads_20250117_143022.tar.gz -C backend/
```

**恢复配置文件**:
```bash
tar -xzf config_20250117_143022.tar.gz -C backend/
```

### Cron定时备份

```bash
# 每天凌晨2点执行备份
0 2 * * * /path/to/running-app/scripts/backup.sh >> /var/log/backup.log 2>&1
```

### 远程备份

```bash
# 备份后上传到远程服务器
./scripts/backup.sh /tmp/backup
rsync -avz /tmp/backup/ user@remote:/backups/running-app/
```

---

## 🧪 test_api.php

### 功能描述

自动化测试所有核心API接口，验证后端功能是否正常。

详见 [TEST_SCRIPTS.md](TEST_SCRIPTS.md#test_apiphp)

### 使用方法

```bash
cd backend
php test_api.php http://localhost:8000
```

---

## 🗄️ test_db.php

### 功能描述

专门测试数据库连接、表结构、数据完整性和优化状态。

详见 [TEST_SCRIPTS.md](TEST_SCRIPTS.md#test_dbphp)

### 使用方法

```bash
cd backend
php test_db.php
```

---

## 🎯 最佳实践

### 1. 开发工作流

```bash
# 1. 启动开发环境
./scripts/quick_start.sh

# 2. 开发代码...

# 3. 运行健康检查
./scripts/health_check.sh

# 4. 测试API
cd backend && php test_api.php

# 5. 提交代码
git add . && git commit -m "..."
```

### 2. 部署工作流

```bash
# 1. 部署前检查
./scripts/deploy_checklist.sh

# 2. 备份当前数据
./scripts/backup.sh

# 3. 部署代码
git pull && cd backend && composer install

# 4. 更新数据库
mysql -u root -p < database/migrations.sql

# 5. 健康检查
./scripts/health_check.sh

# 6. API测试
php backend/test_api.php https://api.yourapp.com
```

### 3. 运维工作流

```bash
# 定时任务配置
crontab -e

# 添加以下任务:
# 每天2点备份
0 2 * * * /path/to/scripts/backup.sh

# 每小时健康检查
0 * * * * /path/to/scripts/health_check.sh >> /var/log/health.log 2>&1

# 每周日部署检查
0 0 * * 0 /path/to/scripts/deploy_checklist.sh >> /var/log/checklist.log 2>&1
```

---

## 🔧 故障排查

### 脚本执行失败

**问题**: `Permission denied`
```bash
chmod +x scripts/*.sh
```

**问题**: `/bin/bash: bad interpreter`
```bash
# 转换行尾符
dos2unix scripts/*.sh
```

### 数据库连接失败

**问题**: `Access denied for user`
- 检查 `backend/.env` 中的数据库密码
- 确认MySQL用户权限

**问题**: `Can't connect to MySQL server`
- 检查MySQL服务是否启动
- 检查防火墙设置

### 备份失败

**问题**: `No space left on device`
- 清理磁盘空间
- 修改备份目录到其他磁盘

**问题**: `mysqldump: command not found`
```bash
# Ubuntu/Debian
sudo apt-get install mysql-client

# macOS
brew install mysql-client
```

---

## 📊 脚本对比

| 特性 | quick_start | health_check | deploy_checklist | backup |
|------|-------------|--------------|------------------|--------|
| **用途** | 快速启动 | 健康检查 | 部署检查 | 数据备份 |
| **交互性** | 部分交互 | 无交互 | 完全交互 | 无交互 |
| **执行时间** | 2-5分钟 | <1分钟 | 3-5分钟 | 1-3分钟 |
| **适用环境** | 开发 | 开发+生产 | 生产 | 生产 |
| **自动化** | ✅ | ✅ | ❌ | ✅ |
| **幂等性** | ✅ | ✅ | ✅ | ✅ |

---

## 📚 相关文档

- [TEST_SCRIPTS.md](TEST_SCRIPTS.md) - 测试脚本详细文档
- [DEPLOYMENT.md](DEPLOYMENT.md) - 部署指南
- [QUICK_START.md](QUICK_START.md) - 快速开始
- [DOCKER_DEPLOY.md](DOCKER_DEPLOY.md) - Docker部署

---

## 🤝 贡献

欢迎贡献更多实用脚本！请遵循以下规范：

1. **脚本头部** - 包含用途、用法、功能描述
2. **错误处理** - 使用 `set -e` 和适当的错误提示
3. **用户反馈** - 清晰的成功/失败/警告信息
4. **可配置性** - 通过参数或环境变量配置
5. **幂等性** - 多次执行结果一致
6. **文档完整** - 在本文档中添加使用说明

---

<div align="center">

**如有问题，请查看 [ERROR_HANDLING.md](ERROR_HANDLING.md) 或提交Issue**

Made with ❤️ by Running App Team

</div>
