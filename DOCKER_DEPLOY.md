# Running App Docker 部署指南

本指南介绍如何使用 Docker 和 Docker Compose 快速部署 Running App 后端服务。

## 目录

- [前置要求](#前置要求)
- [快速开始](#快速开始)
- [配置说明](#配置说明)
- [常用命令](#常用命令)
- [数据持久化](#数据持久化)
- [故障排查](#故障排查)
- [生产环境部署](#生产环境部署)

---

## 前置要求

在开始之前，请确保您的系统已安装以下软件：

- **Docker** >= 20.10
- **Docker Compose** >= 2.0

### 安装 Docker

**Ubuntu/Debian:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

**CentOS/RHEL:**
```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
```

**macOS:**
```bash
# 下载并安装 Docker Desktop
# https://www.docker.com/products/docker-desktop
```

**Windows:**
```powershell
# 下载并安装 Docker Desktop
# https://www.docker.com/products/docker-desktop
```

---

## 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/your-username/running-app.git
cd running-app
```

### 2. 配置环境变量

复制环境变量模板并根据需要修改：

```bash
cp .env.docker .env
```

编辑 `.env` 文件，修改以下关键配置：

```ini
# 数据库密码（必改）
DB_ROOT_PASSWORD=your_secure_root_password
DB_PASSWORD=your_secure_db_password

# Redis 密码（必改）
REDIS_PASSWORD=your_secure_redis_password

# 应用密钥（必改）
APP_KEY=base64:$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)
```

### 3. 启动服务

```bash
# 构建并启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 4. 初始化数据库

首次启动时，数据库会自动导入 `backend/database/running_app.sql`。

如需手动导入：

```bash
# 进入 MySQL 容器
docker-compose exec mysql bash

# 导入 SQL 文件
mysql -u root -p running_app < /docker-entrypoint-initdb.d/init.sql
```

### 5. 验证部署

访问以下地址验证服务是否正常运行：

- **API 接口**: http://localhost:8000/api/config
- **健康检查**: http://localhost:8000/api/health

预期响应：

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "version": "1.5.9",
    "env": "production"
  }
}
```

---

## 配置说明

### 服务端口

默认端口配置（可通过 `.env` 文件修改）：

| 服务 | 端口 | 说明 |
|------|------|------|
| 后端 API | 8000 | PHP 应用服务 |
| MySQL | 3306 | 数据库服务 |
| Redis | 6379 | 缓存服务 |

### 修改端口

编辑 `.env` 文件：

```ini
BACKEND_PORT=8080    # 后端端口改为 8080
DB_PORT=3307         # MySQL 端口改为 3307
REDIS_PORT=6380      # Redis 端口改为 6380
```

重启服务：

```bash
docker-compose down
docker-compose up -d
```

### 环境模式

**开发模式:**

```ini
APP_DEBUG=true
```

- 显示详细错误信息
- 短信/实名认证使用模拟模式
- 不建议在生产环境使用

**生产模式:**

```ini
APP_DEBUG=false
```

- 隐藏敏感错误信息
- 必须配置真实的第三方服务
- 启用所有安全特性

---

## 常用命令

### 服务管理

```bash
# 启动所有服务
docker-compose up -d

# 停止所有服务
docker-compose down

# 重启服务
docker-compose restart

# 重启单个服务
docker-compose restart backend

# 查看服务状态
docker-compose ps

# 查看服务日志
docker-compose logs -f

# 查看单个服务日志
docker-compose logs -f backend
```

### 容器管理

```bash
# 进入后端容器
docker-compose exec backend bash

# 进入 MySQL 容器
docker-compose exec mysql bash

# 进入 Redis 容器
docker-compose exec redis sh

# 查看容器资源使用
docker stats
```

### 数据库操作

```bash
# 导出数据库
docker-compose exec mysql mysqldump -u root -p running_app > backup.sql

# 导入数据库
docker-compose exec -T mysql mysql -u root -p running_app < backup.sql

# 连接数据库
docker-compose exec mysql mysql -u running -p running_app
```

### 清理操作

```bash
# 停止并删除所有容器
docker-compose down

# 停止并删除所有容器和数据卷（谨慎使用！）
docker-compose down -v

# 清理未使用的镜像
docker image prune

# 清理所有未使用的资源
docker system prune -a
```

---

## 数据持久化

### 数据卷说明

Docker Compose 会自动创建以下数据卷：

| 数据卷 | 用途 | 路径 |
|--------|------|------|
| `mysql_data` | MySQL 数据 | `/var/lib/mysql` |
| `redis_data` | Redis 数据 | `/data` |
| `backend_runtime` | 运行时缓存 | `/var/www/html/runtime` |
| `backend_uploads` | 用户上传文件 | `/var/www/html/uploads` |
| `backend_crash_logs` | 崩溃日志 | `/var/www/html/crash_logs` |

### 数据备份

#### 备份数据库

```bash
# 创建备份目录
mkdir -p backups

# 备份数据库
docker-compose exec mysql mysqldump \
  -u root -p${DB_ROOT_PASSWORD} \
  --databases running_app \
  --single-transaction \
  --quick \
  --lock-tables=false \
  > backups/running_app_$(date +%Y%m%d_%H%M%S).sql
```

#### 备份上传文件

```bash
# 备份 uploads 目录
docker-compose exec backend tar -czf /tmp/uploads.tar.gz -C /var/www/html uploads
docker-compose cp backend:/tmp/uploads.tar.gz backups/uploads_$(date +%Y%m%d_%H%M%S).tar.gz
```

#### 自动备份脚本

创建 `backup.sh`:

```bash
#!/bin/bash
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# 备份数据库
docker-compose exec -T mysql mysqldump \
  -u root -p${DB_ROOT_PASSWORD} \
  --databases running_app \
  --single-transaction \
  > $BACKUP_DIR/db_$DATE.sql

# 备份 uploads
docker-compose exec backend tar -czf /tmp/uploads.tar.gz -C /var/www/html uploads
docker-compose cp backend:/tmp/uploads.tar.gz $BACKUP_DIR/uploads_$DATE.tar.gz

# 删除 7 天前的备份
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
```

添加到 crontab（每天凌晨 2 点备份）：

```bash
0 2 * * * /path/to/running-app/backup.sh >> /var/log/running-app-backup.log 2>&1
```

### 数据恢复

#### 恢复数据库

```bash
# 停止服务
docker-compose down

# 删除旧数据卷
docker volume rm running-app_mysql_data

# 重新启动服务
docker-compose up -d mysql

# 等待 MySQL 启动
sleep 10

# 导入备份
docker-compose exec -T mysql mysql -u root -p${DB_ROOT_PASSWORD} running_app < backups/db_20250117_020000.sql
```

#### 恢复上传文件

```bash
# 解压备份到容器
docker-compose cp backups/uploads_20250117_020000.tar.gz backend:/tmp/
docker-compose exec backend tar -xzf /tmp/uploads_20250117_020000.tar.gz -C /var/www/html
```

---

## 故障排查

### 容器无法启动

**问题**: 执行 `docker-compose up` 后容器立即退出

**排查步骤**:

```bash
# 1. 查看容器日志
docker-compose logs backend
docker-compose logs mysql

# 2. 检查端口是否被占用
netstat -tuln | grep 8000
netstat -tuln | grep 3306

# 3. 检查配置文件
cat .env
```

**常见原因**:
- 端口被占用：修改 `.env` 中的端口配置
- 环境变量错误：检查 `.env` 文件语法
- 磁盘空间不足：清理 Docker 缓存

### MySQL 连接失败

**问题**: 后端无法连接 MySQL

**排查步骤**:

```bash
# 1. 检查 MySQL 健康状态
docker-compose ps

# 2. 测试 MySQL 连接
docker-compose exec mysql mysql -u root -p -e "SHOW DATABASES;"

# 3. 检查网络连接
docker-compose exec backend ping mysql
```

**解决方案**:

```bash
# 重启 MySQL 服务
docker-compose restart mysql

# 查看 MySQL 日志
docker-compose logs mysql

# 检查数据库用户权限
docker-compose exec mysql mysql -u root -p -e "
  GRANT ALL PRIVILEGES ON running_app.* TO 'running'@'%';
  FLUSH PRIVILEGES;
"
```

### 文件权限问题

**问题**: 上传文件失败或无法写入日志

**解决方案**:

```bash
# 进入容器
docker-compose exec backend bash

# 修复权限
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
chmod -R 777 runtime uploads crash_logs
```

### 性能问题

**问题**: API 响应缓慢

**排查步骤**:

```bash
# 1. 查看容器资源使用
docker stats

# 2. 检查 MySQL 慢查询
docker-compose exec mysql mysql -u root -p -e "
  SET GLOBAL slow_query_log = 'ON';
  SET GLOBAL long_query_time = 2;
  SHOW VARIABLES LIKE 'slow_query%';
"

# 3. 查看 PHP-FPM 状态
docker-compose exec backend curl http://localhost/status
```

**优化建议**:

1. **增加容器资源限制**:

编辑 `docker-compose.yml`:

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 512M
```

2. **启用 Redis 缓存**:

编辑 `backend/.env`:

```ini
CACHE_DRIVER=redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=redis123
```

3. **优化 MySQL 配置**:

创建 `docker/mysql.cnf`:

```ini
[mysqld]
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
max_connections = 500
```

添加到 `docker-compose.yml`:

```yaml
services:
  mysql:
    volumes:
      - ./docker/mysql.cnf:/etc/mysql/conf.d/custom.cnf:ro
```

---

## 生产环境部署

### 安全加固

#### 1. 修改默认密码

```ini
# .env
DB_ROOT_PASSWORD=$(openssl rand -base64 32)
DB_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)
```

#### 2. 禁用 Debug 模式

```ini
APP_DEBUG=false
```

#### 3. 限制端口访问

修改 `docker-compose.yml`，移除数据库端口暴露：

```yaml
services:
  mysql:
    # ports:
    #   - "3306:3306"  # 注释掉此行
```

#### 4. 配置 HTTPS

使用 Nginx 反向代理 + Let's Encrypt SSL:

创建 `docker/nginx.conf`:

```nginx
server {
    listen 80;
    server_name api.your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.your-domain.com;

    ssl_certificate /etc/letsencrypt/live/api.your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.your-domain.com/privkey.pem;

    location / {
        proxy_pass http://backend:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

添加 Nginx 到 `docker-compose.yml`:

```yaml
services:
  nginx:
    image: nginx:alpine
    container_name: running-app-nginx
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./docker/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
    depends_on:
      - backend
    networks:
      - running-app-network
```

### 监控和日志

#### 1. 日志管理

配置日志轮转，编辑 `docker-compose.yml`:

```yaml
services:
  backend:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

#### 2. 健康检查

已在 `docker-compose.yml` 中配置，可通过以下命令查看：

```bash
docker-compose ps
```

健康状态显示为 `healthy` 表示服务正常。

#### 3. 监控工具

推荐使用 Docker 监控工具：

- **cAdvisor**: 容器资源监控
- **Prometheus**: 指标收集
- **Grafana**: 可视化仪表板

### 自动更新和部署

创建 `deploy-docker.sh`:

```bash
#!/bin/bash

set -e

echo "开始部署 Running App..."

# 拉取最新代码
git pull origin main

# 重新构建镜像
docker-compose build --no-cache

# 停止旧容器
docker-compose down

# 启动新容器
docker-compose up -d

# 等待服务启动
sleep 10

# 检查健康状态
docker-compose ps

# 查看日志
docker-compose logs --tail=50

echo "部署完成！"
```

添加可执行权限：

```bash
chmod +x deploy-docker.sh
```

---

## 扩展阅读

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [ThinkPHP 6 文档](https://www.kancloud.cn/manual/thinkphp6_0/)
- [项目集成指南](./INTEGRATION_GUIDE.md)
- [快速开始指南](./QUICK_START.md)

---

## 技术支持

如遇到问题，请通过以下方式获取帮助：

- **GitHub Issues**: https://github.com/your-username/running-app/issues
- **文档**: 查看项目根目录下的 `docs/` 文件夹
- **邮件**: support@your-domain.com

---

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](./LICENSE) 文件。
