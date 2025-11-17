import Foundation
import SwiftUI
import Combine
import UIKit

// MARK: - 键盘管理器
class KeyboardManager: ObservableObject {

    static let shared = KeyboardManager()

    // 键盘状态
    @Published var isKeyboardVisible: Bool = false
    @Published var keyboardHeight: CGFloat = 0
    @Published var keyboardFrame: CGRect = .zero

    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupKeyboardNotifications()
    }

    // MARK: - 通知监听

    /// 设置键盘通知监听
    private func setupKeyboardNotifications() {
        // 键盘将要显示
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] notification in
                self?.handleKeyboardWillShow(notification)
            }
            .store(in: &cancellables)

        // 键盘将要隐藏
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] notification in
                self?.handleKeyboardWillHide(notification)
            }
            .store(in: &cancellables)

        // 键盘已显示
        NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)
            .sink { [weak self] notification in
                self?.handleKeyboardDidShow(notification)
            }
            .store(in: &cancellables)

        // 键盘已隐藏
        NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)
            .sink { [weak self] notification in
                self?.handleKeyboardDidHide(notification)
            }
            .store(in: &cancellables)

        // 键盘frame变化
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .sink { [weak self] notification in
                self?.handleKeyboardWillChangeFrame(notification)
            }
            .store(in: &cancellables)
    }

    // MARK: - 通知处理

    /// 处理键盘将要显示
    private func handleKeyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        withAnimation {
            self.isKeyboardVisible = true
            self.keyboardHeight = keyboardFrame.height
            self.keyboardFrame = keyboardFrame
        }

        Logger.d("Keyboard will show - height: \(keyboardFrame.height)")
    }

    /// 处理键盘将要隐藏
    private func handleKeyboardWillHide(_ notification: Notification) {
        withAnimation {
            self.isKeyboardVisible = false
            self.keyboardHeight = 0
            self.keyboardFrame = .zero
        }

        Logger.d("Keyboard will hide")
    }

    /// 处理键盘已显示
    private func handleKeyboardDidShow(_ notification: Notification) {
        Logger.d("Keyboard did show")
    }

    /// 处理键盘已隐藏
    private func handleKeyboardDidHide(_ notification: Notification) {
        Logger.d("Keyboard did hide")
    }

    /// 处理键盘frame变化
    private func handleKeyboardWillChangeFrame(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        withAnimation {
            self.keyboardHeight = keyboardFrame.height
            self.keyboardFrame = keyboardFrame
        }

        Logger.d("Keyboard frame changed - height: \(keyboardFrame.height)")
    }

    // MARK: - 键盘控制

    /// 显示键盘
    func showKeyboard() {
        // 键盘显示需要通过UITextField或UITextView的becomeFirstResponder来触发
        Logger.d("Request to show keyboard")
    }

    /// 隐藏键盘
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        Logger.d("Hide keyboard")
    }

    /// 关闭键盘（通过让当前窗口结束编辑）
    func dismissKeyboard() {
        UIApplication.shared.windows.first?.endEditing(true)
    }

    // MARK: - 键盘动画信息

    /// 获取键盘动画时长
    func keyboardAnimationDuration(from notification: Notification) -> TimeInterval {
        return notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
    }

    /// 获取键盘动画曲线
    func keyboardAnimationCurve(from notification: Notification) -> UIView.AnimationCurve {
        let rawValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int ?? 0
        return UIView.AnimationCurve(rawValue: rawValue) ?? .easeInOut
    }
}

// MARK: - SwiftUI扩展

extension View {
    /// 点击空白处隐藏键盘
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            KeyboardManager.shared.hideKeyboard()
        }
    }

    /// 键盘显示时调整padding
    func keyboardAdaptive() -> some View {
        self.modifier(KeyboardAdaptive())
    }

    /// 监听键盘状态
    func onKeyboardChange(perform action: @escaping (Bool, CGFloat) -> Void) -> some View {
        self.modifier(KeyboardObserverModifier(onChange: action))
    }
}

// MARK: - 键盘自适应修饰符

struct KeyboardAdaptive: ViewModifier {
    @ObservedObject private var keyboardManager = KeyboardManager.shared

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardManager.keyboardHeight)
            .animation(.easeOut(duration: 0.25), value: keyboardManager.keyboardHeight)
    }
}

// MARK: - 键盘观察修饰符

struct KeyboardObserverModifier: ViewModifier {
    @ObservedObject private var keyboardManager = KeyboardManager.shared
    let onChange: (Bool, CGFloat) -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: keyboardManager.isKeyboardVisible) { isVisible in
                onChange(isVisible, keyboardManager.keyboardHeight)
            }
    }
}

// MARK: - 键盘避让修饰符

struct KeyboardAvoidingModifier: ViewModifier {
    @ObservedObject private var keyboardManager = KeyboardManager.shared

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .padding(.bottom, calculateBottomPadding(geometry: geometry))
                .animation(.easeOut(duration: 0.25), value: keyboardManager.keyboardHeight)
        }
    }

    private func calculateBottomPadding(geometry: GeometryProxy) -> CGFloat {
        guard keyboardManager.isKeyboardVisible else { return 0 }

        let viewBottom = geometry.frame(in: .global).maxY
        let keyboardTop = UIScreen.main.bounds.height - keyboardManager.keyboardHeight

        if viewBottom > keyboardTop {
            return viewBottom - keyboardTop
        }

        return 0
    }
}

extension View {
    /// 自动避让键盘
    func keyboardAvoiding() -> some View {
        self.modifier(KeyboardAvoidingModifier())
    }
}

// MARK: - Combine Publisher

extension KeyboardManager {
    /// 键盘可见性Publisher
    var keyboardVisibilityPublisher: AnyPublisher<Bool, Never> {
        $isKeyboardVisible.eraseToAnyPublisher()
    }

    /// 键盘高度Publisher
    var keyboardHeightPublisher: AnyPublisher<CGFloat, Never> {
        $keyboardHeight.eraseToAnyPublisher()
    }
}

// MARK: - UIKit扩展

extension UIViewController {
    /// 添加键盘隐藏手势
    func addKeyboardDismissGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardOnTap))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboardOnTap() {
        view.endEditing(true)
    }
}

extension UITextField {
    /// 添加键盘工具栏
    func addKeyboardToolbar(
        doneTitle: String = "完成",
        cancelTitle: String = "取消",
        onDone: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let cancelButton = UIBarButtonItem(
            title: cancelTitle,
            style: .plain,
            target: self,
            action: #selector(handleCancel)
        )

        let flexSpace = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )

        let doneButton = UIBarButtonItem(
            title: doneTitle,
            style: .done,
            target: self,
            action: #selector(handleDone)
        )

        toolbar.items = [cancelButton, flexSpace, doneButton]
        inputAccessoryView = toolbar

        // 保存回调（需要使用关联对象）
        objc_setAssociatedObject(self, &AssociatedKeys.onDone, onDone, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(self, &AssociatedKeys.onCancel, onCancel, .OBJC_ASSOCIATION_RETAIN)
    }

    @objc private func handleDone() {
        resignFirstResponder()
        if let onDone = objc_getAssociatedObject(self, &AssociatedKeys.onDone) as? () -> Void {
            onDone()
        }
    }

    @objc private func handleCancel() {
        resignFirstResponder()
        if let onCancel = objc_getAssociatedObject(self, &AssociatedKeys.onCancel) as? () -> Void {
            onCancel()
        }
    }

    private struct AssociatedKeys {
        static var onDone = "onDone"
        static var onCancel = "onCancel"
    }
}

// MARK: - 全局便捷函数

/// 隐藏键盘
func hideKeyboard() {
    KeyboardManager.shared.hideKeyboard()
}

/// 关闭键盘
func dismissKeyboard() {
    KeyboardManager.shared.dismissKeyboard()
}

// MARK: - SwiftUI预览辅助

#if DEBUG
struct KeyboardManager_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TextField("输入文本", text: .constant(""))
                .textFieldStyle(.roundedBorder)
                .padding()

            Text("键盘高度: \(KeyboardManager.shared.keyboardHeight)")

            Button("隐藏键盘") {
                hideKeyboard()
            }
        }
        .keyboardAdaptive()
        .hideKeyboardOnTap()
    }
}
#endif
