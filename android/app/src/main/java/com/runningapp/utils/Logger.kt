package com.runningapp.utils

import android.util.Log
import com.runningapp.BuildConfig

/**
 * 日志工具类
 * 统一管理应用日志输出
 */
object Logger {

    private const val TAG_PREFIX = "RunningApp"
    private var isDebug = BuildConfig.DEBUG

    /**
     * 设置是否启用日志
     */
    fun setDebug(debug: Boolean) {
        isDebug = debug
    }

    /**
     * Verbose日志
     */
    fun v(tag: String, message: String) {
        if (isDebug) {
            Log.v("$TAG_PREFIX:$tag", message)
        }
    }

    /**
     * Debug日志
     */
    fun d(tag: String, message: String) {
        if (isDebug) {
            Log.d("$TAG_PREFIX:$tag", message)
        }
    }

    /**
     * Info日志
     */
    fun i(tag: String, message: String) {
        if (isDebug) {
            Log.i("$TAG_PREFIX:$tag", message)
        }
    }

    /**
     * Warning日志
     */
    fun w(tag: String, message: String, throwable: Throwable? = null) {
        if (isDebug) {
            if (throwable != null) {
                Log.w("$TAG_PREFIX:$tag", message, throwable)
            } else {
                Log.w("$TAG_PREFIX:$tag", message)
            }
        }
    }

    /**
     * Error日志
     */
    fun e(tag: String, message: String, throwable: Throwable? = null) {
        if (isDebug) {
            if (throwable != null) {
                Log.e("$TAG_PREFIX:$tag", message, throwable)
            } else {
                Log.e("$TAG_PREFIX:$tag", message)
            }
        }
    }

    /**
     * 网络请求日志
     */
    fun network(tag: String, method: String, url: String, params: String? = null) {
        if (isDebug) {
            val message = buildString {
                append("$method $url")
                if (!params.isNullOrEmpty()) {
                    append("\nParams: $params")
                }
            }
            d(tag, message)
        }
    }

    /**
     * 网络响应日志
     */
    fun networkResponse(tag: String, url: String, response: String) {
        if (isDebug) {
            d(tag, "Response from $url:\n$response")
        }
    }

    /**
     * 网络错误日志
     */
    fun networkError(tag: String, url: String, error: Throwable) {
        if (isDebug) {
            e(tag, "Network error from $url", error)
        }
    }

    /**
     * 数据库操作日志
     */
    fun database(tag: String, operation: String, table: String, details: String? = null) {
        if (isDebug) {
            val message = buildString {
                append("DB: $operation on $table")
                if (!details.isNullOrEmpty()) {
                    append(" - $details")
                }
            }
            d(tag, message)
        }
    }

    /**
     * 生命周期日志
     */
    fun lifecycle(tag: String, event: String) {
        if (isDebug) {
            i(tag, "Lifecycle: $event")
        }
    }

    /**
     * 导航日志
     */
    fun navigation(tag: String, from: String, to: String) {
        if (isDebug) {
            i(tag, "Navigation: $from -> $to")
        }
    }

    /**
     * 性能日志
     */
    fun performance(tag: String, operation: String, duration: Long) {
        if (isDebug) {
            i(tag, "Performance: $operation took ${duration}ms")
        }
    }

    /**
     * JSON日志（格式化输出）
     */
    fun json(tag: String, json: String) {
        if (isDebug) {
            try {
                // 简单的JSON格式化
                val formatted = json
                    .replace("{", "{\n  ")
                    .replace("}", "\n}")
                    .replace(",", ",\n  ")
                d(tag, "JSON:\n$formatted")
            } catch (e: Exception) {
                d(tag, "JSON: $json")
            }
        }
    }
}

/**
 * 扩展函数：在Any类上添加日志方法
 */
inline fun <reified T> T.logd(message: String) {
    Logger.d(T::class.java.simpleName, message)
}

inline fun <reified T> T.logi(message: String) {
    Logger.i(T::class.java.simpleName, message)
}

inline fun <reified T> T.logw(message: String, throwable: Throwable? = null) {
    Logger.w(T::class.java.simpleName, message, throwable)
}

inline fun <reified T> T.loge(message: String, throwable: Throwable? = null) {
    Logger.e(T::class.java.simpleName, message, throwable)
}
