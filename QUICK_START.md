# 快速开始指南

本文档提供最快速的项目配置和启动步骤。详细配置请参考 [API_CONFIG.md](API_CONFIG.md) 和 [DEPLOYMENT.md](DEPLOYMENT.md)。

## 📋 前置要求

### 后端
- PHP 8.0+
- MySQL 8.0+
- Composer

### Android
- Android Studio Hedgehog+ (2023.1.1+)
- JDK 17+
- Android SDK 34

### iOS
- macOS Ventura+ (13.0+)
- Xcode 15+
- CocoaPods

---

## 🚀 5分钟快速启动

### 1️⃣ 克隆项目

```bash
git clone <repository-url>
cd running-app
```

### 2️⃣ 后端配置（3分钟）

```bash
# 进入后端目录
cd backend

# 安装依赖
composer install

# 创建配置文件
cp .env.example .env

# 编辑配置文件（必需修改数据库密码和JWT密钥）
# vim .env 或使用其他编辑器

# 导入数据库
mysql -u root -p < database/running_app.sql

# 启动服务（开发环境）
php think run

# 后端将运行在 http://127.0.0.1:8000
```

**必需修改的配置项：**
- `DATABASE.PASSWORD` - 数据库密码
- `JWT.SECRET_KEY` - JWT密钥（建议32位随机字符串）

### 3️⃣ Android配置（2分钟）

```bash
# 进入Android目录
cd android

# 创建配置文件
cp local.properties.example local.properties

# 编辑配置文件
# vim local.properties 或使用其他编辑器
```

**必需修改的配置项：**
```properties
# 修改为你的Android SDK路径
sdk.dir=/path/to/your/android/sdk

# 修改为后端API地址
api.base.url=http://192.168.1.100:8000
```

**获取本机IP地址：**
- Windows: `ipconfig`
- Mac/Linux: `ifconfig` 或 `ip addr`

**在Android Studio中：**
1. 打开 `android` 文件夹
2. 等待Gradle同步完成
3. 连接Android设备或启动模拟器
4. 点击运行按钮

### 4️⃣ iOS配置（2分钟）

```bash
# 进入iOS目录
cd ios

# 安装依赖（首次需要）
pod install

# 创建配置文件（可选）
cp Config.xcconfig.example Config.xcconfig

# 编辑 RunningApp/Services/NetworkService.swift
# 修改第8行的 baseURL
```

**修改API地址：**

打开 `ios/RunningApp/Services/NetworkService.swift`，修改：

```swift
private let baseURL = "http://192.168.1.100:8000"  // 改为你的后端地址
```

**在Xcode中：**
1. 打开 `RunningApp.xcworkspace`（不是.xcodeproj）
2. 选择开发团队（Signing & Capabilities）
3. 连接iOS设备或启动模拟器
4. 点击运行按钮

---

## ✅ 验证安装

### 后端验证

访问：`http://127.0.0.1:8000/api/test`

预期响应：
```json
{
  "code": 200,
  "msg": "API is working"
}
```

### 移动端验证

1. 打开应用
2. 点击"注册"
3. 输入手机号：`13800138000`
4. 输入密码：`123456`
5. 点击注册

如果注册成功，说明配置正确！

---

## 🔧 常见问题

### 1. Android网络请求失败

**问题：** Network Error 或 Connection refused

**解决方案：**
- 检查 `local.properties` 中的 `api.base.url` 是否正确
- 确保使用本机IP地址，不要使用 `localhost` 或 `127.0.0.1`
- 确保手机和电脑在同一WiFi网络
- 检查防火墙是否允许8000端口

### 2. iOS网络请求失败

**问题：** URLError 或 The resource could not be loaded

**解决方案：**
- 检查 `NetworkService.swift` 中的 `baseURL` 是否正确
- 在 `Info.plist` 中添加 `NSAppTransportSecurity` 配置允许HTTP
- 确保使用本机IP地址
- 检查是否在模拟器中，模拟器可以使用 `127.0.0.1`

### 3. 后端数据库连接失败

**问题：** SQLSTATE[HY000] [1045] Access denied

**解决方案：**
- 检查 `.env` 中的数据库用户名密码是否正确
- 确保MySQL服务已启动
- 确保数据库 `running_app` 已创建

### 4. Android Gradle同步失败

**问题：** Gradle sync failed

**解决方案：**
- 检查 `local.properties` 中的 `sdk.dir` 路径是否正确
- 确保已安装 Android SDK 34
- 尝试：File → Invalidate Caches / Restart

### 5. iOS CocoaPods安装失败

**问题：** pod install 失败

**解决方案：**
```bash
# 更新CocoaPods
sudo gem install cocoapods

# 清理缓存
pod cache clean --all

# 重新安装
pod install --repo-update
```

---

## 📱 测试账号

系统预置了测试账号（数据库导入后自动创建）：

| 手机号 | 密码 | 说明 |
|--------|------|------|
| 13800138000 | 123456 | 测试用户1 |
| 13800138001 | 123456 | 测试用户2 |
| 13800138002 | 123456 | 测试用户3 |

---

## 🔐 安全提示

### 开发环境

- `.env` 中使用简单密码和密钥即可
- 可以使用HTTP协议

### 生产环境

**必需修改：**
1. `.env` 中的所有密码和密钥改为强密码
2. 修改 `JWT.SECRET_KEY` 为32位以上随机字符串
3. 修改 `APP_DEBUG = false`
4. 使用HTTPS协议
5. 配置防火墙规则
6. 使用Nginx/Apache反向代理

---

## 📚 下一步

配置完成后，建议阅读：

1. [API 接口文档](API.md) - 了解所有可用接口
2. [数据库设计文档](DATABASE.md) - 了解数据库结构
3. [部署指南](DEPLOYMENT.md) - 生产环境部署
4. [API配置指南](API_CONFIG.md) - 详细配置说明

---

## 💬 获取帮助

如遇到问题：

1. 查看 [常见问题](#🔧-常见问题) 章节
2. 查看项目 [Issues](../../issues)
3. 提交新的 Issue

---

**祝你使用愉快！ 🎉**
