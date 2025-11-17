package com.runningapp.utils

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 权限管理助手
 * 提供统一的权限请求、检查和处理功能
 */
@Singleton
class PermissionHelper @Inject constructor(
    @ApplicationContext private val context: Context
) {

    companion object {
        // 常用权限定义
        object Permissions {
            // 定位权限
            val LOCATION_FINE = Manifest.permission.ACCESS_FINE_LOCATION
            val LOCATION_COARSE = Manifest.permission.ACCESS_COARSE_LOCATION
            val LOCATION_BACKGROUND = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                Manifest.permission.ACCESS_BACKGROUND_LOCATION
            } else {
                ""
            }

            // 存储权限
            val READ_STORAGE = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                Manifest.permission.READ_MEDIA_IMAGES
            } else {
                Manifest.permission.READ_EXTERNAL_STORAGE
            }
            val WRITE_STORAGE = Manifest.permission.WRITE_EXTERNAL_STORAGE

            // 相机权限
            val CAMERA = Manifest.permission.CAMERA

            // 通知权限
            val POST_NOTIFICATIONS = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                Manifest.permission.POST_NOTIFICATIONS
            } else {
                ""
            }

            // 运动传感器权限
            val ACTIVITY_RECOGNITION = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                Manifest.permission.ACTIVITY_RECOGNITION
            } else {
                "com.google.android.gms.permission.ACTIVITY_RECOGNITION"
            }
        }

        // 权限组
        object PermissionGroups {
            // 基础定位权限（前台）
            val LOCATION_FOREGROUND = arrayOf(
                Permissions.LOCATION_FINE,
                Permissions.LOCATION_COARSE
            )

            // 完整定位权限（前台+后台）
            val LOCATION_ALL = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                arrayOf(
                    Permissions.LOCATION_FINE,
                    Permissions.LOCATION_COARSE,
                    Permissions.LOCATION_BACKGROUND
                )
            } else {
                arrayOf(
                    Permissions.LOCATION_FINE,
                    Permissions.LOCATION_COARSE
                )
            }

            // 存储权限
            val STORAGE = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                arrayOf(Permissions.READ_STORAGE)
            } else {
                arrayOf(Permissions.READ_STORAGE, Permissions.WRITE_STORAGE)
            }

            // 跑步应用核心权限
            val RUNNING_CORE = buildList {
                add(Permissions.LOCATION_FINE)
                add(Permissions.LOCATION_COARSE)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    add(Permissions.ACTIVITY_RECOGNITION)
                }
            }.toTypedArray()
        }
    }

    // MARK: - 权限检查

    /**
     * 检查单个权限是否已授予
     */
    fun isPermissionGranted(permission: String): Boolean {
        if (permission.isEmpty()) return true
        return ContextCompat.checkSelfPermission(
            context,
            permission
        ) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * 检查多个权限是否全部已授予
     */
    fun arePermissionsGranted(permissions: Array<String>): Boolean {
        return permissions.all { isPermissionGranted(it) }
    }

    /**
     * 检查多个权限，返回未授予的权限列表
     */
    fun getUnauthorizedPermissions(permissions: Array<String>): List<String> {
        return permissions.filter { !isPermissionGranted(it) && it.isNotEmpty() }
    }

    /**
     * 检查是否需要显示权限说明（用户之前拒绝过）
     */
    fun shouldShowRationale(activity: Activity, permission: String): Boolean {
        if (permission.isEmpty()) return false
        return ActivityCompat.shouldShowRequestPermissionRationale(activity, permission)
    }

    /**
     * 检查权限是否被永久拒绝
     */
    fun isPermissionPermanentlyDenied(activity: Activity, permission: String): Boolean {
        if (permission.isEmpty()) return false
        return !isPermissionGranted(permission) && !shouldShowRationale(activity, permission)
    }

    // MARK: - 定位权限特殊处理

    /**
     * 检查前台定位权限
     */
    fun hasLocationPermission(): Boolean {
        return isPermissionGranted(Permissions.LOCATION_FINE) ||
                isPermissionGranted(Permissions.LOCATION_COARSE)
    }

    /**
     * 检查后台定位权限
     */
    fun hasBackgroundLocationPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return hasLocationPermission()
        }
        return hasLocationPermission() && isPermissionGranted(Permissions.LOCATION_BACKGROUND)
    }

    /**
     * 检查精确定位权限
     */
    fun hasPreciseLocationPermission(): Boolean {
        return isPermissionGranted(Permissions.LOCATION_FINE)
    }

    // MARK: - 其他常用权限检查

    /**
     * 检查存储权限
     */
    fun hasStoragePermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            isPermissionGranted(Permissions.READ_STORAGE)
        } else {
            isPermissionGranted(Permissions.READ_STORAGE) &&
                    isPermissionGranted(Permissions.WRITE_STORAGE)
        }
    }

    /**
     * 检查相机权限
     */
    fun hasCameraPermission(): Boolean {
        return isPermissionGranted(Permissions.CAMERA)
    }

    /**
     * 检查通知权限
     */
    fun hasNotificationPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return true // Android 13以下不需要通知权限
        }
        return isPermissionGranted(Permissions.POST_NOTIFICATIONS)
    }

    /**
     * 检查运动识别权限
     */
    fun hasActivityRecognitionPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return true // Android 10以下不需要运动识别权限
        }
        return isPermissionGranted(Permissions.ACTIVITY_RECOGNITION)
    }

    // MARK: - 权限说明文本

    /**
     * 获取权限的用户友好说明
     */
    fun getPermissionRationale(permission: String): String {
        return when (permission) {
            Permissions.LOCATION_FINE, Permissions.LOCATION_COARSE ->
                "我们需要定位权限来记录您的跑步轨迹"

            Permissions.LOCATION_BACKGROUND ->
                "我们需要后台定位权限来在应用后台运行时继续记录您的跑步轨迹"

            Permissions.CAMERA ->
                "我们需要相机权限来拍摄照片分享您的跑步瞬间"

            Permissions.READ_STORAGE, Permissions.WRITE_STORAGE ->
                "我们需要存储权限来保存和读取跑步照片"

            Permissions.POST_NOTIFICATIONS ->
                "我们需要通知权限来发送训练提醒和成就通知"

            Permissions.ACTIVITY_RECOGNITION ->
                "我们需要运动识别权限来更准确地识别您的运动状态"

            else -> "我们需要此权限来提供更好的服务"
        }
    }

    /**
     * 获取权限被拒绝后的说明
     */
    fun getPermissionDeniedMessage(permission: String): String {
        return when (permission) {
            Permissions.LOCATION_FINE, Permissions.LOCATION_COARSE ->
                "没有定位权限，无法记录跑步轨迹"

            Permissions.LOCATION_BACKGROUND ->
                "没有后台定位权限，应用切换到后台后将停止记录轨迹"

            Permissions.CAMERA ->
                "没有相机权限，无法拍摄照片"

            Permissions.READ_STORAGE, Permissions.WRITE_STORAGE ->
                "没有存储权限，无法选择或保存照片"

            Permissions.POST_NOTIFICATIONS ->
                "没有通知权限，您将收不到训练提醒和成就通知"

            Permissions.ACTIVITY_RECOGNITION ->
                "没有运动识别权限，运动数据可能不够准确"

            else -> "缺少必要权限，部分功能可能无法使用"
        }
    }

    // MARK: - 打开设置页面

    /**
     * 打开应用设置页面
     */
    fun openAppSettings(activity: Activity) {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", activity.packageName, null)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        activity.startActivity(intent)
    }

    /**
     * 打开定位设置页面
     */
    fun openLocationSettings(activity: Activity) {
        val intent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        activity.startActivity(intent)
    }
}

/**
 * 权限请求结果
 */
data class PermissionResult(
    val permission: String,
    val granted: Boolean,
    val shouldShowRationale: Boolean = false
)

/**
 * 权限请求回调
 */
typealias PermissionCallback = (PermissionResult) -> Unit
typealias MultiplePermissionsCallback = (Map<String, Boolean>) -> Unit

/**
 * 权限请求扩展函数
 * 在ComponentActivity中使用
 */
class PermissionRequestHelper(private val activity: ComponentActivity) {

    private var singlePermissionLauncher: ActivityResultLauncher<String>? = null
    private var multiplePermissionsLauncher: ActivityResultLauncher<Array<String>>? = null
    private var singlePermissionCallback: PermissionCallback? = null
    private var multiplePermissionsCallback: MultiplePermissionsCallback? = null

    /**
     * 注册单个权限请求（在onCreate中调用）
     */
    fun registerSinglePermission(callback: PermissionCallback) {
        singlePermissionCallback = callback
        singlePermissionLauncher = activity.registerForActivityResult(
            ActivityResultContracts.RequestPermission()
        ) { granted ->
            // 获取权限字符串需要从上下文保存
            callback(PermissionResult("", granted))
        }
    }

    /**
     * 注册多个权限请求（在onCreate中调用）
     */
    fun registerMultiplePermissions(callback: MultiplePermissionsCallback) {
        multiplePermissionsCallback = callback
        multiplePermissionsLauncher = activity.registerForActivityResult(
            ActivityResultContracts.RequestMultiplePermissions()
        ) { results ->
            callback(results)
        }
    }

    /**
     * 请求单个权限
     */
    fun requestPermission(permission: String) {
        singlePermissionLauncher?.launch(permission)
    }

    /**
     * 请求多个权限
     */
    fun requestPermissions(permissions: Array<String>) {
        multiplePermissionsLauncher?.launch(permissions)
    }
}

/**
 * 扩展函数：检查权限并请求
 */
fun ComponentActivity.checkAndRequestPermission(
    permission: String,
    onGranted: () -> Unit,
    onDenied: (shouldShowRationale: Boolean) -> Unit
) {
    when {
        ContextCompat.checkSelfPermission(
            this,
            permission
        ) == PackageManager.PERMISSION_GRANTED -> {
            onGranted()
        }
        ActivityCompat.shouldShowRequestPermissionRationale(this, permission) -> {
            onDenied(true)
        }
        else -> {
            onDenied(false)
        }
    }
}
