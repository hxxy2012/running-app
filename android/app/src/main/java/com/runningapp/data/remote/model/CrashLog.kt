package com.runningapp.data.remote.model

import com.google.gson.annotations.SerializedName

/**
 * 崩溃日志请求
 */
data class CrashLogRequest(
    @SerializedName("platform")
    val platform: String = "android",

    @SerializedName("app_version")
    val appVersion: String,

    @SerializedName("os_version")
    val osVersion: String,

    @SerializedName("device_model")
    val deviceModel: String,

    @SerializedName("crash_time")
    val crashTime: String,

    @SerializedName("log_content")
    val logContent: String
)
