import Foundation
import UIKit

// MARK: - 触觉反馈助手
class HapticHelper {

    static let shared = HapticHelper()

    private init() {}

    // 触觉反馈生成器
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = {
        if #available(iOS 13.0, *) {
            return UIImpactFeedbackGenerator(style: .soft)
        } else {
            return UIImpactFeedbackGenerator(style: .light)
        }
    }()
    private let impactRigid = {
        if #available(iOS 13.0, *) {
            return UIImpactFeedbackGenerator(style: .rigid)
        } else {
            return UIImpactFeedbackGenerator(style: .heavy)
        }
    }()

    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()

    // MARK: - 冲击反馈

    /// 轻度冲击
    func light() {
        impactLight.impactOccurred()
    }

    /// 中度冲击
    func medium() {
        impactMedium.impactOccurred()
    }

    /// 重度冲击
    func heavy() {
        impactHeavy.impactOccurred()
    }

    /// 柔和冲击（iOS 13+）
    func soft() {
        impactSoft.impactOccurred()
    }

    /// 刚性冲击（iOS 13+）
    func rigid() {
        impactRigid.impactOccurred()
    }

    /// 自定义强度冲击（iOS 13+）
    @available(iOS 13.0, *)
    func impact(intensity: CGFloat) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: intensity)
    }

    // MARK: - 选择反馈

    /// 选择改变反馈
    func selectionChanged() {
        selectionFeedback.selectionChanged()
    }

    // MARK: - 通知反馈

    /// 成功通知
    func success() {
        notificationFeedback.notificationOccurred(.success)
    }

    /// 警告通知
    func warning() {
        notificationFeedback.notificationOccurred(.warning)
    }

    /// 错误通知
    func error() {
        notificationFeedback.notificationOccurred(.error)
    }

    // MARK: - 预准备（优化响应时间）

    /// 预准备冲击反馈
    func prepareImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        switch style {
        case .light:
            impactLight.prepare()
        case .medium:
            impactMedium.prepare()
        case .heavy:
            impactHeavy.prepare()
        case .soft:
            if #available(iOS 13.0, *) {
                impactSoft.prepare()
            }
        case .rigid:
            if #available(iOS 13.0, *) {
                impactRigid.prepare()
            }
        @unknown default:
            impactMedium.prepare()
        }
    }

    /// 预准备选择反馈
    func prepareSelection() {
        selectionFeedback.prepare()
    }

    /// 预准备通知反馈
    func prepareNotification() {
        notificationFeedback.prepare()
    }

    // MARK: - 跑步专用反馈

    /// 跑步开始
    func runningStart() {
        // 三次中度冲击
        medium()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.medium()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.medium()
        }
    }

    /// 跑步暂停
    func runningPause() {
        light()
    }

    /// 跑步继续
    func runningResume() {
        // 两次轻度冲击
        light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.light()
        }
    }

    /// 跑步结束
    func runningStop() {
        success()
    }

    /// 完成1公里
    func kilometerCompleted() {
        // 三次轻度冲击
        light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.light()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.light()
        }
    }

    /// 达成目标
    func goalAchieved() {
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.success()
        }
    }

    // MARK: - UI交互反馈

    /// 按钮点击
    func buttonTap() {
        light()
    }

    /// 开关切换
    func switchToggle() {
        selectionChanged()
    }

    /// 滑块拖动
    func sliderChanged() {
        light()
    }

    /// 列表项选择
    func itemSelected() {
        selectionChanged()
    }

    /// 下拉刷新
    func pullToRefresh() {
        medium()
    }

    /// 长按
    func longPress() {
        medium()
    }

    // MARK: - 复杂模式

    /// 倒计时滴答（3-2-1）
    func countdown() {
        light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.medium()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.heavy()
        }
    }

    /// 双击确认
    func doubleConfirm() {
        light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.light()
        }
    }

    /// 进度完成
    func progressComplete() {
        success()
    }

    /// 数据加载完成
    func loadComplete() {
        soft()
    }
}

// MARK: - 便捷扩展

extension HapticHelper {

    /// 根据成功/失败执行反馈
    func feedback(success: Bool) {
        if success {
            self.success()
        } else {
            error()
        }
    }

    /// 根据值变化执行反馈
    func valueChanged<T: Equatable>(oldValue: T, newValue: T) {
        if oldValue != newValue {
            selectionChanged()
        }
    }
}

// MARK: - SwiftUI支持

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 13.0, *)
extension View {
    /// 添加触觉反馈修饰符
    func hapticFeedback(
        _ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
        trigger: some Equatable
    ) -> some View {
        self.onChange(of: trigger) { _ in
            switch style {
            case .light:
                HapticHelper.shared.light()
            case .medium:
                HapticHelper.shared.medium()
            case .heavy:
                HapticHelper.shared.heavy()
            case .soft:
                HapticHelper.shared.soft()
            case .rigid:
                HapticHelper.shared.rigid()
            @unknown default:
                HapticHelper.shared.medium()
            }
        }
    }

    /// 点击时触发触觉反馈
    func hapticOnTap(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                switch style {
                case .light:
                    HapticHelper.shared.light()
                case .medium:
                    HapticHelper.shared.medium()
                case .heavy:
                    HapticHelper.shared.heavy()
                case .soft:
                    HapticHelper.shared.soft()
                case .rigid:
                    HapticHelper.shared.rigid()
                @unknown default:
                    HapticHelper.shared.light()
                }
            }
        )
    }

    /// 选择反馈修饰符
    func selectionFeedback<T: Equatable>(trigger: T) -> some View {
        self.onChange(of: trigger) { _ in
            HapticHelper.shared.selectionChanged()
        }
    }
}

#endif

// MARK: - UIButton扩展

extension UIButton {
    /// 添加触觉反馈到按钮
    func addHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        addTarget(self, action: #selector(triggerHaptic), for: .touchDown)
        objc_setAssociatedObject(
            self,
            "hapticStyle",
            style,
            .OBJC_ASSOCIATION_RETAIN
        )
    }

    @objc private func triggerHaptic() {
        if let style = objc_getAssociatedObject(self, "hapticStyle") as? UIImpactFeedbackGenerator.FeedbackStyle {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }
}

// MARK: - 全局便捷函数

/// 快速触发轻度触觉反馈
func hapticLight() {
    HapticHelper.shared.light()
}

/// 快速触发中度触觉反馈
func hapticMedium() {
    HapticHelper.shared.medium()
}

/// 快速触发重度触觉反馈
func hapticHeavy() {
    HapticHelper.shared.heavy()
}

/// 快速触发成功反馈
func hapticSuccess() {
    HapticHelper.shared.success()
}

/// 快速触发错误反馈
func hapticError() {
    HapticHelper.shared.error()
}

/// 快速触发选择反馈
func hapticSelection() {
    HapticHelper.shared.selectionChanged()
}
