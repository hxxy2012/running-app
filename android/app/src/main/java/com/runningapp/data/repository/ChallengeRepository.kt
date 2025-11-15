package com.runningapp.data.repository

import com.runningapp.data.remote.ApiService
import com.runningapp.data.remote.model.*
import com.runningapp.utils.Result
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 挑战赛仓库
 */
@Singleton
class ChallengeRepository @Inject constructor(
    private val apiService: ApiService
) {

    /**
     * 获取挑战赛列表
     */
    suspend fun getChallenges(status: String = "ongoing", page: Int = 1): Result<PageResponse<Challenge>> {
        return try {
            val response = apiService.getChallenges(status, page, 20)
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
     * 获取挑战赛详情
     */
    suspend fun getChallengeDetail(challengeId: Int): Result<Challenge> {
        return try {
            val response = apiService.getChallengeDetail(challengeId)
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
     * 参加挑战赛
     */
    suspend fun joinChallenge(challengeId: Int): Result<Unit> {
        return try {
            val response = apiService.joinChallenge(mapOf("challenge_id" to challengeId))
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
     * 获取挑战赛排行榜
     */
    suspend fun getChallengeRanking(challengeId: Int, page: Int = 1): Result<PageResponse<RankingItem>> {
        return try {
            val response = apiService.getChallengeRanking(challengeId, page, 20)
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
     * 获取我的挑战
     */
    suspend fun getMyChallenges(page: Int = 1): Result<PageResponse<UserChallenge>> {
        return try {
            val response = apiService.getMyChallenges(page, 20)
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
