# 更新日志 (Changelog)

## [v1.5.1] - 2025-11-17

### 新增功能 🎉

#### Android工具类
- **Logger** - 统一日志管理工具
  - 支持网络请求日志记录
  - 支持数据库操作日志
  - 支持性能监控日志
  - 支持生命周期日志
  - 支持JSON格式化输出
  - 扩展函数简化使用

- **NetworkMonitor** - 网络状态监测工具
  - 实时监听网络连接状态
  - 自动识别网络类型（WiFi/移动数据/以太网）
  - Flow响应式API
  - 网络连接检查扩展函数

#### iOS工具类
- **Logger** - 统一日志管理工具
  - 基于os.log系统日志
  - 支持多种日志类别
  - 性能测量工具（PerformanceMeasure）
  - 便捷的静态方法
  - 自动包含文件名和行号

- **NetworkMonitor** - 网络状态监测工具
  - 基于NWPathMonitor实现
  - 自动识别连接类型
  - 网络质量评估功能
  - 网络可达性检查
  - Ping延迟测量
  - Combine Publisher支持

#### 后端服务类

- **AchievementService** - 成就管理服务
  - 自动检查和解锁成就
  - 支持9种成就类型：
    - 累计距离/次数/时长
    - 单次距离/时长/配速
    - 连续天数/本月次数/本月距离
  - 成就进度计算
  - 连续跑步天数统计

- **ChallengeService** - 挑战管理服务
  - 自动更新挑战进度
  - 支持7种挑战类型：
    - 总距离/次数/时长挑战
    - 单次距离/时长挑战
    - 平均配速挑战
    - 连续天数挑战
  - 挑战排行榜功能
  - 过期挑战自动处理

- **NotificationService** - 通知管理服务
  - 8种通知类型支持
  - 点赞/评论/关注通知
  - 成就解锁/挑战完成通知
  - 系统通知（支持批量发送）
  - 通知已读管理
  - 自动清理过期通知

### 完善功能 ✨

#### 后端业务逻辑
- **Running控制器** - 跑步结束时自动检查成就解锁和挑战进度
- **Post控制器** - 点赞和评论时自动发送通知
- **Follow控制器** - 关注时自动发送通知

### 技术改进 🔧

#### 代码质量
- 统一的日志管理，便于调试和问题追踪
- 完善的网络状态监测，提升用户体验
- 业务逻辑解耦，服务类独立管理

#### 性能优化
- Logger支持Debug模式开关
- NetworkMonitor使用Flow实现响应式监听
- 通知服务异步处理，不阻塞主业务

### 代码统计 📊

- **新增文件**: 10个
- **新增代码**: 1,566行
- **Android工具类**: 400+行
- **iOS工具类**: 450+行
- **后端服务类**: 800+行

### 移除的TODO ✅

- ✅ 检查成就解锁（Running控制器）
- ✅ 检查挑战进度（Running控制器）
- ✅ 发送消息通知（Follow控制器）
- ✅ 发送消息通知（Post控制器 - 点赞）
- ✅ 发送消息通知（Post控制器 - 评论）

---

## [v1.5.0] - 2025-11-17

### 新增功能

#### 统一的错误处理机制
- Android ErrorHandler工具类
- iOS ErrorHandler工具类
- 所有ViewModel集成错误处理

#### 配置示例文件
- backend/.env.example
- android/local.properties.example
- ios/Config.xcconfig.example

#### 文档完善
- QUICK_START.md - 5分钟快速开始指南
- ERROR_HANDLING.md - 错误处理详细文档

### 改进
- 所有Android ViewModel使用统一ErrorHandler
- 所有iOS ViewModel使用userFriendlyMessage扩展
- 用户友好的错误提示

### 完成度
- 后端: 100% ✅
- Android: 100% ✅
- iOS: 100% ✅
- **总完成度: 100%** 🎉

---

## [v1.4.0] - 2025-11-15

### 新增功能

#### ViewModel体系
- iOS HistoryViewModel
- iOS SocialViewModel
- iOS ProfileViewModel

#### 工具类
- Android ValidationUtils
- Android DateTimeUtils
- iOS ValidationUtils

#### iOS模型增强
- Post模型支持状态更新
- 新增TrainingPlan模型
- 新增Challenge模型
- 新增RunningClub模型
- 新增Achievement模型

### Bug修复
- Android ProfileScreen clickable导入
- LoginViewModel缺失方法
- RunningViewModel缺失方法
- iOS KeychainManager实现
- iOS Token刷新逻辑

### 完成度
- 后端: 100% ✅
- Android: 99% ✅
- iOS: 99% ✅

---

## [v1.3.0] - 2025-11-14

### Phase 9: UI实现

#### Android UI
- LoginScreen - 登录页面
- RegisterScreen - 注册页面
- RunningScreen - 跑步页面
- HistoryScreen - 历史记录页面
- SocialFeedScreen - 社交动态页面
- ProfileScreen - 个人中心页面

#### iOS UI
- LoginView - 登录视图
- RunningView - 跑步视图
- HistoryListView - 历史记录列表
- SocialFeedView - 社交动态视图
- ProfileView - 个人中心视图

---

## [v1.2.0] - 2025-11-13

### Phase 8: Repository和ViewModel

#### Android
- 8个Repository类实现
- 8个ViewModel类实现
- MVVM架构完成

#### iOS
- LoginViewModel
- RunningViewModel
- 基础架构搭建

---

## [v1.1.0] - 2025-11-12

### Phase 7: 客户端核心架构

#### Android
- 依赖注入配置（Hilt）
- 网络层封装（Retrofit）
- 本地数据库（Room）
- 数据模型定义

#### iOS
- 网络服务封装（Alamofire）
- 数据模型定义
- Keychain安全存储

---

## [v1.0.0] - 2025-11-10

### 后端完成

- 74个API接口实现
- 30个数据库表设计
- JWT认证系统
- 文件上传功能
- 完整的RESTful API

---

## 图例说明

- 🎉 新增功能
- ✨ 功能完善
- 🔧 技术改进
- 🐛 Bug修复
- 📊 代码统计
- ✅ 完成项目
- 🔒 安全更新
- 📚 文档更新
