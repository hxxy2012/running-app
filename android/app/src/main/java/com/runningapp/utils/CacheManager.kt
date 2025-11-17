package com.runningapp.utils

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 缓存管理工具类
 * 管理应用缓存，包括图片缓存、数据缓存等
 */
@Singleton
class CacheManager @Inject constructor(
    @ApplicationContext private val context: Context
) {

    // 缓存目录
    private val cacheDir: File = context.cacheDir
    private val externalCacheDir: File? = context.externalCacheDir

    /**
     * 获取缓存大小（字节）
     */
    suspend fun getCacheSize(): Long = withContext(Dispatchers.IO) {
        var size = 0L
        size += getDirSize(cacheDir)
        externalCacheDir?.let { size += getDirSize(it) }
        size
    }

    /**
     * 获取格式化的缓存大小
     */
    suspend fun getFormattedCacheSize(): String {
        val size = getCacheSize()
        return formatSize(size)
    }

    /**
     * 清除所有缓存
     */
    suspend fun clearAllCache(): Boolean = withContext(Dispatchers.IO) {
        var success = true
        success = clearDir(cacheDir) && success
        externalCacheDir?.let { success = clearDir(it) && success }
        success
    }

    /**
     * 清除图片缓存
     */
    suspend fun clearImageCache(): Boolean = withContext(Dispatchers.IO) {
        val imageDir = File(cacheDir, "images")
        clearDir(imageDir)
    }

    /**
     * 清除过期缓存（超过7天）
     */
    suspend fun clearExpiredCache(days: Int = 7): Long = withContext(Dispatchers.IO) {
        val expireTime = System.currentTimeMillis() - days * 24 * 60 * 60 * 1000L
        var deletedSize = 0L

        fun deleteExpiredFiles(dir: File) {
            dir.listFiles()?.forEach { file ->
                if (file.isDirectory) {
                    deleteExpiredFiles(file)
                } else {
                    if (file.lastModified() < expireTime) {
                        deletedSize += file.length()
                        file.delete()
                    }
                }
            }
        }

        deleteExpiredFiles(cacheDir)
        externalCacheDir?.let { deleteExpiredFiles(it) }
        deletedSize
    }

    /**
     * 获取指定目录的缓存大小
     */
    suspend fun getDirCacheSize(dirName: String): Long = withContext(Dispatchers.IO) {
        val dir = File(cacheDir, dirName)
        if (dir.exists() && dir.isDirectory) {
            getDirSize(dir)
        } else {
            0L
        }
    }

    /**
     * 清除指定目录的缓存
     */
    suspend fun clearDirCache(dirName: String): Boolean = withContext(Dispatchers.IO) {
        val dir = File(cacheDir, dirName)
        if (dir.exists() && dir.isDirectory) {
            clearDir(dir)
        } else {
            true
        }
    }

    /**
     * 保存缓存文件
     */
    suspend fun saveCache(dirName: String, fileName: String, data: ByteArray): File? =
        withContext(Dispatchers.IO) {
            try {
                val dir = File(cacheDir, dirName)
                if (!dir.exists()) {
                    dir.mkdirs()
                }
                val file = File(dir, fileName)
                file.writeBytes(data)
                file
            } catch (e: Exception) {
                Logger.e("CacheManager", "保存缓存失败", e)
                null
            }
        }

    /**
     * 读取缓存文件
     */
    suspend fun readCache(dirName: String, fileName: String): ByteArray? =
        withContext(Dispatchers.IO) {
            try {
                val file = File(File(cacheDir, dirName), fileName)
                if (file.exists()) {
                    file.readBytes()
                } else {
                    null
                }
            } catch (e: Exception) {
                Logger.e("CacheManager", "读取缓存失败", e)
                null
            }
        }

    /**
     * 删除缓存文件
     */
    suspend fun deleteCache(dirName: String, fileName: String): Boolean =
        withContext(Dispatchers.IO) {
            try {
                val file = File(File(cacheDir, dirName), fileName)
                if (file.exists()) {
                    file.delete()
                } else {
                    true
                }
            } catch (e: Exception) {
                Logger.e("CacheManager", "删除缓存失败", e)
                false
            }
        }

    /**
     * 缓存是否存在
     */
    suspend fun cacheExists(dirName: String, fileName: String): Boolean =
        withContext(Dispatchers.IO) {
            val file = File(File(cacheDir, dirName), fileName)
            file.exists()
        }

    /**
     * 获取缓存文件
     */
    fun getCacheFile(dirName: String, fileName: String): File {
        val dir = File(cacheDir, dirName)
        if (!dir.exists()) {
            dir.mkdirs()
        }
        return File(dir, fileName)
    }

    // === 私有方法 ===

    /**
     * 获取目录大小
     */
    private fun getDirSize(dir: File): Long {
        var size = 0L
        dir.listFiles()?.forEach { file ->
            size += if (file.isDirectory) {
                getDirSize(file)
            } else {
                file.length()
            }
        }
        return size
    }

    /**
     * 清空目录
     */
    private fun clearDir(dir: File): Boolean {
        if (!dir.exists()) {
            return true
        }

        var success = true
        dir.listFiles()?.forEach { file ->
            success = if (file.isDirectory) {
                clearDir(file) && file.delete() && success
            } else {
                file.delete() && success
            }
        }
        return success
    }

    /**
     * 格式化文件大小
     */
    private fun formatSize(size: Long): String {
        val kb = 1024.0
        val mb = kb * 1024
        val gb = mb * 1024

        return when {
            size >= gb -> String.format("%.2f GB", size / gb)
            size >= mb -> String.format("%.2f MB", size / mb)
            size >= kb -> String.format("%.2f KB", size / kb)
            else -> "$size B"
        }
    }
}

/**
 * 缓存键生成器
 */
object CacheKeyGenerator {
    /**
     * 生成图片缓存键
     */
    fun imageKey(url: String): String {
        return url.hashCode().toString()
    }

    /**
     * 生成API缓存键
     */
    fun apiKey(endpoint: String, params: Map<String, Any>?): String {
        val paramsStr = params?.entries?.sortedBy { it.key }
            ?.joinToString("&") { "${it.key}=${it.value}" } ?: ""
        return "$endpoint?$paramsStr".hashCode().toString()
    }

    /**
     * 生成用户数据缓存键
     */
    fun userDataKey(userId: Int, dataType: String): String {
        return "user_${userId}_$dataType"
    }
}
