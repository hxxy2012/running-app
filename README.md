# Running App - 完整的跑步运动APP系统

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## 项目简介

这是一个功能完整的商业级跑步运动APP系统，包括：
- **Android原生客户端** (Kotlin + Jetpack Compose)
- **iOS原生客户端** (Swift + SwiftUI)
- **ThinkPHP后台服务** (PHP 8.0 + MySQL 8.0)

## 核心功能

### 用户系统
- 手机号注册/登录（短信验证码）
- 第三方登录（微信、QQ、Apple ID）
- 用户资料管理
- 实名认证
- 隐私设置

### 跑步核心功能
- GPS轨迹记录（实时定位、轨迹绘制）
- 运动数据记录（距离、时间、配速、步频、卡路里等）
- 多种运动类型支持（跑步、骑行、健走、登山、室内跑）
- 语音播报（每公里提醒、配速播报）
- 轨迹地图展示
- 运动轨迹分享（生成精美海报）
- 历史记录查询

### 训练计划
- 预设训练计划（5公里、10公里、半马、全马）
- 自定义训练计划
- 训练进度跟踪
- 每日训练提醒

### 数据统计与分析
- 个人数据汇总（日/周/月/年统计）
- 数据趋势图表
- 运动分析报告
- PB记录（Personal Best）
- 运动热力图

### 社交功能
- 运动动态发布
- 动态广场
- 点赞、评论、转发
- 关注/粉丝系统
- 私信聊天
- 附近的人
- 跑团功能

### 挑战与成就
- 每日挑战任务
- 里程挑战
- 虚拟赛事
- 成就徽章系统
- 段位系统
- 挑战排行榜

### 其他功能
- 全国/城市/好友排行榜
- 运动装备管理
- 健康数据整合
- 天气信息
- 音乐播放
- 消息推送
- 客服系统

## 技术栈

### 后台服务
```yaml
框架: ThinkPHP 6.x
数据库: MySQL 8.0+
服务器: Nginx + PHP 8.0+
存储: 本地文件存储
```

### Android客户端
```yaml
语言: Kotlin
最低版本: Android 7.0 (API 24)
目标版本: Android 14 (API 34)
架构: MVVM + Clean Architecture
UI: Jetpack Compose + Material Design 3
```

### iOS客户端
```yaml
语言: Swift 5.9+
最低版本: iOS 14.0
架构: MVVM + Combine
UI: SwiftUI + UIKit混合
```

## 项目结构

```
running-app/
├── backend/                 # ThinkPHP后台
│   ├── app/                # 应用代码
│   ├── config/             # 配置文件
│   ├── database/           # 数据库迁移
│   ├── public/             # 公开访问目录
│   └── route/              # 路由配置
├── android/                 # Android客户端
│   ├── app/                # 应用模块
│   │   ├── data/          # 数据层
│   │   ├── domain/        # 业务逻辑层
│   │   └── presentation/  # UI层
│   └── build.gradle.kts   # 构建配置
├── ios/                     # iOS客户端
│   ├── RunningApp/        # 应用代码
│   │   ├── Data/         # 数据层
│   │   ├── Domain/       # 业务逻辑层
│   │   └── Presentation/ # UI层
│   └── RunningApp.xcodeproj
└── docs/                    # 文档
    ├── API.md              # API接口文档
    ├── DATABASE.md         # 数据库设计文档
    └── DEPLOYMENT.md       # 部署文档
```

## 快速开始

### 后台部署

1. 安装依赖
```bash
cd backend
composer install
```

2. 配置数据库
```bash
cp config/database.example.php config/database.php
# 编辑 config/database.php 配置数据库连接
```

3. 导入数据库
```bash
mysql -u root -p running_app < database/running_app.sql
```

4. 配置Nginx
```bash
# 将项目的 public 目录设置为网站根目录
```

5. 访问
```
http://your-domain.com
```

### Android客户端

1. 环境要求
- Android Studio Hedgehog | 2023.1.1+
- Kotlin 1.9.20+
- Gradle 8.2+

2. 打开项目
```bash
# 使用 Android Studio 打开 android 目录
```

3. 配置API地址
```kotlin
// 编辑 app/src/main/java/com/yourapp/running/data/remote/ApiConstants.kt
const val BASE_URL = "https://your-api-domain.com/api/v1/"
```

4. 运行
```bash
# 点击 Run 或使用快捷键 Shift+F10
```

### iOS客户端

1. 环境要求
- Xcode 15.0+
- Swift 5.9+
- iOS 14.0+

2. 安装依赖
```bash
cd ios
pod install
```

3. 打开项目
```bash
open RunningApp.xcworkspace
```

4. 配置API地址
```swift
// 编辑 RunningApp/Data/Remote/APIService.swift
let baseURL = "https://your-api-domain.com/api/v1/"
```

5. 运行
```bash
# 选择模拟器或真机，点击 Run (⌘+R)
```

## API接口

详细的API接口文档请查看：[API文档](docs/API.md)

基础URL: `https://api.yourapp.com/v1`

### 接口认证
所有需要认证的接口需要在请求头中携带Token：
```
Authorization: Bearer {token}
```

### 响应格式
```json
{
  "code": 200,
  "message": "success",
  "data": {},
  "timestamp": 1234567890
}
```

## 数据库设计

详细的数据库设计文档请查看：[数据库文档](docs/DATABASE.md)

主要数据表：
- `user` - 用户表
- `running_record` - 跑步记录
- `track_point` - 轨迹坐标点
- `post` - 动态
- `training_plan` - 训练计划
- `challenge` - 挑战赛
- `running_club` - 跑团
- `ranking` - 排行榜
- 等共30+张表

## 开发进度

- [x] Phase 1: 基础框架搭建
  - [x] 后台ThinkPHP初始化
  - [x] Android项目初始化
  - [x] iOS项目初始化
  - [x] 用户认证系统
- [ ] Phase 2: 跑步核心功能
  - [ ] GPS定位与轨迹记录
  - [ ] 地图展示
  - [ ] 数据计算
- [ ] Phase 3: 数据统计
- [ ] Phase 4: 社交功能
- [ ] Phase 5: 高级功能
- [ ] Phase 6: 优化与发布

## 开发规范

### 代码规范
- **后台**: PSR-12编码规范
- **Android**: Kotlin官方编码规范 + ktlint
- **iOS**: Swift官方编码规范 + SwiftLint

### Git提交规范
```
feat: 新功能
fix: 修复bug
docs: 文档更新
style: 代码格式调整
refactor: 重构
test: 测试
chore: 构建/工具变动
```

## 安全说明

### 后台安全
- SQL注入防护（参数绑定）
- XSS防护（输出转义）
- CSRF防护（Token验证）
- 密码加密（bcrypt）
- JWT Token安全
- API频率限制
- HTTPS强制

### 客户端安全
- HTTPS通信
- 证书固定
- 本地数据加密
- Token安全存储
- 代码混淆

## 部署说明

详细的部署文档请查看：[部署文档](docs/DEPLOYMENT.md)

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 联系方式

- 项目主页: https://github.com/yourusername/running-app
- 问题反馈: https://github.com/yourusername/running-app/issues
- 邮箱: your.email@example.com

## 致谢

感谢所有为本项目做出贡献的开发者！

---

**注意**: 这是一个商业级项目，请遵守相关法律法规，不得用于非法用途。
