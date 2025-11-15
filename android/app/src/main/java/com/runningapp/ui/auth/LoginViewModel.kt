package com.runningapp.ui.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.runningapp.data.remote.model.LoginResponse
import com.runningapp.data.repository.AuthRepository
import com.runningapp.utils.PreferenceManager
import com.runningapp.utils.Result
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 登录ViewModel
 */
@HiltViewModel
class LoginViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val preferenceManager: PreferenceManager
) : ViewModel() {

    private val _uiState = MutableStateFlow<UiState>(UiState.Idle)
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    /**
     * 发送验证码
     */
    fun sendCode(phone: String) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = authRepository.sendCode(phone, "login")) {
                is Result.Success -> {
                    _uiState.value = UiState.CodeSent
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.message ?: "发送失败")
                }
                else -> {}
            }
        }
    }

    /**
     * 密码登录
     */
    fun login(phone: String, password: String) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = authRepository.login(phone, password)) {
                is Result.Success -> {
                    saveLoginInfo(result.data)
                    _uiState.value = UiState.Success(result.data)
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.message ?: "登录失败")
                }
                else -> {}
            }
        }
    }

    /**
     * 验证码登录
     */
    fun loginWithCode(phone: String, code: String) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = authRepository.loginWithCode(phone, code)) {
                is Result.Success -> {
                    saveLoginInfo(result.data)
                    _uiState.value = UiState.Success(result.data)
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.message ?: "登录失败")
                }
                else -> {}
            }
        }
    }

    /**
     * 注册
     */
    fun register(phone: String, code: String, password: String) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = authRepository.register(phone, code, password)) {
                is Result.Success -> {
                    saveLoginInfo(result.data)
                    _uiState.value = UiState.Success(result.data)
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.message ?: "注册失败")
                }
                else -> {}
            }
        }
    }

    /**
     * 保存登录信息
     */
    private fun saveLoginInfo(loginResponse: LoginResponse) {
        preferenceManager.saveLoginInfo(
            accessToken = loginResponse.token,
            refreshToken = loginResponse.refreshToken,
            userId = loginResponse.user.id
        )
    }

    sealed class UiState {
        object Idle : UiState()
        object Loading : UiState()
        object CodeSent : UiState()
        data class Success(val loginResponse: LoginResponse) : UiState()
        data class Error(val message: String) : UiState()
    }
}
