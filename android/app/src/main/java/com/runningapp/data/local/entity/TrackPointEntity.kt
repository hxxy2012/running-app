package com.runningapp.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * 轨迹点实体
 */
@Entity(tableName = "track_point")
data class TrackPointEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val recordId: Int, // 关联的跑步记录ID
    val latitude: Double, // 纬度
    val longitude: Double, // 经度
    val altitude: Double?, // 海拔
    val speed: Float?, // 速度(m/s)
    val accuracy: Float?, // 精度(米)
    val timestamp: Long // 时间戳
)
