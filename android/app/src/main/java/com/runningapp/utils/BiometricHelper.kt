package com.runningapp.utils

import android.content.Context
import android.os.Build
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 生物识别助手
 * 支持指纹识别和面部识别
 */
@Singleton
class BiometricHelper @Inject constructor(
    @ApplicationContext private val context: Context
) {

    companion object {
        // 认证器类型
        const val AUTHENTICATORS_BIOMETRIC_STRONG = BiometricManager.Authenticators.BIOMETRIC_STRONG
        const val AUTHENTICATORS_BIOMETRIC_WEAK = BiometricManager.Authenticators.BIOMETRIC_WEAK
        const val AUTHENTICATORS_DEVICE_CREDENTIAL = BiometricManager.Authenticators.DEVICE_CREDENTIAL
    }

    /**
     * 生物识别可用性状态
     */
    enum class BiometricAvailability {
        AVAILABLE,                  // 可用
        NO_HARDWARE,               // 无硬件支持
        HARDWARE_UNAVAILABLE,      // 硬件不可用
        NONE_ENROLLED,            // 未注册生物特征
        SECURITY_UPDATE_REQUIRED, // 需要安全更新
        UNSUPPORTED,              // 不支持
        STATUS_UNKNOWN            // 未知状态
    }

    /**
     * 认证结果
     */
    sealed class AuthenticationResult {
        object Success : AuthenticationResult()
        data class Error(val errorCode: Int, val errorMessage: String) : AuthenticationResult()
        object Failed : AuthenticationResult()
        object Cancelled : AuthenticationResult()
    }

    // MARK: - 可用性检查

    /**
     * 检查生物识别是否可用
     */
    fun checkBiometricAvailability(): BiometricAvailability {
        val biometricManager = BiometricManager.from(context)
        return when (biometricManager.canAuthenticate(AUTHENTICATORS_BIOMETRIC_STRONG)) {
            BiometricManager.BIOMETRIC_SUCCESS ->
                BiometricAvailability.AVAILABLE

            BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE ->
                BiometricAvailability.NO_HARDWARE

            BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE ->
                BiometricAvailability.HARDWARE_UNAVAILABLE

            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED ->
                BiometricAvailability.NONE_ENROLLED

            BiometricManager.BIOMETRIC_ERROR_SECURITY_UPDATE_REQUIRED ->
                BiometricAvailability.SECURITY_UPDATE_REQUIRED

            BiometricManager.BIOMETRIC_ERROR_UNSUPPORTED ->
                BiometricAvailability.UNSUPPORTED

            BiometricManager.BIOMETRIC_STATUS_UNKNOWN ->
                BiometricAvailability.STATUS_UNKNOWN

            else -> BiometricAvailability.STATUS_UNKNOWN
        }
    }

    /**
     * 检查弱生物识别是否可用（包括面部识别）
     */
    fun checkWeakBiometricAvailability(): BiometricAvailability {
        val biometricManager = BiometricManager.from(context)
        return when (biometricManager.canAuthenticate(AUTHENTICATORS_BIOMETRIC_WEAK)) {
            BiometricManager.BIOMETRIC_SUCCESS ->
                BiometricAvailability.AVAILABLE

            BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE ->
                BiometricAvailability.NO_HARDWARE

            BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE ->
                BiometricAvailability.HARDWARE_UNAVAILABLE

            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED ->
                BiometricAvailability.NONE_ENROLLED

            BiometricManager.BIOMETRIC_ERROR_SECURITY_UPDATE_REQUIRED ->
                BiometricAvailability.SECURITY_UPDATE_REQUIRED

            BiometricManager.BIOMETRIC_ERROR_UNSUPPORTED ->
                BiometricAvailability.UNSUPPORTED

            BiometricManager.BIOMETRIC_STATUS_UNKNOWN ->
                BiometricAvailability.STATUS_UNKNOWN

            else -> BiometricAvailability.STATUS_UNKNOWN
        }
    }

    /**
     * 是否支持生物识别
     */
    fun isBiometricAvailable(): Boolean {
        return checkBiometricAvailability() == BiometricAvailability.AVAILABLE
    }

    /**
     * 是否已注册生物特征
     */
    fun hasBiometricEnrolled(): Boolean {
        val availability = checkBiometricAvailability()
        return availability == BiometricAvailability.AVAILABLE
    }

    // MARK: - 认证

    /**
     * 显示生物识别认证对话框
     * @param activity FragmentActivity
     * @param title 标题
     * @param subtitle 副标题
     * @param description 描述
     * @param negativeButtonText 取消按钮文本
     * @param allowDeviceCredential 是否允许设备凭据（PIN/图案/密码）
     * @param callback 认证结果回调
     */
    fun authenticate(
        activity: FragmentActivity,
        title: String = "生物识别验证",
        subtitle: String? = "请验证以继续",
        description: String? = null,
        negativeButtonText: String = "取消",
        allowDeviceCredential: Boolean = false,
        callback: (AuthenticationResult) -> Unit
    ) {
        val executor = ContextCompat.getMainExecutor(activity)

        val authCallback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                super.onAuthenticationError(errorCode, errString)
                Logger.e("BiometricHelper", "Authentication error: $errorCode - $errString")

                when (errorCode) {
                    BiometricPrompt.ERROR_NEGATIVE_BUTTON,
                    BiometricPrompt.ERROR_USER_CANCELED,
                    BiometricPrompt.ERROR_CANCELED -> {
                        callback(AuthenticationResult.Cancelled)
                    }
                    else -> {
                        callback(AuthenticationResult.Error(errorCode, errString.toString()))
                    }
                }
            }

            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                super.onAuthenticationSucceeded(result)
                Logger.d("BiometricHelper", "Authentication succeeded")
                callback(AuthenticationResult.Success)
            }

            override fun onAuthenticationFailed() {
                super.onAuthenticationFailed()
                Logger.w("BiometricHelper", "Authentication failed")
                callback(AuthenticationResult.Failed)
            }
        }

        val biometricPrompt = BiometricPrompt(activity, executor, authCallback)

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle(title)
            .apply {
                subtitle?.let { setSubtitle(it) }
                description?.let { setDescription(it) }
            }
            .apply {
                if (allowDeviceCredential && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    setAllowedAuthenticators(
                        AUTHENTICATORS_BIOMETRIC_STRONG or AUTHENTICATORS_DEVICE_CREDENTIAL
                    )
                } else if (allowDeviceCredential && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    @Suppress("DEPRECATION")
                    setDeviceCredentialAllowed(true)
                } else {
                    setNegativeButtonText(negativeButtonText)
                }
            }
            .build()

        biometricPrompt.authenticate(promptInfo)
    }

    /**
     * 快速认证（使用默认配置）
     */
    fun quickAuthenticate(
        activity: FragmentActivity,
        onSuccess: () -> Unit,
        onError: (String) -> Unit,
        onCancelled: () -> Unit = {}
    ) {
        authenticate(
            activity = activity,
            title = "身份验证",
            subtitle = "请使用指纹或面部识别",
            callback = { result ->
                when (result) {
                    is AuthenticationResult.Success -> onSuccess()
                    is AuthenticationResult.Error -> onError(result.errorMessage)
                    is AuthenticationResult.Failed -> onError("识别失败，请重试")
                    is AuthenticationResult.Cancelled -> onCancelled()
                }
            }
        )
    }

    // MARK: - 辅助方法

    /**
     * 获取生物识别类型名称
     */
    fun getBiometricTypeName(): String {
        return when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
                val biometricManager = BiometricManager.from(context)
                when (biometricManager.canAuthenticate(AUTHENTICATORS_BIOMETRIC_STRONG)) {
                    BiometricManager.BIOMETRIC_SUCCESS -> "生物识别"
                    else -> "未知"
                }
            }
            else -> "指纹识别"
        }
    }

    /**
     * 获取错误描述
     */
    fun getErrorDescription(errorCode: Int): String {
        return when (errorCode) {
            BiometricPrompt.ERROR_HW_UNAVAILABLE ->
                "生物识别硬件当前不可用"

            BiometricPrompt.ERROR_UNABLE_TO_PROCESS ->
                "无法处理当前请求"

            BiometricPrompt.ERROR_TIMEOUT ->
                "操作超时"

            BiometricPrompt.ERROR_NO_SPACE ->
                "存储空间不足"

            BiometricPrompt.ERROR_CANCELED ->
                "操作已取消"

            BiometricPrompt.ERROR_LOCKOUT ->
                "尝试次数过多，生物识别已锁定"

            BiometricPrompt.ERROR_VENDOR ->
                "设备特定错误"

            BiometricPrompt.ERROR_LOCKOUT_PERMANENT ->
                "尝试次数过多，生物识别已永久锁定"

            BiometricPrompt.ERROR_USER_CANCELED ->
                "用户取消"

            BiometricPrompt.ERROR_NO_BIOMETRICS ->
                "未注册生物特征"

            BiometricPrompt.ERROR_HW_NOT_PRESENT ->
                "设备不支持生物识别"

            BiometricPrompt.ERROR_NEGATIVE_BUTTON ->
                "用户点击取消按钮"

            BiometricPrompt.ERROR_NO_DEVICE_CREDENTIAL ->
                "未设置设备凭据"

            BiometricPrompt.ERROR_SECURITY_UPDATE_REQUIRED ->
                "需要安全更新"

            else -> "未知错误 (代码: $errorCode)"
        }
    }

    /**
     * 获取可用性描述
     */
    fun getAvailabilityDescription(availability: BiometricAvailability): String {
        return when (availability) {
            BiometricAvailability.AVAILABLE ->
                "生物识别可用"

            BiometricAvailability.NO_HARDWARE ->
                "设备不支持生物识别"

            BiometricAvailability.HARDWARE_UNAVAILABLE ->
                "生物识别硬件当前不可用"

            BiometricAvailability.NONE_ENROLLED ->
                "未注册生物特征，请先在系统设置中添加指纹或面部数据"

            BiometricAvailability.SECURITY_UPDATE_REQUIRED ->
                "需要安全更新才能使用生物识别"

            BiometricAvailability.UNSUPPORTED ->
                "当前系统不支持生物识别"

            BiometricAvailability.STATUS_UNKNOWN ->
                "生物识别状态未知"
        }
    }
}

/**
 * 扩展函数：显示生物识别对话框
 */
fun FragmentActivity.showBiometricPrompt(
    title: String = "生物识别验证",
    subtitle: String? = "请验证以继续",
    onSuccess: () -> Unit,
    onError: (String) -> Unit,
    onCancelled: () -> Unit = {}
) {
    val helper = BiometricHelper(applicationContext)
    helper.quickAuthenticate(
        activity = this,
        onSuccess = onSuccess,
        onError = onError,
        onCancelled = onCancelled
    )
}
