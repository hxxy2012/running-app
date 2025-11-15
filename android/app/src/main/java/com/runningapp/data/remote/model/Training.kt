package com.runningapp.data.remote.model

import com.google.gson.annotations.SerializedName

/**
 * 训练计划
 */
data class TrainingPlan(
    @SerializedName("id")
    val id: Int,
    @SerializedName("name")
    val name: String,
    @SerializedName("description")
    val description: String,
    @SerializedName("level")
    val level: String,
    @SerializedName("duration_weeks")
    val durationWeeks: Int,
    @SerializedName("days_per_week")
    val daysPerWeek: Int,
    @SerializedName("target_distance")
    val targetDistance: Int?,
    @SerializedName("plan_data")
    val planData: String
)

/**
 * 用户训练计划
 */
data class UserTrainingPlan(
    @SerializedName("id")
    val id: Int,
    @SerializedName("plan")
    val plan: TrainingPlan,
    @SerializedName("start_date")
    val startDate: String,
    @SerializedName("current_week")
    val currentWeek: Int,
    @SerializedName("current_day")
    val currentDay: Int,
    @SerializedName("completed_days")
    val completedDays: Int,
    @SerializedName("status")
    val status: Int,
    @SerializedName("progress")
    val progress: Int,
    @SerializedName("created_at")
    val createdAt: Long
)

/**
 * 挑战赛
 */
data class Challenge(
    @SerializedName("id")
    val id: Int,
    @SerializedName("name")
    val name: String,
    @SerializedName("description")
    val description: String,
    @SerializedName("cover_image")
    val coverImage: String?,
    @SerializedName("type")
    val type: Int,
    @SerializedName("target_type")
    val targetType: Int,
    @SerializedName("target_value")
    val targetValue: Int,
    @SerializedName("start_time")
    val startTime: Long,
    @SerializedName("end_time")
    val endTime: Long,
    @SerializedName("participant_count")
    val participantCount: Int,
    @SerializedName("is_joined")
    val isJoined: Boolean,
    @SerializedName("status")
    val status: Int
)

/**
 * 用户挑战
 */
data class UserChallenge(
    @SerializedName("id")
    val id: Int,
    @SerializedName("challenge")
    val challenge: Challenge,
    @SerializedName("current_value")
    val currentValue: Int,
    @SerializedName("progress")
    val progress: Int,
    @SerializedName("is_completed")
    val isCompleted: Boolean,
    @SerializedName("rank")
    val rank: Int?,
    @SerializedName("joined_at")
    val joinedAt: Long
)
