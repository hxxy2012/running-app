package com.runningapp.utils

/**
 * 统一结果封装
 */
sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Error(val exception: Exception) : Result<Nothing>()
    object Loading : Result<Nothing>()
}

/**
 * 扩展函数：是否成功
 */
fun <T> Result<T>.isSuccess(): Boolean = this is Result.Success

/**
 * 扩展函数：是否失败
 */
fun <T> Result<T>.isError(): Boolean = this is Result.Error

/**
 * 扩展函数：获取数据或null
 */
fun <T> Result<T>.dataOrNull(): T? {
    return when (this) {
        is Result.Success -> data
        else -> null
    }
}

/**
 * 扩展函数：获取错误信息或null
 */
fun <T> Result<T>.errorOrNull(): Exception? {
    return when (this) {
        is Result.Error -> exception
        else -> null
    }
}
