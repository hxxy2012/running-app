import Foundation

// MARK: - 数据格式化工具
class DataFormatter {

    // MARK: - 单例
    static let shared = DataFormatter()

    private init() {}

    // MARK: - 日期格式化
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    /// 格式化时间戳为日期时间字符串
    func formatDateTime(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter.string(from: date)
    }

    /// 格式化时间戳为日期字符串
    func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }

    /// 格式化时间戳为相对时间（如：刚刚、5分钟前、昨天等）
    func formatRelativeTime(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)

        if timeInterval < 60 {
            return "刚刚"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)分钟前"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)小时前"
        } else if timeInterval < 172800 {
            return "昨天"
        } else if timeInterval < 604800 {
            let days = Int(timeInterval / 86400)
            return "\(days)天前"
        } else {
            return formatDate(timestamp)
        }
    }

    // MARK: - 距离格式化

    /// 格式化距离（米转千米，保留2位小数）
    func formatDistance(_ meters: Float) -> String {
        let km = meters / 1000.0
        return String(format: "%.2f km", km)
    }

    /// 格式化距离（简短版本，超过1000米显示千米）
    func formatDistanceShort(_ meters: Float) -> String {
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        } else {
            let km = meters / 1000.0
            return String(format: "%.1f km", km)
        }
    }

    // MARK: - 时长格式化

    /// 格式化秒数为时:分:秒格式
    func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    /// 格式化时长（中文版本）
    func formatDurationChinese(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return String(format: "%d小时%d分钟", hours, minutes)
        } else {
            return String(format: "%d分钟", minutes)
        }
    }

    // MARK: - 配速格式化

    /// 格式化配速（分/公里）
    func formatPace(_ pace: Int) -> String {
        let minutes = pace / 60
        let seconds = pace % 60
        return String(format: "%d'%02d\"", minutes, seconds)
    }

    /// 格式化速度（公里/小时）
    func formatSpeed(_ metersPerSecond: Float) -> String {
        let kmPerHour = metersPerSecond * 3.6
        return String(format: "%.1f km/h", kmPerHour)
    }

    // MARK: - 卡路里格式化

    /// 格式化卡路里
    func formatCalories(_ calories: Int) -> String {
        return "\(calories) kcal"
    }

    // MARK: - 数字格式化

    /// 格式化大数字（如：10000 -> 1w）
    func formatLargeNumber(_ number: Int) -> String {
        if number >= 10000 {
            let wan = Float(number) / 10000.0
            return String(format: "%.1fw", wan)
        } else if number >= 1000 {
            let thousand = Float(number) / 1000.0
            return String(format: "%.1fk", thousand)
        } else {
            return "\(number)"
        }
    }

    // MARK: - 百分比格式化

    /// 格式化百分比
    func formatPercentage(_ value: Float, total: Float) -> String {
        guard total > 0 else { return "0%" }
        let percentage = (value / total) * 100
        return String(format: "%.1f%%", percentage)
    }

    // MARK: - 文件大小格式化

    /// 格式化文件大小
    func formatFileSize(_ bytes: Int64) -> String {
        let kb = 1024.0
        let mb = kb * 1024
        let gb = mb * 1024

        let size = Double(bytes)

        if size >= gb {
            return String(format: "%.2f GB", size / gb)
        } else if size >= mb {
            return String(format: "%.2f MB", size / mb)
        } else if size >= kb {
            return String(format: "%.2f KB", size / kb)
        } else {
            return "\(bytes) B"
        }
    }

    // MARK: - 电话号码格式化

    /// 格式化手机号（隐藏中间4位）
    func formatPhoneNumber(_ phone: String) -> String {
        guard phone.count == 11 else { return phone }
        let start = phone.prefix(3)
        let end = phone.suffix(4)
        return "\(start)****\(end)"
    }
}
