# Running App - 全栈跑步应用

<div align="center">

![Version](https://img.shields.io/badge/version-1.5.1-blue)
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
| Android (Kotlin) | 99% | ✅ 生产可用 |
| iOS (Swift) | 99% | ✅ 生产可用 |

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
```bash
cd backend
composer install
cp config/database_example.php config/database.php
# 编辑database.php配置数据库连接
mysql -u root -p < database/running_app.sql
php think run
```

#### 3. Android配置
```bash
cd android
# 编辑 android/app/src/main/java/com/runningapp/di/AppModule.kt
# 修改第18行的API地址
./gradlew assembleDebug
```

#### 4. iOS配置
```bash
cd ios
# 编辑 ios/RunningApp/Services/NetworkService.swift
# 修改第8行的API地址
pod install
open RunningApp.xcworkspace
```

详细配置说明请参考 [API_CONFIG.md](API_CONFIG.md)

---

## 📚 文档

| 文档 | 说明 |
|------|------|
| [QUICK_START.md](QUICK_START.md) | ⭐ 快速开始指南（5分钟） |
| [API_CONFIG.md](API_CONFIG.md) | API配置指南 |
| [ERROR_HANDLING.md](ERROR_HANDLING.md) | 错误处理文档 |
| [API.md](API.md) | API接口文档（74个接口） |
| [DATABASE.md](DATABASE.md) | 数据库设计文档（30个表） |
| [DEPLOYMENT.md](DEPLOYMENT.md) | 部署指南 |
| [BUG_FIXES_REPORT.md](BUG_FIXES_REPORT.md) | Bug修复报告 |
| [PHASE_8_9_REPORT.md](PHASE_8_9_REPORT.md) | Phase 8-9实现报告 |
| [FINAL_COMPLETION_REPORT.md](FINAL_COMPLETION_REPORT.md) | 最终完成报告 |
| [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) | 项目总结 |

---

## 📊 代码统计

```
总文件数：132+
总代码行数：29,700+

后端：
- 控制器：15个
- 模型：20个
- API接口：74个
- 数据表：30个
- 代码：12,100+行

Android：
- Repository：8个
- ViewModel：8个
- UI Screen：6个
- 工具类：5个
- 代码：9,000+行

iOS：
- Model：10个
- ViewModel：5个
- View：8个
- 工具类：4个
- 代码：4,200+行
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

## 📞 联系方式

- **项目名称**: Running App
- **当前版本**: v1.4.0
- **最后更新**: 2025-11-15

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
