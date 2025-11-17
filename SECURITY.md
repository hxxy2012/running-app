# 安全政策 (Security Policy)

## 支持的版本 (Supported Versions)

目前支持安全更新的版本：

| Version | Supported          |
| ------- | ------------------ |
| 1.5.x   | :white_check_mark: |
| < 1.5   | :x:                |

---

## 报告漏洞 (Reporting a Vulnerability)

我们非常重视安全问题。如果您发现了安全漏洞，请通过以下方式负责任地向我们报告。

### 报告流程

1. **请勿公开披露**
   - 请不要在公共 Issue 中报告安全漏洞
   - 请不要在社交媒体或论坛上讨论漏洞细节

2. **发送报告**

   通过电子邮件将漏洞详情发送至：**security@your-domain.com**

   报告应包含以下信息：
   - 漏洞类型（如：SQL注入、XSS、认证绕过等）
   - 漏洞的详细描述
   - 重现步骤（POC）
   - 受影响的版本
   - 潜在影响范围
   - 您的联系方式（以便我们跟进）

3. **等待响应**

   我们承诺：
   - **24小时内**：确认收到您的报告
   - **7天内**：提供初步评估和预计修复时间
   - **30天内**：发布安全补丁（视漏洞复杂度而定）

4. **协调披露**

   - 在补丁发布前，请不要公开漏洞细节
   - 我们将在修复完成后公开致谢您的贡献（如果您同意）
   - 我们可能会请求您协助测试修复方案

---

## 安全最佳实践 (Security Best Practices)

### 对于部署者

#### 1. 环境配置

```ini
# .env 配置示例

# 生产环境必须关闭调试模式
APP_DEBUG=false

# 使用强密码
DB_ROOT_PASSWORD=your_very_strong_password_here_min_16_chars
DB_PASSWORD=your_strong_db_password_here
REDIS_PASSWORD=your_strong_redis_password_here

# 使用随机密钥（绝不使用默认值）
APP_KEY=base64:$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)
```

#### 2. 数据库安全

```bash
# 创建专用数据库用户，限制权限
CREATE USER 'running'@'localhost' IDENTIFIED BY 'strong_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON running_app.* TO 'running'@'localhost';
FLUSH PRIVILEGES;

# 禁止root远程访问
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
FLUSH PRIVILEGES;
```

#### 3. 文件权限

```bash
# 后端目录权限设置
cd backend
chmod -R 755 .
chmod -R 777 runtime uploads crash_logs
chmod 600 .env

# 禁止Web访问敏感文件
# 在 Nginx 配置中添加：
location ~ /\.(env|git) {
    deny all;
}
```

#### 4. HTTPS配置

**强制使用HTTPS**（生产环境必须）：

```nginx
# Nginx 配置
server {
    listen 80;
    server_name api.your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.your-domain.com;

    ssl_certificate /path/to/fullchain.pem;
    ssl_certificate_key /path/to/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # 其他安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    location / {
        proxy_pass http://backend:80;
        # ...
    }
}
```

#### 5. 定期更新

```bash
# 定期更新依赖
cd backend && composer update
cd android && ./gradlew dependencies --refresh-dependencies
cd ios && pod update
```

#### 6. 防火墙配置

```bash
# 使用 UFW (Ubuntu)
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw enable

# 限制数据库端口仅本地访问
sudo ufw deny 3306/tcp
sudo ufw deny 6379/tcp
```

### 对于开发者

#### 1. 输入验证

**后端 (PHP)**:

```php
// 使用 ThinkPHP 验证器
use think\Validate;

$validate = Validate::make([
    'phone' => 'require|mobile',
    'code' => 'require|number|length:6',
    'password' => 'require|min:6|max:32'
]);

if (!$validate->check($data)) {
    return json(['code' => 400, 'message' => $validate->getError()]);
}
```

**Android (Kotlin)**:

```kotlin
// 使用验证工具类
if (!ValidationHelper.isValidPhone(phone)) {
    showError("手机号格式不正确")
    return
}

if (!ValidationHelper.isValidPassword(password)) {
    showError("密码长度必须在6-32位之间")
    return
}
```

#### 2. SQL注入防护

```php
// ✅ 正确 - 使用参数化查询
$user = Db::table('user')
    ->where('phone', $phone)
    ->where('status', 1)
    ->find();

// ❌ 错误 - 直接拼接SQL
$sql = "SELECT * FROM user WHERE phone = '$phone'";
```

#### 3. XSS防护

```php
// 输出时转义
echo htmlspecialchars($userInput, ENT_QUOTES, 'UTF-8');

// 或使用模板引擎自动转义
{$userInput|raw}  // 不转义（谨慎使用）
{$userInput}      // 自动转义
```

#### 4. CSRF防护

已在后端实现Token验证，前端需要：

```kotlin
// Android - 在请求头中添加Token
@Headers("Authorization: Bearer $token")
@POST("/api/user/profile")
suspend fun updateProfile(@Body profile: ProfileRequest): Response<User>
```

#### 5. 密码存储

```php
// ✅ 正确 - 使用密码哈希
$hashedPassword = password_hash($password, PASSWORD_BCRYPT);

// 验证密码
if (password_verify($inputPassword, $hashedPassword)) {
    // 密码正确
}

// ❌ 错误 - 明文存储或使用MD5
$password = md5($password); // 不安全！
```

#### 6. 敏感信息处理

```php
// 日志中不记录敏感信息
trace("User login: {$phone}", 'info');  // ✅
trace("User login: {$phone} / {$password}", 'info');  // ❌

// 身份证号脱敏
$maskedIdCard = substr($idCard, 0, 6) . '********' . substr($idCard, -4);

// 返回数据时移除敏感字段
unset($user['password']);
unset($user['salt']);
```

---

## 已知安全特性 (Security Features)

### 认证和授权

- ✅ JWT Token 认证
- ✅ Token 自动刷新
- ✅ 密码加密存储（bcrypt）
- ✅ 验证码防护（登录/注册）
- ✅ 请求频率限制

### 数据保护

- ✅ SQL 参数化查询
- ✅ XSS 过滤
- ✅ CSRF Token验证
- ✅ 敏感数据脱敏
- ✅ HTTPS 支持

### 输入验证

- ✅ 手机号格式验证
- ✅ 邮箱格式验证
- ✅ 身份证号格式验证
- ✅ 文件上传类型和大小限制
- ✅ JSON 数据格式验证

### 日志和监控

- ✅ 错误日志记录
- ✅ 访问日志
- ✅ 崩溃日志上报
- ✅ 异常追踪

---

## 安全检查清单 (Security Checklist)

### 部署前检查

- [ ] 关闭调试模式 (`APP_DEBUG=false`)
- [ ] 修改所有默认密码
- [ ] 生成随机密钥 (`APP_KEY`, `JWT_SECRET`)
- [ ] 配置HTTPS
- [ ] 设置正确的文件权限
- [ ] 禁用不必要的服务和端口
- [ ] 配置防火墙规则
- [ ] 设置日志轮转
- [ ] 配置备份策略
- [ ] 审查第三方依赖漏洞

### 定期检查

- [ ] 检查系统和依赖更新
- [ ] 审查访问日志
- [ ] 检查异常登录
- [ ] 监控服务器资源使用
- [ ] 验证备份完整性
- [ ] 测试灾难恢复流程

---

## 联系方式 (Contact)

**安全问题报告**：security@your-domain.com

**PGP 公钥**：
```
-----BEGIN PGP PUBLIC KEY BLOCK-----
（如果提供PGP加密，在此添加公钥）
-----END PGP PUBLIC KEY BLOCK-----
```

**其他支持**：
- GitHub Issues（非安全问题）: https://github.com/your-username/running-app/issues
- Email: support@your-domain.com

---

## 致谢 (Acknowledgments)

我们感谢以下安全研究人员负责任地披露安全问题：

| 日期 | 研究人员 | 漏洞类型 | 严重程度 |
|------|----------|----------|----------|
| - | - | - | - |

（当有安全报告时，我们会在此致谢）

---

## 变更历史 (Changelog)

| 版本 | 日期 | 安全更新 |
|------|------|----------|
| 1.5.9 | 2025-11-17 | 初始版本 |

---

感谢您帮助我们保持 Running App 的安全！

---

## English Version

### Reporting a Vulnerability

If you discover a security vulnerability, please email us at **security@your-domain.com** instead of using the public issue tracker.

We will respond to your report within 24 hours and provide a timeline for a fix.

### Security Best Practices

Please refer to the Chinese version above for detailed security best practices and guidelines.

Thank you for helping keep Running App secure!
