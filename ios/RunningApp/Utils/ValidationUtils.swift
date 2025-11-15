import Foundation

// MARK: - 验证工具类
class ValidationUtils {

    // MARK: - 手机号验证
    static func isValidPhone(_ phone: String) -> Bool {
        let pattern = "^1[3-9]\\d{9}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: phone.utf16.count)
        return regex?.firstMatch(in: phone, range: range) != nil
    }

    // MARK: - 密码验证（6-20位）
    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6 && password.count <= 20
    }

    // MARK: - 强密码验证（包含字母和数字）
    static func isValidStrongPassword(_ password: String) -> Bool {
        guard isValidPassword(password) else { return false }

        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasDigit = password.rangeOfCharacter(from: .decimalDigits) != nil

        return hasLetter && hasDigit
    }

    // MARK: - 验证码验证（6位数字）
    static func isValidCode(_ code: String) -> Bool {
        let pattern = "^\\d{6}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: code.utf16.count)
        return regex?.firstMatch(in: code, range: range) != nil
    }

    // MARK: - 邮箱验证
    static func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[a-zA-Z0-9_+&*-]+(?:\\.[a-zA-Z0-9_+&*-]+)*@(?:[a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,7}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: email.utf16.count)
        return regex?.firstMatch(in: email, range: range) != nil
    }

    // MARK: - 昵称验证（2-20个字符）
    static func isValidNickname(_ nickname: String) -> Bool {
        return nickname.count >= 2 && nickname.count <= 20
    }

    // MARK: - URL验证
    static func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    // MARK: - 身份证号验证
    static func isValidIdCard(_ idCard: String) -> Bool {
        guard idCard.count == 18 else { return false }

        let pattern = "^[1-9]\\d{5}(18|19|20)\\d{2}((0[1-9])|(1[0-2]))(([0-2][1-9])|10|20|30|31)\\d{3}[0-9Xx]$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: idCard.utf16.count)

        guard regex?.firstMatch(in: idCard, range: range) != nil else {
            return false
        }

        // 验证校验码
        let factors = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]
        let parity = ["1", "0", "X", "9", "8", "7", "6", "5", "4", "3", "2"]

        var sum = 0
        let idArray = Array(idCard)

        for i in 0..<17 {
            if let digit = Int(String(idArray[i])) {
                sum += digit * factors[i]
            }
        }

        let checkCode = parity[sum % 11]
        let lastChar = String(idArray[17]).uppercased()

        return lastChar == checkCode
    }

    // MARK: - 密码强度检查
    /// - Returns: 0-弱, 1-中, 2-强
    static func getPasswordStrength(_ password: String) -> Int {
        guard password.count >= 6 else { return 0 }

        var strength = 0

        // 包含小写字母
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil {
            strength += 1
        }

        // 包含大写字母
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil {
            strength += 1
        }

        // 包含数字
        if password.rangeOfCharacter(from: .decimalDigits) != nil {
            strength += 1
        }

        // 包含特殊字符
        let specialCharacterSet = CharacterSet.alphanumerics.inverted
        if password.rangeOfCharacter(from: specialCharacterSet) != nil {
            strength += 1
        }

        // 长度 >= 12
        if password.count >= 12 {
            strength += 1
        }

        switch strength {
        case 0...2:
            return 0 // 弱
        case 3:
            return 1 // 中
        default:
            return 2 // 强
        }
    }

    // MARK: - 长度范围验证
    static func isLengthInRange(_ string: String, min: Int, max: Int) -> Bool {
        return string.count >= min && string.count <= max
    }

    // MARK: - 纯数字验证
    static func isNumeric(_ string: String) -> Bool {
        return !string.isEmpty && string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }

    // MARK: - 整数验证
    static func isInteger(_ string: String) -> Bool {
        return Int(string) != nil
    }

    // MARK: - 浮点数验证
    static func isFloat(_ string: String) -> Bool {
        return Float(string) != nil
    }

    // MARK: - 纯中文验证
    static func isChinese(_ string: String) -> Bool {
        let pattern = "^[\\u4e00-\\u9fa5]+$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: string.utf16.count)
        return regex?.firstMatch(in: string, range: range) != nil
    }

    // MARK: - 两次输入一致性验证
    static func isMatching(_ first: String, _ second: String) -> Bool {
        return first == second && !first.isEmpty
    }
}
