# Running App - 测试脚本文档

## 📋 概述

本项目提供了三个测试脚本，帮助您快速验证应用的各个组件是否正常运行。

## 🚀 快速开始

### 1. 完整健康检查（推荐）

```bash
# 在项目根目录执行
./scripts/health_check.sh
```

**检查项目**:
- ✅ 环境检查（PHP、MySQL、Composer）
- ✅ 项目文件完整性
- ✅ 数据库连接和表结构
- ✅ 后端服务状态
- ✅ 数据库优化状态
- ✅ 安全配置（JWT密钥、调试模式）
- ✅ 客户端配置

### 2. 数据库测试

```bash
# 在backend目录执行
cd backend
php test_db.php
```

**检查项目**:
- ✅ 数据库连接
- ✅ 表结构完整性（30个核心表）
- ✅ 外键约束和索引
- ✅ 初始数据
- ✅ 写入权限
- ✅ JWT密钥安全性

### 3. API接口测试

```bash
# 在backend目录执行
cd backend
php test_api.php [base_url]

# 示例
php test_api.php http://localhost:8000
php test_api.php http://your-domain.com
```

**测试接口**:
- ✅ 用户注册/登录
- ✅ 获取用户信息
- ✅ 创建跑步记录
- ✅ 获取跑步记录列表
- ✅ 统计数据
- ✅ 挑战赛列表
- ✅ 排行榜
- ✅ 社交动态

---

## 📖 详细说明

### 1. health_check.sh - 综合健康检查

#### 功能描述

全面检查应用的所有组件，包括环境、文件、数据库、服务、安全配置等。

#### 使用场景

- ✅ 首次部署后验证环境
- ✅ 定期健康检查
- ✅ CI/CD流水线集成
- ✅ 生产环境监控

#### 返回值

- `0` - 所有检查通过
- `1` - 有检查失败

#### 示例输出

```
==========================================
【1】环境检查
==========================================
✅ PHP 已安装: 8.1.0
✅ MySQL 已安装: 8.0.28
✅ Composer 已安装: 2.5.0

==========================================
【2】项目文件检查
==========================================
✅ 后端目录存在
✅ Composer依赖已安装
✅ 数据库配置文件存在
✅ .env 配置文件存在
✅ runtime 目录可写

==========================================
检查结果汇总
==========================================
总检查项: 15
通过: 15 ✅
通过率: 100%

🎉 所有检查通过！应用已准备就绪。
```

#### 集成到CI/CD

```yaml
# .gitlab-ci.yml
test:
  script:
    - ./scripts/health_check.sh
```

---

### 2. test_db.php - 数据库测试

#### 功能描述

专门测试数据库连接、表结构、数据完整性和优化状态。

#### 使用场景

- ✅ 数据库初始化后验证
- ✅ 应用优化脚本前后对比
- ✅ 故障排查数据库问题

#### 检查的表

核心表（10个）:
- `user` - 用户表
- `running_record` - 跑步记录表
- `track_point` - 轨迹点表
- `post` - 动态表
- `challenge` - 挑战赛表
- `achievement` - 成就表
- `training_plan` - 训练计划表
- `running_club` - 跑团表
- `ranking` - 排行榜表
- `message` - 消息表

#### 优化建议

如果脚本提示"建议应用优化脚本"：

```bash
mysql -u root -p running_app < database/optimization_v1.5.9.sql
```

**优化内容**:
- 添加20+外键约束
- 添加14个性能索引
- 移除不安全的默认JWT密钥
- 添加数据完整性CHECK约束

---

### 3. test_api.php - API接口测试

#### 功能描述

自动化测试所有核心API接口，验证后端功能是否正常。

#### 测试流程

1. **服务器连接测试** - 验证服务器可达性
2. **用户注册** - 使用随机手机号注册测试用户
3. **用户登录** - 获取JWT token
4. **获取用户信息** - 验证token有效性
5. **创建跑步记录** - 测试核心功能
6. **获取记录列表** - 验证查询功能
7. **统计数据** - 验证聚合查询
8. **挑战赛列表** - 测试挑战系统
9. **排行榜** - 测试排行榜功能
10. **发布动态** - 测试社交功能

#### 参数说明

```bash
php test_api.php [base_url]
```

- `base_url` - API基础地址（默认: http://localhost:8000）

#### 示例输出

```
==========================================
Running App - API 测试脚本
==========================================
测试地址: http://localhost:8000
==========================================

【阶段 1】服务器连接测试
==========================================
✅ 服务器连接成功

【阶段 2】用户相关接口测试
==========================================
测试 #1: 发送验证码
  请求: POST /user/sendCode
  ✅ 通过: HTTP 200
  响应: {"code":200,"message":"发送成功（开发模式）"}

测试 #2: 用户注册
  请求: POST /user/register
  ✅ 通过: HTTP 200

测试 #3: 用户登录
  请求: POST /user/login
  ✅ 通过: HTTP 200

📝 获取到Token: eyJ0eXAiOiJKV1QiLCJ...

==========================================
测试结果汇总
==========================================
总测试数: 12
通过: 12 ✅
失败: 0 ❌
通过率: 100%

🎉 所有测试通过！
```

#### 测试用户说明

- 脚本会自动生成随机手机号（13开头）
- 密码统一为：`Test123456`
- 验证码使用测试码：`123456`（开发模式）
- 测试数据会实际写入数据库

---

## ⚠️ 常见问题

### Q1: health_check.sh 提示权限不足？

```bash
chmod +x scripts/health_check.sh
```

### Q2: test_api.php 所有请求都失败？

**检查项**:
1. 后端服务是否启动：`php think run`
2. 端口是否正确：默认8000
3. 防火墙是否开放端口

### Q3: test_db.php 提示配置文件不存在？

```bash
cp backend/config/database_example.php backend/config/database.php
# 然后编辑 database.php 配置数据库连接
```

### Q4: 数据库连接失败？

**排查步骤**:
1. MySQL服务是否启动
   ```bash
   # Linux
   sudo systemctl status mysql

   # macOS
   brew services list
   ```

2. 数据库是否创建
   ```sql
   CREATE DATABASE running_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```

3. 用户权限是否正确
   ```sql
   GRANT ALL PRIVILEGES ON running_app.* TO 'your_user'@'localhost';
   FLUSH PRIVILEGES;
   ```

### Q5: API测试失败 - JWT验证错误？

确保JWT密钥已配置：

```bash
# 在 .env 文件中添加
jwt.secret=your-random-secret-key-at-least-32-characters
```

### Q6: 应该多久运行一次健康检查？

**建议频率**:
- 开发环境：每次重大代码变更后
- 测试环境：每日自动运行
- 生产环境：每小时自动运行（通过cron）

**Cron配置示例**:
```bash
# 每小时运行一次健康检查
0 * * * * cd /path/to/running-app && ./scripts/health_check.sh >> /var/log/running-app-health.log 2>&1
```

---

## 🔧 高级用法

### 1. 仅测试特定组件

修改 `health_check.sh`，注释掉不需要的检查部分。

### 2. 自定义API测试用例

编辑 `test_api.php`，添加您的测试用例：

```php
// 添加自定义测试
runTest(
    '测试名称',
    '/your/endpoint',
    'POST',
    ['param' => 'value'],
    $token
);
```

### 3. 性能测试

使用 `ab` (Apache Bench) 进行压力测试：

```bash
# 安装 ab
sudo apt-get install apache2-utils  # Ubuntu/Debian
brew install httpd  # macOS

# 压力测试登录接口
ab -n 1000 -c 10 -p login.json -T application/json http://localhost:8000/user/login
```

`login.json`:
```json
{"phone": "13800138000", "password": "123456"}
```

---

## 📊 测试覆盖率

| 模块 | 覆盖率 | 说明 |
|------|--------|------|
| 用户系统 | 100% | 注册、登录、信息获取 |
| 跑步记录 | 80% | 创建、列表、统计（不含删除/更新） |
| 挑战赛 | 60% | 列表查询（不含参加/退出） |
| 排行榜 | 60% | 总排行（不含周/月排行） |
| 社交功能 | 40% | 动态列表、发布（不含点赞/评论） |

**未覆盖功能**:
- 文件上传（头像、图片）
- 复杂的业务逻辑（训练计划执行）
- 第三方服务集成（地图、支付）

---

## 🎯 最佳实践

### 1. 开发工作流

```bash
# 1. 拉取最新代码
git pull

# 2. 更新依赖
cd backend && composer install

# 3. 运行健康检查
cd .. && ./scripts/health_check.sh

# 4. 如果有问题，运行详细测试
cd backend
php test_db.php
php test_api.php

# 5. 修复问题后重新测试
```

### 2. 部署前检查

```bash
# 生产部署前的最终检查
./scripts/health_check.sh || exit 1
cd backend && php test_db.php || exit 1
cd backend && php test_api.php http://your-production-domain.com || exit 1
```

### 3. 监控告警

配置监控系统调用健康检查脚本，如果失败则发送告警：

```bash
# 示例：每5分钟检查一次
*/5 * * * * /path/to/running-app/scripts/health_check.sh || echo "Health check failed" | mail -s "Running App Alert" admin@example.com
```

---

## 📚 相关文档

- [QUICK_START.md](QUICK_START.md) - 快速开始指南
- [DEPLOYMENT.md](DEPLOYMENT.md) - 部署文档
- [ERROR_HANDLING.md](ERROR_HANDLING.md) - 错误处理文档
- [API.md](API.md) - API接口文档
- [backend/database/DB_OPTIMIZATION_v1.5.9.md](backend/database/DB_OPTIMIZATION_v1.5.9.md) - 数据库优化文档

---

## 🤝 贡献

欢迎贡献更多测试用例！请参考 [CONTRIBUTING.md](CONTRIBUTING.md)

---

<div align="center">

**如有问题，请查看 [ERROR_HANDLING.md](ERROR_HANDLING.md) 或提交Issue**

</div>
