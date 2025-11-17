# Running App - 全栈跑步应用

<div align="center">

![Version](https://img.shields.io/badge/version-1.5.9-blue)
![Backend](https://img.shields.io/badge/backend-100%25-brightgreen)
![Android](https://img.shields.io/badge/android-100%25-brightgreen)
![iOS](https://img.shields.io/badge/iOS-100%25-brightgreen)
![License](https://img.shields.io/badge/license-MIT-green)

一个功能完整的全栈跑步应用系统，包含ThinkPHP后端、Android原生客户端和iOS原生客户端

[功能特性](#功能特性) • [技术栈](#技术栈) • [快速开始](#快速开始) • [文档](#文档) • [截图](#截图)

</div>

---

## 📱 项目概述

Running App是一个企业级的全栈跑步应用系统，支持GPS跑步跟踪、社交互动、训练计划、挑战赛等丰富功能。

### 项目特点

- ✅ **完整的全栈架构** - 后端 + Android + iOS三端完整实现
- ✅ **现代化技术栈** - Jetpack Compose + SwiftUI + ThinkPHP
- ✅ **企业级代码质量** - MVVM架构 + 依赖注入 + 响应式编程
- ✅ **完善的文档** - 8份详细技术文档
- ✅ **生产可用** - 核心功能全部完成，可立即部署

### 完成度

| 模块 | 完成度 | 状态 |
|------|--------|------|
| 后端 (ThinkPHP) | 100% | ✅ 生产可用 |
| Android (Kotlin) | 100% | ✅ 生产可用 |
| iOS (Swift) | 100% | ✅ 生产可用 |

---

## 🎯 功能特性

### 核心功能

#### 🏃 跑步记录
- GPS实时定位跟踪
- 轨迹点采集和存储
- 距离、时长、配速实时计算
- 卡路里消耗计算
- 爬升/下降统计
- 历史记录查询和统计

#### 👥 社交互动
- 动态发布（文字+图片+跑步记录）
- 点赞、评论、分享
- 关注/取关用户
- 动态流（关注/广场）
- 好友系统

#### 🎯 训练计划
- 预设训练计划
- 自定义训练目标
- 训练进度跟踪
- 每日训练打卡

#### 🏆 挑战赛
- 创建/参加挑战赛
- 实时排行榜
- 挑战进度统计
- 成就徽章系统

#### 👨‍👩‍👧‍👦 跑团功能
- 创建/加入跑团
- 跑团成员管理
- 跑团活动组织
- 跑团数据统计

#### 📊 其他功能
- 排行榜（总/周/月/好友/同城）
- 成就系统
- 装备管理
- 系统消息
- 用户反馈

---

## 💻 技术栈

### 后端
- **框架**: ThinkPHP 6.x
- **数据库**: MySQL 8.0
- **认证**: JWT (Firebase JWT)
- **架构**: MVC + RESTful API

### Android
- **语言**: Kotlin
- **UI框架**: Jetpack Compose + Material Design 3
- **架构**: MVVM + Clean Architecture
- **依赖注入**: Hilt
- **网络**: Retrofit + OkHttp
- **数据库**: Room
- **异步**: Coroutines + Flow
- **定位**: Google Play Services Location

### iOS
- **语言**: Swift 5.9+
- **UI框架**: SwiftUI
- **架构**: MVVM + Combine
- **网络**: Alamofire
- **异步**: Async/Await + Combine
- **定位**: CoreLocation
- **安全**: Keychain

---

## 🚀 快速开始

### 环境要求

#### 后端
- PHP 8.0+
- MySQL 8.0+
- Composer
- Nginx/Apache

#### Android
- Android Studio Hedgehog+
- JDK 17+
- Android SDK 34

#### iOS
- macOS Ventura+
- Xcode 15+
- CocoaPods

### 安装步骤

#### 1. 克隆项目
```bash
git clone <repository-url>
cd running-app
```

#### 2. 后端部署

##### 快速开始（开发环境）
```bash
cd backend

# 安装依赖
composer install

# 配置数据库
cp config/database_example.php config/database.php
# 编辑 config/database.php 配置数据库连接

# 导入数据库
mysql -u root -p running_app < database/running_app.sql

# 【推荐】应用数据库优化（可选但强烈推荐）
# 包含外键约束、性能索引、安全加固等
mysql -u root -p running_app < database/optimization_v1.5.9.sql

# 配置环境变量（.env文件）
# 重要：配置JWT密钥、短信服务等
cp .env.example .env
# 编辑 .env 文件，至少配置以下项：
# - jwt.secret（随机字符串，至少32位）
# - database.*（数据库连接信息）
# - sms.*（短信服务商配置，可选）

# 启动开发服务器
php think run
```

##### 生产部署

**推荐使用Docker部署** - 参考 [DOCKER_DEPLOY.md](DOCKER_DEPLOY.md)

```bash
docker-compose up -d
```

**传统部署方式** - 详见 [DEPLOYMENT.md](DEPLOYMENT.md)

**安全检查清单**:
- ✅ 修改默认JWT密钥（必须）
- ✅ 应用数据库优化脚本（推荐）
- ✅ 配置SSL/HTTPS（生产必需）
- ✅ 设置防火墙规则
- ✅ 配置文件上传限制
- 详见 [backend/database/DB_OPTIMIZATION_v1.5.9.md](backend/database/DB_OPTIMIZATION_v1.5.9.md)

#### 3. Android配置
```bash
cd android

# 配置API地址
# 编辑 app/src/main/java/com/runningapp/di/AppModule.kt
# 修改第18行的 BASE_URL 为你的后端地址

# 编译Debug版本
./gradlew assembleDebug

# 或直接在Android Studio中打开项目
```

**注意**: Android需要Google Play Services（定位功能）

#### 4. iOS配置
```bash
cd ios

# 安装依赖
pod install

# 配置API地址
# 编辑 RunningApp/Services/NetworkService.swift
# 修改第8行的 baseURL 为你的后端地址

# 在Xcode中打开工作空间
open RunningApp.xcworkspace
```

**注意**: iOS需要配置位置权限（Info.plist）

---

### 📖 详细文档

| 场景 | 推荐文档 |
|------|---------|
| **5分钟快速体验** | [QUICK_START.md](QUICK_START.md) ⭐ |
| **Docker部署（推荐）** | [DOCKER_DEPLOY.md](DOCKER_DEPLOY.md) ⭐ |
| **生产环境部署** | [DEPLOYMENT.md](DEPLOYMENT.md) |
| **API地址配置** | [API_CONFIG.md](API_CONFIG.md) |
| **数据库优化** | [backend/database/DB_OPTIMIZATION_v1.5.9.md](backend/database/DB_OPTIMIZATION_v1.5.9.md) |
| **第三方服务集成** | [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) |
| **Bug修复记录** | [BUG_FIXES_v1.5.9_PATCH.md](BUG_FIXES_v1.5.9_PATCH.md) |

### ⚠️ 常见问题

**Q: 数据库连接失败？**
- 检查 `config/database.php` 配置是否正确
- 确认MySQL服务已启动
- 检查数据库用户权限

**Q: API请求失败（404/500）？**
- 检查后端服务是否启动
- 确认客户端配置的API地址正确
- 查看后端日志：`runtime/log/`

**Q: JWT令牌验证失败？**
- 确保配置了jwt.secret（不能使用默认值）
- 检查客户端和服务端时间是否同步

**Q: 数据库性能问题？**
- 应用优化脚本：`database/optimization_v1.5.9.sql`
- 参考优化文档：`backend/database/DB_OPTIMIZATION_v1.5.9.md`

更多问题请查看 [ERROR_HANDLING.md](ERROR_HANDLING.md)

---

## 📚 文档

### 核心文档

| 文档 | 说明 |
|------|------|
| [QUICK_START.md](QUICK_START.md) | ⭐ 快速开始指南（5分钟） |
| [SCRIPTS_GUIDE.md](SCRIPTS_GUIDE.md) | ⭐⭐ 脚本使用指南（必读） |
| [OPERATIONS_GUIDE.md](OPERATIONS_GUIDE.md) | ⭐⭐⭐ 运维监控指南（生产必读） |
| [PERFORMANCE_OPTIMIZATION.md](PERFORMANCE_OPTIMIZATION.md) | ⭐⭐⭐ 性能优化指南（生产必读） |
| [TESTING_GUIDE.md](TESTING_GUIDE.md) | ⭐⭐ 测试指南（开发必读） |
| [DOCKER_DEPLOY.md](DOCKER_DEPLOY.md) | ⭐ Docker部署指南（推荐） |
| [DEPLOYMENT.md](DEPLOYMENT.md) | 传统部署指南 |
| [API_CONFIG.md](API_CONFIG.md) | API配置指南 |
| [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) | ⭐ 第三方服务集成指南 |

### 技术文档

| 文档 | 说明 |
|------|------|
| [API.md](API.md) | API接口文档（74个接口） |
| [DATABASE.md](DATABASE.md) | 数据库设计文档（30个表） |
| [backend/database/DB_OPTIMIZATION_v1.5.9.md](backend/database/DB_OPTIMIZATION_v1.5.9.md) | 🔴 数据库优化报告（重要） |
| [ERROR_HANDLING.md](ERROR_HANDLING.md) | 错误处理文档 |

### 修复与更新

| 文档 | 说明 |
|------|------|
| [BUG_FIXES_v1.5.9_PATCH.md](BUG_FIXES_v1.5.9_PATCH.md) | 🔴 v1.5.9补丁修复报告（重要） |
| [CHANGELOG.md](CHANGELOG.md) | 版本更新日志 |
| [BUG_FIXES_REPORT.md](BUG_FIXES_REPORT.md) | Bug修复报告 |

### 项目报告

| 文档 | 说明 |
|------|------|
| [FINAL_PROJECT_SUMMARY_v1.5.9.md](FINAL_PROJECT_SUMMARY_v1.5.9.md) | ⭐⭐⭐ 最终项目总结（必读） |
| [COMPLETION_REPORT_v1.5.9.md](COMPLETION_REPORT_v1.5.9.md) | ⭐ v1.5.9完成报告（最新） |
| [TEST_SCRIPTS.md](TEST_SCRIPTS.md) | ⭐ 测试脚本文档 |
| [COMPLETION_REPORT_v1.5.8.md](COMPLETION_REPORT_v1.5.8.md) | v1.5.8完成报告 |
| [FINAL_COMPLETION_REPORT.md](FINAL_COMPLETION_REPORT.md) | 最终完成报告 |
| [PHASE_8_9_REPORT.md](PHASE_8_9_REPORT.md) | Phase 8-9实现报告 |
| [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) | 项目总结 |

---

## 📊 代码统计

```
总文件数：166+
总代码行数：42,000+

后端：
- 控制器：15个
- 模型：20个
- 服务类：3个 (Achievement/Challenge/Notification)
- API接口：74个
- 数据表：30个
- 代码：12,900+行

Android：
- Repository：8个
- ViewModel：8个
- UI Screen：6个
- 工具类：25个 (ErrorHandler/Logger/NetworkMonitor/CacheManager/ImageCompressor/FormatUtils/PermissionHelper/BiometricHelper/ShareHelper/NotificationHelper/HapticHelper/TTSHelper/DeviceHelper/BackupHelper/PerformanceMonitor/CrashHandler/ThemeManager/KeyboardManager/AnimationHelper/ValidationHelper等)
- 代码：13,950+行

iOS：
- Model：10个
- ViewModel：5个
- View：8个
- 工具类：24个 (ErrorHandler/Logger/NetworkMonitor/CacheManager/ImageCompressor/FormatUtils/PermissionHelper/BiometricHelper/ShareHelper/NotificationHelper/HapticHelper/TTSHelper/DeviceHelper/BackupHelper/PerformanceMonitor/CrashHandler/ThemeManager/KeyboardManager/AnimationHelper/ValidationHelper等)
- 代码：10,100+行
```

---

## 🔒 安全性

- ✅ JWT Token认证
- ✅ Token自动刷新机制
- ✅ Keychain安全存储（iOS）
- ✅ SharedPreferences加密（Android）
- ✅ SQL注入防护
- ✅ XSS防护
- ✅ 请求签名验证

---

## 🎨 截图

> 注：实际截图需要在真机或模拟器上运行后获取

### Android界面
- 登录/注册界面
- 跑步主界面
- 历史记录界面
- 社交动态界面
- 个人中心界面

### iOS界面
- 登录界面
- 跑步界面
- 历史记录列表
- 社交动态流
- 个人中心

---

## 🛠️ 开发指南

### API调用示例

```kotlin
// Android - Kotlin
viewModel.login(phone, password)
```

```swift
// iOS - Swift
await loginViewModel.login()
```

### 添加新功能

1. **后端**：在`backend/app/api/controller/`添加控制器
2. **Android**：按照MVVM架构添加Repository、ViewModel、Screen
3. **iOS**：按照MVVM架构添加ViewModel、View

---

## 📋 待完善功能

### 可选增强功能

- [ ] 地图SDK集成（Google Maps/高德/MapKit）
- [ ] 第三方登录（微信/QQ/Apple ID）
- [ ] 数据可视化图表
- [ ] HealthKit集成（iOS）
- [ ] Health Connect集成（Android）
- [ ] 单元测试覆盖
- [ ] CI/CD配置
- [ ] 国际化支持

---

## 🤝 贡献

欢迎提交Issue和Pull Request！

### 开发流程

1. Fork本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启Pull Request

---

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## 👥 团队

- **后端开发**: ThinkPHP + MySQL
- **Android开发**: Kotlin + Jetpack Compose
- **iOS开发**: Swift + SwiftUI
- **架构设计**: MVVM + Clean Architecture

---

## 🤝 参与贡献

我们欢迎所有形式的贡献！在参与之前，请阅读以下文档：

- [贡献指南](CONTRIBUTING.md) - 如何提交代码、报告Bug、提出新功能
- [行为准则](CODE_OF_CONDUCT.md) - 社区行为规范
- [安全政策](SECURITY.md) - 如何报告安全漏洞

### 快速开始贡献

1. Fork 本项目
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'feat: Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

---

## 📞 联系方式

- **项目名称**: Running App
- **当前版本**: v1.5.9
- **最后更新**: 2025-11-17

---

## 🙏 致谢

感谢以下开源项目：
- ThinkPHP
- Jetpack Compose
- SwiftUI
- Retrofit
- Alamofire
- Room
- CoreData

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给一个星标！ ⭐**

Made with ❤️ by Running App Team

</div>
