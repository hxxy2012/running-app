# Running App - iOS客户端

## 项目简介

Running App iOS客户端，使用Swift语言，采用MVVM架构，SwiftUI构建现代化UI。

## 实现状态

### ✅ 已完成
- **数据模型**: User、RunningRecord、TrackPoint、Post等完整模型
- **网络层**: NetworkService基于Alamofire的完整实现
- **定位服务**: LocationTrackingService GPS跟踪服务
- **安全存储**: KeychainManager token安全管理
- **ViewModels**: LoginViewModel、RunningViewModel实现
- **API封装**: 统一的ApiResponse和错误处理

### 🚧 待完善
- **UI界面**: SwiftUI具体页面实现
- **CoreData**: 本地数据持久化
- **HealthKit集成**: 健康数据读写
- **第三方登录**: Apple ID、微信、QQ登录
- **单元测试**: ViewModel和Service测试用例

## 技术栈

- **语言**: Swift 5.9+
- **最低版本**: iOS 14.0
- **目标版本**: iOS 17.0
- **UI框架**: SwiftUI + UIKit混合
- **架构**: MVVM + Combine
- **网络**: Alamofire
- **数据库**: CoreData
- **异步**: Async/Await + Combine
- **地图**: MapKit
- **图表**: Charts

## 项目结构

```
RunningApp/
├── Models/                        # 数据模型 ✅
│   ├── User.swift                 # 用户模型 ✅
│   ├── RunningRecord.swift        # 跑步记录模型 ✅
│   ├── Post.swift                 # 动态帖子模型 ✅
│   ├── ApiResponse.swift          # API响应模型 ✅
│   └── TrackPoint.swift           # 轨迹点模型 ✅
├── Services/                      # 服务层 ✅
│   ├── NetworkService.swift       # 网络服务 ✅
│   ├── LocationTrackingService.swift  # GPS跟踪服务 ✅
│   └── KeychainManager.swift      # 钥匙串管理 ✅
├── ViewModels/                    # 视图模型 ✅
│   ├── LoginViewModel.swift       # 登录ViewModel ✅
│   └── RunningViewModel.swift     # 跑步ViewModel ✅
├── Views/                         # 视图层 🚧
│   ├── Auth/                      # 认证模块
│   │   ├── LoginView.swift
│   │   └── RegisterView.swift
│   ├── Main/
│   │   └── MainTabView.swift
│   ├── Running/                   # 跑步模块
│   │   └── RunningView.swift
│   ├── History/                   # 历史记录
│   ├── Social/                    # 社交模块
│   └── Profile/                   # 个人中心
├── Utils/                         # 工具类 ✅
│   └── LocationUtils.swift        # 位置工具 ✅
└── Resources/
    ├── Assets.xcassets
    └── Info.plist
```

## 核心功能模块

### 1. 用户认证模块
- 手机号注册/登录
- 第三方登录（微信、QQ、Apple ID）
- Token管理
- Keychain安全存储

### 2. 跑步记录模块
- CLLocationManager定位
- 轨迹记录
- MapKit地图展示
- 数据计算
- 语音播报（AVSpeechSynthesizer）
- 后台定位

### 3. 数据统计模块
- SwiftUI Charts图表
- 日历视图
- PB记录
- 趋势分析

### 4. 健康整合
- HealthKit数据读写
- 心率数据
- 步数同步
- 运动记录同步

### 5. 社交模块
- SwiftUI动态列表
- 点赞评论
- 关注系统
- 用户主页

## 依赖管理

使用CocoaPods管理依赖：

```ruby
pod 'Alamofire', '~> 5.8'        # 网络请求
pod 'Kingfisher', '~> 7.10'      # 图片加载
pod 'Charts', '~> 5.0'           # 图表
pod 'KeychainAccess', '~> 4.2'   # 钥匙串
```

## API配置

在 `APIService.swift` 中配置API地址：

```swift
let baseURL = "https://api.yourapp.com/api/"
```

## 构建和运行

### 开发环境要求
- macOS Ventura 13.0+
- Xcode 15.0+
- Swift 5.9+
- CocoaPods 1.12+

### 构建步骤

1. 克隆项目
```bash
git clone <repository-url>
cd running-app/ios
```

2. 安装依赖
```bash
pod install
```

3. 打开项目
```bash
open RunningApp.xcworkspace
```

4. 配置API地址
编辑 `APIService.swift` 中的 `baseURL`

5. 运行
在Xcode中选择目标设备，点击Run (⌘+R)

## 权限配置

在 `Info.plist` 中添加以下权限说明：

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>需要获取您的位置信息以记录跑步轨迹</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>需要始终获取位置信息以在后台记录轨迹</string>

<key>NSMotionUsageDescription</key>
<string>需要访问运动数据以记录步数</string>

<key>NSHealthShareUsageDescription</key>
<string>需要读取健康数据</string>

<key>NSHealthUpdateUsageDescription</key>
<string>需要写入健康数据</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册以上传图片</string>

<key>NSCameraUsageDescription</key>
<string>需要使用相机拍照</string>
```

## 项目特点

### 1. SwiftUI + Combine
- 声明式UI
- 响应式数据流
- @Published属性包装器
- ObservableObject协议

### 2. MVVM架构
```swift
// View
struct RunningView: View {
    @StateObject private var viewModel = RunningViewModel()

    var body: some View {
        // UI代码
    }
}

// ViewModel
class RunningViewModel: ObservableObject {
    @Published var distance: Double = 0
    @Published var duration: Int = 0

    func startRunning() {
        // 业务逻辑
    }
}
```

### 3. Async/Await
```swift
func fetchData() async throws {
    let data = try await apiService.getData()
    self.items = data
}
```

### 4. CLLocationManager定位
```swift
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var locations: [CLLocation] = []

    func startTracking() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.startUpdatingLocation()
    }
}
```

### 5. HealthKit集成
```swift
class HealthKitManager {
    let healthStore = HKHealthStore()

    func requestAuthorization() async throws {
        // 请求权限
    }

    func saveWorkout(record: RunningRecord) async throws {
        // 保存运动记录
    }
}
```

## 性能优化

- LazyVStack列表懒加载
- 图片缓存（Kingfisher）
- CoreData批量操作
- 主线程UI更新
- 内存管理（weak, unowned）

## 测试

```bash
# 单元测试
⌘ + U

# UI测试
在Xcode中选择UI Testing方案运行
```

## 发布

### 1. Archive
```
Product > Archive
```

### 2. 导出IPA
```
Organizer > Distribute App
```

### 3. 提交App Store
使用Xcode或Application Loader上传

## 注意事项

1. **Apple Developer账号**：需要开发者账号进行真机测试和发布
2. **证书配置**：配置Development和Distribution证书
3. **Bundle ID**：设置唯一的Bundle Identifier
4. **第三方登录**：配置URL Schemes
5. **推送通知**：配置APNs证书

## 代码规范

遵循Swift官方编码规范：

```swift
// MARK: - Properties
private let apiService: APIService

// MARK: - Lifecycle
override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
}

// MARK: - Actions
@IBAction func buttonTapped() {
    // ...
}

// MARK: - Helpers
private func setupUI() {
    // ...
}
```

使用SwiftLint进行代码检查：

```bash
brew install swiftlint
```

## 开发者

Running App Team

## 许可证

MIT License

---

**更新日期**: 2025-11-15
**版本**: 1.0.0
