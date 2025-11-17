package com.runningapp.utils

import android.app.ActivityManager
import android.content.Context
import android.os.Debug
import android.os.Process
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.system.measureTimeMillis

/**
 * 性能监控工具
 * 监控应用性能指标
 */
@Singleton
class PerformanceMonitor @Inject constructor(
    @ApplicationContext private val context: Context
) {

    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private var isMonitoring = false

    // 性能指标
    private val _performanceMetrics = MutableStateFlow(PerformanceMetrics())
    val performanceMetrics: StateFlow<PerformanceMetrics> = _performanceMetrics

    data class PerformanceMetrics(
        val memoryUsage: Long = 0,
        val cpuUsage: Float = 0f,
        val fps: Int = 0,
        val networkLatency: Long = 0
    )

    // MARK: - 内存监控

    /**
     * 获取当前内存使用（MB）
     */
    fun getCurrentMemoryUsage(): Long {
        val runtime = Runtime.getRuntime()
        val usedMemory = runtime.totalMemory() - runtime.freeMemory()
        return usedMemory / (1024 * 1024)
    }

    /**
     * 获取可用内存（MB）
     */
    fun getAvailableMemory(): Long {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        return memoryInfo.availMem / (1024 * 1024)
    }

    /**
     * 获取总内存（MB）
     */
    fun getTotalMemory(): Long {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        return memoryInfo.totalMem / (1024 * 1024)
    }

    /**
     * 获取内存使用百分比
     */
    fun getMemoryUsagePercentage(): Float {
        val total = getTotalMemory()
        val used = getCurrentMemoryUsage()
        return if (total > 0) (used.toFloat() / total * 100) else 0f
    }

    /**
     * 获取Dalvik堆内存信息
     */
    fun getDalvikHeapInfo(): Map<String, Long> {
        val runtime = Runtime.getRuntime()
        return mapOf(
            "maxMemory" to runtime.maxMemory() / (1024 * 1024),
            "totalMemory" to runtime.totalMemory() / (1024 * 1024),
            "freeMemory" to runtime.freeMemory() / (1024 * 1024),
            "usedMemory" to (runtime.totalMemory() - runtime.freeMemory()) / (1024 * 1024)
        )
    }

    /**
     * 获取Native堆内存信息
     */
    fun getNativeHeapInfo(): Map<String, Long> {
        return mapOf(
            "allocatedSize" to Debug.getNativeHeapAllocatedSize() / (1024 * 1024),
            "freeSize" to Debug.getNativeHeapFreeSize() / (1024 * 1024),
            "totalSize" to Debug.getNativeHeapSize() / (1024 * 1024)
        )
    }

    // MARK: - 性能测量

    /**
     * 测量代码块执行时间
     */
    inline fun <T> measurePerformance(tag: String, block: () -> T): T {
        val result: T
        val time = measureTimeMillis {
            result = block()
        }
        Logger.d("PerformanceMonitor", "$tag took ${time}ms")
        return result
    }

    /**
     * 测量异步代码块执行时间
     */
    suspend inline fun <T> measurePerformanceAsync(tag: String, crossinline block: suspend () -> T): T {
        val result: T
        val time = measureTimeMillis {
            result = block()
        }
        Logger.d("PerformanceMonitor", "$tag took ${time}ms")
        return result
    }

    // MARK: - 启动时间追踪

    private val startupMarkers = mutableMapOf<String, Long>()

    /**
     * 标记启动时间点
     */
    fun markStartupTime(marker: String) {
        startupMarkers[marker] = System.currentTimeMillis()
        Logger.d("PerformanceMonitor", "Startup marker: $marker")
    }

    /**
     * 获取启动耗时
     */
    fun getStartupDuration(startMarker: String, endMarker: String): Long? {
        val start = startupMarkers[startMarker]
        val end = startupMarkers[endMarker]
        return if (start != null && end != null) {
            end - start
        } else {
            null
        }
    }

    /**
     * 获取所有启动标记
     */
    fun getAllStartupMarkers(): Map<String, Long> {
        return startupMarkers.toMap()
    }

    // MARK: - 网络性能监控

    private val networkMetrics = mutableListOf<NetworkMetric>()

    data class NetworkMetric(
        val url: String,
        val method: String,
        val duration: Long,
        val timestamp: Long,
        val success: Boolean
    )

    /**
     * 记录网络请求
     */
    fun recordNetworkRequest(
        url: String,
        method: String,
        duration: Long,
        success: Boolean
    ) {
        val metric = NetworkMetric(
            url = url,
            method = method,
            duration = duration,
            timestamp = System.currentTimeMillis(),
            success = success
        )
        networkMetrics.add(metric)

        // 只保留最近100条
        if (networkMetrics.size > 100) {
            networkMetrics.removeAt(0)
        }

        Logger.d("PerformanceMonitor", "Network: $method $url - ${duration}ms")
    }

    /**
     * 获取平均网络延迟
     */
    fun getAverageNetworkLatency(): Long {
        return if (networkMetrics.isNotEmpty()) {
            networkMetrics.map { it.duration }.average().toLong()
        } else {
            0
        }
    }

    /**
     * 获取网络请求成功率
     */
    fun getNetworkSuccessRate(): Float {
        if (networkMetrics.isEmpty()) return 100f
        val successCount = networkMetrics.count { it.success }
        return (successCount.toFloat() / networkMetrics.size) * 100
    }

    // MARK: - 持续监控

    /**
     * 开始性能监控
     */
    fun startMonitoring(intervalMs: Long = 1000) {
        if (isMonitoring) return

        isMonitoring = true
        scope.launch {
            while (isMonitoring) {
                updateMetrics()
                delay(intervalMs)
            }
        }

        Logger.d("PerformanceMonitor", "Monitoring started")
    }

    /**
     * 停止性能监控
     */
    fun stopMonitoring() {
        isMonitoring = false
        Logger.d("PerformanceMonitor", "Monitoring stopped")
    }

    /**
     * 更新性能指标
     */
    private fun updateMetrics() {
        _performanceMetrics.value = PerformanceMetrics(
            memoryUsage = getCurrentMemoryUsage(),
            cpuUsage = 0f, // CPU使用率需要更复杂的计算
            networkLatency = getAverageNetworkLatency()
        )
    }

    // MARK: - 性能报告

    /**
     * 生成性能报告
     */
    fun generatePerformanceReport(): String {
        val sb = StringBuilder()
        sb.append("=== Performance Report ===\n")
        sb.append("Memory Usage: ${getCurrentMemoryUsage()}MB / ${getTotalMemory()}MB\n")
        sb.append("Memory Usage Percentage: ${"%.2f".format(getMemoryUsagePercentage())}%\n")
        sb.append("\nDalvik Heap:\n")
        getDalvikHeapInfo().forEach { (key, value) ->
            sb.append("  $key: ${value}MB\n")
        }
        sb.append("\nNative Heap:\n")
        getNativeHeapInfo().forEach { (key, value) ->
            sb.append("  $key: ${value}MB\n")
        }
        sb.append("\nNetwork:\n")
        sb.append("  Average Latency: ${getAverageNetworkLatency()}ms\n")
        sb.append("  Success Rate: ${"%.2f".format(getNetworkSuccessRate())}%\n")
        sb.append("  Total Requests: ${networkMetrics.size}\n")
        sb.append("========================\n")

        return sb.toString()
    }

    /**
     * 打印性能报告
     */
    fun printPerformanceReport() {
        Logger.d("PerformanceMonitor", "\n" + generatePerformanceReport())
    }

    // MARK: - 清理

    /**
     * 清理监控数据
     */
    fun cleanup() {
        stopMonitoring()
        networkMetrics.clear()
        startupMarkers.clear()
        scope.cancel()
    }
}

/**
 * 扩展函数：测量代码块执行时间
 */
inline fun <T> measureTime(tag: String, block: () -> T): T {
    val result: T
    val time = measureTimeMillis {
        result = block()
    }
    Logger.d("Performance", "$tag: ${time}ms")
    return result
}

/**
 * 扩展函数：测量异步代码块执行时间
 */
suspend inline fun <T> measureTimeAsync(tag: String, crossinline block: suspend () -> T): T {
    val result: T
    val time = measureTimeMillis {
        result = block()
    }
    Logger.d("Performance", "$tag: ${time}ms")
    return result
}
