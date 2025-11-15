package com.runningapp.data.repository

import com.runningapp.data.local.dao.UserDao
import com.runningapp.data.remote.ApiService
import com.runningapp.data.remote.model.LoginResponse
import com.runningapp.data.remote.model.RefreshTokenResponse
import com.runningapp.utils.Result
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 认证仓库
 */
@Singleton
class AuthRepository @Inject constructor(
    private val apiService: ApiService,
    private val userDao: UserDao
) {

    /**
     * 发送验证码
     */
    suspend fun sendCode(phone: String, type: String): Result<Unit> {
        return try {
            val response = apiService.sendCode(mapOf("phone" to phone, "type" to type))
            if (response.code == 200) {
                Result.Success(Unit)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 注册
     */
    suspend fun register(phone: String, code: String, password: String): Result<LoginResponse> {
        return try {
            val response = apiService.register(
                mapOf(
                    "phone" to phone,
                    "code" to code,
                    "password" to password
                )
            )
            if (response.code == 200 && response.data != null) {
                // 保存用户信息到本地数据库
                userDao.insertUser(response.data.user.toEntity())
                Result.Success(response.data)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 登录
     */
    suspend fun login(phone: String, password: String): Result<LoginResponse> {
        return try {
            val response = apiService.login(
                mapOf(
                    "phone" to phone,
                    "password" to password
                )
            )
            if (response.code == 200 && response.data != null) {
                // 保存用户信息到本地数据库
                userDao.insertUser(response.data.user.toEntity())
                Result.Success(response.data)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 刷新Token
     */
    suspend fun refreshToken(refreshToken: String): Result<RefreshTokenResponse> {
        return try {
            val response = apiService.refreshToken(mapOf("refresh_token" to refreshToken))
            if (response.code == 200 && response.data != null) {
                Result.Success(response.data)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * OAuth登录
     */
    suspend fun oauthLogin(platform: String, code: String): Result<LoginResponse> {
        return try {
            val response = apiService.oauthLogin(
                mapOf(
                    "platform" to platform,
                    "code" to code
                )
            )
            if (response.code == 200 && response.data != null) {
                userDao.insertUser(response.data.user.toEntity())
                Result.Success(response.data)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }
}
