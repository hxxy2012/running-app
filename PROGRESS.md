# Running App 项目进度说明

## 当前状态

**项目开始日期**: 2025-11-15

**当前进度**: Phase 1 后台基础功能已完成，准备开始Android/iOS开发

---

## 已完成功能

### ✅ 后台服务 (ThinkPHP)

#### 1. 项目基础架构
- [x] ThinkPHP 6.x 项目初始化
- [x] Composer依赖配置
- [x] 目录结构搭建
- [x] 配置文件设置（数据库、应用、路由）
- [x] 中间件配置（JWT认证）

#### 2. 数据库设计
- [x] 完整的数据库设计（30+张表）
- [x] 用户相关表（user, user_oauth, sms_code）
- [x] 跑步记录表（running_record, track_point）
- [x] 训练计划表（training_plan, user_training_plan, training_plan_detail）
- [x] 社交功能表（post, like, comment, follow）
- [x] 跑团表（running_club, club_member）
- [x] 挑战表（challenge, user_challenge）
- [x] 成就表（achievement, user_achievement）
- [x] 排行榜表（ranking）
- [x] 其他表（equipment, message, feedback, config）
- [x] 初始数据插入（配置、成就、训练计划）

#### 3. API接口实现

**认证相关 (无需Token)**:
- [x] POST /auth/send-code - 发送验证码
- [x] POST /auth/register - 用户注册
- [x] POST /auth/login - 用户登录
- [x] POST /auth/refresh-token - 刷新Token
- [x] POST /auth/oauth - 第三方登录（框架）

**跑步记录 (需要Token)**:
- [x] POST /running/start - 开始跑步
- [x] POST /running/upload-point - 上传轨迹点
- [x] POST /running/finish - 结束跑步
- [x] GET /running/records - 获取记录列表
- [x] GET /running/record/:id - 记录详情
- [x] PUT /running/record/:id - 编辑记录
- [x] DELETE /running/record/:id - 删除记录
- [x] GET /running/statistics - 统计数据
- [x] GET /running/calendar - 日历数据
- [x] GET /running/pb - PB记录
- [x] POST /running/share - 生成分享海报

**文件上传 (需要Token)**:
- [x] POST /upload/image - 上传图片

**公共接口 (无需Token)**:
- [x] GET /config - 获取配置
- [x] GET /version - 版本检测
- [x] GET /common/weather - 获取天气

#### 4. 核心功能
- [x] JWT Token认证机制
- [x] 短信验证码系统（框架）
- [x] 文件上传处理
- [x] 统一响应格式
- [x] 错误处理机制
- [x] 数据验证

#### 5. 模型层
- [x] User模型（用户）
- [x] SmsCode模型（验证码）
- [x] RunningRecord模型（跑步记录）
- [x] TrackPoint模型（轨迹点）

#### 6. 服务层
- [x] JwtService（JWT Token生成和验证）

#### 7. 文档
- [x] 完整的API接口文档（docs/API.md）
- [x] 详细的部署文档（docs/DEPLOYMENT.md）
- [x] 数据库设计文档（docs/DATABASE.md）
- [x] README项目说明文档

---

## 待开发功能

### 🔄 后台服务（剩余API）

#### 1. 用户管理
- [ ] GET /user/profile - 获取个人信息
- [ ] PUT /user/profile - 更新个人信息
- [ ] POST /user/avatar - 上传头像
- [ ] PUT /user/password - 修改密码
- [ ] POST /user/real-auth - 实名认证
- [ ] DELETE /user/account - 注销账号

#### 2. 训练计划
- [ ] GET /training/plans - 获取计划列表
- [ ] GET /training/plan/:id - 计划详情
- [ ] POST /training/plan - 创建自定义计划
- [ ] POST /training/join/:id - 加入计划
- [ ] GET /training/my-plan - 我的计划
- [ ] PUT /training/complete-day - 完成某天训练
- [ ] PUT /training/abandon - 放弃计划

#### 3. 社交动态
- [ ] POST /post - 发布动态
- [ ] GET /post/feed - 动态流
- [ ] GET /post/square - 广场
- [ ] GET /post/:id - 动态详情
- [ ] DELETE /post/:id - 删除动态
- [ ] POST /post/:id/like - 点赞
- [ ] DELETE /post/:id/like - 取消点赞
- [ ] POST /post/:id/comment - 评论
- [ ] GET /post/:id/comments - 评论列表
- [ ] DELETE /comment/:id - 删除评论

#### 4. 关注系统
- [ ] POST /follow/:userId - 关注
- [ ] DELETE /follow/:userId - 取消关注
- [ ] GET /follow/following - 关注列表
- [ ] GET /follow/followers - 粉丝列表
- [ ] GET /follow/friends - 互相关注

#### 5. 跑团
- [ ] POST /club - 创建跑团
- [ ] GET /club/list - 跑团列表
- [ ] GET /club/:id - 跑团详情
- [ ] PUT /club/:id - 编辑跑团
- [ ] POST /club/:id/join - 加入跑团
- [ ] DELETE /club/:id/quit - 退出跑团
- [ ] GET /club/:id/members - 成员列表
- [ ] PUT /club/:id/member/:userId - 修改成员角色
- [ ] GET /club/:id/ranking - 跑团排行

#### 6. 挑战赛
- [ ] GET /challenge/list - 挑战列表
- [ ] GET /challenge/:id - 挑战详情
- [ ] POST /challenge/:id/join - 参加挑战
- [ ] GET /challenge/:id/ranking - 挑战排行
- [ ] GET /challenge/my - 我的挑战

#### 7. 成就系统
- [ ] GET /achievement/list - 成就列表
- [ ] GET /achievement/my - 我的成就

#### 8. 排行榜
- [ ] GET /ranking/total - 总排行
- [ ] GET /ranking/month - 月排行
- [ ] GET /ranking/week - 周排行
- [ ] GET /ranking/friends - 好友排行
- [ ] GET /ranking/city - 城市排行

#### 9. 装备管理
- [ ] POST /equipment - 添加装备
- [ ] GET /equipment/list - 装备列表
- [ ] PUT /equipment/:id - 更新装备
- [ ] DELETE /equipment/:id - 删除装备

#### 10. 消息通知
- [ ] GET /message/list - 消息列表
- [ ] PUT /message/read - 标记已读
- [ ] GET /message/unread-count - 未读数

#### 11. 其他
- [ ] POST /feedback - 提交反馈

### 📱 Android客户端

#### Phase 1: 基础框架
- [ ] 项目初始化和依赖配置
- [ ] Hilt依赖注入配置
- [ ] Room数据库配置
- [ ] 网络层封装（Retrofit + OkHttp）
- [ ] 数据层架构（Repository模式）
- [ ] UI层架构（MVVM + Jetpack Compose）
- [ ] 登录注册UI
- [ ] 用户信息管理

#### Phase 2: 跑步核心功能
- [ ] GPS定位服务（高德地图SDK）
- [ ] 轨迹记录前台服务
- [ ] 地图展示（MapView）
- [ ] 实时数据计算（距离、配速、速度）
- [ ] 语音播报服务
- [ ] 跑步主界面UI
- [ ] 历史记录列表
- [ ] 记录详情页

#### Phase 3: 数据统计
- [ ] 统计数据展示
- [ ] 图表组件（MPAndroidChart）
- [ ] 日历视图
- [ ] PB记录展示

#### Phase 4: 社交功能
- [ ] 动态发布
- [ ] 动态流
- [ ] 点赞/评论
- [ ] 用户主页
- [ ] 关注系统

#### Phase 5: 高级功能
- [ ] 训练计划
- [ ] 挑战赛
- [ ] 跑团功能
- [ ] 排行榜
- [ ] 成就系统

### 🍎 iOS客户端

#### Phase 1: 基础框架
- [ ] 项目初始化（SwiftUI + UIKit混合）
- [ ] CoreData配置
- [ ] 网络层封装（Alamofire）
- [ ] MVVM架构搭建
- [ ] 登录注册UI（SwiftUI）
- [ ] 用户信息管理

#### Phase 2: 跑步核心功能
- [ ] LocationManager（CLLocationManager）
- [ ] 轨迹记录服务
- [ ] MapKit地图展示
- [ ] 实时数据计算
- [ ] 语音播报
- [ ] 跑步主界面UI（SwiftUI）
- [ ] 历史记录列表
- [ ] 记录详情页

#### Phase 3: 数据统计
- [ ] 统计数据展示
- [ ] 图表组件（Charts库）
- [ ] 日历视图
- [ ] PB记录展示
- [ ] HealthKit集成

#### Phase 4: 社交功能
- [ ] 动态发布
- [ ] 动态流
- [ ] 点赞/评论
- [ ] 用户主页
- [ ] 关注系统

#### Phase 5: 高级功能
- [ ] 训练计划
- [ ] 挑战赛
- [ ] 跑团功能
- [ ] 排行榜
- [ ] 成就系统

---

## 技术栈总结

### 后台
```
框架: ThinkPHP 6.x
语言: PHP 8.0+
数据库: MySQL 8.0+
Web服务器: Nginx
认证: JWT
依赖管理: Composer
```

### Android
```
语言: Kotlin
最低版本: Android 7.0 (API 24)
目标版本: Android 14 (API 34)
UI框架: Jetpack Compose
架构: MVVM + Clean Architecture
依赖注入: Hilt
网络: Retrofit + OkHttp
数据库: Room
地图: 高德地图SDK
图表: MPAndroidChart
```

### iOS
```
语言: Swift 5.9+
最低版本: iOS 14.0
UI框架: SwiftUI + UIKit
架构: MVVM + Combine
网络: Alamofire
数据库: CoreData
地图: MapKit
图表: Charts
图片: Kingfisher
```

---

## 下一步计划

### 立即可做
1. **测试后台API**: 使用Postman或其他工具测试已实现的API
2. **部署后台服务**: 按照DEPLOYMENT.md文档部署到服务器
3. **开始Android开发**: 创建Android项目基础框架
4. **开始iOS开发**: 创建iOS项目基础框架

### 建议顺序
1. 先完成一个平台（Android或iOS）的Phase 1-2
2. 同时完善后台剩余API
3. 然后开发另一个平台
4. 最后完善高级功能和优化

---

## 项目文件结构

```
running-app/
├── README.md                 # 项目说明
├── LICENSE                   # MIT许可证
├── PROGRESS.md              # 本文档
├── .gitignore               # Git忽略配置
│
├── backend/                 # ThinkPHP后台 ✅
│   ├── app/
│   │   ├── api/
│   │   │   ├── controller/  # 控制器（Auth, Running, Common已完成）
│   │   │   └── middleware/  # 中间件（Auth已完成）
│   │   └── common/
│   │       ├── model/       # 模型（User, SmsCode, RunningRecord, TrackPoint已完成）
│   │       └── service/     # 服务（JwtService已完成）
│   ├── config/              # 配置文件 ✅
│   ├── database/            # 数据库SQL ✅
│   ├── public/              # 公开访问目录
│   ├── route/               # 路由配置 ✅
│   └── composer.json        # Composer配置 ✅
│
├── android/                 # Android客户端 🔄
│   └── (待创建)
│
├── ios/                     # iOS客户端 🔄
│   └── (待创建)
│
└── docs/                    # 文档 ✅
    ├── API.md               # API接口文档 ✅
    ├── DATABASE.md          # 数据库设计文档 ✅
    └── DEPLOYMENT.md        # 部署文档 ✅
```

**图例**:
- ✅ 已完成
- 🔄 进行中
- ⏸️ 待开始

---

## 开发人员备注

### 已实现的核心功能
1. **完整的用户认证系统**: 注册、登录、JWT Token
2. **跑步记录完整流程**: 开始 -> 上传轨迹 -> 结束
3. **数据查询和统计**: 列表、详情、统计、日历、PB
4. **文件上传**: 支持图片上传
5. **完善的文档**: API、部署、数据库三大文档

### 技术亮点
- **RESTful API设计**: 符合REST规范
- **JWT认证**: 安全的Token机制
- **数据库设计**: 完整的30+张表设计
- **MVC架构**: 清晰的代码结构
- **统一响应格式**: 便于客户端处理

### 待优化项
- 短信服务商接入（目前为框架）
- 第三方登录实现（微信、QQ、Apple）
- Redis缓存系统
- 消息队列
- 定时任务实现
- 单元测试

---

**最后更新**: 2025-11-15
**文档维护**: 持续更新中
