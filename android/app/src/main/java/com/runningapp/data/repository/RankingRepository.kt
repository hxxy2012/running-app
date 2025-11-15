package com.runningapp.data.repository

import com.runningapp.data.remote.ApiService
import com.runningapp.data.remote.model.*
import com.runningapp.utils.Result
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 排行榜和成就仓库
 */
@Singleton
class RankingRepository @Inject constructor(
    private val apiService: ApiService
) {

    /**
     * 获取总排行榜
     */
    suspend fun getTotalRanking(page: Int = 1): Result<PageResponse<RankingItem>> {
        return try {
            val response = apiService.getTotalRanking(page, 50)
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
     * 获取月排行榜
     */
    suspend fun getMonthRanking(page: Int = 1): Result<PageResponse<RankingItem>> {
        return try {
            val response = apiService.getMonthRanking(page, 50)
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
     * 获取周排行榜
     */
    suspend fun getWeekRanking(page: Int = 1): Result<PageResponse<RankingItem>> {
        return try {
            val response = apiService.getWeekRanking(page, 50)
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
     * 获取好友排行榜
     */
    suspend fun getFriendsRanking(page: Int = 1): Result<PageResponse<RankingItem>> {
        return try {
            val response = apiService.getFriendsRanking(page, 50)
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
     * 获取同城排行榜
     */
    suspend fun getCityRanking(city: String, page: Int = 1): Result<PageResponse<RankingItem>> {
        return try {
            val response = apiService.getCityRanking(city, page, 50)
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
     * 获取成就列表
     */
    suspend fun getAchievements(): Result<List<Achievement>> {
        return try {
            val response = apiService.getAchievements()
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
     * 获取我的成就
     */
    suspend fun getMyAchievements(): Result<List<Achievement>> {
        return try {
            val response = apiService.getMyAchievements()
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
