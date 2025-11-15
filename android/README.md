# Running App - Android客户端

## 项目简介

Running App Android客户端，使用Kotlin语言，采用MVVM + Clean Architecture架构，Jetpack Compose构建现代化UI。

## 技术栈

- **语言**: Kotlin
- **最低版本**: Android 7.0 (API 24)
- **目标版本**: Android 14 (API 34)
- **UI框架**: Jetpack Compose + Material Design 3
- **架构**: MVVM + Clean Architecture
- **依赖注入**: Hilt
- **网络**: Retrofit + OkHttp
- **数据库**: Room
- **异步**: Coroutines + Flow
- **地图**: Google Maps / 高德地图
- **图表**: MPAndroidChart

## 项目结构

```
app/src/main/java/com/runningapp/
├── RunningApplication.kt          # Application类
├── data/                          # 数据层
│   ├── local/                     # 本地数据
│   │   ├── dao/                   # Room DAO
│   │   ├── database/              # 数据库
│   │   └── entity/                # 数据库实体
│   ├── remote/                    # 远程数据
│   │   ├── ApiService.kt          # API接口定义
│   │   ├── dto/                   # 数据传输对象
│   │   └── interceptor/           # 网络拦截器
│   └── repository/                # 数据仓库实现
├── domain/                        # 业务逻辑层
│   ├── model/                     # 领域模型
│   ├── repository/                # 仓库接口
│   └── usecase/                   # 用例
├── presentation/                  # 展示层
│   ├── MainActivity.kt            # 主Activity
│   ├── navigation/                # 导航
│   ├── theme/                     # 主题
│   ├── components/                # 通用组件
│   ├── auth/                      # 认证模块
│   │   ├── LoginScreen.kt
│   │   ├── RegisterScreen.kt
│   │   └── LoginViewModel.kt
│   ├── running/                   # 跑步模块
│   │   ├── RunningScreen.kt
│   │   ├── RunningViewModel.kt
│   │   └── components/
│   ├── record/                    # 记录模块
│   ├── social/                    # 社交模块
│   └── profile/                   # 个人中心
├── service/                       # 服务
│   ├── LocationService.kt         # 定位服务
│   └── RunningTrackingService.kt  # 跑步追踪服务
├── utils/                         # 工具类
└── di/                            # 依赖注入模块
    ├── AppModule.kt
    ├── NetworkModule.kt
    └── DatabaseModule.kt
```

## 核心功能模块

### 1. 用户认证模块
- 手机号注册/登录
- 第三方登录（微信、QQ）
- Token管理
- 自动刷新Token

### 2. 跑步记录模块
- GPS实时定位
- 轨迹记录
- 地图展示
- 数据计算（距离、配速、速度）
- 语音播报
- 前台服务

### 3. 数据统计模块
- 图表展示
- 日历视图
- PB记录
- 趋势分析

### 4. 社交模块
- 动态发布
- 点赞评论
- 关注系统
- 用户主页

### 5. 其他模块
- 训练计划
- 挑战赛
- 跑团
- 排行榜
- 成就系统

## 依赖库

```kotlin
// Jetpack Compose
implementation("androidx.compose.ui:ui")
implementation("androidx.compose.material3:material3")
implementation("androidx.navigation:navigation-compose")

// Hilt DI
implementation("com.google.dagger:hilt-android:2.48")
kapt("com.google.dagger:hilt-compiler:2.48")

// Room Database
implementation("androidx.room:room-runtime:2.6.1")
kapt("androidx.room:room-compiler:2.6.1")

// Retrofit & OkHttp
implementation("com.squareup.retrofit2:retrofit:2.9.0")
implementation("com.squareup.retrofit2:converter-gson:2.9.0")
implementation("com.squareup.okhttp3:okhttp:4.12.0")

// Location & Maps
implementation("com.google.android.gms:play-services-location:21.0.1")
implementation("com.google.maps.android:maps-compose:4.3.0")

// Image Loading
implementation("io.coil-kt:coil-compose:2.5.0")

// Charts
implementation("com.github.PhilJay:MPAndroidChart:v3.1.0")
```

## API配置

在 `app/build.gradle.kts` 中配置API地址：

```kotlin
buildConfigField("String", "BASE_URL", "\"https://api.yourapp.com/api/\"")
```

## 构建和运行

### 开发环境要求
- Android Studio Hedgehog | 2023.1.1+
- JDK 17+
- Gradle 8.2+

### 构建步骤

1. 克隆项目
```bash
git clone <repository-url>
cd running-app/android
```

2. 配置API地址
编辑 `app/build.gradle.kts` 中的 `BASE_URL`

3. 同步依赖
```bash
./gradlew clean build
```

4. 运行
使用Android Studio运行或执行：
```bash
./gradlew installDebug
```

## 权限说明

应用需要以下权限：
- `INTERNET` - 网络访问
- `ACCESS_FINE_LOCATION` - 精确定位
- `ACCESS_COARSE_LOCATION` - 粗略定位
- `FOREGROUND_SERVICE` - 前台服务
- `FOREGROUND_SERVICE_LOCATION` - 定位前台服务
- `POST_NOTIFICATIONS` - 通知权限
- `ACTIVITY_RECOGNITION` - 活动识别

## 项目特点

### 1. Clean Architecture
严格遵循Clean Architecture原则，代码分层清晰：
- Presentation层：UI和ViewModel
- Domain层：业务逻辑和用例
- Data层：数据访问

### 2. MVVM模式
使用ViewModel管理UI状态，LiveData/StateFlow响应式更新UI

### 3. 依赖注入
使用Hilt简化依赖注入，提高代码可测试性

### 4. Kotlin Coroutines
使用协程处理异步操作，代码简洁优雅

### 5. Jetpack Compose
使用声明式UI框架，提高开发效率

## 性能优化

- LazyColumn实现列表懒加载
- 图片缓存（Coil）
- 数据库索引优化
- 网络请求缓存
- ProGuard代码混淆

## 测试

```bash
# 单元测试
./gradlew test

# UI测试
./gradlew connectedAndroidTest
```

## 发布

### Debug版本
```bash
./gradlew assembleDebug
```

### Release版本
```bash
./gradlew assembleRelease
```

生成的APK位于：`app/build/outputs/apk/`

## 注意事项

1. **地图API密钥**：需要申请Google Maps API密钥或高德地图密钥
2. **第三方登录**：需要在对应平台申请AppID
3. **推送服务**：需要集成FCM或其他推送服务
4. **混淆规则**：Release版本需要配置ProGuard规则

## 开发者

Running App Team

## 许可证

MIT License

---

**更新日期**: 2025-11-15
**版本**: 1.0.0
