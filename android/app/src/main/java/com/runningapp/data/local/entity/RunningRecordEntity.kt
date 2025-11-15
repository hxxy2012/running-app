package com.runningapp.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * 跑步记录实体
 */
@Entity(tableName = "running_record")
data class RunningRecordEntity(
    @PrimaryKey
    val id: Int,
    val userId: Int,
    val distance: Float, // 距离(米)
    val duration: Int, // 时长(秒)
    val calories: Int, // 卡路里
    val avgPace: Int, // 平均配速(秒/公里)
    val avgSpeed: Float, // 平均速度(km/h)
    val maxSpeed: Float, // 最大速度(km/h)
    val steps: Int?, // 步数
    val stepFrequency: Int?, // 步频(步/分钟)
    val startTime: Long, // 开始时间戳
    val endTime: Long, // 结束时间戳
    val trackData: String, // 轨迹数据JSON
    val elevationGain: Int?, // 累计爬升(米)
    val elevationLoss: Int?, // 累计下降(米)
    val weather: String?, // 天气
    val temperature: Int?, // 温度
    val note: String?, // 备注
    val images: String?, // 图片JSON数组
    val isSynced: Boolean = false, // 是否已同步到服务器
    val createdAt: Long,
    val updatedAt: Long
)
