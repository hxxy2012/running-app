package com.runningapp.service

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.location.Location
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import com.runningapp.R
import com.runningapp.data.local.entity.TrackPointEntity
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

/**
 * GPS跟踪服务 - 后台持续跟踪用户位置
 */
@AndroidEntryPoint
class LocationTrackingService : Service() {

    @Inject
    lateinit var fusedLocationClient: FusedLocationProviderClient

    private val binder = LocalBinder()

    // 跟踪状态
    private val _isTracking = MutableStateFlow(false)
    val isTracking: StateFlow<Boolean> = _isTracking.asStateFlow()

    // 位置更新流
    private val _locationUpdates = MutableStateFlow<Location?>(null)
    val locationUpdates: StateFlow<Location?> = _locationUpdates.asStateFlow()

    // 轨迹点列表
    private val _trackPoints = MutableStateFlow<List<TrackPointEntity>>(emptyList())
    val trackPoints: StateFlow<List<TrackPointEntity>> = _trackPoints.asStateFlow()

    // 跑步数据
    private val _runningData = MutableStateFlow(RunningData())
    val runningData: StateFlow<RunningData> = _runningData.asStateFlow()

    private var lastLocation: Location? = null
    private var totalDistance: Float = 0f
    private var startTime: Long = 0L

    companion object {
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "location_tracking_channel"
        private const val LOCATION_UPDATE_INTERVAL = 3000L // 3秒
        private const val LOCATION_FASTEST_INTERVAL = 1000L // 1秒
        private const val MIN_DISTANCE_THRESHOLD = 5f // 最小距离阈值(米)
    }

    inner class LocalBinder : Binder() {
        fun getService(): LocationTrackingService = this@LocationTrackingService
    }

    override fun onBind(intent: Intent?): IBinder {
        return binder
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    /**
     * 开始跟踪
     */
    @SuppressLint("MissingPermission")
    fun startTracking() {
        if (_isTracking.value) return

        _isTracking.value = true
        startTime = System.currentTimeMillis()
        totalDistance = 0f
        lastLocation = null
        _trackPoints.value = emptyList()
        _runningData.value = RunningData()

        // 请求位置更新
        val locationRequest = LocationRequest.create().apply {
            interval = LOCATION_UPDATE_INTERVAL
            fastestInterval = LOCATION_FASTEST_INTERVAL
            priority = LocationRequest.PRIORITY_HIGH_ACCURACY
        }

        fusedLocationClient.requestLocationUpdates(
            locationRequest,
            locationCallback,
            Looper.getMainLooper()
        )

        // 启动前台服务
        startForeground(NOTIFICATION_ID, createNotification())
    }

    /**
     * 停止跟踪
     */
    fun stopTracking() {
        if (!_isTracking.value) return

        _isTracking.value = false
        fusedLocationClient.removeLocationUpdates(locationCallback)
        stopForeground(true)
        stopSelf()
    }

    /**
     * 暂停跟踪
     */
    fun pauseTracking() {
        if (!_isTracking.value) return
        fusedLocationClient.removeLocationUpdates(locationCallback)
    }

    /**
     * 恢复跟踪
     */
    @SuppressLint("MissingPermission")
    fun resumeTracking() {
        if (!_isTracking.value) return

        val locationRequest = LocationRequest.create().apply {
            interval = LOCATION_UPDATE_INTERVAL
            fastestInterval = LOCATION_FASTEST_INTERVAL
            priority = LocationRequest.PRIORITY_HIGH_ACCURACY
        }

        fusedLocationClient.requestLocationUpdates(
            locationRequest,
            locationCallback,
            Looper.getMainLooper()
        )
    }

    /**
     * 位置回调
     */
    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            result.lastLocation?.let { location ->
                handleLocationUpdate(location)
            }
        }
    }

    /**
     * 处理位置更新
     */
    private fun handleLocationUpdate(location: Location) {
        _locationUpdates.value = location

        // 计算距离
        lastLocation?.let { last ->
            val distance = last.distanceTo(location)

            // 过滤异常点
            if (distance > MIN_DISTANCE_THRESHOLD && distance < 100) {
                totalDistance += distance

                // 更新跑步数据
                val duration = (System.currentTimeMillis() - startTime) / 1000
                val speed = if (duration > 0) (totalDistance / duration) * 3.6f else 0f
                val pace = if (speed > 0) (60 / (speed / 60)) else 0

                _runningData.value = _runningData.value.copy(
                    distance = totalDistance,
                    duration = duration.toInt(),
                    avgSpeed = speed,
                    avgPace = pace.toInt(),
                    currentSpeed = location.speed * 3.6f
                )

                // 添加轨迹点
                val trackPoint = TrackPointEntity(
                    recordId = 0, // 将在保存时设置
                    latitude = location.latitude,
                    longitude = location.longitude,
                    altitude = location.altitude,
                    speed = location.speed,
                    accuracy = location.accuracy,
                    timestamp = location.time
                )
                _trackPoints.value = _trackPoints.value + trackPoint
            }
        }

        lastLocation = location
    }

    /**
     * 创建通知渠道
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "位置跟踪",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "跑步时的GPS位置跟踪"
                setShowBadge(false)
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    /**
     * 创建通知
     */
    private fun createNotification() =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("正在跑步")
            .setContentText("GPS定位中...")
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setOngoing(true)
            .build()

    /**
     * 跑步数据
     */
    data class RunningData(
        val distance: Float = 0f,
        val duration: Int = 0,
        val avgSpeed: Float = 0f,
        val avgPace: Int = 0,
        val currentSpeed: Float = 0f,
        val calories: Int = 0
    )
}
