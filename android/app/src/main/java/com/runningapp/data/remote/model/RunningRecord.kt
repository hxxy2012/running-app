package com.runningapp.data.remote.model

import com.google.gson.annotations.SerializedName
import com.runningapp.data.local.entity.RunningRecordEntity

/**
 * 跑步记录
 */
data class RunningRecord(
    @SerializedName("id")
    val id: Int,
    @SerializedName("user_id")
    val userId: Int,
    @SerializedName("distance")
    val distance: Float,
    @SerializedName("duration")
    val duration: Int,
    @SerializedName("calories")
    val calories: Int,
    @SerializedName("avg_pace")
    val avgPace: Int,
    @SerializedName("avg_speed")
    val avgSpeed: Float,
    @SerializedName("max_speed")
    val maxSpeed: Float,
    @SerializedName("steps")
    val steps: Int?,
    @SerializedName("step_frequency")
    val stepFrequency: Int?,
    @SerializedName("start_time")
    val startTime: Long,
    @SerializedName("end_time")
    val endTime: Long,
    @SerializedName("track_data")
    val trackData: String,
    @SerializedName("elevation_gain")
    val elevationGain: Int?,
    @SerializedName("elevation_loss")
    val elevationLoss: Int?,
    @SerializedName("weather")
    val weather: String?,
    @SerializedName("temperature")
    val temperature: Int?,
    @SerializedName("note")
    val note: String?,
    @SerializedName("images")
    val images: String?,
    @SerializedName("created_at")
    val createdAt: Long,
    @SerializedName("updated_at")
    val updatedAt: Long
) {
    fun toEntity(): RunningRecordEntity {
        return RunningRecordEntity(
            id = id,
            userId = userId,
            distance = distance,
            duration = duration,
            calories = calories,
            avgPace = avgPace,
            avgSpeed = avgSpeed,
            maxSpeed = maxSpeed,
            steps = steps,
            stepFrequency = stepFrequency,
            startTime = startTime,
            endTime = endTime,
            trackData = trackData,
            elevationGain = elevationGain,
            elevationLoss = elevationLoss,
            weather = weather,
            temperature = temperature,
            note = note,
            images = images,
            isSynced = true,
            createdAt = createdAt,
            updatedAt = updatedAt
        )
    }
}

/**
 * 开始跑步响应
 */
data class StartRunningResponse(
    @SerializedName("record_id")
    val recordId: Int
)

/**
 * 跑步统计
 */
data class RunningStatistics(
    @SerializedName("total_distance")
    val totalDistance: Float,
    @SerializedName("total_duration")
    val totalDuration: Int,
    @SerializedName("total_calories")
    val totalCalories: Int,
    @SerializedName("total_count")
    val totalCount: Int,
    @SerializedName("avg_distance")
    val avgDistance: Float,
    @SerializedName("avg_duration")
    val avgDuration: Int,
    @SerializedName("avg_pace")
    val avgPace: Int,
    @SerializedName("best_pace")
    val bestPace: Int?,
    @SerializedName("best_distance")
    val bestDistance: Float?,
    @SerializedName("best_duration")
    val bestDuration: Int?
)

/**
 * 个人最佳记录
 */
data class PersonalBest(
    @SerializedName("best_5k")
    val best5k: RunningRecord?,
    @SerializedName("best_10k")
    val best10k: RunningRecord?,
    @SerializedName("best_half_marathon")
    val bestHalfMarathon: RunningRecord?,
    @SerializedName("best_marathon")
    val bestMarathon: RunningRecord?,
    @SerializedName("longest_distance")
    val longestDistance: RunningRecord?,
    @SerializedName("longest_duration")
    val longestDuration: RunningRecord?
)
