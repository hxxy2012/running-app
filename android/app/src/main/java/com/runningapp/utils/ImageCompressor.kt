package com.runningapp.utils

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.net.Uri
import androidx.exifinterface.media.ExifInterface
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.max
import kotlin.math.min

/**
 * 图片压缩工具类
 * 支持质量压缩、尺寸压缩、保持宽高比压缩
 */
@Singleton
class ImageCompressor @Inject constructor(
    @ApplicationContext private val context: Context
) {

    /**
     * 压缩配置
     */
    data class CompressConfig(
        val maxWidth: Int = 1080,           // 最大宽度
        val maxHeight: Int = 1920,          // 最大高度
        val quality: Int = 85,              // 压缩质量 0-100
        val format: Bitmap.CompressFormat = Bitmap.CompressFormat.JPEG,  // 输出格式
        val maxSize: Long = 1024 * 1024,   // 最大文件大小（字节）
        val keepExif: Boolean = false       // 是否保留EXIF信息
    )

    /**
     * 压缩图片（从Uri）
     */
    suspend fun compress(uri: Uri, config: CompressConfig = CompressConfig()): File? =
        withContext(Dispatchers.IO) {
            try {
                val inputStream = context.contentResolver.openInputStream(uri) ?: return@withContext null
                compressFromStream(inputStream, config)
            } catch (e: Exception) {
                Logger.e("ImageCompressor", "压缩失败", e)
                null
            }
        }

    /**
     * 压缩图片（从文件路径）
     */
    suspend fun compress(filePath: String, config: CompressConfig = CompressConfig()): File? =
        withContext(Dispatchers.IO) {
            try {
                val file = File(filePath)
                if (!file.exists()) return@withContext null

                val inputStream = file.inputStream()
                compressFromStream(inputStream, config, filePath)
            } catch (e: Exception) {
                Logger.e("ImageCompressor", "压缩失败", e)
                null
            }
        }

    /**
     * 批量压缩图片
     */
    suspend fun compressBatch(
        uris: List<Uri>,
        config: CompressConfig = CompressConfig()
    ): List<File> = withContext(Dispatchers.IO) {
        uris.mapNotNull { uri ->
            compress(uri, config)
        }
    }

    /**
     * 压缩为Bitmap
     */
    suspend fun compressToBitmap(
        uri: Uri,
        config: CompressConfig = CompressConfig()
    ): Bitmap? = withContext(Dispatchers.IO) {
        try {
            val inputStream = context.contentResolver.openInputStream(uri) ?: return@withContext null
            val options = BitmapFactory.Options()

            // 第一次解析，获取图片尺寸
            options.inJustDecodeBounds = true
            BitmapFactory.decodeStream(inputStream, null, options)
            inputStream.close()

            // 计算采样率
            options.inSampleSize = calculateInSampleSize(
                options.outWidth,
                options.outHeight,
                config.maxWidth,
                config.maxHeight
            )

            // 第二次解析，加载图片
            val newInputStream = context.contentResolver.openInputStream(uri)
            options.inJustDecodeBounds = false
            val bitmap = BitmapFactory.decodeStream(newInputStream, null, options)
            newInputStream?.close()

            // 缩放到目标尺寸
            bitmap?.let { scaleBitmap(it, config.maxWidth, config.maxHeight) }
        } catch (e: Exception) {
            Logger.e("ImageCompressor", "压缩为Bitmap失败", e)
            null
        }
    }

    /**
     * 从输入流压缩
     */
    private fun compressFromStream(
        inputStream: InputStream,
        config: CompressConfig,
        originalPath: String? = null
    ): File? {
        try {
            val options = BitmapFactory.Options()

            // 第一次解析，获取图片尺寸
            options.inJustDecodeBounds = true
            val bytes = inputStream.readBytes()
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)

            // 计算采样率
            options.inSampleSize = calculateInSampleSize(
                options.outWidth,
                options.outHeight,
                config.maxWidth,
                config.maxHeight
            )

            // 第二次解析，加载图片
            options.inJustDecodeBounds = false
            var bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)
                ?: return null

            // 旋转图片（根据EXIF信息）
            originalPath?.let {
                bitmap = rotateBitmapIfNeeded(bitmap, it)
            }

            // 缩放到目标尺寸
            bitmap = scaleBitmap(bitmap, config.maxWidth, config.maxHeight)

            // 保存到临时文件
            val outputFile = createTempFile()
            var quality = config.quality

            // 如果文件大小超过限制，降低质量
            do {
                val fos = FileOutputStream(outputFile)
                bitmap.compress(config.format, quality, fos)
                fos.flush()
                fos.close()

                if (outputFile.length() <= config.maxSize || quality <= 10) {
                    break
                }

                quality -= 10
            } while (true)

            // 保留EXIF信息（仅JPEG格式）
            if (config.keepExif && config.format == Bitmap.CompressFormat.JPEG && originalPath != null) {
                copyExifInfo(originalPath, outputFile.path)
            }

            bitmap.recycle()

            Logger.d("ImageCompressor", "压缩成功: ${outputFile.length()} bytes, quality: $quality")
            return outputFile

        } catch (e: Exception) {
            Logger.e("ImageCompressor", "压缩失败", e)
            return null
        }
    }

    /**
     * 计算采样率
     */
    private fun calculateInSampleSize(
        width: Int,
        height: Int,
        maxWidth: Int,
        maxHeight: Int
    ): Int {
        var inSampleSize = 1

        if (width > maxWidth || height > maxHeight) {
            val halfWidth = width / 2
            val halfHeight = height / 2

            while (halfWidth / inSampleSize >= maxWidth && halfHeight / inSampleSize >= maxHeight) {
                inSampleSize *= 2
            }
        }

        return inSampleSize
    }

    /**
     * 缩放Bitmap
     */
    private fun scaleBitmap(bitmap: Bitmap, maxWidth: Int, maxHeight: Int): Bitmap {
        val width = bitmap.width
        val height = bitmap.height

        if (width <= maxWidth && height <= maxHeight) {
            return bitmap
        }

        val scale = min(maxWidth.toFloat() / width, maxHeight.toFloat() / height)
        val matrix = Matrix()
        matrix.postScale(scale, scale)

        val scaledBitmap = Bitmap.createBitmap(bitmap, 0, 0, width, height, matrix, true)
        if (scaledBitmap != bitmap) {
            bitmap.recycle()
        }

        return scaledBitmap
    }

    /**
     * 根据EXIF信息旋转图片
     */
    private fun rotateBitmapIfNeeded(bitmap: Bitmap, path: String): Bitmap {
        try {
            val exif = ExifInterface(path)
            val orientation = exif.getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL
            )

            val degree = when (orientation) {
                ExifInterface.ORIENTATION_ROTATE_90 -> 90f
                ExifInterface.ORIENTATION_ROTATE_180 -> 180f
                ExifInterface.ORIENTATION_ROTATE_270 -> 270f
                else -> 0f
            }

            if (degree != 0f) {
                val matrix = Matrix()
                matrix.postRotate(degree)
                val rotated = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
                if (rotated != bitmap) {
                    bitmap.recycle()
                }
                return rotated
            }
        } catch (e: Exception) {
            Logger.e("ImageCompressor", "读取EXIF信息失败", e)
        }

        return bitmap
    }

    /**
     * 复制EXIF信息
     */
    private fun copyExifInfo(sourcePath: String, destPath: String) {
        try {
            val sourceExif = ExifInterface(sourcePath)
            val destExif = ExifInterface(destPath)

            val attributes = listOf(
                ExifInterface.TAG_DATETIME,
                ExifInterface.TAG_GPS_LATITUDE,
                ExifInterface.TAG_GPS_LONGITUDE,
                ExifInterface.TAG_GPS_ALTITUDE,
                ExifInterface.TAG_MAKE,
                ExifInterface.TAG_MODEL,
                ExifInterface.TAG_ORIENTATION
            )

            attributes.forEach { tag ->
                sourceExif.getAttribute(tag)?.let { value ->
                    destExif.setAttribute(tag, value)
                }
            }

            destExif.saveAttributes()
        } catch (e: Exception) {
            Logger.e("ImageCompressor", "复制EXIF信息失败", e)
        }
    }

    /**
     * 创建临时文件
     */
    private fun createTempFile(): File {
        val cacheDir = context.cacheDir
        val imageDir = File(cacheDir, "compressed")
        if (!imageDir.exists()) {
            imageDir.mkdirs()
        }

        return File.createTempFile("compressed_", ".jpg", imageDir)
    }

    /**
     * 获取图片信息
     */
    fun getImageInfo(uri: Uri): ImageInfo? {
        return try {
            val inputStream = context.contentResolver.openInputStream(uri) ?: return null
            val options = BitmapFactory.Options()
            options.inJustDecodeBounds = true
            BitmapFactory.decodeStream(inputStream, null, options)
            inputStream.close()

            ImageInfo(
                width = options.outWidth,
                height = options.outHeight,
                mimeType = options.outMimeType ?: "unknown"
            )
        } catch (e: Exception) {
            Logger.e("ImageCompressor", "获取图片信息失败", e)
            null
        }
    }

    data class ImageInfo(
        val width: Int,
        val height: Int,
        val mimeType: String
    )
}
