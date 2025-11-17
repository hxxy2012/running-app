package com.runningapp.ui.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.runningapp.data.local.entity.UserEntity
import com.runningapp.data.remote.model.User
import com.runningapp.data.repository.UserRepository
import com.runningapp.utils.PreferenceManager
import com.runningapp.utils.Result
import com.runningapp.utils.toErrorMessage
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.io.File
import javax.inject.Inject

/**
 * 个人中心ViewModel
 */
@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val userRepository: UserRepository,
    private val preferenceManager: PreferenceManager
) : ViewModel() {

    // 本地用户信息
    val user: StateFlow<UserEntity?> = userRepository
        .getUserLocal(preferenceManager.getUserId())
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = null
        )

    // UI状态
    private val _uiState = MutableStateFlow<UiState>(UiState.Idle)
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    init {
        refreshProfile()
    }

    /**
     * 刷新用户信息
     */
    fun refreshProfile() {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = userRepository.getProfile()) {
                is Result.Success -> {
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
     * 更新个人信息
     */
    fun updateProfile(params: Map<String, Any>) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = userRepository.updateProfile(params)) {
                is Result.Success -> {
                    _uiState.value = UiState.Updated
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.toErrorMessage())
                }
                else -> {}
            }
        }
    }

    /**
     * 上传头像
     */
    fun uploadAvatar(file: File) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = userRepository.uploadAvatar(file)) {
                is Result.Success -> {
                    _uiState.value = UiState.AvatarUploaded(result.data)
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.toErrorMessage())
                }
                else -> {}
            }
        }
    }

    /**
     * 修改密码
     */
    fun changePassword(oldPassword: String, newPassword: String) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = userRepository.changePassword(oldPassword, newPassword)) {
                is Result.Success -> {
                    _uiState.value = UiState.PasswordChanged
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.toErrorMessage())
                }
                else -> {}
            }
        }
    }

    /**
     * 退出登录
     */
    fun logout() {
        preferenceManager.clearLoginInfo()
        _uiState.value = UiState.LoggedOut
    }

    sealed class UiState {
        object Idle : UiState()
        object Loading : UiState()
        object Updated : UiState()
        object PasswordChanged : UiState()
        object LoggedOut : UiState()
        data class AvatarUploaded(val url: String) : UiState()
        data class Error(val message: String) : UiState()
    }
}
