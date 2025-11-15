package com.runningapp.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * 用户实体
 */
@Entity(tableName = "user")
data class UserEntity(
    @PrimaryKey
    val id: Int,
    val phone: String,
    val nickname: String?,
    val avatar: String?,
    val gender: Int?, // 0-未知, 1-男, 2-女
    val birthday: String?,
    val height: Int?,
    val weight: Int?,
    val city: String?,
    val signature: String?,
    val isRealAuth: Boolean = false,
    val createdAt: Long,
    val updatedAt: Long
)
