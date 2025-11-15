package com.runningapp.ui.running

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.gson.Gson
import com.runningapp.data.local.entity.RunningRecordEntity
import com.runningapp.data.local.entity.TrackPointEntity
import com.runningapp.data.repository.RunningRepository
import com.runningapp.service.LocationTrackingService
import com.runningapp.utils.LocationUtils
import com.runningapp.utils.PreferenceManager
import com.runningapp.utils.Result
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 跑步ViewModel
 */
@HiltViewModel
class RunningViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    private val runningRepository: RunningRepository,
    private val preferenceManager: PreferenceManager,
    private val gson: Gson
) : ViewModel() {

    private var trackingService: LocationTrackingService? = null
    private var isBound = false

    // UI状态
    private val _uiState = MutableStateFlow<UiState>(UiState.Idle)
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    // 跑步状态
    private val _runningState = MutableStateFlow(RunningState.STOPPED)
    val runningState: StateFlow<RunningState> = _runningState.asStateFlow()

    // 跑步数据
    private val _runningData = MutableStateFlow(RunningData())
    val runningData: StateFlow<RunningData> = _runningData.asStateFlow()

    // 当前记录ID
    private var currentRecordId: Int = 0

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as LocationTrackingService.LocalBinder
            trackingService = binder.getService()
            isBound = true

            // 监听服务数据
            trackingService?.let { service ->
                viewModelScope.launch {
                    service.runningData.collect { data ->
                        _runningData.value = RunningData(
                            distance = data.distance,
                            duration = data.duration,
                            avgSpeed = data.avgSpeed,
                            avgPace = data.avgPace,
                            currentSpeed = data.currentSpeed,
                            calories = LocationUtils.calculateCalories(data.distance)
                        )
                    }
                }
            }
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            trackingService = null
            isBound = false
        }
    }

    /**
     * 开始跑步
     */
    fun startRunning() {
        viewModelScope.launch {
            _uiState.value = UiState.Loading

            // 请求服务器分配记录ID
            when (val result = runningRepository.startRunning()) {
                is Result.Success -> {
                    currentRecordId = result.data.recordId

                    // 启动定位服务
                    val intent = Intent(context, LocationTrackingService::class.java)
                    context.startService(intent)
                    context.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)

                    // 开始跟踪
                    trackingService?.startTracking()
                    _runningState.value = RunningState.RUNNING
                    _uiState.value = UiState.Idle
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.message ?: "启动失败")
                }
                else -> {}
            }
        }
    }

    /**
     * 暂停跑步
     */
    fun pauseRunning() {
        trackingService?.pauseTracking()
        _runningState.value = RunningState.PAUSED
    }

    /**
     * 恢复跑步
     */
    fun resumeRunning() {
        trackingService?.resumeTracking()
        _runningState.value = RunningState.RUNNING
    }

    /**
     * 停止跑步
     */
    fun stopRunning() {
        viewModelScope.launch {
            val data = _runningData.value
            val trackPoints = trackingService?.trackPoints?.value ?: emptyList()

            if (trackPoints.isEmpty()) {
                _uiState.value = UiState.Error("没有记录到轨迹数据")
                return@launch
            }

            _uiState.value = UiState.Loading

            // 先保存到本地数据库
            val record = RunningRecordEntity(
                id = currentRecordId,
                userId = preferenceManager.getUserId(),
                distance = data.distance,
                duration = data.duration,
                calories = data.calories,
                avgPace = data.avgPace,
                avgSpeed = data.avgSpeed,
                maxSpeed = trackPoints.maxOfOrNull { it.speed ?: 0f } ?: 0f,
                steps = null,
                stepFrequency = null,
                startTime = trackPoints.first().timestamp,
                endTime = trackPoints.last().timestamp,
                trackData = gson.toJson(trackPoints),
                elevationGain = calculateElevationGain(trackPoints),
                elevationLoss = calculateElevationLoss(trackPoints),
                weather = null,
                temperature = null,
                note = null,
                images = null,
                isSynced = false,
                createdAt = System.currentTimeMillis(),
                updatedAt = System.currentTimeMillis()
            )

            runningRepository.saveRecordLocal(record)

            // 同步到服务器
            val trackData = gson.toJson(trackPoints.map {
                mapOf(
                    "latitude" to it.latitude,
                    "longitude" to it.longitude,
                    "altitude" to it.altitude,
                    "speed" to it.speed,
                    "timestamp" to it.timestamp
                )
            })

            when (val result = runningRepository.finishRunning(
                recordId = currentRecordId,
                distance = data.distance,
                duration = data.duration,
                calories = data.calories,
                trackData = trackData
            )) {
                is Result.Success -> {
                    // 停止服务
                    trackingService?.stopTracking()
                    context.unbindService(serviceConnection)
                    isBound = false

                    _runningState.value = RunningState.STOPPED
                    _uiState.value = UiState.Finished(record)
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.message ?: "保存失败")
                }
                else -> {}
            }
        }
    }

    /**
     * 关闭完成对话框
     */
    fun dismissFinishDialog() {
        _uiState.value = UiState.Idle
        _runningData.value = RunningData()
        currentRecordId = 0
    }

    /**
     * 计算累计爬升
     */
    private fun calculateElevationGain(points: List<TrackPointEntity>): Int {
        var gain = 0.0
        for (i in 0 until points.size - 1) {
            val current = points[i].altitude ?: 0.0
            val next = points[i + 1].altitude ?: 0.0
            val diff = next - current
            if (diff > 0) gain += diff
        }
        return gain.toInt()
    }

    /**
     * 计算累计下降
     */
    private fun calculateElevationLoss(points: List<TrackPointEntity>): Int {
        var loss = 0.0
        for (i in 0 until points.size - 1) {
            val current = points[i].altitude ?: 0.0
            val next = points[i + 1].altitude ?: 0.0
            val diff = current - next
            if (diff > 0) loss += diff
        }
        return loss.toInt()
    }

    override fun onCleared() {
        super.onCleared()
        if (isBound) {
            context.unbindService(serviceConnection)
            isBound = false
        }
    }

    enum class RunningState {
        STOPPED, RUNNING, PAUSED
    }

    data class RunningData(
        val distance: Float = 0f,
        val duration: Int = 0,
        val avgSpeed: Float = 0f,
        val avgPace: Int = 0,
        val currentSpeed: Float = 0f,
        val calories: Int = 0
    )

    sealed class UiState {
        object Idle : UiState()
        object Loading : UiState()
        data class Finished(val record: RunningRecordEntity) : UiState()
        data class Error(val message: String) : UiState()
    }
}
