import Foundation
import UIKit

// MARK: - 数据格式化工具类
class FormatUtils {

    static let shared = FormatUtils()

    private init() {}

    // MARK: - 常量定义

    /// 日期格式
    struct DateFormats {
        static let full = "yyyy-MM-dd HH:mm:ss"
        static let date = "yyyy-MM-dd"
        static let time = "HH:mm:ss"
        static let dateTime = "yyyy-MM-dd HH:mm"
        static let monthDay = "MM-dd"
        static let hourMinute = "HH:mm"
        static let chineseFull = "yyyy年MM月dd日 HH:mm"
        static let chineseDate = "yyyy年MM月dd日"
        static let chineseMonthDay = "MM月dd日"
    }

    /// 距离单位阈值
    private let distanceThresholdKm: Double = 1000.0

    /// 配速单位
    private let paceUnitMinKm = "min/km"
    private let paceUnitMinMi = "min/mi"

    // MARK: - 日期时间格式化

    /// 格式化日期字符串
    /// - Parameters:
    ///   - dateString: 日期字符串
    ///   - inputFormat: 输入格式
    ///   - outputFormat: 输出格式
    /// - Returns: 格式化后的字符串
    func formatDate(
        _ dateString: String,
        inputFormat: String = DateFormats.full,
        outputFormat: String = DateFormats.dateTime
    ) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = inputFormat
        inputFormatter.locale = Locale(identifier: "zh_CN")

        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = outputFormat
        outputFormatter.locale = Locale(identifier: "zh_CN")

        return outputFormatter.string(from: date)
    }

    /// 格式化时间戳
    /// - Parameters:
    ///   - timestamp: 时间戳（毫秒）
    ///   - format: 格式
    /// - Returns: 格式化后的字符串
    func formatTimestamp(_ timestamp: Int64, format: String = DateFormats.dateTime) -> String {
        let date = Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    /// 相对时间格式化（如：刚刚、5分钟前、昨天等）
    /// - Parameter dateString: 日期字符串
    /// - Returns: 相对时间描述
    func formatRelativeTime(_ dateString: String, format: String = DateFormats.full) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "zh_CN")

        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        return formatRelativeTime(date)
    }

    /// 相对时间格式化（Date版本）
    /// - Parameter date: 日期
    /// - Returns: 相对时间描述
    func formatRelativeTime(_ date: Date) -> String {
        let now = Date()
        let diff = now.timeIntervalSince(date)

        switch diff {
        case ..<0:
            return "未来"
        case 0..<60:
            return "刚刚"
        case 60..<3600:
            return "\(Int(diff / 60))分钟前"
        case 3600..<86400:
            return "\(Int(diff / 3600))小时前"
        case 86400..<172800:
            return "昨天"
        case 172800..<259200:
            return "前天"
        case 259200..<604800:
            return "\(Int(diff / 86400))天前"
        case 604800..<2592000:
            return "\(Int(diff / 604800))周前"
        case 2592000..<31536000:
            return "\(Int(diff / 2592000))个月前"
        default:
            return "\(Int(diff / 31536000))年前"
        }
    }

    /// 相对时间格式化（时间戳版本）
    /// - Parameter timestamp: 时间戳（毫秒）
    /// - Returns: 相对时间描述
    func formatRelativeTime(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
        return formatRelativeTime(date)
    }

    // MARK: - 距离格式化

    /// 格式化距离（米转换为合适单位）
    /// - Parameters:
    ///   - meters: 距离（米）
    ///   - precision: 小数位数
    ///   - includeUnit: 是否包含单位
    /// - Returns: 格式化后的距离字符串
    func formatDistance(_ meters: Double, precision: Int = 2, includeUnit: Bool = true) -> String {
        let (value, unit): (Double, String)

        if meters >= distanceThresholdKm {
            let km = meters / 1000.0
            (value, unit) = (km, "km")
        } else {
            (value, unit) = (meters, "m")
        }

        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = precision

        guard let formattedValue = formatter.string(from: NSNumber(value: value)) else {
            return includeUnit ? "\(value) \(unit)" : "\(value)"
        }

        return includeUnit ? "\(formattedValue) \(unit)" : formattedValue
    }

    /// 格式化距离（只返回数值，总是以公里为单位）
    /// - Parameters:
    ///   - meters: 距离（米）
    ///   - precision: 小数位数
    /// - Returns: 公里数
    func formatDistanceKm(_ meters: Double, precision: Int = 2) -> String {
        let km = meters / 1000.0
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = precision
        return formatter.string(from: NSNumber(value: km)) ?? String(format: "%.\(precision)f", km)
    }

    // MARK: - 配速格式化

    /// 格式化配速（秒/米转换为分/公里）
    /// - Parameters:
    ///   - secondsPerMeter: 配速（秒/米）
    ///   - includeUnit: 是否包含单位
    /// - Returns: 格式化后的配速字符串（如：5'30" 或 5'30"/km）
    func formatPace(_ secondsPerMeter: Double, includeUnit: Bool = true) -> String {
        if secondsPerMeter <= 0 {
            return "--'--\""
        }

        let secondsPerKm = secondsPerMeter * 1000
        let minutes = Int(secondsPerKm / 60)
        let seconds = Int(secondsPerKm.truncatingRemainder(dividingBy: 60))

        let paceStr = String(format: "%d'%02d\"", minutes, seconds)
        return includeUnit ? "\(paceStr)/\(paceUnitMinKm)" : paceStr
    }

    /// 格式化配速（分钟/公里）
    /// - Parameters:
    ///   - minutesPerKm: 配速（分/公里）
    ///   - includeUnit: 是否包含单位
    /// - Returns: 格式化后的配速字符串
    func formatPaceFromMinutes(_ minutesPerKm: Double, includeUnit: Bool = true) -> String {
        if minutesPerKm <= 0 {
            return "--'--\""
        }

        let minutes = Int(minutesPerKm)
        let seconds = Int((minutesPerKm - Double(minutes)) * 60)

        let paceStr = String(format: "%d'%02d\"", minutes, seconds)
        return includeUnit ? "\(paceStr)/\(paceUnitMinKm)" : paceStr
    }

    // MARK: - 时长格式化

    /// 时长格式类型
    enum DurationFormat {
        case full    // 1小时23分45秒
        case short   // 1h 23m 45s
        case compact // 1:23:45 或 23:45
    }

    /// 格式化时长（秒转换为可读格式）
    /// - Parameters:
    ///   - seconds: 时长（秒）
    ///   - format: 格式类型
    /// - Returns: 格式化后的时长字符串
    func formatDuration(_ seconds: Int, format: DurationFormat = .full) -> String {
        if seconds <= 0 {
            switch format {
            case .full: return "0秒"
            case .short: return "0s"
            case .compact: return "00:00"
            }
        }

        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        switch format {
        case .full:
            var result = ""
            if hours > 0 { result += "\(hours)小时" }
            if minutes > 0 { result += "\(minutes)分钟" }
            if secs > 0 || (hours == 0 && minutes == 0) { result += "\(secs)秒" }
            return result

        case .short:
            var parts: [String] = []
            if hours > 0 { parts.append("\(hours)h") }
            if minutes > 0 { parts.append("\(minutes)m") }
            if secs > 0 || (hours == 0 && minutes == 0) { parts.append("\(secs)s") }
            return parts.joined(separator: " ")

        case .compact:
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, secs)
            } else {
                return String(format: "%02d:%02d", minutes, secs)
            }
        }
    }

    /// 格式化时长（毫秒版本）
    /// - Parameters:
    ///   - milliseconds: 时长（毫秒）
    ///   - format: 格式类型
    /// - Returns: 格式化后的时长字符串
    func formatDurationMillis(_ milliseconds: Int64, format: DurationFormat = .full) -> String {
        return formatDuration(Int(milliseconds / 1000), format: format)
    }

    // MARK: - 数字格式化

    /// 格式化数字（添加千位分隔符）
    /// - Parameters:
    ///   - number: 数字
    ///   - precision: 小数位数
    /// - Returns: 格式化后的数字字符串
    func formatNumber(_ number: Double, precision: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = precision
        formatter.maximumFractionDigits = precision
        return formatter.string(from: NSNumber(value: number)) ?? String(format: "%.\(precision)f", number)
    }

    /// 格式化卡路里
    /// - Parameters:
    ///   - calories: 卡路里
    ///   - includeUnit: 是否包含单位
    /// - Returns: 格式化后的卡路里字符串
    func formatCalories(_ calories: Double, includeUnit: Bool = true) -> String {
        let formatted = formatNumber(calories, precision: 0)
        return includeUnit ? "\(formatted) kcal" : formatted
    }

    /// 格式化步数
    /// - Parameters:
    ///   - steps: 步数
    ///   - includeUnit: 是否包含单位
    /// - Returns: 格式化后的步数字符串
    func formatSteps(_ steps: Int, includeUnit: Bool = true) -> String {
        let formatted = formatNumber(Double(steps))
        return includeUnit ? "\(formatted) 步" : formatted
    }

    /// 格式化心率
    /// - Parameters:
    ///   - heartRate: 心率
    ///   - includeUnit: 是否包含单位
    /// - Returns: 格式化后的心率字符串
    func formatHeartRate(_ heartRate: Int, includeUnit: Bool = true) -> String {
        return includeUnit ? "\(heartRate) bpm" : "\(heartRate)"
    }

    /// 格式化海拔
    /// - Parameters:
    ///   - altitude: 海拔（米）
    ///   - includeUnit: 是否包含单位
    /// - Returns: 格式化后的海拔字符串
    func formatAltitude(_ altitude: Double, includeUnit: Bool = true) -> String {
        let formatted = formatNumber(altitude, precision: 1)
        return includeUnit ? "\(formatted) m" : formatted
    }

    /// 格式化速度（米/秒转换为公里/小时）
    /// - Parameters:
    ///   - metersPerSecond: 速度（米/秒）
    ///   - precision: 小数位数
    ///   - includeUnit: 是否包含单位
    /// - Returns: 格式化后的速度字符串
    func formatSpeed(_ metersPerSecond: Double, precision: Int = 2, includeUnit: Bool = true) -> String {
        let kmPerHour = metersPerSecond * 3.6
        let formatted = formatNumber(kmPerHour, precision: precision)
        return includeUnit ? "\(formatted) km/h" : formatted
    }

    // MARK: - 百分比格式化

    /// 格式化百分比
    /// - Parameters:
    ///   - value: 数值（0-1或0-100）
    ///   - isDecimal: 是否为小数形式（true: 0-1, false: 0-100）
    ///   - precision: 小数位数
    /// - Returns: 格式化后的百分比字符串
    func formatPercentage(_ value: Double, isDecimal: Bool = true, precision: Int = 1) -> String {
        let percentage = isDecimal ? value * 100 : value
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = precision

        guard let formatted = formatter.string(from: NSNumber(value: percentage)) else {
            return String(format: "%.\(precision)f%%", percentage)
        }

        return "\(formatted)%"
    }

    // MARK: - 文件大小格式化

    /// 格式化文件大小
    /// - Parameters:
    ///   - bytes: 字节数
    ///   - precision: 小数位数
    /// - Returns: 格式化后的文件大小字符串
    func formatFileSize(_ bytes: Int64, precision: Int = 2) -> String {
        if bytes < 0 { return "0 B" }

        let units = ["B", "KB", "MB", "GB", "TB"]
        var size = Double(bytes)
        var unitIndex = 0

        while size >= 1024 && unitIndex < units.count - 1 {
            size /= 1024
            unitIndex += 1
        }

        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = unitIndex == 0 ? 0 : precision

        guard let formatted = formatter.string(from: NSNumber(value: size)) else {
            return String(format: "%.\(precision)f \(units[unitIndex])", size)
        }

        return "\(formatted) \(units[unitIndex])"
    }
}

// MARK: - 便利方法

extension FormatUtils {

    /// 格式化距离（静态方法）
    static func distance(_ meters: Double, precision: Int = 2, includeUnit: Bool = true) -> String {
        return shared.formatDistance(meters, precision: precision, includeUnit: includeUnit)
    }

    /// 格式化配速（静态方法）
    static func pace(_ secondsPerMeter: Double, includeUnit: Bool = true) -> String {
        return shared.formatPace(secondsPerMeter, includeUnit: includeUnit)
    }

    /// 格式化时长（静态方法）
    static func duration(_ seconds: Int, format: DurationFormat = .compact) -> String {
        return shared.formatDuration(seconds, format: format)
    }

    /// 格式化相对时间（静态方法）
    static func relativeTime(_ date: Date) -> String {
        return shared.formatRelativeTime(date)
    }
}

// MARK: - 扩展

extension Double {

    /// 格式化为距离字符串
    /// - Parameters:
    ///   - precision: 小数位数
    ///   - includeUnit: 是否包含单位
    /// - Returns: 格式化后的距离字符串
    func toDistanceString(precision: Int = 2, includeUnit: Bool = true) -> String {
        return FormatUtils.shared.formatDistance(self, precision: precision, includeUnit: includeUnit)
    }

    /// 格式化为配速字符串
    /// - Parameter includeUnit: 是否包含单位
    /// - Returns: 格式化后的配速字符串
    func toPaceString(includeUnit: Bool = true) -> String {
        return FormatUtils.shared.formatPace(self, includeUnit: includeUnit)
    }

    /// 格式化为速度字符串
    /// - Parameters:
    ///   - precision: 小数位数
    ///   - includeUnit: 是否包含单位
    /// - Returns: 格式化后的速度字符串
    func toSpeedString(precision: Int = 2, includeUnit: Bool = true) -> String {
        return FormatUtils.shared.formatSpeed(self, precision: precision, includeUnit: includeUnit)
    }
}

extension Int {

    /// 格式化为时长字符串
    /// - Parameter format: 格式类型
    /// - Returns: 格式化后的时长字符串
    func toDurationString(format: FormatUtils.DurationFormat = .compact) -> String {
        return FormatUtils.shared.formatDuration(self, format: format)
    }

    /// 格式化为步数字符串
    /// - Parameter includeUnit: 是否包含单位
    /// - Returns: 格式化后的步数字符串
    func toStepsString(includeUnit: Bool = true) -> String {
        return FormatUtils.shared.formatSteps(self, includeUnit: includeUnit)
    }

    /// 格式化为心率字符串
    /// - Parameter includeUnit: 是否包含单位
    /// - Returns: 格式化后的心率字符串
    func toHeartRateString(includeUnit: Bool = true) -> String {
        return FormatUtils.shared.formatHeartRate(self, includeUnit: includeUnit)
    }
}

extension Int64 {

    /// 格式化为文件大小字符串
    /// - Parameter precision: 小数位数
    /// - Returns: 格式化后的文件大小字符串
    func toFileSizeString(precision: Int = 2) -> String {
        return FormatUtils.shared.formatFileSize(self, precision: precision)
    }

    /// 格式化为相对时间字符串（时间戳毫秒）
    /// - Returns: 相对时间描述
    func toRelativeTimeString() -> String {
        return FormatUtils.shared.formatRelativeTime(timestamp: self)
    }
}

extension Date {

    /// 格式化为相对时间字符串
    /// - Returns: 相对时间描述
    func toRelativeTimeString() -> String {
        return FormatUtils.shared.formatRelativeTime(self)
    }

    /// 格式化为指定格式的字符串
    /// - Parameter format: 日期格式
    /// - Returns: 格式化后的字符串
    func toString(format: String = FormatUtils.DateFormats.dateTime) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }
}
