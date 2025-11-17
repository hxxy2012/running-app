import Foundation
import UIKit

// MARK: - 设备信息助手
class DeviceHelper {

    static let shared = DeviceHelper()

    private init() {}

    // MARK: - 设备基本信息

    /// 获取设备唯一标识符
    var deviceId: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }

    /// 获取设备型号（如iPhone14,2）
    var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    /// 获取设备名称（用户设定的名称）
    var deviceName: String {
        return UIDevice.current.name
    }

    /// 获取设备类型名称（如iPhone 13 Pro）
    var deviceTypeName: String {
        return mapDeviceModel(deviceModel)
    }

    /// 获取系统名称
    var systemName: String {
        return UIDevice.current.systemName
    }

    /// 获取系统版本
    var systemVersion: String {
        return UIDevice.current.systemVersion
    }

    // MARK: - 屏幕信息

    /// 获取屏幕宽度（点）
    var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }

    /// 获取屏幕高度（点）
    var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }

    /// 获取屏幕密度
    var screenScale: CGFloat {
        return UIScreen.main.scale
    }

    /// 获取屏幕分辨率
    var screenResolution: String {
        let width = Int(screenWidth * screenScale)
        let height = Int(screenHeight * screenScale)
        return "\(width)x\(height)"
    }

    /// 获取屏幕信息描述
    var screenInfo: String {
        return "\(screenResolution) @\(screenScale)x"
    }

    /// 是否为刘海屏
    var hasNotch: Bool {
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.windows.first
            return (window?.safeAreaInsets.bottom ?? 0) > 0
        }
        return false
    }

    // MARK: - 语言和地区

    /// 获取系统语言
    var language: String {
        return Locale.current.languageCode ?? "en"
    }

    /// 获取国家/地区
    var country: String {
        return Locale.current.regionCode ?? "US"
    }

    /// 获取完整语言环境
    var locale: String {
        return Locale.current.identifier
    }

    /// 获取首选语言
    var preferredLanguage: String {
        return Locale.preferredLanguages.first ?? "en"
    }

    // MARK: - 应用信息

    /// 获取应用Bundle ID
    var bundleId: String {
        return Bundle.main.bundleIdentifier ?? "unknown"
    }

    /// 获取应用名称
    var appName: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Running App"
    }

    /// 获取应用显示名称
    var appDisplayName: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? appName
    }

    /// 获取应用版本号
    var appVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    /// 获取构建版本号
    var buildNumber: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    // MARK: - 存储信息

    /// 获取磁盘总空间（字节）
    var totalDiskSpace: Int64 {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            return attributes[.systemSize] as? Int64 ?? 0
        } catch {
            return 0
        }
    }

    /// 获取可用磁盘空间（字节）
    var freeDiskSpace: Int64 {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            return attributes[.systemFreeSize] as? Int64 ?? 0
        } catch {
            return 0
        }
    }

    /// 获取已用磁盘空间（字节）
    var usedDiskSpace: Int64 {
        return totalDiskSpace - freeDiskSpace
    }

    // MARK: - 电池信息

    /// 获取电池电量（0.0-1.0）
    var batteryLevel: Float {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryLevel
    }

    /// 获取电池状态
    var batteryState: UIDevice.BatteryState {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryState
    }

    /// 电池状态描述
    var batteryStateDescription: String {
        switch batteryState {
        case .unknown:
            return "未知"
        case .unplugged:
            return "未充电"
        case .charging:
            return "充电中"
        case .full:
            return "已充满"
        @unknown default:
            return "未知"
        }
    }

    // MARK: - 网络信息

    /// 获取WiFi SSID（需要定位权限和配置）
    var wifiSSID: String? {
        // 需要添加 Capability: Access WiFi Information
        // 并在Info.plist中添加位置权限说明
        return nil // 简化实现
    }

    // MARK: - 综合信息

    /// 获取设备完整信息
    func getDeviceInfo() -> [String: String] {
        return [
            "deviceId": deviceId,
            "deviceModel": deviceModel,
            "deviceName": deviceName,
            "deviceTypeName": deviceTypeName,
            "systemName": systemName,
            "systemVersion": systemVersion,
            "screenInfo": screenInfo,
            "language": language,
            "country": country,
            "locale": locale,
            "bundleId": bundleId,
            "appName": appDisplayName,
            "appVersion": appVersion,
            "buildNumber": buildNumber,
            "totalDiskSpace": FormatUtils.shared.formatFileSize(totalDiskSpace),
            "freeDiskSpace": FormatUtils.shared.formatFileSize(freeDiskSpace),
            "batteryLevel": String(format: "%.0f%%", batteryLevel * 100),
            "batteryState": batteryStateDescription
        ]
    }

    /// 获取设备信息JSON字符串
    func getDeviceInfoJson() -> String {
        let info = getDeviceInfo()
        let jsonData = try? JSONSerialization.data(withJSONObject: info, options: .prettyPrinted)
        return String(data: jsonData ?? Data(), encoding: .utf8) ?? "{}"
    }

    /// 获取User-Agent字符串
    func getUserAgent() -> String {
        return "RunningApp/\(appVersion) (\(systemName) \(systemVersion); \(deviceTypeName))"
    }

    // MARK: - 设备判断

    /// 是否为iPhone
    var isiPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }

    /// 是否为iPad
    var isiPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    /// 是否为模拟器
    var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// 是否为越狱设备
    var isJailbroken: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        let paths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        return false
        #endif
    }

    // MARK: - 设备型号映射

    private func mapDeviceModel(_ model: String) -> String {
        let modelMap: [String: String] = [
            // iPhone
            "iPhone14,5": "iPhone 13",
            "iPhone14,4": "iPhone 13 mini",
            "iPhone14,2": "iPhone 13 Pro",
            "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone14,7": "iPhone 14",
            "iPhone14,8": "iPhone 14 Plus",
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",

            // iPad
            "iPad13,18": "iPad Pro 12.9-inch (6th generation)",
            "iPad13,16": "iPad Pro 11-inch (4th generation)",
            "iPad14,3": "iPad Pro 11-inch (5th generation)",
            "iPad14,4": "iPad Pro 12.9-inch (7th generation)",

            // Simulator
            "i386": "Simulator",
            "x86_64": "Simulator",
            "arm64": "Simulator"
        ]

        return modelMap[model] ?? model
    }
}

// MARK: - 便捷扩展

extension DeviceHelper {

    /// 打印所有设备信息
    func printDeviceInfo() {
        let info = getDeviceInfo()
        print("=== Device Information ===")
        info.forEach { key, value in
            print("\(key): \(value)")
        }
        print("========================")
    }
}
