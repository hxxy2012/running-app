package com.runningapp.utils

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import androidx.core.content.FileProvider
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.File
import java.io.FileOutputStream
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 分享助手
 * 提供分享文本、图片、文件等功能
 */
@Singleton
class ShareHelper @Inject constructor(
    @ApplicationContext private val context: Context
) {

    companion object {
        private const val SHARE_CACHE_DIR = "share_cache"
    }

    // MARK: - 分享文本

    /**
     * 分享纯文本
     */
    fun shareText(
        text: String,
        subject: String? = null,
        chooserTitle: String = "分享到"
    ) {
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, text)
            subject?.let { putExtra(Intent.EXTRA_SUBJECT, it) }
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }

        val chooser = Intent.createChooser(intent, chooserTitle)
        chooser.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(chooser)
    }

    // MARK: - 分享图片

    /**
     * 分享单张图片
     */
    fun shareImage(
        imageUri: Uri,
        text: String? = null,
        chooserTitle: String = "分享图片"
    ) {
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "image/*"
            putExtra(Intent.EXTRA_STREAM, imageUri)
            text?.let { putExtra(Intent.EXTRA_TEXT, it) }
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }

        val chooser = Intent.createChooser(intent, chooserTitle)
        chooser.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(chooser)
    }

    /**
     * 分享Bitmap图片
     */
    fun shareBitmap(
        bitmap: Bitmap,
        text: String? = null,
        fileName: String = "share_${System.currentTimeMillis()}.jpg",
        chooserTitle: String = "分享图片"
    ) {
        try {
            val uri = saveBitmapToCache(bitmap, fileName)
            shareImage(uri, text, chooserTitle)
        } catch (e: Exception) {
            Logger.e("ShareHelper", "Share bitmap failed", e)
        }
    }

    /**
     * 分享多张图片
     */
    fun shareImages(
        imageUris: List<Uri>,
        text: String? = null,
        chooserTitle: String = "分享图片"
    ) {
        if (imageUris.isEmpty()) return

        if (imageUris.size == 1) {
            shareImage(imageUris[0], text, chooserTitle)
            return
        }

        val intent = Intent(Intent.ACTION_SEND_MULTIPLE).apply {
            type = "image/*"
            putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(imageUris))
            text?.let { putExtra(Intent.EXTRA_TEXT, it) }
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }

        val chooser = Intent.createChooser(intent, chooserTitle)
        chooser.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(chooser)
    }

    // MARK: - 分享文件

    /**
     * 分享单个文件
     */
    fun shareFile(
        fileUri: Uri,
        mimeType: String = "*/*",
        chooserTitle: String = "分享文件"
    ) {
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = mimeType
            putExtra(Intent.EXTRA_STREAM, fileUri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }

        val chooser = Intent.createChooser(intent, chooserTitle)
        chooser.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(chooser)
    }

    // MARK: - 跑步数据分享

    /**
     * 分享跑步记录
     */
    fun shareRunningRecord(
        distance: Float,
        duration: Int,
        pace: Float,
        calories: Float,
        additionalText: String? = null
    ) {
        val distanceText = distance.toDistanceString()
        val durationText = duration.toDurationString()
        val paceMinKm = (pace / 60).let {
            String.format("%d'%02d\"", it.toInt(), ((it % 1) * 60).toInt())
        }

        val shareText = buildString {
            append("🏃 我的跑步记录\n\n")
            append("📏 距离：$distanceText\n")
            append("⏱️ 用时：$durationText\n")
            append("⚡ 配速：$paceMinKm/km\n")
            append("🔥 卡路里：${calories.toInt()} kcal\n")
            additionalText?.let { append("\n$it\n") }
            append("\n#跑步 #运动 #健康生活")
        }

        shareText(shareText, subject = "我的跑步记录")
    }

    /**
     * 分享跑步记录（带图片）
     */
    fun shareRunningRecordWithImage(
        distance: Float,
        duration: Int,
        imageUri: Uri,
        additionalText: String? = null
    ) {
        val distanceText = distance.toDistanceString()
        val durationText = duration.toDurationString()

        val shareText = buildString {
            append("🏃 我完成了一次跑步\n")
            append("📏 $distanceText  ⏱️ $durationText\n")
            additionalText?.let { append("$it\n") }
            append("#跑步 #运动")
        }

        shareImage(imageUri, shareText)
    }

    /**
     * 分享成就
     */
    fun shareAchievement(
        achievementName: String,
        achievementDescription: String,
        imageUri: Uri? = null
    ) {
        val shareText = buildString {
            append("🏆 解锁新成就！\n\n")
            append("$achievementName\n")
            append("$achievementDescription\n\n")
            append("#成就解锁 #跑步 #坚持")
        }

        if (imageUri != null) {
            shareImage(imageUri, shareText)
        } else {
            shareText(shareText)
        }
    }

    // MARK: - 辅助方法

    /**
     * 保存Bitmap到缓存目录并返回Uri
     */
    private fun saveBitmapToCache(bitmap: Bitmap, fileName: String): Uri {
        val cacheDir = File(context.cacheDir, SHARE_CACHE_DIR)
        if (!cacheDir.exists()) {
            cacheDir.mkdirs()
        }

        val imageFile = File(cacheDir, fileName)
        FileOutputStream(imageFile).use { out ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, 90, out)
        }

        return FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            imageFile
        )
    }

    /**
     * 清理分享缓存
     */
    fun clearShareCache() {
        try {
            val cacheDir = File(context.cacheDir, SHARE_CACHE_DIR)
            if (cacheDir.exists() && cacheDir.isDirectory) {
                cacheDir.listFiles()?.forEach { it.delete() }
            }
        } catch (e: Exception) {
            Logger.e("ShareHelper", "Clear share cache failed", e)
        }
    }

    /**
     * 检查是否可以分享
     */
    fun canShare(): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
            }
            val activities = context.packageManager.queryIntentActivities(intent, 0)
            activities.isNotEmpty()
        } catch (e: Exception) {
            false
        }
    }
}

/**
 * 扩展函数：快速分享文本
 */
fun Context.shareText(text: String, chooserTitle: String = "分享到") {
    val shareHelper = ShareHelper(applicationContext)
    shareHelper.shareText(text, chooserTitle = chooserTitle)
}

/**
 * 扩展函数：快速分享图片
 */
fun Context.shareImage(imageUri: Uri, text: String? = null, chooserTitle: String = "分享图片") {
    val shareHelper = ShareHelper(applicationContext)
    shareHelper.shareImage(imageUri, text, chooserTitle)
}
