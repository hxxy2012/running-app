import Foundation

// MARK: - 数据验证工具类
class ValidationHelper {

    static let shared = ValidationHelper()

    private init() {}

    // 正则表达式
    private let phoneRegex = "^1[3-9]\\d{9}$"
    private let passwordRegex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)[a-zA-Z\\d@$!%*?&]{8,}$"
    private let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
    private let idCardRegex = "^[1-9]\\d{5}(19|20)\\d{2}((0[1-9])|(1[0-2]))(([0-2][1-9])|10|20|30|31)\\d{3}[0-9Xx]$"
    private let chineseRegex = "^[\\u{4e00}-\\u{9fa5}]+$"
    private let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    private let urlRegex = "^(https?://)?([\\da-z.-]+)\\.([a-z.]{2,6})([/\\w .-]*)*/?$"

    // MARK: - 基础验证

    /// 验证是否为空
    func isEmpty(_ text: String?) -> Bool {
        return text?.isEmpty ?? true
    }

    /// 验证是否非空
    func isNotEmpty(_ text: String?) -> Bool {
        return !isEmpty(text)
    }

    /// 验证长度范围
    func isLengthInRange(_ text: String?, min: Int, max: Int) -> Bool {
        guard let text = text else { return false }
        return text.count >= min && text.count <= max
    }

    /// 验证最小长度
    func hasMinLength(_ text: String?, min: Int) -> Bool {
        guard let text = text else { return false }
        return text.count >= min
    }

    /// 验证最大长度
    func hasMaxLength(_ text: String?, max: Int) -> Bool {
        guard let text = text else { return false }
        return text.count <= max
    }

    // MARK: - 手机号验证

    /// 验证手机号
    func isPhoneValid(_ phone: String?) -> Bool {
        guard let phone = phone else { return false }
        return matches(phone, regex: phoneRegex)
    }

    /// 获取手机号验证错误信息
    func getPhoneError(_ phone: String?) -> String? {
        if isEmpty(phone) {
            return "请输入手机号"
        }
        if !isPhoneValid(phone) {
            return "手机号格式不正确"
        }
        return nil
    }

    // MARK: - 邮箱验证

    /// 验证邮箱
    func isEmailValid(_ email: String?) -> Bool {
        guard let email = email else { return false }
        return matches(email, regex: emailRegex)
    }

    /// 获取邮箱验证错误信息
    func getEmailError(_ email: String?) -> String? {
        if isEmpty(email) {
            return "请输入邮箱"
        }
        if !isEmailValid(email) {
            return "邮箱格式不正确"
        }
        return nil
    }

    // MARK: - 密码验证

    /// 验证密码（至少8位，包含大小写字母和数字）
    func isPasswordValid(_ password: String?) -> Bool {
        guard let password = password else { return false }
        return matches(password, regex: passwordRegex)
    }

    /// 验证简单密码（至少6位）
    func isSimplePasswordValid(_ password: String?) -> Bool {
        return hasMinLength(password, min: 6)
    }

    /// 密码强度
    enum PasswordStrength {
        case empty
        case weak
        case medium
        case strong

        var description: String {
            switch self {
            case .empty: return "空"
            case .weak: return "弱"
            case .medium: return "中"
            case .strong: return "强"
            }
        }

        var color: String {
            switch self {
            case .empty: return "gray"
            case .weak: return "red"
            case .medium: return "orange"
            case .strong: return "green"
            }
        }
    }

    /// 验证密码强度
    func getPasswordStrength(_ password: String?) -> PasswordStrength {
        guard let password = password, !password.isEmpty else {
            return .empty
        }

        var score = 0

        // 长度检查
        if password.count >= 12 {
            score += 2
        } else if password.count >= 8 {
            score += 1
        }

        // 包含小写字母
        if password.range(of: "[a-z]", options: .regularExpression) != nil {
            score += 1
        }

        // 包含大写字母
        if password.range(of: "[A-Z]", options: .regularExpression) != nil {
            score += 1
        }

        // 包含数字
        if password.range(of: "\\d", options: .regularExpression) != nil {
            score += 1
        }

        // 包含特殊字符
        if password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil {
            score += 1
        }

        switch score {
        case 0..<2: return .weak
        case 2..<4: return .medium
        default: return .strong
        }
    }

    /// 验证两次密码是否一致
    func isPasswordMatching(_ password: String?, confirmPassword: String?) -> Bool {
        guard let password = password,
              let confirmPassword = confirmPassword,
              !password.isEmpty else {
            return false
        }
        return password == confirmPassword
    }

    /// 获取密码验证错误信息
    func getPasswordError(_ password: String?, confirmPassword: String? = nil) -> String? {
        if isEmpty(password) {
            return "请输入密码"
        }
        if !hasMinLength(password, min: 6) {
            return "密码至少6位"
        }
        if let confirm = confirmPassword, !isPasswordMatching(password, confirmPassword: confirm) {
            return "两次密码不一致"
        }
        return nil
    }

    // MARK: - 用户名验证

    /// 验证用户名（3-20位字母、数字、下划线）
    func isUsernameValid(_ username: String?) -> Bool {
        guard let username = username else { return false }
        return matches(username, regex: usernameRegex)
    }

    /// 获取用户名验证错误信息
    func getUsernameError(_ username: String?) -> String? {
        if isEmpty(username) {
            return "请输入用户名"
        }
        if !isLengthInRange(username, min: 3, max: 20) {
            return "用户名长度为3-20位"
        }
        if !isUsernameValid(username) {
            return "用户名只能包含字母、数字和下划线"
        }
        return nil
    }

    // MARK: - 身份证验证

    /// 验证身份证号
    func isIDCardValid(_ idCard: String?) -> Bool {
        guard let idCard = idCard else { return false }
        guard matches(idCard, regex: idCardRegex) else { return false }
        return validateIDCardChecksum(idCard)
    }

    /// 验证身份证校验码
    private func validateIDCardChecksum(_ idCard: String) -> Bool {
        let weights = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]
        let checksums: [Character] = ["1", "0", "X", "9", "8", "7", "6", "5", "4", "3", "2"]

        var sum = 0
        for i in 0..<17 {
            let index = idCard.index(idCard.startIndex, offsetBy: i)
            if let digit = Int(String(idCard[index])) {
                sum += digit * weights[i]
            }
        }

        let checksum = checksums[sum % 11]
        let lastChar = idCard.last?.uppercased() ?? ""
        return lastChar == String(checksum)
    }

    /// 获取身份证验证错误信息
    func getIDCardError(_ idCard: String?) -> String? {
        if isEmpty(idCard) {
            return "请输入身份证号"
        }
        if !isIDCardValid(idCard) {
            return "身份证号格式不正确"
        }
        return nil
    }

    // MARK: - URL验证

    /// 验证URL
    func isUrlValid(_ url: String?) -> Bool {
        guard let url = url else { return false }
        return matches(url, regex: urlRegex)
    }

    /// 获取URL验证错误信息
    func getUrlError(_ url: String?) -> String? {
        if isEmpty(url) {
            return "请输入URL"
        }
        if !isUrlValid(url) {
            return "URL格式不正确"
        }
        return nil
    }

    // MARK: - 数字验证

    /// 验证是否为数字
    func isNumeric(_ text: String?) -> Bool {
        guard let text = text else { return false }
        return matches(text, regex: "^\\d+$")
    }

    /// 验证是否为小数
    func isDecimal(_ text: String?) -> Bool {
        guard let text = text else { return false }
        return matches(text, regex: "^\\d+(\\.\\d+)?$")
    }

    /// 验证数值范围
    func isNumberInRange(_ number: Double?, min: Double, max: Double) -> Bool {
        guard let number = number else { return false }
        return number >= min && number <= max
    }

    // MARK: - 中文验证

    /// 验证是否为中文
    func isChinese(_ text: String?) -> Bool {
        guard let text = text else { return false }
        return matches(text, regex: chineseRegex)
    }

    /// 验证真实姓名（2-20位中文）
    func isRealNameValid(_ name: String?) -> Bool {
        return isChinese(name) && isLengthInRange(name, min: 2, max: 20)
    }

    /// 获取真实姓名验证错误信息
    func getRealNameError(_ name: String?) -> String? {
        if isEmpty(name) {
            return "请输入姓名"
        }
        if !isChinese(name) {
            return "姓名只能为中文"
        }
        if !isLengthInRange(name, min: 2, max: 20) {
            return "姓名长度为2-20位"
        }
        return nil
    }

    // MARK: - 银行卡验证

    /// 验证银行卡号（Luhn算法）
    func isBankCardValid(_ cardNumber: String?) -> Bool {
        guard let cardNumber = cardNumber,
              isNumeric(cardNumber),
              cardNumber.count >= 12,
              cardNumber.count <= 19 else {
            return false
        }

        var sum = 0
        var shouldDouble = false

        for char in cardNumber.reversed() {
            guard var digit = Int(String(char)) else { return false }

            if shouldDouble {
                digit *= 2
                if digit > 9 {
                    digit -= 9
                }
            }

            sum += digit
            shouldDouble = !shouldDouble
        }

        return sum % 10 == 0
    }

    /// 获取银行卡验证错误信息
    func getBankCardError(_ cardNumber: String?) -> String? {
        if isEmpty(cardNumber) {
            return "请输入银行卡号"
        }
        if !isNumeric(cardNumber) {
            return "银行卡号只能为数字"
        }
        if !isBankCardValid(cardNumber) {
            return "银行卡号格式不正确"
        }
        return nil
    }

    // MARK: - 验证码验证

    /// 验证验证码（通常为4-6位数字）
    func isVerificationCodeValid(_ code: String?, length: Int = 6) -> Bool {
        return isNumeric(code) && code?.count == length
    }

    /// 获取验证码验证错误信息
    func getVerificationCodeError(_ code: String?, length: Int = 6) -> String? {
        if isEmpty(code) {
            return "请输入验证码"
        }
        if code?.count != length {
            return "验证码为\(length)位数字"
        }
        if !isNumeric(code) {
            return "验证码只能为数字"
        }
        return nil
    }

    // MARK: - 综合表单验证

    /// 验证结果
    struct ValidationResult {
        let isValid: Bool
        let errors: [String: String]

        func getError(_ field: String) -> String? {
            return errors[field]
        }

        func hasError(_ field: String) -> Bool {
            return errors[field] != nil
        }

        func getAllErrors() -> [String] {
            return Array(errors.values)
        }
    }

    /// 验证登录表单
    func validateLoginForm(phone: String?, password: String?) -> ValidationResult {
        var errors: [String: String] = [:]

        if let error = getPhoneError(phone) {
            errors["phone"] = error
        }
        if let error = getPasswordError(password) {
            errors["password"] = error
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    /// 验证注册表单
    func validateRegisterForm(
        phone: String?,
        password: String?,
        confirmPassword: String?,
        code: String?
    ) -> ValidationResult {
        var errors: [String: String] = [:]

        if let error = getPhoneError(phone) {
            errors["phone"] = error
        }
        if let error = getPasswordError(password, confirmPassword: confirmPassword) {
            errors["password"] = error
        }
        if let error = getVerificationCodeError(code) {
            errors["code"] = error
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    // MARK: - 辅助方法

    /// 正则匹配
    private func matches(_ text: String, regex: String) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: text)
    }
}

// MARK: - String扩展

extension String {
    /// 验证手机号
    var isValidPhone: Bool {
        return ValidationHelper.shared.isPhoneValid(self)
    }

    /// 验证邮箱
    var isValidEmail: Bool {
        return ValidationHelper.shared.isEmailValid(self)
    }

    /// 验证密码
    var isValidPassword: Bool {
        return ValidationHelper.shared.isSimplePasswordValid(self)
    }

    /// 验证URL
    var isValidUrl: Bool {
        return ValidationHelper.shared.isUrlValid(self)
    }

    /// 验证数字
    var isNumeric: Bool {
        return ValidationHelper.shared.isNumeric(self)
    }

    /// 验证中文
    var isChinese: Bool {
        return ValidationHelper.shared.isChinese(self)
    }
}

// MARK: - 全局便捷函数

/// 验证手机号
func isValidPhone(_ phone: String?) -> Bool {
    return ValidationHelper.shared.isPhoneValid(phone)
}

/// 验证邮箱
func isValidEmail(_ email: String?) -> Bool {
    return ValidationHelper.shared.isEmailValid(email)
}

/// 验证密码
func isValidPassword(_ password: String?) -> Bool {
    return ValidationHelper.shared.isSimplePasswordValid(password)
}
