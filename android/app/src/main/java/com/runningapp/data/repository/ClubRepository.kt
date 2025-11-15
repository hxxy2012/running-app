package com.runningapp.data.repository

import com.runningapp.data.remote.ApiService
import com.runningapp.data.remote.model.*
import com.runningapp.utils.Result
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 跑团仓库
 */
@Singleton
class ClubRepository @Inject constructor(
    private val apiService: ApiService
) {

    /**
     * 创建跑团
     */
    suspend fun createClub(
        name: String,
        description: String?,
        city: String?
    ): Result<RunningClub> {
        return try {
            val params = mutableMapOf<String, Any>(
                "name" to name
            )
            description?.let { params["description"] = it }
            city?.let { params["city"] = it }

            val response = apiService.createClub(params)
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
     * 获取跑团列表
     */
    suspend fun getClubs(city: String? = null, page: Int = 1): Result<PageResponse<RunningClub>> {
        return try {
            val response = apiService.getClubs(city, page, 20)
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
     * 获取跑团详情
     */
    suspend fun getClubDetail(clubId: Int): Result<RunningClub> {
        return try {
            val response = apiService.getClubDetail(clubId)
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
     * 加入跑团
     */
    suspend fun joinClub(clubId: Int): Result<Unit> {
        return try {
            val response = apiService.joinClub(mapOf("club_id" to clubId))
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
     * 退出跑团
     */
    suspend fun quitClub(clubId: Int): Result<Unit> {
        return try {
            val response = apiService.quitClub(clubId)
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
     * 获取跑团成员
     */
    suspend fun getClubMembers(clubId: Int, page: Int = 1): Result<PageResponse<ClubMember>> {
        return try {
            val response = apiService.getClubMembers(clubId, page, 20)
            if (response.code == 200 && response.data != null) {
                Result.Success(response.data)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }
}
