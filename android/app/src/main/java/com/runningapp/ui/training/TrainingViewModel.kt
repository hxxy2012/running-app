package com.runningapp.ui.training

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.runningapp.data.remote.model.TrainingPlan
import com.runningapp.data.remote.model.UserTrainingPlan
import com.runningapp.data.repository.TrainingRepository
import com.runningapp.utils.Result
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 训练计划ViewModel
 */
@HiltViewModel
class TrainingViewModel @Inject constructor(
    private val trainingRepository: TrainingRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow<UiState>(UiState.Idle)
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    private val _plans = MutableStateFlow<List<TrainingPlan>>(emptyList())
    val plans: StateFlow<List<TrainingPlan>> = _plans.asStateFlow()

    private val _myPlan = MutableStateFlow<UserTrainingPlan?>(null)
    val myPlan: StateFlow<UserTrainingPlan?> = _myPlan.asStateFlow()

    init {
        loadTrainingPlans()
        loadMyPlan()
    }

    /**
     * 加载训练计划列表
     */
    fun loadTrainingPlans() {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = trainingRepository.getTrainingPlans()) {
                is Result.Success -> {
                    _plans.value = result.data
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
     * 加载我的训练计划
     */
    fun loadMyPlan() {
        viewModelScope.launch {
            when (val result = trainingRepository.getMyTrainingPlan()) {
                is Result.Success -> {
                    _myPlan.value = result.data
                }
                is Result.Error -> {
                    // 静默处理，可能还没有训练计划
                }
                else -> {}
            }
        }
    }

    /**
     * 加入训练计划
     */
    fun joinPlan(planId: Int, startDate: String) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = trainingRepository.joinTrainingPlan(planId, startDate)) {
                is Result.Success -> {
                    _myPlan.value = result.data
                    _uiState.value = UiState.Joined
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.message ?: "加入失败")
                }
                else -> {}
            }
        }
    }

    /**
     * 完成某一天训练
     */
    fun completeDay(planId: Int, week: Int, day: Int) {
        viewModelScope.launch {
            when (val result = trainingRepository.completeTrainingDay(planId, week, day)) {
                is Result.Success -> {
                    loadMyPlan() // 重新加载计划
                    _uiState.value = UiState.DayCompleted
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.message ?: "完成失败")
                }
                else -> {}
            }
        }
    }

    /**
     * 放弃训练计划
     */
    fun abandonPlan(planId: Int) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = trainingRepository.abandonTrainingPlan(planId)) {
                is Result.Success -> {
                    _myPlan.value = null
                    _uiState.value = UiState.Abandoned
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.message ?: "操作失败")
                }
                else -> {}
            }
        }
    }

    sealed class UiState {
        object Idle : UiState()
        object Loading : UiState()
        object Joined : UiState()
        object DayCompleted : UiState()
        object Abandoned : UiState()
        data class Error(val message: String) : UiState()
    }
}
