package com.runningapp.utils

import android.content.Context
import android.os.Build
import android.provider.Settings
import android.util.DisplayMetrics
import android.view.WindowManager
import dagger.hilt.android.qualifiers.ApplicationContext
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 设备信息助手
 * 获取设备相关信息
 */
@Singleton
class DeviceHelper @Inject constructor(
    @ApplicationContext private val context: Context
) {

    // MARK: - 设备基本信息

    /**
     * 获取设备唯一ID
     */
    @Suppress("HardwareIds")
    fun getDeviceId(): String {
        return Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
    }

    /**
     * 获取设备制造商
     */
    fun getManufacturer(): String {
        return Build.MANUFACTURER
    }

    /**
     * 获取设备品牌
     */
    fun getBrand(): String {
        return Build.BRAND
    }

    /**
     * 获取设备型号
     */
    fun getModel(): String {
        return Build.MODEL
    }

    /**
     * 获取设备名称
     */
    fun getDeviceName(): String {
        return "${Build.MANUFACTURER} ${Build.MODEL}"
    }

    /**
     * 获取产品名称
     */
    fun getProduct(): String {
        return Build.PRODUCT
    }

    // MARK: - 系统信息

    /**
     * 获取Android版本号
     */
    fun getAndroidVersion(): String {
        return Build.VERSION.RELEASE
    }

    /**
     * 获取SDK版本号
     */
    fun getSdkVersion(): Int {
        return Build.VERSION.SDK_INT
    }

    /**
     * 获取系统版本代号
     */
    fun getVersionCodename(): String {
        return Build.VERSION.CODENAME
    }

    /**
     * 获取构建版本
     */
    fun getBuildNumber(): String {
        return Build.DISPLAY
    }

    // MARK: - 屏幕信息

    /**
     * 获取屏幕宽度（像素）
     */
    fun getScreenWidth(): Int {
        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val metrics = DisplayMetrics()
        wm.defaultDisplay.getMetrics(metrics)
        return metrics.widthPixels
    }

    /**
     * 获取屏幕高度（像素）
     */
    fun getScreenHeight(): Int {
        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val metrics = DisplayMetrics()
        wm.defaultDisplay.getMetrics(metrics)
        return metrics.heightPixels
    }

    /**
     * 获取屏幕密度
     */
    fun getScreenDensity(): Float {
        val metrics = context.resources.displayMetrics
        return metrics.density
    }

    /**
     * 获取屏幕DPI
     */
    fun getScreenDpi(): Int {
        val metrics = context.resources.displayMetrics
        return metrics.densityDpi
    }

    /**
     * 获取屏幕信息描述
     */
    fun getScreenInfo(): String {
        return "${getScreenWidth()}x${getScreenHeight()} @${getScreenDpi()}dpi"
    }

    // MARK: - 语言和地区

    /**
     * 获取系统语言
     */
    fun getLanguage(): String {
        return Locale.getDefault().language
    }

    /**
     * 获取系统国家/地区
     */
    fun getCountry(): String {
        return Locale.getDefault().country
    }

    /**
     * 获取完整语言环境
     */
    fun getLocale(): String {
        return Locale.getDefault().toString()
    }

    // MARK: - 硬件信息

    /**
     * 获取CPU架构
     */
    fun getCpuAbi(): String {
        return Build.SUPPORTED_ABIS.joinToString(", ")
    }

    /**
     * 获取主CPU架构
     */
    fun getPrimaryCpuAbi(): String {
        return Build.SUPPORTED_ABIS.firstOrNull() ?: "unknown"
    }

    /**
     * 获取硬件名称
     */
    fun getHardware(): String {
        return Build.HARDWARE
    }

    /**
     * 获取主板信息
     */
    fun getBoard(): String {
        return Build.BOARD
    }

    // MARK: - 应用信息

    /**
     * 获取应用包名
     */
    fun getPackageName(): String {
        return context.packageName
    }

    /**
     * 获取应用版本名
     */
    fun getVersionName(): String {
        return try {
            val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
            packageInfo.versionName ?: "unknown"
        } catch (e: Exception) {
            "unknown"
        }
    }

    /**
     * 获取应用版本号
     */
    fun getVersionCode(): Long {
        return try {
            val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageInfo.longVersionCode
            } else {
                @Suppress("DEPRECATION")
                packageInfo.versionCode.toLong()
            }
        } catch (e: Exception) {
            0L
        }
    }

    // MARK: - 综合信息

    /**
     * 获取设备完整信息
     */
    fun getDeviceInfo(): Map<String, String> {
        return mapOf(
            "deviceId" to getDeviceId(),
            "manufacturer" to getManufacturer(),
            "brand" to getBrand(),
            "model" to getModel(),
            "product" to getProduct(),
            "androidVersion" to getAndroidVersion(),
            "sdkVersion" to getSdkVersion().toString(),
            "buildNumber" to getBuildNumber(),
            "screenInfo" to getScreenInfo(),
            "language" to getLanguage(),
            "country" to getCountry(),
            "locale" to getLocale(),
            "cpuAbi" to getCpuAbi(),
            "hardware" to getHardware(),
            "packageName" to getPackageName(),
            "versionName" to getVersionName(),
            "versionCode" to getVersionCode().toString()
        )
    }

    /**
     * 获取设备信息JSON字符串
     */
    fun getDeviceInfoJson(): String {
        val info = getDeviceInfo()
        return info.entries.joinToString(",\n", "{\n", "\n}") { (key, value) ->
            "  \"$key\": \"$value\""
        }
    }

    /**
     * 获取User-Agent字符串
     */
    fun getUserAgent(): String {
        return "RunningApp/${getVersionName()} " +
                "(Android ${getAndroidVersion()}; ${getDeviceName()})"
    }

    // MARK: - 辅助判断

    /**
     * 是否为平板
     */
    fun isTablet(): Boolean {
        val screenLayout = context.resources.configuration.screenLayout
        val screenSize = screenLayout and android.content.res.Configuration.SCREENLAYOUT_SIZE_MASK
        return screenSize >= android.content.res.Configuration.SCREENLAYOUT_SIZE_LARGE
    }

    /**
     * 是否为模拟器
     */
    fun isEmulator(): Boolean {
        return (Build.FINGERPRINT.startsWith("generic")
                || Build.FINGERPRINT.startsWith("unknown")
                || Build.MODEL.contains("google_sdk")
                || Build.MODEL.contains("Emulator")
                || Build.MODEL.contains("Android SDK built for x86")
                || Build.MANUFACTURER.contains("Genymotion")
                || Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic")
                || "google_sdk" == Build.PRODUCT)
    }
}

/**
 * 扩展函数：获取设备信息
 */
fun Context.getDeviceInfo(): Map<String, String> {
    val helper = DeviceHelper(applicationContext)
    return helper.getDeviceInfo()
}
