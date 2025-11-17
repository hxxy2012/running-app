package com.runningapp.utils

import android.util.Patterns
import java.util.regex.Pattern
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 数据验证工具类
 * 提供各种常用的数据验证功能
 */
@Singleton
class ValidationHelper @Inject constructor() {

    companion object {
        // 正则表达式
        private val PHONE_PATTERN = Pattern.compile("^1[3-9]\\d{9}$")
        private val PASSWORD_PATTERN = Pattern.compile("^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)[a-zA-Z\\d@$!%*?&]{8,}$")
        private val USERNAME_PATTERN = Pattern.compile("^[a-zA-Z0-9_]{3,20}$")
        private val ID_CARD_PATTERN = Pattern.compile("^[1-9]\\d{5}(19|20)\\d{2}((0[1-9])|(1[0-2]))(([0-2][1-9])|10|20|30|31)\\d{3}[0-9Xx]$")
        private val CHINESE_PATTERN = Pattern.compile("^[\\u4e00-\\u9fa5]+$")
        private val URL_PATTERN = Patterns.WEB_URL
    }

    // MARK: - 基础验证

    /**
     * 验证是否为空
     */
    fun isEmpty(text: String?): Boolean {
        return text.isNullOrEmpty()
    }

    /**
     * 验证是否非空
     */
    fun isNotEmpty(text: String?): Boolean {
        return !isEmpty(text)
    }

    /**
     * 验证长度范围
     */
    fun isLengthInRange(text: String?, min: Int, max: Int): Boolean {
        if (text == null) return false
        return text.length in min..max
    }

    /**
     * 验证最小长度
     */
    fun hasMinLength(text: String?, min: Int): Boolean {
        if (text == null) return false
        return text.length >= min
    }

    /**
     * 验证最大长度
     */
    fun hasMaxLength(text: String?, max: Int): Boolean {
        if (text == null) return false
        return text.length <= max
    }

    // MARK: - 手机号验证

    /**
     * 验证手机号
     */
    fun isPhoneValid(phone: String?): Boolean {
        if (phone == null) return false
        return PHONE_PATTERN.matcher(phone).matches()
    }

    /**
     * 获取手机号验证错误信息
     */
    fun getPhoneError(phone: String?): String? {
        return when {
            isEmpty(phone) -> "请输入手机号"
            !isPhoneValid(phone) -> "手机号格式不正确"
            else -> null
        }
    }

    // MARK: - 邮箱验证

    /**
     * 验证邮箱
     */
    fun isEmailValid(email: String?): Boolean {
        if (email == null) return false
        return Patterns.EMAIL_ADDRESS.matcher(email).matches()
    }

    /**
     * 获取邮箱验证错误信息
     */
    fun getEmailError(email: String?): String? {
        return when {
            isEmpty(email) -> "请输入邮箱"
            !isEmailValid(email) -> "邮箱格式不正确"
            else -> null
        }
    }

    // MARK: - 密码验证

    /**
     * 验证密码（至少8位，包含大小写字母和数字）
     */
    fun isPasswordValid(password: String?): Boolean {
        if (password == null) return false
        return PASSWORD_PATTERN.matcher(password).matches()
    }

    /**
     * 验证简单密码（至少6位）
     */
    fun isSimplePasswordValid(password: String?): Boolean {
        return hasMinLength(password, 6)
    }

    /**
     * 验证密码强度
     */
    fun getPasswordStrength(password: String?): PasswordStrength {
        if (password.isNullOrEmpty()) return PasswordStrength.EMPTY

        var score = 0

        // 长度检查
        when {
            password.length >= 12 -> score += 2
            password.length >= 8 -> score += 1
        }

        // 包含小写字母
        if (password.contains(Regex("[a-z]"))) score++

        // 包含大写字母
        if (password.contains(Regex("[A-Z]"))) score++

        // 包含数字
        if (password.contains(Regex("\\d"))) score++

        // 包含特殊字符
        if (password.contains(Regex("[!@#$%^&*(),.?\":{}|<>]"))) score++

        return when {
            score < 2 -> PasswordStrength.WEAK
            score < 4 -> PasswordStrength.MEDIUM
            else -> PasswordStrength.STRONG
        }
    }

    /**
     * 验证两次密码是否一致
     */
    fun isPasswordMatching(password: String?, confirmPassword: String?): Boolean {
        return password == confirmPassword && !password.isNullOrEmpty()
    }

    /**
     * 获取密码验证错误信息
     */
    fun getPasswordError(password: String?, confirmPassword: String? = null): String? {
        return when {
            isEmpty(password) -> "请输入密码"
            !hasMinLength(password, 6) -> "密码至少6位"
            confirmPassword != null && !isPasswordMatching(password, confirmPassword) -> "两次密码不一致"
            else -> null
        }
    }

    enum class PasswordStrength {
        EMPTY, WEAK, MEDIUM, STRONG
    }

    // MARK: - 用户名验证

    /**
     * 验证用户名（3-20位字母、数字、下划线）
     */
    fun isUsernameValid(username: String?): Boolean {
        if (username == null) return false
        return USERNAME_PATTERN.matcher(username).matches()
    }

    /**
     * 获取用户名验证错误信息
     */
    fun getUsernameError(username: String?): String? {
        return when {
            isEmpty(username) -> "请输入用户名"
            !isLengthInRange(username, 3, 20) -> "用户名长度为3-20位"
            !isUsernameValid(username) -> "用户名只能包含字母、数字和下划线"
            else -> null
        }
    }

    // MARK: - 身份证验证

    /**
     * 验证身份证号
     */
    fun isIDCardValid(idCard: String?): Boolean {
        if (idCard == null) return false
        if (!ID_CARD_PATTERN.matcher(idCard).matches()) return false

        // 校验码验证
        return validateIDCardChecksum(idCard)
    }

    /**
     * 验证身份证校验码
     */
    private fun validateIDCardChecksum(idCard: String): Boolean {
        val weights = intArrayOf(7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2)
        val checksums = charArrayOf('1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2')

        var sum = 0
        for (i in 0 until 17) {
            sum += (idCard[i] - '0') * weights[i]
        }

        val checksum = checksums[sum % 11]
        return idCard[17].uppercaseChar() == checksum
    }

    /**
     * 获取身份证验证错误信息
     */
    fun getIDCardError(idCard: String?): String? {
        return when {
            isEmpty(idCard) -> "请输入身份证号"
            !isIDCardValid(idCard) -> "身份证号格式不正确"
            else -> null
        }
    }

    // MARK: - URL验证

    /**
     * 验证URL
     */
    fun isUrlValid(url: String?): Boolean {
        if (url == null) return false
        return URL_PATTERN.matcher(url).matches()
    }

    /**
     * 获取URL验证错误信息
     */
    fun getUrlError(url: String?): String? {
        return when {
            isEmpty(url) -> "请输入URL"
            !isUrlValid(url) -> "URL格式不正确"
            else -> null
        }
    }

    // MARK: - 数字验证

    /**
     * 验证是否为数字
     */
    fun isNumeric(text: String?): Boolean {
        if (text == null) return false
        return text.matches(Regex("^\\d+$"))
    }

    /**
     * 验证是否为小数
     */
    fun isDecimal(text: String?): Boolean {
        if (text == null) return false
        return text.matches(Regex("^\\d+(\\.\\d+)?$"))
    }

    /**
     * 验证数值范围
     */
    fun isNumberInRange(number: Double?, min: Double, max: Double): Boolean {
        if (number == null) return false
        return number in min..max
    }

    // MARK: - 中文验证

    /**
     * 验证是否为中文
     */
    fun isChinese(text: String?): Boolean {
        if (text == null) return false
        return CHINESE_PATTERN.matcher(text).matches()
    }

    /**
     * 验证真实姓名（2-20位中文）
     */
    fun isRealNameValid(name: String?): Boolean {
        return isChinese(name) && isLengthInRange(name, 2, 20)
    }

    /**
     * 获取真实姓名验证错误信息
     */
    fun getRealNameError(name: String?): String? {
        return when {
            isEmpty(name) -> "请输入姓名"
            !isChinese(name) -> "姓名只能为中文"
            !isLengthInRange(name, 2, 20) -> "姓名长度为2-20位"
            else -> null
        }
    }

    // MARK: - 银行卡验证

    /**
     * 验证银行卡号（Luhn算法）
     */
    fun isBankCardValid(cardNumber: String?): Boolean {
        if (cardNumber == null || !isNumeric(cardNumber)) return false
        if (cardNumber.length < 12 || cardNumber.length > 19) return false

        var sum = 0
        var shouldDouble = false

        for (i in cardNumber.length - 1 downTo 0) {
            var digit = cardNumber[i] - '0'

            if (shouldDouble) {
                digit *= 2
                if (digit > 9) digit -= 9
            }

            sum += digit
            shouldDouble = !shouldDouble
        }

        return sum % 10 == 0
    }

    /**
     * 获取银行卡验证错误信息
     */
    fun getBankCardError(cardNumber: String?): String? {
        return when {
            isEmpty(cardNumber) -> "请输入银行卡号"
            !isNumeric(cardNumber) -> "银行卡号只能为数字"
            !isBankCardValid(cardNumber) -> "银行卡号格式不正确"
            else -> null
        }
    }

    // MARK: - 验证码验证

    /**
     * 验证验证码（通常为4-6位数字）
     */
    fun isVerificationCodeValid(code: String?, length: Int = 6): Boolean {
        return isNumeric(code) && code?.length == length
    }

    /**
     * 获取验证码验证错误信息
     */
    fun getVerificationCodeError(code: String?, length: Int = 6): String? {
        return when {
            isEmpty(code) -> "请输入验证码"
            code?.length != length -> "验证码为${length}位数字"
            !isNumeric(code) -> "验证码只能为数字"
            else -> null
        }
    }

    // MARK: - 综合表单验证

    /**
     * 验证结果
     */
    data class ValidationResult(
        val isValid: Boolean,
        val errors: Map<String, String> = emptyMap()
    ) {
        fun getError(field: String): String? = errors[field]

        fun hasError(field: String): Boolean = errors.containsKey(field)

        fun getAllErrors(): List<String> = errors.values.toList()
    }

    /**
     * 验证登录表单
     */
    fun validateLoginForm(phone: String?, password: String?): ValidationResult {
        val errors = mutableMapOf<String, String>()

        getPhoneError(phone)?.let { errors["phone"] = it }
        getPasswordError(password)?.let { errors["password"] = it }

        return ValidationResult(errors.isEmpty(), errors)
    }

    /**
     * 验证注册表单
     */
    fun validateRegisterForm(
        phone: String?,
        password: String?,
        confirmPassword: String?,
        code: String?
    ): ValidationResult {
        val errors = mutableMapOf<String, String>()

        getPhoneError(phone)?.let { errors["phone"] = it }
        getPasswordError(password, confirmPassword)?.let { errors["password"] = it }
        getVerificationCodeError(code)?.let { errors["code"] = it }

        return ValidationResult(errors.isEmpty(), errors)
    }
}

/**
 * 扩展函数：字符串验证
 */
fun String?.isValidPhone(): Boolean = ValidationHelper().isPhoneValid(this)
fun String?.isValidEmail(): Boolean = ValidationHelper().isEmailValid(this)
fun String?.isValidPassword(): Boolean = ValidationHelper().isSimplePasswordValid(this)
fun String?.isValidUrl(): Boolean = ValidationHelper().isUrlValid(this)
