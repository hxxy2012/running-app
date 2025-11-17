package com.runningapp.data.remote

import com.runningapp.data.remote.dto.*
import com.runningapp.data.remote.model.*
import retrofit2.http.*

/**
 * API Service接口
 * 定义所有的网络请求
 */
interface ApiService {

    // ========== 认证相关 ==========

    @POST("auth/send-code")
    suspend fun sendCode(@Body request: SendCodeRequest): ApiResponse<Any>

    @POST("auth/register")
    suspend fun register(@Body request: RegisterRequest): ApiResponse<LoginResponse>

    @POST("auth/login")
    suspend fun login(@Body request: LoginRequest): ApiResponse<LoginResponse>

    @POST("auth/refresh-token")
    suspend fun refreshToken(): ApiResponse<TokenResponse>

    // ========== 用户相关 ==========

    @GET("user/profile")
    suspend fun getProfile(@Query("user_id") userId: Int? = null): ApiResponse<UserDto>

    @PUT("user/profile")
    suspend fun updateProfile(@Body request: UpdateProfileRequest): ApiResponse<UserDto>

    @Multipart
    @POST("user/avatar")
    suspend fun uploadAvatar(@Part file: okhttp3.MultipartBody.Part): ApiResponse<UploadResponse>

    // ========== 跑步记录 ==========

    @POST("running/start")
    suspend fun startRunning(@Body request: StartRunningRequest): ApiResponse<StartRunningResponse>

    @POST("running/upload-point")
    suspend fun uploadTrackPoints(@Body request: UploadPointsRequest): ApiResponse<UploadPointsResponse>

    @POST("running/finish")
    suspend fun finishRunning(@Body request: FinishRunningRequest): ApiResponse<RunningRecordDto>

    @GET("running/records")
    suspend fun getRunningRecords(
        @Query("page") page: Int,
        @Query("page_size") pageSize: Int,
        @Query("type") type: Int? = null
    ): ApiResponse<PaginatedResponse<RunningRecordDto>>

    @GET("running/record/{id}")
    suspend fun getRunningRecordDetail(@Path("id") id: Int): ApiResponse<RunningRecordDetailDto>

    @GET("running/statistics")
    suspend fun getStatistics(@Query("type") type: String): ApiResponse<StatisticsDto>

    // ========== 社交相关 ==========

    @GET("post/feed")
    suspend fun getFeed(
        @Query("page") page: Int,
        @Query("page_size") pageSize: Int
    ): ApiResponse<PaginatedResponse<PostDto>>

    @GET("post/square")
    suspend fun getSquare(
        @Query("page") page: Int,
        @Query("page_size") pageSize: Int
    ): ApiResponse<PaginatedResponse<PostDto>>

    @POST("post")
    suspend fun createPost(@Body request: CreatePostRequest): ApiResponse<PostDto>

    @POST("post/{id}/like")
    suspend fun likePost(@Path("id") id: Int): ApiResponse<Any>

    @DELETE("post/{id}/like")
    suspend fun unlikePost(@Path("id") id: Int): ApiResponse<Any>

    // ========== 文件上传 ==========

    @Multipart
    @POST("upload/image")
    suspend fun uploadImage(
        @Part file: okhttp3.MultipartBody.Part,
        @Query("type") type: String
    ): ApiResponse<UploadResponse>

    // ========== 公共接口 ==========

    @GET("config")
    suspend fun getConfig(): ApiResponse<ConfigDto>

    @GET("common/weather")
    suspend fun getWeather(
        @Query("city") city: String? = null,
        @Query("lat") lat: Double? = null,
        @Query("lon") lon: Double? = null
    ): ApiResponse<WeatherDto>

    // ========== 崩溃日志 ==========

    @POST("crash/upload")
    suspend fun uploadCrashLog(@Body request: CrashLogRequest): ApiResponse<Any>

    @Multipart
    @POST("crash/upload-file")
    suspend fun uploadCrashFile(
        @Part file: okhttp3.MultipartBody.Part,
        @Query("platform") platform: String,
        @Query("app_version") appVersion: String
    ): ApiResponse<Any>
}
