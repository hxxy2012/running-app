import Foundation
import SwiftUI
import UIKit

// MARK: - 动画工具类
class AnimationHelper {

    static let shared = AnimationHelper()

    private init() {}

    // 动画时长
    enum Duration {
        static let short: TimeInterval = 0.2
        static let normal: TimeInterval = 0.3
        static let long: TimeInterval = 0.5
    }

    // MARK: - UIView动画

    /// 淡入动画
    func fadeIn(
        _ view: UIView,
        duration: TimeInterval = Duration.normal,
        completion: (() -> Void)? = nil
    ) {
        view.alpha = 0
        view.isHidden = false
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                view.alpha = 1
            },
            completion: { _ in
                completion?()
            }
        )
    }

    /// 淡出动画
    func fadeOut(
        _ view: UIView,
        duration: TimeInterval = Duration.normal,
        completion: (() -> Void)? = nil
    ) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                view.alpha = 0
            },
            completion: { _ in
                view.isHidden = true
                completion?()
            }
        )
    }

    /// 缩放动画
    func scale(
        _ view: UIView,
        from fromScale: CGFloat = 0,
        to toScale: CGFloat = 1,
        duration: TimeInterval = Duration.normal,
        completion: (() -> Void)? = nil
    ) {
        view.transform = CGAffineTransform(scaleX: fromScale, y: fromScale)
        view.isHidden = false
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut,
            animations: {
                view.transform = CGAffineTransform(scaleX: toScale, y: toScale)
            },
            completion: { _ in
                completion?()
            }
        )
    }

    /// 滑入动画（从底部）
    func slideInFromBottom(
        _ view: UIView,
        duration: TimeInterval = Duration.normal,
        completion: (() -> Void)? = nil
    ) {
        let originalTransform = view.transform
        view.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        view.isHidden = false
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                view.transform = originalTransform
            },
            completion: { _ in
                completion?()
            }
        )
    }

    /// 滑出动画（向底部）
    func slideOutToBottom(
        _ view: UIView,
        duration: TimeInterval = Duration.normal,
        completion: (() -> Void)? = nil
    ) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                view.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
            },
            completion: { _ in
                view.isHidden = true
                view.transform = .identity
                completion?()
            }
        )
    }

    /// 弹跳动画
    func bounce(
        _ view: UIView,
        duration: TimeInterval = Duration.long,
        completion: (() -> Void)? = nil
    ) {
        UIView.animateKeyframes(
            withDuration: duration,
            delay: 0,
            options: [],
            animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.2) {
                    view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.2) {
                    view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.2) {
                    view.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.2) {
                    view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.2) {
                    view.transform = .identity
                }
            },
            completion: { _ in
                completion?()
            }
        )
    }

    /// 摇晃动画
    func shake(
        _ view: UIView,
        duration: TimeInterval = Duration.long,
        completion: (() -> Void)? = nil
    ) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = duration
        animation.values = [0, 25, -25, 25, -25, 15, -15, 6, -6, 0]
        view.layer.add(animation, forKey: "shake")

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            completion?()
        }
    }

    /// 旋转动画
    func rotate(
        _ view: UIView,
        from fromAngle: CGFloat = 0,
        to toAngle: CGFloat = .pi * 2,
        duration: TimeInterval = Duration.normal,
        repeat: Bool = false,
        completion: (() -> Void)? = nil
    ) {
        if `repeat` {
            let animation = CABasicAnimation(keyPath: "transform.rotation")
            animation.fromValue = fromAngle
            animation.toValue = toAngle
            animation.duration = duration
            animation.repeatCount = .infinity
            view.layer.add(animation, forKey: "rotation")
        } else {
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: .curveLinear,
                animations: {
                    view.transform = CGAffineTransform(rotationAngle: toAngle)
                },
                completion: { _ in
                    completion?()
                }
            )
        }
    }

    /// 脉冲动画（心跳效果）
    func pulse(
        _ view: UIView,
        duration: TimeInterval = Duration.normal,
        repeat: Bool = true
    ) {
        UIView.animate(
            withDuration: duration / 2,
            delay: 0,
            options: [.autoreverse, .repeat],
            animations: {
                view.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }
        )
    }

    /// 停止所有动画
    func stopAllAnimations(_ view: UIView) {
        view.layer.removeAllAnimations()
        UIView.animate(withDuration: 0) {
            view.transform = .identity
        }
    }
}

// MARK: - UIView扩展

extension UIView {

    /// 淡入
    func fadeIn(duration: TimeInterval = AnimationHelper.Duration.normal) {
        AnimationHelper.shared.fadeIn(self, duration: duration)
    }

    /// 淡出
    func fadeOut(duration: TimeInterval = AnimationHelper.Duration.normal) {
        AnimationHelper.shared.fadeOut(self, duration: duration)
    }

    /// 缩放进入
    func scaleIn(duration: TimeInterval = AnimationHelper.Duration.normal) {
        AnimationHelper.shared.scale(self, from: 0, to: 1, duration: duration)
    }

    /// 缩放退出
    func scaleOut(duration: TimeInterval = AnimationHelper.Duration.normal) {
        AnimationHelper.shared.scale(self, from: 1, to: 0, duration: duration)
    }

    /// 弹跳
    func bounce() {
        AnimationHelper.shared.bounce(self)
    }

    /// 摇晃
    func shake() {
        AnimationHelper.shared.shake(self)
    }

    /// 旋转
    func rotate(repeat: Bool = false) {
        AnimationHelper.shared.rotate(self, repeat: `repeat`)
    }

    /// 脉冲
    func pulse() {
        AnimationHelper.shared.pulse(self)
    }

    /// 停止动画
    func stopAnimations() {
        AnimationHelper.shared.stopAllAnimations(self)
    }
}

// MARK: - SwiftUI动画

extension Animation {

    /// 快速动画
    static var quick: Animation {
        .easeOut(duration: AnimationHelper.Duration.short)
    }

    /// 标准动画
    static var standard: Animation {
        .easeInOut(duration: AnimationHelper.Duration.normal)
    }

    /// 缓慢动画
    static var slow: Animation {
        .easeInOut(duration: AnimationHelper.Duration.long)
    }

    /// 弹性动画
    static var bouncy: Animation {
        .spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)
    }

    /// 流畅弹性动画
    static var smoothBouncy: Animation {
        .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)
    }
}

// MARK: - SwiftUI过渡

extension AnyTransition {

    /// 淡入淡出过渡
    static var fade: AnyTransition {
        .opacity
    }

    /// 缩放过渡
    static var scale: AnyTransition {
        .scale(scale: 0)
    }

    /// 滑动过渡（从底部）
    static var slideFromBottom: AnyTransition {
        .move(edge: .bottom)
    }

    /// 滑动过渡（从顶部）
    static var slideFromTop: AnyTransition {
        .move(edge: .top)
    }

    /// 滑动过渡（从左）
    static var slideFromLeading: AnyTransition {
        .move(edge: .leading)
    }

    /// 滑动过渡（从右）
    static var slideFromTrailing: AnyTransition {
        .move(edge: .trailing)
    }

    /// 缩放+淡入淡出组合过渡
    static var scaleAndFade: AnyTransition {
        .scale.combined(with: .opacity)
    }

    /// 滑动+淡入淡出组合过渡
    static var slideAndFade: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }
}

// MARK: - SwiftUI修饰符

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
                y: 0
            )
        )
    }
}

extension View {

    /// 摇晃动画
    func shake(trigger: Int) -> some View {
        modifier(ShakeEffect(animatableData: CGFloat(trigger)))
    }

    /// 脉冲动画
    func pulse(enabled: Bool = true) -> some View {
        scaleEffect(enabled ? 1.05 : 1.0)
            .animation(
                enabled ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default,
                value: enabled
            )
    }

    /// 闪烁动画
    func blink(enabled: Bool = true) -> some View {
        opacity(enabled ? 0.3 : 1.0)
            .animation(
                enabled ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default,
                value: enabled
            )
    }

    /// 旋转动画
    func rotating(enabled: Bool = true) -> some View {
        rotationEffect(.degrees(enabled ? 360 : 0))
            .animation(
                enabled ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default,
                value: enabled
            )
    }

    /// 弹跳进入动画
    func bounceIn() -> some View {
        transition(.scale.combined(with: .opacity))
            .animation(.bouncy, value: UUID())
    }
}

// MARK: - 自定义动画修饰符

struct WiggleModifier: ViewModifier {
    let amount: CGFloat

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(amount))
    }
}

extension View {
    /// 摆动动画
    func wiggle(amount: CGFloat = 5) -> some View {
        modifier(WiggleModifier(amount: amount))
    }
}

// MARK: - 运动动画

struct RunningAnimationModifier: ViewModifier {
    @State private var isRunning = false

    func body(content: Content) -> some View {
        content
            .offset(x: isRunning ? 20 : -20, y: 0)
            .animation(
                .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                value: isRunning
            )
            .onAppear {
                isRunning = true
            }
    }
}

extension View {
    /// 跑步动画效果
    func runningAnimation() -> some View {
        modifier(RunningAnimationModifier())
    }
}

// MARK: - 全局便捷函数

/// 执行动画
func animate(
    duration: TimeInterval = AnimationHelper.Duration.normal,
    delay: TimeInterval = 0,
    animations: @escaping () -> Void,
    completion: (() -> Void)? = nil
) {
    UIView.animate(
        withDuration: duration,
        delay: delay,
        options: .curveEaseInOut,
        animations: animations,
        completion: { _ in
            completion?()
        }
    )
}

/// 执行弹性动画
func animateSpring(
    duration: TimeInterval = AnimationHelper.Duration.normal,
    delay: TimeInterval = 0,
    dampingRatio: CGFloat = 0.7,
    animations: @escaping () -> Void,
    completion: (() -> Void)? = nil
) {
    UIView.animate(
        withDuration: duration,
        delay: delay,
        usingSpringWithDamping: dampingRatio,
        initialSpringVelocity: 0.5,
        options: .curveEaseOut,
        animations: animations,
        completion: { _ in
            completion?()
        }
    )
}

// MARK: - SwiftUI预览

#if DEBUG
struct AnimationHelper_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(Color.blue)
                .frame(width: 50, height: 50)
                .pulse(enabled: true)

            Text("摇晃我")
                .shake(trigger: 0)

            Circle()
                .fill(Color.green)
                .frame(width: 50, height: 50)
                .rotating(enabled: true)
        }
    }
}
#endif
