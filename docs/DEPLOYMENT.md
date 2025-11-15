# Running App 部署文档

## 系统要求

### 后台服务器
- **操作系统**: Linux (Ubuntu 20.04+ / CentOS 7+)
- **PHP**: 8.0+
- **MySQL**: 8.0+
- **Nginx**: 1.20+
- **Composer**: 2.0+
- **磁盘空间**: 至少10GB（用于存储图片、轨迹文件等）

### 客户端开发环境

**Android**:
- Android Studio Hedgehog | 2023.1.1+
- JDK 17+
- Kotlin 1.9.20+
- Android SDK API 34

**iOS**:
- macOS Ventura 13.0+
- Xcode 15.0+
- Swift 5.9+
- CocoaPods 1.12+

---

## 后台部署

### 1. 环境安装

#### 1.1 安装PHP 8.0

```bash
# Ubuntu
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:ondrej/php
sudo apt update
sudo apt install -y php8.0 php8.0-fpm php8.0-mysql php8.0-mbstring \
  php8.0-xml php8.0-curl php8.0-zip php8.0-gd php8.0-bcmath

# CentOS
sudo yum install -y epel-release
sudo yum install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
sudo yum module reset php
sudo yum module enable php:remi-8.0
sudo yum install -y php php-fpm php-mysqlnd php-mbstring \
  php-xml php-curl php-zip php-gd php-bcmath
```

#### 1.2 安装MySQL 8.0

```bash
# Ubuntu
sudo apt install -y mysql-server-8.0

# CentOS
sudo yum install -y mysql-server

# 启动MySQL
sudo systemctl start mysql
sudo systemctl enable mysql

# 安全配置
sudo mysql_secure_installation
```

#### 1.3 安装Nginx

```bash
# Ubuntu
sudo apt install -y nginx

# CentOS
sudo yum install -y nginx

# 启动Nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

#### 1.4 安装Composer

```bash
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer
```

---

### 2. 数据库配置

#### 2.1 创建数据库

```bash
# 登录MySQL
mysql -u root -p

# 创建数据库
CREATE DATABASE running_app DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# 创建用户
CREATE USER 'running_user'@'localhost' IDENTIFIED BY 'your_password';

# 授权
GRANT ALL PRIVILEGES ON running_app.* TO 'running_user'@'localhost';
FLUSH PRIVILEGES;

EXIT;
```

#### 2.2 导入数据库

```bash
cd /path/to/running-app/backend
mysql -u running_user -p running_app < database/running_app.sql
```

---

### 3. 部署后台代码

#### 3.1 上传代码

```bash
# 使用Git克隆（推荐）
cd /var/www
git clone https://github.com/yourusername/running-app.git

# 或上传压缩包
scp running-app.zip user@your-server:/var/www/
ssh user@your-server
cd /var/www
unzip running-app.zip
```

#### 3.2 安装依赖

```bash
cd /var/www/running-app/backend
composer install --no-dev --optimize-autoloader
```

#### 3.3 配置环境变量

```bash
cd /var/www/running-app/backend

# 创建.env文件（如果使用环境变量）
cat > .env << EOF
[database]
type = mysql
hostname = 127.0.0.1
database = running_app
username = running_user
password = your_password
hostport = 3306
charset = utf8mb4
prefix =

[app]
debug = false
name = Running App
api_domain = https://api.yourapp.com
jwt_key = your-very-secret-key-change-this-in-production
jwt_expire = 604800

[sms]
provider = aliyun
access_key = your_access_key
access_secret = your_access_secret
sign_name = Running App
EOF
```

#### 3.4 设置目录权限

```bash
cd /var/www/running-app/backend

# 设置所有者
sudo chown -R www-data:www-data .

# 设置权限
sudo chmod -R 755 .
sudo chmod -R 777 runtime
sudo chmod -R 777 public/uploads
```

---

### 4. 配置Nginx

#### 4.1 创建站点配置

```bash
sudo vim /etc/nginx/sites-available/running-app
```

**配置内容**:
```nginx
server {
    listen 80;
    server_name api.yourapp.com;

    root /var/www/running-app/backend/public;
    index index.php index.html;

    # 访问日志
    access_log /var/log/nginx/running-app_access.log;
    error_log /var/log/nginx/running-app_error.log;

    # 上传文件大小限制
    client_max_body_size 10M;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.0-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # 禁止访问隐藏文件
    location ~ /\. {
        deny all;
    }

    # 静态资源缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

#### 4.2 启用站点

```bash
# 创建软链接
sudo ln -s /etc/nginx/sites-available/running-app /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启Nginx
sudo systemctl restart nginx
```

---

### 5. 配置SSL证书（HTTPS）

#### 使用Let's Encrypt免费证书

```bash
# 安装Certbot
sudo apt install -y certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d api.yourapp.com

# 自动续期
sudo certbot renew --dry-run
```

---

### 6. 配置定时任务

#### 6.1 创建定时任务脚本

```bash
cd /var/www/running-app/backend

# 排行榜更新任务
crontab -e
```

添加以下内容:
```cron
# 每天凌晨2点更新排行榜
0 2 * * * php /var/www/running-app/backend/think ranking:update

# 每小时清理过期验证码
0 * * * * php /var/www/running-app/backend/think sms:clean
```

---

### 7. 性能优化

#### 7.1 开启OPcache

```bash
sudo vim /etc/php/8.0/fpm/php.ini
```

添加/修改:
```ini
opcache.enable=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=10000
opcache.revalidate_freq=60
opcache.fast_shutdown=1
```

#### 7.2 配置PHP-FPM

```bash
sudo vim /etc/php/8.0/fpm/pool.d/www.conf
```

优化配置:
```ini
pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 500
```

重启PHP-FPM:
```bash
sudo systemctl restart php8.0-fpm
```

---

### 8. 监控和日志

#### 8.1 查看错误日志

```bash
# Nginx日志
tail -f /var/log/nginx/running-app_error.log

# PHP-FPM日志
tail -f /var/log/php8.0-fpm.log

# 应用日志
tail -f /var/www/running-app/backend/runtime/log/*.log
```

#### 8.2 监控工具

推荐使用:
- **Supervisor**: 进程管理
- **Logrotate**: 日志轮转
- **Prometheus + Grafana**: 监控和可视化

---

## Android客户端部署

### 1. 配置API地址

编辑 `android/app/src/main/java/com/yourapp/running/data/remote/ApiConstants.kt`:

```kotlin
object ApiConstants {
    const val BASE_URL = "https://api.yourapp.com/api/"
}
```

### 2. 配置第三方SDK

#### 2.1 高德地图

在 `app/src/main/AndroidManifest.xml` 中添加:

```xml
<meta-data
    android:name="com.amap.api.v2.apikey"
    android:value="你的高德地图Key" />
```

#### 2.2 微信/QQ登录

按照各平台文档配置相应的AppID和AppSecret

### 3. 构建APK

```bash
cd android
./gradlew assembleRelease

# 生成的APK位于
# app/build/outputs/apk/release/app-release.apk
```

### 4. 应用签名

```bash
# 生成签名密钥
keytool -genkey -v -keystore running-app.keystore \
  -alias running -keyalg RSA -keysize 2048 -validity 10000

# 签名APK
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
  -keystore running-app.keystore \
  app/build/outputs/apk/release/app-release-unsigned.apk running

# 对齐APK
zipalign -v 4 app-release-unsigned.apk app-release.apk
```

---

## iOS客户端部署

### 1. 配置API地址

编辑 `ios/RunningApp/Data/Remote/APIService.swift`:

```swift
let baseURL = "https://api.yourapp.com/api/"
```

### 2. 配置第三方SDK

#### 2.1 安装CocoaPods依赖

```bash
cd ios
pod install
```

#### 2.2 配置地图SDK

在 `Info.plist` 中添加地图API Key

### 3. 构建IPA

1. 在Xcode中打开项目
2. 选择 Product > Archive
3. 在Organizer中选择归档
4. 点击 Distribute App
5. 选择发布方式（App Store / Ad Hoc / Enterprise）
6. 按提示完成构建

---

## 常见问题

### 1. 数据库连接失败

检查:
- MySQL服务是否启动
- 数据库配置是否正确
- 防火墙是否阻止3306端口

### 2. 文件上传失败

检查:
- `public/uploads` 目录权限是否为777
- Nginx `client_max_body_size` 配置
- PHP `upload_max_filesize` 和 `post_max_size` 配置

### 3. Token验证失败

检查:
- JWT密钥配置是否正确
- 请求头是否携带正确的Token
- Token是否过期

---

## 安全建议

1. **修改默认密钥**: 修改 `config/app.php` 中的 `jwt_key`
2. **使用HTTPS**: 生产环境必须使用HTTPS
3. **数据库备份**: 每天自动备份数据库
4. **限制API访问频率**: 使用Redis配置限流
5. **定期更新**: 及时更新PHP、MySQL、Nginx等组件
6. **监控日志**: 定期检查错误日志和访问日志
7. **防火墙配置**: 只开放必要的端口（80、443、22）

---

## 备份和恢复

### 数据库备份

```bash
# 备份
mysqldump -u running_user -p running_app > backup_$(date +%Y%m%d).sql

# 恢复
mysql -u running_user -p running_app < backup_20251115.sql
```

### 文件备份

```bash
# 备份上传文件
tar -czf uploads_backup_$(date +%Y%m%d).tar.gz /var/www/running-app/backend/public/uploads

# 恢复
tar -xzf uploads_backup_20251115.tar.gz -C /var/www/running-app/backend/public/
```

---

**更新日期**: 2025-11-15
**文档版本**: v1.0
