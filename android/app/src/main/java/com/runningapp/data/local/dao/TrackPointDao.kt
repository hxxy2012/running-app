package com.runningapp.data.local.dao

import androidx.room.*
import com.runningapp.data.local.entity.TrackPointEntity
import kotlinx.coroutines.flow.Flow

/**
 * 轨迹点数据访问对象
 */
@Dao
interface TrackPointDao {

    @Query("SELECT * FROM track_point WHERE recordId = :recordId ORDER BY timestamp ASC")
    suspend fun getTrackPointsByRecordId(recordId: Int): List<TrackPointEntity>

    @Query("SELECT * FROM track_point WHERE recordId = :recordId ORDER BY timestamp ASC")
    fun getTrackPointsByRecordIdFlow(recordId: Int): Flow<List<TrackPointEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTrackPoint(point: TrackPointEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTrackPoints(points: List<TrackPointEntity>)

    @Query("DELETE FROM track_point WHERE recordId = :recordId")
    suspend fun deleteTrackPointsByRecordId(recordId: Int)

    @Query("DELETE FROM track_point")
    suspend fun deleteAllTrackPoints()
}
