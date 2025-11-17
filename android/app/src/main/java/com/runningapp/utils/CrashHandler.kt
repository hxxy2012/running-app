package com.runningapp.utils

import android.content.Context
import android.os.Build
import android.os.Process
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.system.exitProcess

/**
 * 崩溃处理器
 * 捕获未捕获的异常并生成崩溃报告
 */
@Singleton
class CrashHandler @Inject constructor(
    @ApplicationContext private val context: Context,
    private val deviceHelper: DeviceHelper
) : Thread.UncaughtExceptionHandler {

    private var defaultHandler: Thread.UncaughtExceptionHandler? = null
    private val crashDir: File by lazy {
        File(context.filesDir, "crashes").apply {
            if (!exists()) mkdirs()
        }
    }

    /**
     * 初始化崩溃处理器
     */
    fun init() {
        defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler(this)
        Logger.d("CrashHandler", "Crash handler initialized")
    }

    /**
     * 处理未捕获的异常
     */
    override fun uncaughtException(thread: Thread, throwable: Throwable) {
        try {
            // 收集崩溃信息
            val crashInfo = collectCrashInfo(thread, throwable)

            // 保存崩溃报告
            saveCrashReport(crashInfo)

            // 记录日志
            Logger.e("CrashHandler", "Uncaught exception in thread ${thread.name}", throwable)

            // 上传崩溃报告（异步）
            uploadCrashReport(crashInfo)

        } catch (e: Exception) {
            Logger.e("CrashHandler", "Error handling crash", e)
        } finally {
            // 调用系统默认处理器
            defaultHandler?.uncaughtException(thread, throwable)

            // 杀死进程
            Process.killProcess(Process.myPid())
            exitProcess(1)
        }
    }

    /**
     * 收集崩溃信息
     */
    private fun collectCrashInfo(thread: Thread, throwable: Throwable): CrashInfo {
        return CrashInfo(
            timestamp = System.currentTimeMillis(),
            threadName = thread.name,
            exceptionType = throwable.javaClass.name,
            exceptionMessage = throwable.message ?: "No message",
            stackTrace = getStackTrace(throwable),
            deviceInfo = deviceHelper.getDeviceInfo(),
            appVersion = deviceHelper.getVersionName(),
            appVersionCode = deviceHelper.getVersionCode()
        )
    }

    /**
     * 获取堆栈跟踪
     */
    private fun getStackTrace(throwable: Throwable): String {
        val writer = StringWriter()
        val printWriter = PrintWriter(writer)
        throwable.printStackTrace(printWriter)
        var cause = throwable.cause
        while (cause != null) {
            cause.printStackTrace(printWriter)
            cause = cause.cause
        }
        printWriter.close()
        return writer.toString()
    }

    /**
     * 保存崩溃报告
     */
    private fun saveCrashReport(crashInfo: CrashInfo) {
        try {
            val fileName = generateCrashFileName(crashInfo.timestamp)
            val file = File(crashDir, fileName)

            file.writeText(formatCrashReport(crashInfo))

            Logger.d("CrashHandler", "Crash report saved: ${file.path}")
        } catch (e: Exception) {
            Logger.e("CrashHandler", "Failed to save crash report", e)
        }
    }

    /**
     * 格式化崩溃报告
     */
    private fun formatCrashReport(crashInfo: CrashInfo): String {
        val sb = StringBuilder()

        sb.appendLine("====== Crash Report ======")
        sb.appendLine()

        // 时间信息
        val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
        sb.appendLine("Time: ${dateFormat.format(Date(crashInfo.timestamp))}")
        sb.appendLine()

        // 应用信息
        sb.appendLine("--- App Info ---")
        sb.appendLine("Version: ${crashInfo.appVersion} (${crashInfo.appVersionCode})")
        sb.appendLine()

        // 设备信息
        sb.appendLine("--- Device Info ---")
        crashInfo.deviceInfo.forEach { (key, value) ->
            sb.appendLine("$key: $value")
        }
        sb.appendLine()

        // 异常信息
        sb.appendLine("--- Exception Info ---")
        sb.appendLine("Thread: ${crashInfo.threadName}")
        sb.appendLine("Type: ${crashInfo.exceptionType}")
        sb.appendLine("Message: ${crashInfo.exceptionMessage}")
        sb.appendLine()

        // 堆栈跟踪
        sb.appendLine("--- Stack Trace ---")
        sb.appendLine(crashInfo.stackTrace)
        sb.appendLine()

        sb.appendLine("=========================")

        return sb.toString()
    }

    /**
     * 生成崩溃文件名
     */
    private fun generateCrashFileName(timestamp: Long): String {
        val dateFormat = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault())
        return "crash_${dateFormat.format(Date(timestamp))}.log"
    }

    /**
     * 上传崩溃报告
     */
    private fun uploadCrashReport(crashInfo: CrashInfo) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                // 构建请求体
                val json = """
                    {
                        "platform": "android",
                        "app_version": "${deviceHelper.appVersion}",
                        "os_version": "${Build.VERSION.RELEASE}",
                        "device_model": "${Build.MODEL}",
                        "crash_time": "${SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date(crashInfo.timestamp))}",
                        "log_content": ${org.json.JSONObject.quote(crashInfo.stackTrace)}
                    }
                """.trimIndent()

                // 使用 OkHttp 上传（需要从 AppModule 获取 baseUrl，这里使用硬编码）
                val client = okhttp3.OkHttpClient()
                val requestBody = okhttp3.RequestBody.create(
                    okhttp3.MediaType.parse("application/json; charset=utf-8"),
                    json
                )
                val request = okhttp3.Request.Builder()
                    .url("YOUR_API_BASE_URL/crash/upload")  // 需要替换为实际的API地址
                    .post(requestBody)
                    .build()

                val response = client.newCall(request).execute()
                if (response.isSuccessful) {
                    Logger.d("CrashHandler", "Crash report uploaded successfully")
                } else {
                    Logger.e("CrashHandler", "Failed to upload: ${response.code()}")
                }
                response.close()
            } catch (e: Exception) {
                Logger.e("CrashHandler", "Failed to upload crash report", e)
                // 上传失败不影响崩溃处理流程
            }
        }
    }

    /**
     * 获取所有崩溃报告
     */
    fun getAllCrashReports(): List<File> {
        return crashDir.listFiles()?.filter { it.extension == "log" }
            ?.sortedByDescending { it.lastModified() }
            ?: emptyList()
    }

    /**
     * 读取崩溃报告内容
     */
    fun readCrashReport(file: File): String? {
        return try {
            if (file.exists()) file.readText() else null
        } catch (e: Exception) {
            Logger.e("CrashHandler", "Failed to read crash report", e)
            null
        }
    }

    /**
     * 删除崩溃报告
     */
    fun deleteCrashReport(file: File): Boolean {
        return try {
            file.delete()
        } catch (e: Exception) {
            Logger.e("CrashHandler", "Failed to delete crash report", e)
            false
        }
    }

    /**
     * 清理所有崩溃报告
     */
    fun clearAllCrashReports() {
        try {
            crashDir.listFiles()?.forEach { it.delete() }
            Logger.d("CrashHandler", "All crash reports cleared")
        } catch (e: Exception) {
            Logger.e("CrashHandler", "Failed to clear crash reports", e)
        }
    }

    /**
     * 清理旧的崩溃报告（保留最近N个）
     */
    fun cleanOldCrashReports(keepCount: Int = 10) {
        try {
            val reports = getAllCrashReports()
            if (reports.size > keepCount) {
                reports.drop(keepCount).forEach { it.delete() }
                Logger.d("CrashHandler", "Cleaned ${reports.size - keepCount} old crash reports")
            }
        } catch (e: Exception) {
            Logger.e("CrashHandler", "Failed to clean old crash reports", e)
        }
    }

    /**
     * 获取崩溃报告数量
     */
    fun getCrashReportCount(): Int {
        return crashDir.listFiles()?.count { it.extension == "log" } ?: 0
    }

    /**
     * 检查是否有新的崩溃报告
     */
    fun hasNewCrashReports(lastCheckTime: Long): Boolean {
        return crashDir.listFiles()?.any {
            it.extension == "log" && it.lastModified() > lastCheckTime
        } ?: false
    }

    /**
     * 崩溃信息数据类
     */
    data class CrashInfo(
        val timestamp: Long,
        val threadName: String,
        val exceptionType: String,
        val exceptionMessage: String,
        val stackTrace: String,
        val deviceInfo: Map<String, String>,
        val appVersion: String,
        val appVersionCode: Long
    )
}

/**
 * 扩展函数：在Application中初始化崩溃处理器
 */
fun Context.initCrashHandler(crashHandler: CrashHandler) {
    crashHandler.init()
}
