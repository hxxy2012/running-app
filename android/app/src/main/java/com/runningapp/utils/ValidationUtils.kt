package com.runningapp.utils

import java.util.regex.Pattern

/**
 * 表单验证工具类
 */
object ValidationUtils {

    /**
     * 验证手机号
     */
    fun isValidPhone(phone: String): Boolean {
        if (phone.isEmpty()) return false
        val pattern = Pattern.compile("^1[3-9]\\d{9}$")
        return pattern.matcher(phone).matches()
    }

    /**
     * 验证密码（6-20位，包含字母和数字）
     */
    fun isValidPassword(password: String): Boolean {
        if (password.length < 6 || password.length > 20) return false
        // 必须包含字母和数字
        val hasLetter = password.any { it.isLetter() }
        val hasDigit = password.any { it.isDigit() }
        return hasLetter && hasDigit
    }

    /**
     * 验证弱密码（仅长度要求）
     */
    fun isValidPasswordWeak(password: String): Boolean {
        return password.length in 6..20
    }

    /**
     * 验证验证码（6位数字）
     */
    fun isValidCode(code: String): Boolean {
        if (code.length != 6) return false
        return code.all { it.isDigit() }
    }

    /**
     * 验证邮箱
     */
    fun isValidEmail(email: String): Boolean {
        if (email.isEmpty()) return false
        val pattern = Pattern.compile(
            "^[a-zA-Z0-9_+&*-]+(?:\\.[a-zA-Z0-9_+&*-]+)*@" +
                    "(?:[a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,7}$"
        )
        return pattern.matcher(email).matches()
    }

    /**
     * 验证昵称（2-20个字符，不含特殊符号）
     */
    fun isValidNickname(nickname: String): Boolean {
        if (nickname.length < 2 || nickname.length > 20) return false
        val pattern = Pattern.compile("^[\\u4e00-\\u9fa5a-zA-Z0-9_]+$")
        return pattern.matcher(nickname).matches()
    }

    /**
     * 验证身份证号
     */
    fun isValidIdCard(idCard: String): Boolean {
        if (idCard.length != 18) return false
        val pattern = Pattern.compile("^[1-9]\\d{5}(18|19|20)\\d{2}((0[1-9])|(1[0-2]))(([0-2][1-9])|10|20|30|31)\\d{3}[0-9Xx]$")
        if (!pattern.matcher(idCard).matches()) return false

        // 验证校验码
        val factors = intArrayOf(7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2)
        val parity = charArrayOf('1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2')

        var sum = 0
        for (i in 0..16) {
            sum += (idCard[i] - '0') * factors[i]
        }

        val checkCode = parity[sum % 11]
        return idCard[17].uppercaseChar() == checkCode
    }

    /**
     * 验证URL
     */
    fun isValidUrl(url: String): Boolean {
        if (url.isEmpty()) return false
        val pattern = Pattern.compile(
            "^(https?|ftp)://[^\\s/$.?#].[^\\s]*$",
            Pattern.CASE_INSENSITIVE
        )
        return pattern.matcher(url).matches()
    }

    /**
     * 验证是否为纯数字
     */
    fun isNumeric(str: String): Boolean {
        return str.isNotEmpty() && str.all { it.isDigit() }
    }

    /**
     * 验证是否为整数（包含负数）
     */
    fun isInteger(str: String): Boolean {
        return try {
            str.toInt()
            true
        } catch (e: NumberFormatException) {
            false
        }
    }

    /**
     * 验证是否为浮点数
     */
    fun isFloat(str: String): Boolean {
        return try {
            str.toFloat()
            true
        } catch (e: NumberFormatException) {
            false
        }
    }

    /**
     * 验证字符串长度范围
     */
    fun isLengthInRange(str: String, min: Int, max: Int): Boolean {
        return str.length in min..max
    }

    /**
     * 验证是否为中文
     */
    fun isChinese(str: String): Boolean {
        val pattern = Pattern.compile("^[\\u4e00-\\u9fa5]+$")
        return pattern.matcher(str).matches()
    }

    /**
     * 密码强度检查
     * @return 0-弱, 1-中, 2-强
     */
    fun getPasswordStrength(password: String): Int {
        if (password.length < 6) return 0

        var strength = 0

        // 包含小写字母
        if (password.any { it.isLowerCase() }) strength++

        // 包含大写字母
        if (password.any { it.isUpperCase() }) strength++

        // 包含数字
        if (password.any { it.isDigit() }) strength++

        // 包含特殊字符
        if (password.any { !it.isLetterOrDigit() }) strength++

        // 长度 >= 12
        if (password.length >= 12) strength++

        return when {
            strength <= 2 -> 0 // 弱
            strength == 3 -> 1 // 中
            else -> 2 // 强
        }
    }

    /**
     * 验证两次输入是否一致
     */
    fun isMatching(first: String, second: String): Boolean {
        return first == second && first.isNotEmpty()
    }
}
