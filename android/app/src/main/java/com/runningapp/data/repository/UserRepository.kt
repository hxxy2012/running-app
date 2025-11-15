package com.runningapp.data.repository

import com.runningapp.data.local.dao.UserDao
import com.runningapp.data.local.entity.UserEntity
import com.runningapp.data.remote.ApiService
import com.runningapp.data.remote.model.User
import com.runningapp.utils.Result
import kotlinx.coroutines.flow.Flow
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 用户仓库
 */
@Singleton
class UserRepository @Inject constructor(
    private val apiService: ApiService,
    private val userDao: UserDao
) {

    /**
     * 获取本地用户信息
     */
    fun getUserLocal(userId: Int): Flow<UserEntity?> {
        return userDao.getUserByIdFlow(userId)
    }

    /**
     * 获取用户信息
     */
    suspend fun getProfile(): Result<User> {
        return try {
            val response = apiService.getProfile()
            if (response.code == 200 && response.data != null) {
                userDao.insertUser(response.data.toEntity())
                Result.Success(response.data)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 更新用户信息
     */
    suspend fun updateProfile(params: Map<String, Any>): Result<User> {
        return try {
            val response = apiService.updateProfile(params)
            if (response.code == 200 && response.data != null) {
                userDao.insertUser(response.data.toEntity())
                Result.Success(response.data)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 上传头像
     */
    suspend fun uploadAvatar(file: File): Result<String> {
        return try {
            val requestFile = file.asRequestBody("image/*".toMediaTypeOrNull())
            val body = MultipartBody.Part.createFormData("avatar", file.name, requestFile)

            val response = apiService.uploadAvatar(body)
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
     * 修改密码
     */
    suspend fun changePassword(oldPassword: String, newPassword: String): Result<Unit> {
        return try {
            val response = apiService.changePassword(
                mapOf(
                    "old_password" to oldPassword,
                    "new_password" to newPassword
                )
            )
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
     * 删除账号
     */
    suspend fun deleteAccount(password: String): Result<Unit> {
        return try {
            val response = apiService.deleteAccount(mapOf("password" to password))
            if (response.code == 200) {
                Result.Success(Unit)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }
}
