package com.runningapp.ui.ranking

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.runningapp.data.remote.model.Achievement
import com.runningapp.data.remote.model.RankingItem
import com.runningapp.data.repository.RankingRepository
import com.runningapp.utils.Result
import com.runningapp.utils.toErrorMessage
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 排行榜ViewModel
 */
@HiltViewModel
class RankingViewModel @Inject constructor(
    private val rankingRepository: RankingRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow<UiState>(UiState.Idle)
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    private val _rankingList = MutableStateFlow<List<RankingItem>>(emptyList())
    val rankingList: StateFlow<List<RankingItem>> = _rankingList.asStateFlow()

    private val _achievements = MutableStateFlow<List<Achievement>>(emptyList())
    val achievements: StateFlow<List<Achievement>> = _achievements.asStateFlow()

    private val _myAchievements = MutableStateFlow<List<Achievement>>(emptyList())
    val myAchievements: StateFlow<List<Achievement>> = _myAchievements.asStateFlow()

    init {
        loadTotalRanking()
    }

    /**
     * 加载总排行榜
     */
    fun loadTotalRanking(page: Int = 1) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = rankingRepository.getTotalRanking(page)) {
                is Result.Success -> {
                    if (page == 1) {
                        _rankingList.value = result.data.list
                    } else {
                        _rankingList.value = _rankingList.value + result.data.list
                    }
                    _uiState.value = UiState.Idle
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.toErrorMessage())
                }
                else -> {}
            }
        }
    }

    /**
     * 加载月排行榜
     */
    fun loadMonthRanking(page: Int = 1) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = rankingRepository.getMonthRanking(page)) {
                is Result.Success -> {
                    if (page == 1) {
                        _rankingList.value = result.data.list
                    } else {
                        _rankingList.value = _rankingList.value + result.data.list
                    }
                    _uiState.value = UiState.Idle
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.toErrorMessage())
                }
                else -> {}
            }
        }
    }

    /**
     * 加载周排行榜
     */
    fun loadWeekRanking(page: Int = 1) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = rankingRepository.getWeekRanking(page)) {
                is Result.Success -> {
                    if (page == 1) {
                        _rankingList.value = result.data.list
                    } else {
                        _rankingList.value = _rankingList.value + result.data.list
                    }
                    _uiState.value = UiState.Idle
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.toErrorMessage())
                }
                else -> {}
            }
        }
    }

    /**
     * 加载好友排行榜
     */
    fun loadFriendsRanking(page: Int = 1) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = rankingRepository.getFriendsRanking(page)) {
                is Result.Success -> {
                    if (page == 1) {
                        _rankingList.value = result.data.list
                    } else {
                        _rankingList.value = _rankingList.value + result.data.list
                    }
                    _uiState.value = UiState.Idle
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.toErrorMessage())
                }
                else -> {}
            }
        }
    }

    /**
     * 加载同城排行榜
     */
    fun loadCityRanking(city: String, page: Int = 1) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = rankingRepository.getCityRanking(city, page)) {
                is Result.Success -> {
                    if (page == 1) {
                        _rankingList.value = result.data.list
                    } else {
                        _rankingList.value = _rankingList.value + result.data.list
                    }
                    _uiState.value = UiState.Idle
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.toErrorMessage())
                }
                else -> {}
            }
        }
    }

    /**
     * 加载成就列表
     */
    fun loadAchievements() {
        viewModelScope.launch {
            when (val result = rankingRepository.getAchievements()) {
                is Result.Success -> {
                    _achievements.value = result.data
                }
                is Result.Error -> {
                    // 静默处理
                }
                else -> {}
            }
        }
    }

    /**
     * 加载我的成就
     */
    fun loadMyAchievements() {
        viewModelScope.launch {
            when (val result = rankingRepository.getMyAchievements()) {
                is Result.Success -> {
                    _myAchievements.value = result.data
                }
                is Result.Error -> {
                    // 静默处理
                }
                else -> {}
            }
        }
    }

    sealed class UiState {
        object Idle : UiState()
        object Loading : UiState()
        data class Error(val message: String) : UiState()
    }
}
