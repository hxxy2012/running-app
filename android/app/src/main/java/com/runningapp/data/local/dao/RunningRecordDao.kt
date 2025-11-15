package com.runningapp.data.local.dao

import androidx.room.*
import com.runningapp.data.local.entity.RunningRecordEntity
import kotlinx.coroutines.flow.Flow

/**
 * 跑步记录数据访问对象
 */
@Dao
interface RunningRecordDao {

    @Query("SELECT * FROM running_record WHERE userId = :userId ORDER BY startTime DESC")
    fun getRecordsByUserId(userId: Int): Flow<List<RunningRecordEntity>>

    @Query("SELECT * FROM running_record WHERE userId = :userId ORDER BY startTime DESC LIMIT :limit OFFSET :offset")
    suspend fun getRecordsPage(userId: Int, limit: Int, offset: Int): List<RunningRecordEntity>

    @Query("SELECT * FROM running_record WHERE id = :recordId")
    suspend fun getRecordById(recordId: Int): RunningRecordEntity?

    @Query("SELECT * FROM running_record WHERE id = :recordId")
    fun getRecordByIdFlow(recordId: Int): Flow<RunningRecordEntity?>

    @Query("SELECT * FROM running_record WHERE userId = :userId AND isSynced = 0")
    suspend fun getUnsyncedRecords(userId: Int): List<RunningRecordEntity>

    @Query("SELECT * FROM running_record WHERE userId = :userId AND startTime >= :startTime AND startTime <= :endTime")
    suspend fun getRecordsByTimeRange(userId: Int, startTime: Long, endTime: Long): List<RunningRecordEntity>

    @Query("SELECT SUM(distance) FROM running_record WHERE userId = :userId")
    suspend fun getTotalDistance(userId: Int): Float?

    @Query("SELECT SUM(duration) FROM running_record WHERE userId = :userId")
    suspend fun getTotalDuration(userId: Int): Int?

    @Query("SELECT COUNT(*) FROM running_record WHERE userId = :userId")
    suspend fun getTotalCount(userId: Int): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertRecord(record: RunningRecordEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertRecords(records: List<RunningRecordEntity>)

    @Update
    suspend fun updateRecord(record: RunningRecordEntity)

    @Query("UPDATE running_record SET isSynced = 1 WHERE id = :recordId")
    suspend fun markAsSynced(recordId: Int)

    @Delete
    suspend fun deleteRecord(record: RunningRecordEntity)

    @Query("DELETE FROM running_record WHERE id = :recordId")
    suspend fun deleteRecordById(recordId: Int)

    @Query("DELETE FROM running_record")
    suspend fun deleteAllRecords()
}
