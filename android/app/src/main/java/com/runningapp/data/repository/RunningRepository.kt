package com.runningapp.data.repository

import com.runningapp.data.local.dao.RunningRecordDao
import com.runningapp.data.local.dao.TrackPointDao
import com.runningapp.data.local.entity.RunningRecordEntity
import com.runningapp.data.local.entity.TrackPointEntity
import com.runningapp.data.remote.ApiService
import com.runningapp.data.remote.model.*
import com.runningapp.utils.Result
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 跑步仓库
 */
@Singleton
class RunningRepository @Inject constructor(
    private val apiService: ApiService,
    private val runningRecordDao: RunningRecordDao,
    private val trackPointDao: TrackPointDao
) {

    /**
     * 获取本地跑步记录列表
     */
    fun getRecordsLocal(userId: Int): Flow<List<RunningRecordEntity>> {
        return runningRecordDao.getRecordsByUserId(userId)
    }

    /**
     * 获取本地跑步记录详情
     */
    fun getRecordDetailLocal(recordId: Int): Flow<RunningRecordEntity?> {
        return runningRecordDao.getRecordByIdFlow(recordId)
    }

    /**
     * 获取本地轨迹点
     */
    fun getTrackPointsLocal(recordId: Int): Flow<List<TrackPointEntity>> {
        return trackPointDao.getTrackPointsByRecordIdFlow(recordId)
    }

    /**
     * 保存轨迹点到本地
     */
    suspend fun saveTrackPointLocal(point: TrackPointEntity) {
        trackPointDao.insertTrackPoint(point)
    }

    /**
     * 保存跑步记录到本地
     */
    suspend fun saveRecordLocal(record: RunningRecordEntity): Long {
        return runningRecordDao.insertRecord(record)
    }

    /**
     * 更新本地跑步记录
     */
    suspend fun updateRecordLocal(record: RunningRecordEntity) {
        runningRecordDao.updateRecord(record)
    }

    /**
     * 开始跑步
     */
    suspend fun startRunning(): Result<StartRunningResponse> {
        return try {
            val response = apiService.startRunning()
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
     * 上传轨迹点
     */
    suspend fun uploadTrackPoint(recordId: Int, points: List<Map<String, Any>>): Result<Unit> {
        return try {
            val response = apiService.uploadTrackPoint(
                mapOf(
                    "record_id" to recordId,
                    "points" to points
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
     * 结束跑步
     */
    suspend fun finishRunning(
        recordId: Int,
        distance: Float,
        duration: Int,
        calories: Int,
        trackData: String
    ): Result<RunningRecord> {
        return try {
            val response = apiService.finishRunning(
                mapOf(
                    "record_id" to recordId,
                    "distance" to distance,
                    "duration" to duration,
                    "calories" to calories,
                    "track_data" to trackData
                )
            )
            if (response.code == 200 && response.data != null) {
                // 保存到本地数据库
                runningRecordDao.insertRecord(response.data.toEntity())
                Result.Success(response.data)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 获取跑步记录列表
     */
    suspend fun getRecords(page: Int = 1, pageSize: Int = 20): Result<PageResponse<RunningRecord>> {
        return try {
            val response = apiService.getRecords(page, pageSize)
            if (response.code == 200 && response.data != null) {
                // 保存到本地数据库
                response.data.list.forEach { record ->
                    runningRecordDao.insertRecord(record.toEntity())
                }
                Result.Success(response.data)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 获取跑步记录详情
     */
    suspend fun getRecordDetail(recordId: Int): Result<RunningRecord> {
        return try {
            val response = apiService.getRecordDetail(recordId)
            if (response.code == 200 && response.data != null) {
                runningRecordDao.insertRecord(response.data.toEntity())
                Result.Success(response.data)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 删除跑步记录
     */
    suspend fun deleteRecord(recordId: Int): Result<Unit> {
        return try {
            val response = apiService.deleteRecord(recordId)
            if (response.code == 200) {
                runningRecordDao.deleteRecordById(recordId)
                trackPointDao.deleteTrackPointsByRecordId(recordId)
                Result.Success(Unit)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 获取跑步统计
     */
    suspend fun getStatistics(type: String): Result<RunningStatistics> {
        return try {
            val response = apiService.getStatistics(type)
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
     * 获取个人最佳记录
     */
    suspend fun getPersonalBest(): Result<PersonalBest> {
        return try {
            val response = apiService.getPersonalBest()
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
