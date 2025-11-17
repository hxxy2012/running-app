import Foundation
import LocalAuthentication

// MARK: - 生物识别类型
enum BiometricType {
    case none       // 不支持
    case touchID    // Touch ID (指纹)
    case faceID     // Face ID (面容)

    var displayName: String {
        switch self {
        case .none: return "无"
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        }
    }

    var icon: String {
        switch self {
        case .none: return ""
        case .touchID: return "touchid"
        case .faceID: return "faceid"
        }
    }
}

// MARK: - 生物识别可用性
enum BiometricAvailability {
    case available              // 可用
    case notAvailable          // 不可用
    case notEnrolled           // 未注册
    case locked                // 已锁定
    case passcodeNotSet        // 未设置密码

    var isAvailable: Bool {
        return self == .available
    }
}

// MARK: - 认证结果
enum BiometricAuthResult {
    case success
    case failure(BiometricError)
    case cancelled
}

// MARK: - 认证错误
enum BiometricError: Error {
    case authenticationFailed       // 认证失败
    case userCancel                // 用户取消
    case userFallback              // 用户选择使用密码
    case systemCancel              // 系统取消
    case passcodeNotSet            // 未设置密码
    case biometryNotAvailable      // 生物识别不可用
    case biometryNotEnrolled       // 未注册生物特征
    case biometryLockout           // 生物识别已锁定
    case appCancel                 // 应用取消
    case invalidContext            // 无效上下文
    case notInteractive            // 非交互模式
    case unknown(Error)            // 未知错误

    var localizedDescription: String {
        switch self {
        case .authenticationFailed:
            return "身份验证失败"
        case .userCancel:
            return "用户取消验证"
        case .userFallback:
            return "用户选择使用密码"
        case .systemCancel:
            return "系统取消验证"
        case .passcodeNotSet:
            return "未设置设备密码"
        case .biometryNotAvailable:
            return "生物识别不可用"
        case .biometryNotEnrolled:
            return "未注册生物特征，请先在系统设置中添加"
        case .biometryLockout:
            return "尝试次数过多，生物识别已锁定"
        case .appCancel:
            return "应用取消验证"
        case .invalidContext:
            return "无效的验证上下文"
        case .notInteractive:
            return "当前无法进行交互式验证"
        case .unknown(let error):
            return "未知错误: \(error.localizedDescription)"
        }
    }
}

// MARK: - 生物识别助手
class BiometricHelper {

    static let shared = BiometricHelper()

    private init() {}

    // MARK: - 设备能力检查

    /// 获取设备支持的生物识别类型
    func getBiometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        @unknown default:
            return .none
        }
    }

    /// 检查生物识别是否可用
    func checkAvailability() -> BiometricAvailability {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let laError = error as? LAError {
                switch laError.code {
                case .biometryNotEnrolled:
                    return .notEnrolled
                case .biometryLockout:
                    return .locked
                case .passcodeNotSet:
                    return .passcodeNotSet
                default:
                    return .notAvailable
                }
            }
            return .notAvailable
        }

        return .available
    }

    /// 是否支持生物识别
    var isBiometricAvailable: Bool {
        return checkAvailability().isAvailable
    }

    /// 是否已注册生物特征
    var hasBiometricEnrolled: Bool {
        let availability = checkAvailability()
        return availability == .available || availability == .locked
    }

    // MARK: - 认证

    /// 执行生物识别认证
    /// - Parameters:
    ///   - reason: 认证原因（显示给用户）
    ///   - fallbackTitle: 备用按钮标题（显示密码输入选项）
    ///   - cancelTitle: 取消按钮标题
    ///   - completion: 认证结果回调
    func authenticate(
        reason: String,
        fallbackTitle: String? = nil,
        cancelTitle: String? = nil,
        completion: @escaping (BiometricAuthResult) -> Void
    ) {
        let context = LAContext()

        // 设置按钮文本
        if let fallback = fallbackTitle {
            context.localizedFallbackTitle = fallback
        }
        if let cancel = cancelTitle {
            context.localizedCancelTitle = cancel
        }

        // 检查是否可用
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            let biometricError = convertError(error)
            DispatchQueue.main.async {
                completion(.failure(biometricError))
            }
            return
        }

        // 执行认证
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        ) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(.success)
                } else if let error = error {
                    let biometricError = self.convertError(error as NSError)
                    if case .userCancel = biometricError {
                        completion(.cancelled)
                    } else {
                        completion(.failure(biometricError))
                    }
                } else {
                    completion(.failure(.authenticationFailed))
                }
            }
        }
    }

    /// 使用设备密码认证（包括生物识别和密码）
    /// - Parameters:
    ///   - reason: 认证原因
    ///   - completion: 认证结果回调
    func authenticateWithDeviceCredential(
        reason: String,
        completion: @escaping (BiometricAuthResult) -> Void
    ) {
        let context = LAContext()

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            let biometricError = convertError(error)
            DispatchQueue.main.async {
                completion(.failure(biometricError))
            }
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        ) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(.success)
                } else if let error = error {
                    let biometricError = self.convertError(error as NSError)
                    if case .userCancel = biometricError {
                        completion(.cancelled)
                    } else {
                        completion(.failure(biometricError))
                    }
                } else {
                    completion(.failure(.authenticationFailed))
                }
            }
        }
    }

    /// 快速认证（使用默认配置）
    /// - Parameters:
    ///   - onSuccess: 成功回调
    ///   - onFailure: 失败回调
    ///   - onCancelled: 取消回调
    func quickAuthenticate(
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (String) -> Void,
        onCancelled: @escaping () -> Void = {}
    ) {
        let biometricType = getBiometricType()
        let reason = biometricType == .faceID ? "验证Face ID以继续" : "验证Touch ID以继续"

        authenticate(reason: reason) { result in
            switch result {
            case .success:
                onSuccess()
            case .failure(let error):
                onFailure(error.localizedDescription)
            case .cancelled:
                onCancelled()
            }
        }
    }

    // MARK: - 辅助方法

    /// 转换系统错误为自定义错误
    private func convertError(_ error: NSError?) -> BiometricError {
        guard let error = error else {
            return .authenticationFailed
        }

        if let laError = error as? LAError {
            switch laError.code {
            case .authenticationFailed:
                return .authenticationFailed
            case .userCancel:
                return .userCancel
            case .userFallback:
                return .userFallback
            case .systemCancel:
                return .systemCancel
            case .passcodeNotSet:
                return .passcodeNotSet
            case .biometryNotAvailable:
                return .biometryNotAvailable
            case .biometryNotEnrolled:
                return .biometryNotEnrolled
            case .biometryLockout:
                return .biometryLockout
            case .appCancel:
                return .appCancel
            case .invalidContext:
                return .invalidContext
            case .notInteractive:
                return .notInteractive
            @unknown default:
                return .unknown(error)
            }
        }

        return .unknown(error)
    }

    /// 获取可用性描述
    func getAvailabilityDescription(_ availability: BiometricAvailability) -> String {
        switch availability {
        case .available:
            return "生物识别可用"
        case .notAvailable:
            return "设备不支持生物识别"
        case .notEnrolled:
            return "未注册生物特征，请先在系统设置中添加"
        case .locked:
            return "尝试次数过多，生物识别已锁定"
        case .passcodeNotSet:
            return "未设置设备密码，请先设置密码"
        }
    }

    /// 获取认证建议文本
    func getAuthenticationPrompt() -> String {
        let biometricType = getBiometricType()
        switch biometricType {
        case .none:
            return "请使用设备密码验证"
        case .touchID:
            return "请使用Touch ID验证"
        case .faceID:
            return "请使用Face ID验证"
        }
    }
}

// MARK: - 便捷扩展

extension BiometricHelper {

    /// 用于快速登录的认证
    func authenticateForLogin(completion: @escaping (Bool) -> Void) {
        authenticate(
            reason: "使用\(getBiometricType().displayName)快速登录",
            cancelTitle: "取消"
        ) { result in
            switch result {
            case .success:
                completion(true)
            case .failure(let error):
                Logger.e("Biometric login failed", error: error)
                completion(false)
            case .cancelled:
                completion(false)
            }
        }
    }

    /// 用于支付验证的认证
    func authenticateForPayment(completion: @escaping (Bool) -> Void) {
        authenticate(
            reason: "验证以完成支付",
            fallbackTitle: "使用密码",
            cancelTitle: "取消"
        ) { result in
            switch result {
            case .success:
                completion(true)
            case .failure(let error):
                Logger.e("Biometric payment auth failed", error: error)
                completion(false)
            case .cancelled:
                completion(false)
            }
        }
    }

    /// 用于敏感操作的认证
    func authenticateForSensitiveOperation(
        operationName: String,
        completion: @escaping (Bool) -> Void
    ) {
        authenticate(
            reason: "验证以\(operationName)",
            cancelTitle: "取消"
        ) { result in
            switch result {
            case .success:
                completion(true)
            case .failure(let error):
                Logger.e("Biometric sensitive operation auth failed", error: error)
                completion(false)
            case .cancelled:
                completion(false)
            }
        }
    }
}

// MARK: - SwiftUI辅助

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 13.0, *)
extension View {
    /// 生物识别认证修饰符
    func biometricAuth(
        isPresented: Binding<Bool>,
        reason: String,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (String) -> Void = { _ in }
    ) -> some View {
        self.onChange(of: isPresented.wrappedValue) { shouldAuth in
            if shouldAuth {
                BiometricHelper.shared.authenticate(reason: reason) { result in
                    switch result {
                    case .success:
                        onSuccess()
                    case .failure(let error):
                        onFailure(error.localizedDescription)
                    case .cancelled:
                        break
                    }
                    isPresented.wrappedValue = false
                }
            }
        }
    }
}

#endif
