package com.runningapp.ui.history

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.runningapp.data.local.entity.RunningRecordEntity
import com.runningapp.data.remote.model.RunningStatistics
import com.runningapp.data.repository.RunningRepository
import com.runningapp.utils.PreferenceManager
import com.runningapp.utils.Result
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 历史记录ViewModel
 */
@HiltViewModel
class HistoryViewModel @Inject constructor(
    private val runningRepository: RunningRepository,
    private val preferenceManager: PreferenceManager
) : ViewModel() {

    // 本地记录列表
    val records: StateFlow<List<RunningRecordEntity>> = runningRepository
        .getRecordsLocal(preferenceManager.getUserId())
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    // UI状态
    private val _uiState = MutableStateFlow<UiState>(UiState.Idle)
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    // 统计数据
    private val _statistics = MutableStateFlow<RunningStatistics?>(null)
    val statistics: StateFlow<RunningStatistics?> = _statistics.asStateFlow()

    init {
        loadRecords()
        loadStatistics()
    }

    /**
     * 加载记录列表
     */
    fun loadRecords(page: Int = 1) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = runningRepository.getRecords(page, 20)) {
                is Result.Success -> {
                    _uiState.value = UiState.Idle
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.message ?: "加载失败")
                }
                else -> {}
            }
        }
    }

    /**
     * 加载统计数据
     */
    fun loadStatistics(type: String = "all") {
        viewModelScope.launch {
            when (val result = runningRepository.getStatistics(type)) {
                is Result.Success -> {
                    _statistics.value = result.data
                }
                is Result.Error -> {
                    // 静默处理错误
                }
                else -> {}
            }
        }
    }

    /**
     * 删除记录
     */
    fun deleteRecord(recordId: Int) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = runningRepository.deleteRecord(recordId)) {
                is Result.Success -> {
                    _uiState.value = UiState.Deleted
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.message ?: "删除失败")
                }
                else -> {}
            }
        }
    }

    sealed class UiState {
        object Idle : UiState()
        object Loading : UiState()
        object Deleted : UiState()
        data class Error(val message: String) : UiState()
    }
}
