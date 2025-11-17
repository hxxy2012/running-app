package com.runningapp.utils

import retrofit2.HttpException
import java.io.IOException
import java.net.SocketTimeoutException
import java.net.UnknownHostException

/**
 * 错误处理工具类
 * 将各种异常转换为用户友好的错误消息
 */
object ErrorHandler {

    /**
     * 获取用户友好的错误消息
     */
    fun getErrorMessage(throwable: Throwable): String {
        return when (throwable) {
            // 网络异常
            is UnknownHostException -> "网络连接失败，请检查网络设置"
            is SocketTimeoutException -> "网络请求超时，请稍后重试"
            is IOException -> "网络异常，请检查网络连接"

            // HTTP异常
            is HttpException -> {
                when (throwable.code()) {
                    400 -> "请求参数错误"
                    401 -> "未授权，请重新登录"
                    403 -> "禁止访问"
                    404 -> "请求的资源不存在"
                    408 -> "请求超时，请稍后重试"
                    429 -> "请求过于频繁，请稍后再试"
                    500 -> "服务器内部错误"
                    502 -> "网关错误"
                    503 -> "服务暂时不可用，请稍后重试"
                    504 -> "网关超时"
                    else -> "网络错误：${throwable.code()}"
                }
            }

            // 自定义异常
            is ApiException -> throwable.message ?: "请求失败"

            // 其他异常
            else -> throwable.message ?: "未知错误"
        }
    }

    /**
     * 根据错误类型获取建议操作
     */
    fun getSuggestion(throwable: Throwable): String? {
        return when (throwable) {
            is UnknownHostException -> "请确认已连接到互联网"
            is SocketTimeoutException -> "网络较慢，建议切换到更稳定的网络"
            is HttpException -> {
                when (throwable.code()) {
                    401 -> "请重新登录"
                    429 -> "请等待一段时间后再试"
                    500, 502, 503, 504 -> "服务器繁忙，请稍后再试"
                    else -> null
                }
            }
            else -> null
        }
    }

    /**
     * 判断是否为网络问题
     */
    fun isNetworkError(throwable: Throwable): Boolean {
        return throwable is UnknownHostException ||
                throwable is SocketTimeoutException ||
                throwable is IOException
    }

    /**
     * 判断是否为服务器错误
     */
    fun isServerError(throwable: Throwable): Boolean {
        if (throwable is HttpException) {
            return throwable.code() in 500..599
        }
        return false
    }

    /**
     * 判断是否需要重新登录
     */
    fun needsReLogin(throwable: Throwable): Boolean {
        if (throwable is HttpException) {
            return throwable.code() == 401
        }
        return false
    }

    /**
     * 判断错误是否可重试
     */
    fun isRetryable(throwable: Throwable): Boolean {
        return when (throwable) {
            is SocketTimeoutException -> true
            is HttpException -> {
                when (throwable.code()) {
                    408, 429, 500, 502, 503, 504 -> true
                    else -> false
                }
            }
            else -> false
        }
    }
}

/**
 * 自定义API异常
 */
class ApiException(
    override val message: String,
    val code: Int = -1,
    val data: Any? = null
) : Exception(message)

/**
 * 扩展函数：将异常转换为错误消息
 */
fun Throwable.toErrorMessage(): String {
    return ErrorHandler.getErrorMessage(this)
}

/**
 * 扩展函数：将异常转换为ApiException
 */
fun Throwable.toApiException(): ApiException {
    return when (this) {
        is ApiException -> this
        else -> ApiException(ErrorHandler.getErrorMessage(this))
    }
}
