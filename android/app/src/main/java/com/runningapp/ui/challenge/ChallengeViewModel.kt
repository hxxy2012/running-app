package com.runningapp.ui.challenge

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.runningapp.data.remote.model.Challenge
import com.runningapp.data.remote.model.RankingItem
import com.runningapp.data.remote.model.UserChallenge
import com.runningapp.data.repository.ChallengeRepository
import com.runningapp.utils.Result
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 挑战赛ViewModel
 */
@HiltViewModel
class ChallengeViewModel @Inject constructor(
    private val challengeRepository: ChallengeRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow<UiState>(UiState.Idle)
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    private val _challenges = MutableStateFlow<List<Challenge>>(emptyList())
    val challenges: StateFlow<List<Challenge>> = _challenges.asStateFlow()

    private val _myChallenges = MutableStateFlow<List<UserChallenge>>(emptyList())
    val myChallenges: StateFlow<List<UserChallenge>> = _myChallenges.asStateFlow()

    private val _ranking = MutableStateFlow<List<RankingItem>>(emptyList())
    val ranking: StateFlow<List<RankingItem>> = _ranking.asStateFlow()

    init {
        loadChallenges()
    }

    /**
     * 加载挑战赛列表
     */
    fun loadChallenges(status: String = "ongoing", page: Int = 1) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = challengeRepository.getChallenges(status, page)) {
                is Result.Success -> {
                    if (page == 1) {
                        _challenges.value = result.data.list
                    } else {
                        _challenges.value = _challenges.value + result.data.list
                    }
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
     * 加载我的挑战
     */
    fun loadMyChallenges(page: Int = 1) {
        viewModelScope.launch {
            when (val result = challengeRepository.getMyChallenges(page)) {
                is Result.Success -> {
                    if (page == 1) {
                        _myChallenges.value = result.data.list
                    } else {
                        _myChallenges.value = _myChallenges.value + result.data.list
                    }
                }
                is Result.Error -> {
                    // 静默处理
                }
                else -> {}
            }
        }
    }

    /**
     * 参加挑战
     */
    fun joinChallenge(challengeId: Int) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = challengeRepository.joinChallenge(challengeId)) {
                is Result.Success -> {
                    // 更新列表中的参与状态
                    _challenges.value = _challenges.value.map { challenge ->
                        if (challenge.id == challengeId) {
                            challenge.copy(isJoined = true)
                        } else {
                            challenge
                        }
                    }
                    _uiState.value = UiState.Joined
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.message ?: "参加失败")
                }
                else -> {}
            }
        }
    }

    /**
     * 加载排行榜
     */
    fun loadRanking(challengeId: Int, page: Int = 1) {
        viewModelScope.launch {
            when (val result = challengeRepository.getChallengeRanking(challengeId, page)) {
                is Result.Success -> {
                    if (page == 1) {
                        _ranking.value = result.data.list
                    } else {
                        _ranking.value = _ranking.value + result.data.list
                    }
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
        object Joined : UiState()
        data class Error(val message: String) : UiState()
    }
}
