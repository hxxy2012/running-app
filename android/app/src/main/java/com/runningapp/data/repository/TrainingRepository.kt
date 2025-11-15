package com.runningapp.data.repository

import com.runningapp.data.remote.ApiService
import com.runningapp.data.remote.model.*
import com.runningapp.utils.Result
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 训练计划仓库
 */
@Singleton
class TrainingRepository @Inject constructor(
    private val apiService: ApiService
) {

    /**
     * 获取训练计划列表
     */
    suspend fun getTrainingPlans(): Result<List<TrainingPlan>> {
        return try {
            val response = apiService.getTrainingPlans()
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
     * 获取训练计划详情
     */
    suspend fun getTrainingPlanDetail(planId: Int): Result<TrainingPlan> {
        return try {
            val response = apiService.getTrainingPlanDetail(planId)
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
     * 加入训练计划
     */
    suspend fun joinTrainingPlan(planId: Int, startDate: String): Result<UserTrainingPlan> {
        return try {
            val response = apiService.joinTrainingPlan(
                mapOf(
                    "plan_id" to planId,
                    "start_date" to startDate
                )
            )
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
     * 获取我的训练计划
     */
    suspend fun getMyTrainingPlan(): Result<UserTrainingPlan> {
        return try {
            val response = apiService.getMyTrainingPlan()
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
     * 完成某一天训练
     */
    suspend fun completeTrainingDay(planId: Int, week: Int, day: Int): Result<Unit> {
        return try {
            val response = apiService.completeTrainingDay(
                mapOf(
                    "plan_id" to planId,
                    "week" to week,
                    "day" to day
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
     * 放弃训练计划
     */
    suspend fun abandonTrainingPlan(planId: Int): Result<Unit> {
        return try {
            val response = apiService.abandonTrainingPlan(planId)
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
