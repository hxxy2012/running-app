package com.runningapp.data.remote.model

import com.google.gson.annotations.SerializedName

/**
 * API统一响应格式
 */
data class ApiResponse<T>(
    @SerializedName("code")
    val code: Int,
    @SerializedName("message")
    val message: String,
    @SerializedName("data")
    val data: T?
)

/**
 * 分页响应
 */
data class PageResponse<T>(
    @SerializedName("list")
    val list: List<T>,
    @SerializedName("total")
    val total: Int,
    @SerializedName("page")
    val page: Int,
    @SerializedName("page_size")
    val pageSize: Int
)

/**
 * 空响应
 */
class EmptyResponse
