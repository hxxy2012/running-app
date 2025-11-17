import Foundation
import UserNotifications

// MARK: - 通知助手
class NotificationHelper {

    static let shared = NotificationHelper()

    private init() {}

    // 通知标识符
    enum NotificationIdentifier: String {
        case running = "running"
        case trainingReminder = "training_reminder"
        case achievement = "achievement"
        case social = "social"
        case system = "system"
    }

    // MARK: - 权限请求

    /// 请求通知权限
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]

        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            DispatchQueue.main.async {
                completion(granted, error)
            }
        }
    }

    /// 检查通知权限状态
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    // MARK: - 发送本地通知

    /// 显示训练提醒通知
    func showTrainingReminder(
        title: String = "训练提醒",
        body: String,
        delay: TimeInterval = 0
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1

        let trigger: UNNotificationTrigger
        if delay > 0 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: NotificationIdentifier.trainingReminder.rawValue,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.e("Show training reminder failed", error: error)
            }
        }
    }

    /// 显示成就解锁通知
    func showAchievementNotification(
        achievementName: String,
        achievementDescription: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = "🏆 解锁新成就！"
        content.body = achievementName
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        let request = UNNotificationRequest(
            identifier: NotificationIdentifier.achievement.rawValue,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.e("Show achievement notification failed", error: error)
            }
        }
    }

    /// 显示社交通知
    func showSocialNotification(
        title: String,
        body: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        let request = UNNotificationRequest(
            identifier: NotificationIdentifier.social.rawValue,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.e("Show social notification failed", error: error)
            }
        }
    }

    // MARK: - 定时通知

    /// 安排定时通知
    func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        triggerDate: Date,
        repeats: Bool = false
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.e("Schedule notification failed", error: error)
            }
        }
    }

    // MARK: - 管理通知

    /// 取消指定通知
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
    }

    /// 取消所有通知
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// 清除已显示的通知
    func clearDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    /// 重置角标
    func resetBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    /// 设置角标数量
    func setBadgeCount(_ count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = count
    }

    // MARK: - 查询通知

    /// 获取待发送的通知
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }

    /// 获取已发送的通知
    func getDeliveredNotifications(completion: @escaping ([UNNotification]) -> Void) {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                completion(notifications)
            }
        }
    }
}

// MARK: - 便捷扩展

extension NotificationHelper {

    /// 每日训练提醒
    func scheduleDailyTrainingReminder(hour: Int, minute: Int) {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "训练提醒"
        content.body = "该开始今天的训练了！💪"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily_training_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.e("Schedule daily training reminder failed", error: error)
            }
        }
    }

    /// 取消每日训练提醒
    func cancelDailyTrainingReminder() {
        cancelNotification(identifier: "daily_training_reminder")
    }
}
