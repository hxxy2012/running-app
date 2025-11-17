import Foundation
import UIKit
import SwiftUI

// MARK: - 分享助手
class ShareHelper {

    static let shared = ShareHelper()

    private init() {}

    // MARK: - 分享文本

    /// 分享纯文本
    /// - Parameters:
    ///   - text: 要分享的文本
    ///   - from: 源视图控制器
    ///   - sourceView: iPad上的源视图（用于popover）
    func shareText(
        _ text: String,
        from viewController: UIViewController,
        sourceView: UIView? = nil
    ) {
        let activityController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        configurePopover(activityController, sourceView: sourceView ?? viewController.view)
        viewController.present(activityController, animated: true)
    }

    // MARK: - 分享图片

    /// 分享单张图片
    /// - Parameters:
    ///   - image: 要分享的图片
    ///   - text: 附加文本
    ///   - from: 源视图控制器
    ///   - sourceView: iPad上的源视图
    func shareImage(
        _ image: UIImage,
        text: String? = nil,
        from viewController: UIViewController,
        sourceView: UIView? = nil
    ) {
        var items: [Any] = [image]
        if let text = text {
            items.append(text)
        }

        let activityController = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        configurePopover(activityController, sourceView: sourceView ?? viewController.view)
        viewController.present(activityController, animated: true)
    }

    /// 分享多张图片
    /// - Parameters:
    ///   - images: 要分享的图片数组
    ///   - text: 附加文本
    ///   - from: 源视图控制器
    ///   - sourceView: iPad上的源视图
    func shareImages(
        _ images: [UIImage],
        text: String? = nil,
        from viewController: UIViewController,
        sourceView: UIView? = nil
    ) {
        guard !images.isEmpty else { return }

        var items: [Any] = images
        if let text = text {
            items.append(text)
        }

        let activityController = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        configurePopover(activityController, sourceView: sourceView ?? viewController.view)
        viewController.present(activityController, animated: true)
    }

    // MARK: - 分享URL

    /// 分享URL
    /// - Parameters:
    ///   - url: 要分享的URL
    ///   - text: 附加文本
    ///   - from: 源视图控制器
    ///   - sourceView: iPad上的源视图
    func shareURL(
        _ url: URL,
        text: String? = nil,
        from viewController: UIViewController,
        sourceView: UIView? = nil
    ) {
        var items: [Any] = [url]
        if let text = text {
            items.append(text)
        }

        let activityController = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        configurePopover(activityController, sourceView: sourceView ?? viewController.view)
        viewController.present(activityController, animated: true)
    }

    // MARK: - 分享文件

    /// 分享文件
    /// - Parameters:
    ///   - fileURL: 文件URL
    ///   - from: 源视图控制器
    ///   - sourceView: iPad上的源视图
    func shareFile(
        _ fileURL: URL,
        from viewController: UIViewController,
        sourceView: UIView? = nil
    ) {
        let activityController = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )

        configurePopover(activityController, sourceView: sourceView ?? viewController.view)
        viewController.present(activityController, animated: true)
    }

    // MARK: - 跑步数据分享

    /// 分享跑步记录
    /// - Parameters:
    ///   - distance: 距离（米）
    ///   - duration: 时长（秒）
    ///   - pace: 配速（秒/米）
    ///   - calories: 卡路里
    ///   - additionalText: 附加文本
    ///   - from: 源视图控制器
    ///   - sourceView: iPad上的源视图
    func shareRunningRecord(
        distance: Double,
        duration: Int,
        pace: Double,
        calories: Double,
        additionalText: String? = nil,
        from viewController: UIViewController,
        sourceView: UIView? = nil
    ) {
        let distanceText = distance.toDistanceString()
        let durationText = duration.toDurationString()
        let paceText = pace.toPaceString()
        let caloriesText = String(format: "%.0f", calories)

        var shareText = """
        🏃 我的跑步记录

        📏 距离：\(distanceText)
        ⏱️ 用时：\(durationText)
        ⚡ 配速：\(paceText)
        🔥 卡路里：\(caloriesText) kcal
        """

        if let additional = additionalText {
            shareText += "\n\n\(additional)"
        }

        shareText += "\n\n#跑步 #运动 #健康生活"

        shareText(shareText, from: viewController, sourceView: sourceView)
    }

    /// 分享跑步记录（带图片）
    /// - Parameters:
    ///   - distance: 距离（米）
    ///   - duration: 时长（秒）
    ///   - image: 分享图片
    ///   - additionalText: 附加文本
    ///   - from: 源视图控制器
    ///   - sourceView: iPad上的源视图
    func shareRunningRecordWithImage(
        distance: Double,
        duration: Int,
        image: UIImage,
        additionalText: String? = nil,
        from viewController: UIViewController,
        sourceView: UIView? = nil
    ) {
        let distanceText = distance.toDistanceString()
        let durationText = duration.toDurationString()

        var shareText = """
        🏃 我完成了一次跑步
        📏 \(distanceText)  ⏱️ \(durationText)
        """

        if let additional = additionalText {
            shareText += "\n\(additional)"
        }

        shareText += "\n#跑步 #运动"

        shareImage(image, text: shareText, from: viewController, sourceView: sourceView)
    }

    /// 分享成就
    /// - Parameters:
    ///   - name: 成就名称
    ///   - description: 成就描述
    ///   - image: 成就图片（可选）
    ///   - from: 源视图控制器
    ///   - sourceView: iPad上的源视图
    func shareAchievement(
        name: String,
        description: String,
        image: UIImage? = nil,
        from viewController: UIViewController,
        sourceView: UIView? = nil
    ) {
        let shareText = """
        🏆 解锁新成就！

        \(name)
        \(description)

        #成就解锁 #跑步 #坚持
        """

        if let image = image {
            shareImage(image, text: shareText, from: viewController, sourceView: sourceView)
        } else {
            self.shareText(shareText, from: viewController, sourceView: sourceView)
        }
    }

    // MARK: - 辅助方法

    /// 配置iPad的Popover显示
    private func configurePopover(_ activityController: UIActivityViewController, sourceView: UIView) {
        if let popoverController = activityController.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = CGRect(
                x: sourceView.bounds.midX,
                y: sourceView.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }
    }

    /// 排除某些分享选项
    func excludeActivityTypes(_ types: [UIActivity.ActivityType]) -> [UIActivity.ActivityType] {
        return types
    }
}

// MARK: - SwiftUI支持

#if canImport(SwiftUI)
@available(iOS 13.0, *)
struct ActivityViewController: UIViewControllerRepresentable {

    let activityItems: [Any]
    let applicationActivities: [UIActivity]?
    let excludedActivityTypes: [UIActivity.ActivityType]?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

@available(iOS 13.0, *)
extension View {
    /// 分享Sheet修饰符
    func shareSheet(
        isPresented: Binding<Bool>,
        items: [Any],
        excludedTypes: [UIActivity.ActivityType]? = nil
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            ActivityViewController(
                activityItems: items,
                applicationActivities: nil,
                excludedActivityTypes: excludedTypes
            )
        }
    }
}

#endif

// MARK: - 便捷扩展

extension ShareHelper {

    /// 创建跑步记录分享图片
    func createRunningShareImage(
        distance: Double,
        duration: Int,
        pace: Double,
        calories: Double,
        date: Date = Date()
    ) -> UIImage? {
        let size = CGSize(width: 1080, height: 1080)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // 背景渐变
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0).cgColor,
                    UIColor(red: 0.1, green: 0.4, blue: 0.8, alpha: 1.0).cgColor
                ] as CFArray,
                locations: [0, 1]
            )!

            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: size.height),
                options: []
            )

            // 绘制文字
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 60, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]

            let dataAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 80, weight: .heavy),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]

            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 40, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9),
                .paragraphStyle: paragraphStyle
            ]

            // 标题
            "我的跑步记录".draw(
                in: CGRect(x: 0, y: 100, width: size.width, height: 80),
                withAttributes: titleAttributes
            )

            // 距离
            distance.toDistanceString(includeUnit: false).draw(
                in: CGRect(x: 0, y: 300, width: size.width, height: 100),
                withAttributes: dataAttributes
            )
            "公里".draw(
                in: CGRect(x: 0, y: 410, width: size.width, height: 50),
                withAttributes: labelAttributes
            )

            // 用时和配速
            let timeText = duration.toDurationString()
            let paceText = pace.toPaceString()

            timeText.draw(
                in: CGRect(x: 0, y: 550, width: size.width / 2, height: 60),
                withAttributes: labelAttributes
            )
            paceText.draw(
                in: CGRect(x: size.width / 2, y: 550, width: size.width / 2, height: 60),
                withAttributes: labelAttributes
            )

            "用时".draw(
                in: CGRect(x: 0, y: 620, width: size.width / 2, height: 40),
                withAttributes: labelAttributes
            )
            "配速".draw(
                in: CGRect(x: size.width / 2, y: 620, width: size.width / 2, height: 40),
                withAttributes: labelAttributes
            )

            // 日期
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy年MM月dd日"
            let dateText = dateFormatter.string(from: date)

            dateText.draw(
                in: CGRect(x: 0, y: size.height - 120, width: size.width, height: 50),
                withAttributes: labelAttributes
            )
        }
    }
}
