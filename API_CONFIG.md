# Running App API配置指南

## 配置API地址

### Android配置

打开文件：`android/app/src/main/java/com/runningapp/di/AppModule.kt`

找到第18行，将以下内容：
```kotlin
.baseUrl("http://your-api-domain.com/api/") // TODO: 替换为实际API地址
```

替换为你的实际API地址，例如：
```kotlin
.baseUrl("http://192.168.1.100:8080/api/")  // 本地测试
// 或
.baseUrl("https://api.runningapp.com/api/") // 生产环境
```

### iOS配置

打开文件：`ios/RunningApp/Services/NetworkService.swift`

找到第8行，将以下内容：
```swift
private let baseURL = "http://your-api-domain.com/api/" // TODO: 替换为实际API地址
```

替换为你的实际API地址，例如：
```swift
private let baseURL = "http://192.168.1.100:8080/api/"  // 本地测试
// 或
private let baseURL = "https://api.runningapp.com/api/" // 生产环境
```

## 环境配置建议

### 1. 开发环境
```
http://localhost:8080/api/
或
http://192.168.1.100:8080/api/ (局域网IP)
```

### 2. 测试环境
```
https://test-api.runningapp.com/api/
```

### 3. 生产环境
```
https://api.runningapp.com/api/
```

## 后端部署步骤

### 1. 环境准备
- PHP 8.0+
- MySQL 8.0+
- Nginx/Apache
- Composer

### 2. 安装依赖
```bash
cd backend
composer install
```

### 3. 配置数据库
```bash
cp config/database_example.php config/database.php
# 编辑database.php，填入数据库连接信息
```

### 4. 导入数据库
```bash
mysql -u root -p < database/running_app.sql
```

### 5. 配置Nginx
```nginx
server {
    listen 80;
    server_name api.runningapp.com;
    root /path/to/running-app/backend/public;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.0-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

### 6. 启动服务
```bash
# 方式1：使用ThinkPHP内置服务器（仅开发）
php think run

# 方式2：使用Nginx（推荐）
sudo systemctl start nginx
sudo systemctl start php8.0-fpm
```

## 测试API连接

### 使用curl测试
```bash
# 测试健康检查
curl http://your-api-domain.com/api/common/config

# 测试注册接口
curl -X POST http://your-api-domain.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"123456","password":"123456"}'

# 测试登录接口
curl -X POST http://your-api-domain.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","password":"123456"}'
```

## 常见问题

### 1. 连接超时
- 检查防火墙设置
- 确认API服务已启动
- 验证IP地址和端口正确

### 2. CORS跨域问题
在`backend/app/middleware.php`中添加CORS中间件（如需要）

### 3. Token失效
- 检查JWT配置
- 确认Token格式正确
- 验证Token过期时间设置

## 安全建议

1. **生产环境必须使用HTTPS**
2. **修改默认的JWT密钥**
3. **启用请求频率限制**
4. **配置防火墙规则**
5. **定期更新依赖包**

## 更多信息

详见项目文档：
- [API.md](API.md) - API接口文档
- [DEPLOYMENT.md](DEPLOYMENT.md) - 部署指南
- [DATABASE.md](DATABASE.md) - 数据库设计
