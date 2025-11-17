import Foundation
import UIKit
import CoreLocation
import Photos
import UserNotifications
import AVFoundation

// MARK: - 权限类型
enum PermissionType {
    case location(LocationPermissionType)
    case photos
    case camera
    case notifications
    case motion

    var name: String {
        switch self {
        case .location: return "定位"
        case .photos: return "相册"
        case .camera: return "相机"
        case .notifications: return "通知"
        case .motion: return "运动与健身"
        }
    }
}

enum LocationPermissionType {
    case whenInUse      // 使用期间
    case always         // 始终允许（包括后台）
}

// MARK: - 权限状态
enum PermissionStatus {
    case notDetermined  // 未询问
    case authorized     // 已授权
    case denied         // 已拒绝
    case restricted     // 受限制（家长控制等）
    case limited        // 有限权限（仅iOS 14+相册）

    var isAuthorized: Bool {
        return self == .authorized
    }
}

// MARK: - 权限管理助手
class PermissionHelper {

    static let shared = PermissionHelper()

    private init() {}

    // MARK: - 定位权限

    /// 检查定位权限状态
    func checkLocationPermission(type: LocationPermissionType = .whenInUse) -> PermissionStatus {
        let manager = CLLocationManager()
        let status = manager.authorizationStatus

        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorizedAlways:
            return .authorized
        case .authorizedWhenInUse:
            // 如果需要always权限但只有whenInUse，返回未完全授权
            if type == .always {
                return .denied
            }
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }

    /// 请求定位权限
    func requestLocationPermission(
        type: LocationPermissionType,
        completion: @escaping (PermissionStatus) -> Void
    ) {
        let manager = CLLocationManager()

        // 创建代理对象来接收回调
        let delegate = LocationPermissionDelegate { status in
            completion(status)
        }

        // 保持代理对象的引用
        objc_setAssociatedObject(
            manager,
            "delegate",
            delegate,
            .OBJC_ASSOCIATION_RETAIN
        )

        manager.delegate = delegate

        switch type {
        case .whenInUse:
            manager.requestWhenInUseAuthorization()
        case .always:
            // 必须先请求whenInUse，再请求always
            let currentStatus = checkLocationPermission(type: .whenInUse)
            if currentStatus.isAuthorized {
                manager.requestAlwaysAuthorization()
            } else {
                manager.requestWhenInUseAuthorization()
            }
        }
    }

    /// 检查是否有精确定位权限（iOS 14+）
    @available(iOS 14.0, *)
    func hasAccurateLocationPermission() -> Bool {
        let manager = CLLocationManager()
        return manager.accuracyAuthorization == .fullAccuracy
    }

    // MARK: - 相册权限

    /// 检查相册权限状态
    func checkPhotosPermission() -> PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus()

        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .limited:
            return .limited
        @unknown default:
            return .notDetermined
        }
    }

    /// 请求相册权限
    func requestPhotosPermission(completion: @escaping (PermissionStatus) -> Void) {
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    completion(self.convertPHAuthorizationStatus(status))
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    completion(self.convertPHAuthorizationStatus(status))
                }
            }
        }
    }

    private func convertPHAuthorizationStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized: return .authorized
        case .limited: return .limited
        @unknown default: return .notDetermined
        }
    }

    // MARK: - 相机权限

    /// 检查相机权限状态
    func checkCameraPermission() -> PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }

    /// 请求相机权限
    func requestCameraPermission(completion: @escaping (PermissionStatus) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted ? .authorized : .denied)
            }
        }
    }

    // MARK: - 通知权限

    /// 检查通知权限状态
    func checkNotificationPermission(completion: @escaping (PermissionStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let status: PermissionStatus
                switch settings.authorizationStatus {
                case .notDetermined:
                    status = .notDetermined
                case .denied:
                    status = .denied
                case .authorized, .provisional, .ephemeral:
                    status = .authorized
                @unknown default:
                    status = .notDetermined
                }
                completion(status)
            }
        }
    }

    /// 请求通知权限
    func requestNotificationPermission(
        options: UNAuthorizationOptions = [.alert, .sound, .badge],
        completion: @escaping (PermissionStatus) -> Void
    ) {
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.e("Request notification permission failed", error: error)
                    completion(.denied)
                } else {
                    completion(granted ? .authorized : .denied)
                }
            }
        }
    }

    // MARK: - 运动与健身权限

    /// 检查运动权限状态（iOS 11+需要隐私说明，但不需要代码请求）
    func checkMotionPermission() -> PermissionStatus {
        // iOS的运动权限不需要显式请求，只需要在Info.plist中添加说明
        // 这里返回authorized表示只要在Info.plist中添加了说明即可使用
        return .authorized
    }

    // MARK: - 通用方法

    /// 检查任意权限
    func checkPermission(_ type: PermissionType, completion: ((PermissionStatus) -> Void)? = nil) {
        switch type {
        case .location(let locationType):
            let status = checkLocationPermission(type: locationType)
            completion?(status)

        case .photos:
            let status = checkPhotosPermission()
            completion?(status)

        case .camera:
            let status = checkCameraPermission()
            completion?(status)

        case .notifications:
            checkNotificationPermission { status in
                completion?(status)
            }

        case .motion:
            let status = checkMotionPermission()
            completion?(status)
        }
    }

    /// 请求任意权限
    func requestPermission(_ type: PermissionType, completion: @escaping (PermissionStatus) -> Void) {
        switch type {
        case .location(let locationType):
            requestLocationPermission(type: locationType, completion: completion)

        case .photos:
            requestPhotosPermission(completion: completion)

        case .camera:
            requestCameraPermission(completion: completion)

        case .notifications:
            requestNotificationPermission(completion: completion)

        case .motion:
            // 运动权限不需要请求
            completion(.authorized)
        }
    }

    // MARK: - 权限说明文本

    /// 获取权限的用户友好说明
    func getPermissionRationale(_ type: PermissionType) -> String {
        switch type {
        case .location(.whenInUse):
            return "我们需要定位权限来记录您的跑步轨迹"
        case .location(.always):
            return "我们需要后台定位权限来在应用后台运行时继续记录您的跑步轨迹"
        case .photos:
            return "我们需要相册权限来保存和读取跑步照片"
        case .camera:
            return "我们需要相机权限来拍摄照片分享您的跑步瞬间"
        case .notifications:
            return "我们需要通知权限来发送训练提醒和成就通知"
        case .motion:
            return "我们需要运动权限来更准确地识别您的运动状态"
        }
    }

    /// 获取权限被拒绝后的说明
    func getPermissionDeniedMessage(_ type: PermissionType) -> String {
        switch type {
        case .location(.whenInUse):
            return "没有定位权限，无法记录跑步轨迹"
        case .location(.always):
            return "没有后台定位权限，应用切换到后台后将停止记录轨迹"
        case .photos:
            return "没有相册权限，无法选择或保存照片"
        case .camera:
            return "没有相机权限，无法拍摄照片"
        case .notifications:
            return "没有通知权限，您将收不到训练提醒和成就通知"
        case .motion:
            return "没有运动权限，运动数据可能不够准确"
        }
    }

    // MARK: - 打开设置页面

    /// 打开应用设置页面
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    /// 显示权限设置提示
    func showPermissionSettingsAlert(
        for type: PermissionType,
        from viewController: UIViewController
    ) {
        let alertController = UIAlertController(
            title: "\(type.name)权限未开启",
            message: getPermissionDeniedMessage(type) + "\n\n请前往设置开启权限",
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        alertController.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
            self.openAppSettings()
        })

        viewController.present(alertController, animated: true)
    }
}

// MARK: - 定位权限代理
private class LocationPermissionDelegate: NSObject, CLLocationManagerDelegate {

    private let completion: (PermissionStatus) -> Void

    init(completion: @escaping (PermissionStatus) -> Void) {
        self.completion = completion
        super.init()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status: PermissionStatus

        switch manager.authorizationStatus {
        case .notDetermined:
            status = .notDetermined
        case .restricted:
            status = .restricted
        case .denied:
            status = .denied
        case .authorizedAlways, .authorizedWhenInUse:
            status = .authorized
        @unknown default:
            status = .notDetermined
        }

        // 只在非notDetermined状态时回调
        if status != .notDetermined {
            DispatchQueue.main.async {
                self.completion(status)
            }
        }
    }
}

// MARK: - SwiftUI辅助
#if canImport(SwiftUI)
import SwiftUI

@available(iOS 13.0, *)
extension View {
    /// 请求权限修饰符
    func requestPermission(
        _ type: PermissionType,
        isPresented: Binding<Bool>,
        onResult: @escaping (PermissionStatus) -> Void
    ) -> some View {
        self.onChange(of: isPresented.wrappedValue) { shouldRequest in
            if shouldRequest {
                PermissionHelper.shared.requestPermission(type) { status in
                    onResult(status)
                    isPresented.wrappedValue = false
                }
            }
        }
    }
}
#endif

// MARK: - 便捷扩展
extension PermissionHelper {

    /// 检查跑步应用核心权限
    func checkRunningCorePermissions(completion: @escaping ([PermissionType: PermissionStatus]) -> Void) {
        var results: [PermissionType: PermissionStatus] = [:]
        let group = DispatchGroup()

        // 定位权限
        group.enter()
        checkPermission(.location(.whenInUse)) { status in
            results[.location(.whenInUse)] = status
            group.leave()
        }

        // 通知权限
        group.enter()
        checkPermission(.notifications) { status in
            results[.notifications] = status
            group.leave()
        }

        // 运动权限
        results[.motion] = checkMotionPermission()

        group.notify(queue: .main) {
            completion(results)
        }
    }

    /// 请求跑步应用核心权限
    func requestRunningCorePermissions(completion: @escaping (Bool) -> Void) {
        // 先请求定位权限
        requestPermission(.location(.whenInUse)) { locationStatus in
            if !locationStatus.isAuthorized {
                completion(false)
                return
            }

            // 再请求通知权限
            self.requestPermission(.notifications) { notificationStatus in
                // 通知权限非必须，所以即使拒绝也返回成功
                completion(true)
            }
        }
    }
}
