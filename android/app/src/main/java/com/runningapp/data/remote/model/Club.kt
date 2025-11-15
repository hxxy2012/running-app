package com.runningapp.data.remote.model

import com.google.gson.annotations.SerializedName

/**
 * 跑团
 */
data class RunningClub(
    @SerializedName("id")
    val id: Int,
    @SerializedName("name")
    val name: String,
    @SerializedName("description")
    val description: String?,
    @SerializedName("avatar")
    val avatar: String?,
    @SerializedName("city")
    val city: String?,
    @SerializedName("member_count")
    val memberCount: Int,
    @SerializedName("total_distance")
    val totalDistance: Float,
    @SerializedName("creator_id")
    val creatorId: Int,
    @SerializedName("is_joined")
    val isJoined: Boolean,
    @SerializedName("created_at")
    val createdAt: Long
)

/**
 * 跑团成员
 */
data class ClubMember(
    @SerializedName("user")
    val user: User,
    @SerializedName("role")
    val role: Int,
    @SerializedName("total_distance")
    val totalDistance: Float,
    @SerializedName("total_count")
    val totalCount: Int,
    @SerializedName("joined_at")
    val joinedAt: Long
)

/**
 * 排行榜项
 */
data class RankingItem(
    @SerializedName("rank")
    val rank: Int,
    @SerializedName("user")
    val user: User,
    @SerializedName("value")
    val value: Float,
    @SerializedName("count")
    val count: Int?
)

/**
 * 成就
 */
data class Achievement(
    @SerializedName("id")
    val id: Int,
    @SerializedName("name")
    val name: String,
    @SerializedName("description")
    val description: String,
    @SerializedName("icon")
    val icon: String,
    @SerializedName("type")
    val type: Int,
    @SerializedName("target_value")
    val targetValue: Int,
    @SerializedName("is_unlocked")
    val isUnlocked: Boolean,
    @SerializedName("unlocked_at")
    val unlockedAt: Long?
)
