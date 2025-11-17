# Running App - 第三方服务集成指南

本文档提供所有第三方服务的详细集成步骤和代码示例。

**版本**: v1.5.9
**更新日期**: 2025-11-17

---

## 目录

1. [短信服务集成](#1-短信服务集成)
2. [实名认证服务集成](#2-实名认证服务集成)
3. [地图SDK集成](#3-地图sdk集成)
4. [数据可视化图表](#4-数据可视化图表)
5. [第三方登录集成](#5-第三方登录集成)
6. [iOS CoreData实现](#6-ios-coredata实现)

---

## 1. 短信服务集成

### 1.1 阿里云短信（推荐）

#### 步骤1: 开通服务

1. 登录 [阿里云控制台](https://www.aliyun.com/)
2. 开通「短信服务」
3. 申请签名和模板
4. 获取 AccessKey ID 和 AccessKey Secret

#### 步骤2: 安装SDK

```bash
cd backend
composer require alibabacloud/sdk
```

#### 步骤3: 配置

在 `backend/.env` 添加：

```ini
# 短信配置
sms.provider=aliyun
sms.aliyun.access_key_id=YOUR_ACCESS_KEY_ID
sms.aliyun.access_key_secret=YOUR_ACCESS_KEY_SECRET
sms.aliyun.sign_name=Running App
sms.aliyun.template_code=SMS_123456789
```

#### 步骤4: 测试

```bash
# 访问API测试
POST /api/auth/send-code
{
    "phone": "13800138000",
    "type": 1
}
```

### 1.2 腾讯云短信

#### 安装SDK

```bash
composer require tencentcloud/tencentcloud-sdk-php
```

#### 配置

```ini
sms.provider=tencent
sms.tencent.secret_id=YOUR_SECRET_ID
sms.tencent.secret_key=YOUR_SECRET_KEY
sms.tencent.sdk_app_id=YOUR_SDK_APP_ID
sms.tencent.sign_name=Running App
sms.tencent.template_id=123456
```

---

## 2. 实名认证服务集成

### 2.1 阿里云实人认证

#### 步骤1: 开通服务

1. 登录阿里云控制台
2. 开通「实人认证」服务
3. 获取 AccessKey

#### 步骤2: 安装SDK

```bash
composer require alibabacloud/cloudauth-20190307
```

#### 步骤3: 配置

在 `backend/.env` 添加：

```ini
# 实名认证配置
realauth.provider=aliyun
realauth.aliyun.access_key_id=YOUR_ACCESS_KEY_ID
realauth.aliyun.access_key_secret=YOUR_ACCESS_KEY_SECRET
realauth.aliyun.region_id=cn-hangzhou
```

#### 步骤4: 更新代码

解开 `backend/app/common/service/RealAuthService.php` 中的注释代码。

### 2.2 腾讯云人脸核身

#### 安装SDK

```bash
composer require tencentcloud/faceid
```

#### 配置

```ini
realauth.provider=tencent
realauth.tencent.secret_id=YOUR_SECRET_ID
realauth.tencent.secret_key=YOUR_SECRET_KEY
realauth.tencent.region=ap-guangzhou
```

---

## 3. 地图SDK集成

### 3.1 Android - Google Maps

#### 步骤1: 获取API密钥

1. 访问 [Google Cloud Console](https://console.cloud.google.com/)
2. 创建项目并启用 Maps SDK for Android
3. 获取 API Key

#### 步骤2: 添加依赖

在 `android/app/build.gradle` 添加：

```gradle
dependencies {
    implementation 'com.google.android.gms:play-services-maps:18.2.0'
    implementation 'com.google.maps.android:android-maps-utils:3.8.2'
}
```

#### 步骤3: 配置API Key

在 `android/app/src/main/AndroidManifest.xml` 添加：

```xml
<application>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
</application>
```

#### 步骤4: 添加权限

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

#### 步骤5: 实现地图组件

创建 `android/app/src/main/java/com/runningapp/ui/map/MapView.kt`:

```kotlin
package com.runningapp.ui.map

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.compose.*

@Composable
fun RunningMapView(
    trackPoints: List<LatLng>,
    currentLocation: LatLng?,
    modifier: Modifier = Modifier
) {
    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(
            currentLocation ?: LatLng(39.9042, 116.4074),
            15f
        )
    }

    GoogleMap(
        modifier = modifier,
        cameraPositionState = cameraPositionState
    ) {
        // 绘制轨迹
        if (trackPoints.isNotEmpty()) {
            Polyline(
                points = trackPoints,
                color = androidx.compose.ui.graphics.Color.Blue,
                width = 10f
            )
        }

        // 当前位置标记
        currentLocation?.let {
            Marker(
                state = MarkerState(position = it),
                title = "当前位置"
            )
        }
    }
}
```

#### 步骤6: 在RunningScreen中使用

更新 `android/app/src/main/java/com/runningapp/ui/running/RunningScreen.kt`:

```kotlin
// 替换占位符Box为：
RunningMapView(
    trackPoints = viewModel.trackPoints.collectAsState().value,
    currentLocation = viewModel.currentLocation.collectAsState().value,
    modifier = Modifier
        .fillMaxWidth()
        .weight(1f)
)
```

### 3.2 Android - 高德地图

#### 步骤1: 注册账号

1. 访问 [高德开放平台](https://lbs.amap.com/)
2. 注册账号并创建应用
3. 获取 API Key

#### 步骤2: 添加依赖

```gradle
dependencies {
    implementation 'com.amap.api:map2d:latest.integration'
    implementation 'com.amap.api:location:latest.integration'
}
```

#### 步骤3: 配置

在 `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.amap.api.v2.apikey"
    android:value="YOUR_AMAP_API_KEY"/>
```

### 3.3 iOS - MapKit (系统自带)

MapKit是iOS系统自带的地图框架，无需额外配置。

#### 步骤1: 创建MapView组件

创建 `ios/RunningApp/Views/Map/RunningMapView.swift`:

```swift
import SwiftUI
import MapKit

struct RunningMapView: View {
    @State private var region: MKCoordinateRegion
    let trackPoints: [CLLocationCoordinate2D]
    let currentLocation: CLLocationCoordinate2D?

    init(trackPoints: [CLLocationCoordinate2D], currentLocation: CLLocationCoordinate2D?) {
        self.trackPoints = trackPoints
        self.currentLocation = currentLocation

        // 设置初始区域
        let center = currentLocation ?? CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)
        _region = State(initialValue: MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: annotations) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
            }
        }
        .overlay(
            // 绘制轨迹线
            MapPolyline(coordinates: trackPoints)
                .stroke(Color.blue, lineWidth: 3)
        )
    }

    private var annotations: [MapPoint] {
        trackPoints.enumerated().map { MapPoint(id: $0.offset, coordinate: $0.element) }
    }
}

struct MapPoint: Identifiable {
    let id: Int
    let coordinate: CLLocationCoordinate2D
}

struct MapPolyline: Shape {
    let coordinates: [CLLocationCoordinate2D]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        // 实现轨迹绘制
        return path
    }
}
```

#### 步骤2: 在RunningView中使用

更新 `ios/RunningApp/Views/Running/RunningView.swift`:

```swift
// 替换占位符为：
RunningMapView(
    trackPoints: viewModel.trackPoints,
    currentLocation: viewModel.currentLocation
)
.frame(height: 300)
```

#### 步骤3: 添加权限

在 `ios/RunningApp/Info.plist` 添加：

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>需要访问您的位置来记录跑步轨迹</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>需要持续访问您的位置来记录完整的跑步轨迹</string>
```

---

## 4. 数据可视化图表

### 4.1 Android - MPAndroidChart

#### 步骤1: 添加依赖

在 `android/app/build.gradle`:

```gradle
dependencies {
    implementation 'com.github.PhilJay:MPAndroidChart:v3.1.0'
}
```

在项目根目录的 `build.gradle`:

```gradle
allprojects {
    repositories {
        maven { url 'https://jitpack.io' }
    }
}
```

#### 步骤2: 创建图表组件

创建 `android/app/src/main/java/com/runningapp/ui/charts/LineChartView.kt`:

```kotlin
package com.runningapp.ui.charts

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import com.github.mikephil.charting.charts.LineChart
import com.github.mikephil.charting.components.XAxis
import com.github.mikephil.charting.data.Entry
import com.github.mikephil.charting.data.LineData
import com.github.mikephil.charting.data.LineDataSet

@Composable
fun RunningLineChart(
    data: List<Float>,
    modifier: Modifier = Modifier
) {
    AndroidView(
        modifier = modifier,
        factory = { context ->
            LineChart(context).apply {
                description.isEnabled = false
                setTouchEnabled(true)
                isDragEnabled = true
                setScaleEnabled(true)
                setPinchZoom(true)

                // X轴配置
                xAxis.position = XAxis.XAxisPosition.BOTTOM
                xAxis.setDrawGridLines(false)

                // Y轴配置
                axisLeft.setDrawGridLines(true)
                axisRight.isEnabled = false

                // 设置数据
                val entries = data.mapIndexed { index, value ->
                    Entry(index.toFloat(), value)
                }

                val dataSet = LineDataSet(entries, "跑步距离").apply {
                    color = android.graphics.Color.BLUE
                    lineWidth = 2f
                    setCircleColor(android.graphics.Color.BLUE)
                    circleRadius = 4f
                    setDrawValues(false)
                    mode = LineDataSet.Mode.CUBIC_BEZIER
                }

                this.data = LineData(dataSet)
                invalidate()
            }
        }
    )
}
```

#### 步骤3: 使用图表

在 `HistoryScreen` 或 `ProfileScreen` 中：

```kotlin
RunningLineChart(
    data = listOf(5.2f, 6.8f, 7.5f, 6.2f, 8.1f, 9.3f, 10.2f),
    modifier = Modifier
        .fillMaxWidth()
        .height(200.dp)
)
```

### 4.2 iOS - Swift Charts

#### 步骤1: 要求

- iOS 16.0+ (Swift Charts 是系统自带)
- Xcode 14+

#### 步骤2: 创建图表组件

创建 `ios/RunningApp/Views/Charts/RunningLineChart.swift`:

```swift
import SwiftUI
import Charts

struct RunningLineChart: View {
    let data: [ChartData]

    var body: some View {
        Chart(data) { item in
            LineMark(
                x: .value("日期", item.date),
                y: .value("距离", item.distance)
            )
            .foregroundStyle(.blue)
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("日期", item.date),
                y: .value("距离", item.distance)
            )
            .foregroundStyle(.blue)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel()
                AxisGridLine()
            }
        }
        .frame(height: 200)
        .padding()
    }
}

struct ChartData: Identifiable {
    let id = UUID()
    let date: Date
    let distance: Double
}
```

#### 步骤3: 使用图表

在 `ProfileView` 中：

```swift
RunningLineChart(data: [
    ChartData(date: Date().addingTimeInterval(-604800), distance: 5.2),
    ChartData(date: Date().addingTimeInterval(-518400), distance: 6.8),
    ChartData(date: Date().addingTimeInterval(-432000), distance: 7.5),
    // ...
])
```

#### iOS 15及以下版本（使用第三方库）

如需支持iOS 15，使用 Charts 库：

```ruby
# 在 Podfile 添加
pod 'Charts'
```

---

## 5. 第三方登录集成

### 5.1 Android - 微信登录

#### 步骤1: 注册应用

1. 访问 [微信开放平台](https://open.weixin.qq.com/)
2. 注册并创建移动应用
3. 获取 AppID 和 AppSecret

#### 步骤2: 添加依赖

在 `android/app/build.gradle`:

```gradle
dependencies {
    implementation 'com.tencent.mm.opensdk:wechat-sdk-android:6.8.0'
}
```

#### 步骤3: 配置

创建 `android/app/src/main/java/com/runningapp/wxapi/WXEntryActivity.kt`:

```kotlin
package com.runningapp.wxapi

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import com.tencent.mm.opensdk.modelbase.BaseReq
import com.tencent.mm.opensdk.modelbase.BaseResp
import com.tencent.mm.opensdk.modelmsg.SendAuth
import com.tencent.mm.opensdk.openapi.IWXAPI
import com.tencent.mm.opensdk.openapi.IWXAPIEventHandler
import com.tencent.mm.opensdk.openapi.WXAPIFactory

class WXEntryActivity : Activity(), IWXAPIEventHandler {
    private var api: IWXAPI? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        api = WXAPIFactory.createWXAPI(this, "YOUR_WECHAT_APP_ID", true)
        api?.handleIntent(intent, this)
    }

    override fun onReq(req: BaseReq?) {
        // 处理请求
    }

    override fun onResp(resp: BaseResp?) {
        when (resp) {
            is SendAuth.Resp -> {
                // 处理登录响应
                val code = resp.code
                // 发送到服务器获取access_token
            }
        }
        finish()
    }
}
```

#### 步骤4: 在AndroidManifest.xml注册

```xml
<activity
    android:name=".wxapi.WXEntryActivity"
    android:exported="true"
    android:label="@string/app_name"
    android:launchMode="singleTask"
    android:taskAffinity="com.runningapp"
    android:theme="@android:style/Theme.Translucent.NoTitleBar" />
```

### 5.2 iOS - Sign in with Apple

#### 步骤1: 启用功能

1. 在 Xcode 的 Signing & Capabilities 中
2. 点击 "+ Capability"
3. 添加 "Sign in with Apple"

#### 步骤2: 实现登录

创建 `ios/RunningApp/Services/AppleSignInService.swift`:

```swift
import AuthenticationServices

class AppleSignInService: NSObject {
    func signIn(completion: @escaping (Result<String, Error>) -> Void) {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

extension AppleSignInService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userID = credential.user
            let identityToken = credential.identityToken
            // 发送到服务器验证
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign In Error: \(error)")
    }
}

extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first!
    }
}
```

#### 步骤3: 在登录界面使用

```swift
SignInWithAppleButton { request in
    request.requestedScopes = [.fullName, .email]
} onCompletion: { result in
    switch result {
    case .success(let authorization):
        // 处理成功
    case .failure(let error):
        // 处理错误
    }
}
.frame(height: 50)
.signInWithAppleButtonStyle(.black)
```

---

## 6. iOS CoreData实现

### 6.1 创建数据模型

#### 步骤1: 创建 .xcdatamodeld 文件

在 Xcode 中：
1. File -> New -> File
2. 选择 "Data Model"
3. 命名为 "RunningApp"

#### 步骤2: 定义实体

在数据模型编辑器中创建以下实体：

**RunningRecord**:
- id: Integer 64
- userId: Integer 64
- distance: Double
- duration: Integer 64
- avgPace: Double
- avgSpeed: Double
- calories: Integer 64
- startTime: Date
- endTime: Date
- weather: String
- remark: String

**TrackPoint**:
- id: Integer 64
- recordId: Integer 64 (关联到RunningRecord)
- latitude: Double
- longitude: Double
- altitude: Double
- timestamp: Date

#### 步骤3: 创建CoreData管理器

创建 `ios/RunningApp/Services/CoreDataManager.swift`:

```swift
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "RunningApp")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                Logger.e("Failed to save context", error: error)
            }
        }
    }

    // MARK: - RunningRecord Operations

    func saveRunningRecord(_ record: RunningRecord) {
        let entity = NSEntityDescription.entity(forEntityName: "RunningRecord", in: context)!
        let recordObject = NSManagedObject(entity: entity, insertInto: context)

        recordObject.setValue(record.id, forKey: "id")
        recordObject.setValue(record.userId, forKey: "userId")
        recordObject.setValue(record.distance, forKey: "distance")
        recordObject.setValue(record.duration, forKey: "duration")
        // ... 设置其他属性

        saveContext()
    }

    func fetchRunningRecords(userId: Int) -> [RunningRecord] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "RunningRecord")
        fetchRequest.predicate = NSPredicate(format: "userId == %d", userId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]

        do {
            let results = try context.fetch(fetchRequest)
            return results.compactMap { object in
                // 转换为RunningRecord模型
                return RunningRecord(
                    id: object.value(forKey: "id") as? Int ?? 0,
                    userId: object.value(forKey: "userId") as? Int ?? 0,
                    distance: object.value(forKey: "distance") as? Double ?? 0.0,
                    // ... 其他属性
                )
            }
        } catch {
            Logger.e("Failed to fetch running records", error: error)
            return []
        }
    }

    func deleteRunningRecord(id: Int) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "RunningRecord")
        fetchRequest.predicate = NSPredicate(format: "id == %d", id)

        do {
            let results = try context.fetch(fetchRequest)
            for object in results {
                context.delete(object)
            }
            saveContext()
        } catch {
            Logger.e("Failed to delete running record", error: error)
        }
    }
}
```

#### 步骤4: 在ViewModel中使用

更新 `ios/RunningApp/ViewModels/HistoryViewModel.swift`:

```swift
class HistoryViewModel: ObservableObject {
    @Published var records: [RunningRecord] = []
    private let coreDataManager = CoreDataManager.shared

    func loadRecords() {
        let userId = KeychainManager.shared.getUserId() ?? 0
        records = coreDataManager.fetchRunningRecords(userId: userId)
    }

    func deleteRecord(id: Int) {
        coreDataManager.deleteRunningRecord(id: id)
        loadRecords()
    }
}
```

---

## 7. 配置优先级建议

### 立即配置（上线前必需）
1. ✅ API地址配置（Android + iOS）
2. ⚠️ 短信服务（用户注册需要）

### 短期配置（1-2周内）
3. 🗺️ 地图SDK（核心功能）
4. 📊 数据图表（用户体验）

### 中期配置（1个月内）
5. 🔐 实名认证
6. 💾 iOS CoreData
7. 👤 第三方登录

---

## 8. 常见问题

### Q: 短信服务在开发环境下如何测试？

A: 开发模式下（`app_debug=true`），验证码会在响应中直接返回，不会实际发送短信。

### Q: 地图SDK哪个更好？

A:
- **国内用户**: 推荐使用高德地图，速度快且免费额度高
- **国际用户**: 推荐使用Google Maps
- **iOS**: MapKit 系统自带，无需额外配置

### Q: 是否必须实现所有第三方登录？

A: 不是。建议：
- iOS 必须实现 Sign in with Apple（App Store 要求）
- Android 可选择微信、QQ等
- 根据目标用户群决定

### Q: iOS CoreData是否必需？

A: 不是必需的。CoreData主要用于：
- 离线数据缓存
- 提高加载速度
- 减少网络请求

如果应用始终在线，可以不实现CoreData。

---

## 9. 技术支持

如有问题，请参考：

- [阿里云短信文档](https://help.aliyun.com/product/44282.html)
- [Google Maps Android文档](https://developers.google.com/maps/documentation/android-sdk)
- [Apple Developer文档](https://developer.apple.com/documentation/)

---

**版本**: v1.5.9
**更新日期**: 2025-11-17
**维护**: Running App Team

🏃‍♂️💨 祝你集成顺利！
