package com.runningapp.data.remote.model

import com.google.gson.annotations.SerializedName

/**
 * 动态帖子
 */
data class Post(
    @SerializedName("id")
    val id: Int,
    @SerializedName("user_id")
    val userId: Int,
    @SerializedName("user")
    val user: User?,
    @SerializedName("content")
    val content: String,
    @SerializedName("images")
    val images: List<String>?,
    @SerializedName("record_id")
    val recordId: Int?,
    @SerializedName("record")
    val record: RunningRecord?,
    @SerializedName("like_count")
    val likeCount: Int,
    @SerializedName("comment_count")
    val commentCount: Int,
    @SerializedName("is_liked")
    val isLiked: Boolean,
    @SerializedName("created_at")
    val createdAt: Long,
    @SerializedName("updated_at")
    val updatedAt: Long
)

/**
 * 评论
 */
data class Comment(
    @SerializedName("id")
    val id: Int,
    @SerializedName("post_id")
    val postId: Int,
    @SerializedName("user_id")
    val userId: Int,
    @SerializedName("user")
    val user: User?,
    @SerializedName("content")
    val content: String,
    @SerializedName("reply_to_user_id")
    val replyToUserId: Int?,
    @SerializedName("reply_to_user")
    val replyToUser: User?,
    @SerializedName("created_at")
    val createdAt: Long
)
