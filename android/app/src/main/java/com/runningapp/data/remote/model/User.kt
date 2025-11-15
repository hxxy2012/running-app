package com.runningapp.data.remote.model

import com.google.gson.annotations.SerializedName
import com.runningapp.data.local.entity.UserEntity

/**
 * 用户信息
 */
data class User(
    @SerializedName("id")
    val id: Int,
    @SerializedName("phone")
    val phone: String,
    @SerializedName("nickname")
    val nickname: String?,
    @SerializedName("avatar")
    val avatar: String?,
    @SerializedName("gender")
    val gender: Int?,
    @SerializedName("birthday")
    val birthday: String?,
    @SerializedName("height")
    val height: Int?,
    @SerializedName("weight")
    val weight: Int?,
    @SerializedName("city")
    val city: String?,
    @SerializedName("signature")
    val signature: String?,
    @SerializedName("is_real_auth")
    val isRealAuth: Boolean,
    @SerializedName("created_at")
    val createdAt: Long,
    @SerializedName("updated_at")
    val updatedAt: Long
) {
    fun toEntity(): UserEntity {
        return UserEntity(
            id = id,
            phone = phone,
            nickname = nickname,
            avatar = avatar,
            gender = gender,
            birthday = birthday,
            height = height,
            weight = weight,
            city = city,
            signature = signature,
            isRealAuth = isRealAuth,
            createdAt = createdAt,
            updatedAt = updatedAt
        )
    }
}

/**
 * 登录响应
 */
data class LoginResponse(
    @SerializedName("token")
    val token: String,
    @SerializedName("refresh_token")
    val refreshToken: String,
    @SerializedName("user")
    val user: User
)

/**
 * Token刷新响应
 */
data class RefreshTokenResponse(
    @SerializedName("token")
    val token: String,
    @SerializedName("refresh_token")
    val refreshToken: String
)
