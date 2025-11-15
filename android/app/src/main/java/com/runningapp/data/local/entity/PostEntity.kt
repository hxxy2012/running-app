package com.runningapp.data.local.entity

import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * 动态帖子实体
 */
@Entity(tableName = "post")
data class PostEntity(
    @PrimaryKey
    val id: Int,
    val userId: Int,
    val content: String,
    val images: String?, // JSON数组
    val recordId: Int?, // 关联的跑步记录
    val likeCount: Int = 0,
    val commentCount: Int = 0,
    val isLiked: Boolean = false,
    val createdAt: Long,
    val updatedAt: Long
)

/**
 * 动态帖子详情（包含用户信息）
 */
data class PostWithUser(
    @Embedded
    val post: PostEntity,
    val userNickname: String,
    val userAvatar: String?
)
