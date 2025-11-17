package com.runningapp.utils

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import java.text.DecimalFormat
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.abs

/**
 * 数据格式化工具类
 * 提供日期、时间、距离、配速、时长等数据的格式化功能
 */
@Singleton
class FormatUtils @Inject constructor(
    @ApplicationContext private val context: Context
) {

    companion object {
        // 日期格式
        const val FORMAT_FULL = "yyyy-MM-dd HH:mm:ss"
        const val FORMAT_DATE = "yyyy-MM-dd"
        const val FORMAT_TIME = "HH:mm:ss"
        const val FORMAT_DATE_TIME = "yyyy-MM-dd HH:mm"
        const val FORMAT_MONTH_DAY = "MM-dd"
        const val FORMAT_HOUR_MINUTE = "HH:mm"
        const val FORMAT_CHINESE_FULL = "yyyy年MM月dd日 HH:mm"
        const val FORMAT_CHINESE_DATE = "yyyy年MM月dd日"
        const val FORMAT_CHINESE_MONTH_DAY = "MM月dd日"

        // 距离单位阈值
        const val DISTANCE_THRESHOLD_KM = 1000f // 1公里

        // 配速单位
        const val PACE_UNIT_MIN_KM = "min/km"
        const val PACE_UNIT_MIN_MI = "min/mi"
    }

    // MARK: - 日期时间格式化

    /**
     * 格式化日期时间
     * @param dateString 日期字符串
     * @param inputFormat 输入格式
     * @param outputFormat 输出格式
     * @return 格式化后的字符串
     */
    fun formatDate(
        dateString: String,
        inputFormat: String = FORMAT_FULL,
        outputFormat: String = FORMAT_DATE_TIME
    ): String {
        return try {
            val inputFormatter = SimpleDateFormat(inputFormat, Locale.getDefault())
            val outputFormatter = SimpleDateFormat(outputFormat, Locale.getDefault())
            val date = inputFormatter.parse(dateString) ?: return dateString
            outputFormatter.format(date)
        } catch (e: Exception) {
            Logger.e("FormatUtils", "Format date failed", e)
            dateString
        }
    }

    /**
     * 格式化时间戳
     * @param timestamp 时间戳（毫秒）
     * @param format 格式
     * @return 格式化后的字符串
     */
    fun formatTimestamp(timestamp: Long, format: String = FORMAT_DATE_TIME): String {
        return try {
            val formatter = SimpleDateFormat(format, Locale.getDefault())
            formatter.format(Date(timestamp))
        } catch (e: Exception) {
            Logger.e("FormatUtils", "Format timestamp failed", e)
            timestamp.toString()
        }
    }

    /**
     * 相对时间格式化（如：刚刚、5分钟前、昨天、3天前等）
     * @param dateString 日期字符串
     * @param format 输入格式
     * @return 相对时间描述
     */
    fun formatRelativeTime(dateString: String, format: String = FORMAT_FULL): String {
        return try {
            val formatter = SimpleDateFormat(format, Locale.getDefault())
            val date = formatter.parse(dateString) ?: return dateString
            formatRelativeTime(date.time)
        } catch (e: Exception) {
            Logger.e("FormatUtils", "Format relative time failed", e)
            dateString
        }
    }

    /**
     * 相对时间格式化（时间戳版本）
     * @param timestamp 时间戳（毫秒）
     * @return 相对时间描述
     */
    fun formatRelativeTime(timestamp: Long): String {
        val now = System.currentTimeMillis()
        val diff = now - timestamp

        return when {
            diff < 0 -> "未来"
            diff < 60_000 -> "刚刚" // 1分钟内
            diff < 3600_000 -> "${diff / 60_000}分钟前" // 1小时内
            diff < 86400_000 -> "${diff / 3600_000}小时前" // 24小时内
            diff < 172800_000 -> "昨天" // 48小时内
            diff < 259200_000 -> "前天" // 72小时内
            diff < 604800_000 -> "${diff / 86400_000}天前" // 7天内
            diff < 2592000_000 -> "${diff / 604800_000}周前" // 30天内
            diff < 31536000_000 -> "${diff / 2592000_000}个月前" // 1年内
            else -> "${diff / 31536000_000}年前"
        }
    }

    // MARK: - 距离格式化

    /**
     * 格式化距离（米转换为合适单位）
     * @param meters 距离（米）
     * @param precision 小数位数
     * @param includeUnit 是否包含单位
     * @return 格式化后的距离字符串
     */
    fun formatDistance(meters: Float, precision: Int = 2, includeUnit: Boolean = true): String {
        val (value, unit) = if (meters >= DISTANCE_THRESHOLD_KM) {
            val km = meters / 1000f
            Pair(km, "km")
        } else {
            Pair(meters, "m")
        }

        val format = if (precision > 0) {
            "0.${"#".repeat(precision)}"
        } else {
            "0"
        }

        val formattedValue = DecimalFormat(format).format(value)
        return if (includeUnit) "$formattedValue $unit" else formattedValue
    }

    /**
     * 格式化距离（只返回数值，总是以公里为单位）
     * @param meters 距离（米）
     * @param precision 小数位数
     * @return 公里数
     */
    fun formatDistanceKm(meters: Float, precision: Int = 2): String {
        val km = meters / 1000f
        val format = "0.${"#".repeat(precision)}"
        return DecimalFormat(format).format(km)
    }

    // MARK: - 配速格式化

    /**
     * 格式化配速（秒/米转换为分/公里）
     * @param secondsPerMeter 配速（秒/米）
     * @param includeUnit 是否包含单位
     * @return 格式化后的配速字符串（如：5'30" 或 5'30"/km）
     */
    fun formatPace(secondsPerMeter: Float, includeUnit: Boolean = true): String {
        if (secondsPerMeter <= 0) {
            return if (includeUnit) "--'--\"" else "--'--\""
        }

        val secondsPerKm = secondsPerMeter * 1000
        val minutes = (secondsPerKm / 60).toInt()
        val seconds = (secondsPerKm % 60).toInt()

        val paceStr = String.format("%d'%02d\"", minutes, seconds)
        return if (includeUnit) "$paceStr/$PACE_UNIT_MIN_KM" else paceStr
    }

    /**
     * 格式化配速（分钟/公里）
     * @param minutesPerKm 配速（分/公里）
     * @param includeUnit 是否包含单位
     * @return 格式化后的配速字符串
     */
    fun formatPaceFromMinutes(minutesPerKm: Float, includeUnit: Boolean = true): String {
        if (minutesPerKm <= 0) {
            return if (includeUnit) "--'--\"" else "--'--\""
        }

        val minutes = minutesPerKm.toInt()
        val seconds = ((minutesPerKm - minutes) * 60).toInt()

        val paceStr = String.format("%d'%02d\"", minutes, seconds)
        return if (includeUnit) "$paceStr/$PACE_UNIT_MIN_KM" else paceStr
    }

    // MARK: - 时长格式化

    /**
     * 格式化时长（秒转换为可读格式）
     * @param seconds 时长（秒）
     * @param format 格式类型：full(完整)、short(简短)、compact(紧凑)
     * @return 格式化后的时长字符串
     */
    fun formatDuration(seconds: Int, format: DurationFormat = DurationFormat.FULL): String {
        if (seconds <= 0) return when (format) {
            DurationFormat.FULL -> "0秒"
            DurationFormat.SHORT -> "0s"
            DurationFormat.COMPACT -> "00:00"
        }

        val hours = seconds / 3600
        val minutes = (seconds % 3600) / 60
        val secs = seconds % 60

        return when (format) {
            DurationFormat.FULL -> buildString {
                if (hours > 0) append("${hours}小时")
                if (minutes > 0) append("${minutes}分钟")
                if (secs > 0 || (hours == 0 && minutes == 0)) append("${secs}秒")
            }
            DurationFormat.SHORT -> buildString {
                if (hours > 0) append("${hours}h ")
                if (minutes > 0) append("${minutes}m ")
                if (secs > 0 || (hours == 0 && minutes == 0)) append("${secs}s")
            }.trim()
            DurationFormat.COMPACT -> {
                if (hours > 0) {
                    String.format("%d:%02d:%02d", hours, minutes, secs)
                } else {
                    String.format("%02d:%02d", minutes, secs)
                }
            }
        }
    }

    /**
     * 格式化时长（毫秒版本）
     * @param milliseconds 时长（毫秒）
     * @param format 格式类型
     * @return 格式化后的时长字符串
     */
    fun formatDurationMillis(milliseconds: Long, format: DurationFormat = DurationFormat.FULL): String {
        return formatDuration((milliseconds / 1000).toInt(), format)
    }

    // MARK: - 数字格式化

    /**
     * 格式化数字（添加千位分隔符）
     * @param number 数字
     * @param precision 小数位数
     * @return 格式化后的数字字符串
     */
    fun formatNumber(number: Number, precision: Int = 0): String {
        val pattern = if (precision > 0) {
            "#,##0.${"0".repeat(precision)}"
        } else {
            "#,##0"
        }
        return DecimalFormat(pattern).format(number)
    }

    /**
     * 格式化卡路里
     * @param calories 卡路里
     * @param includeUnit 是否包含单位
     * @return 格式化后的卡路里字符串
     */
    fun formatCalories(calories: Float, includeUnit: Boolean = true): String {
        val formatted = formatNumber(calories, 0)
        return if (includeUnit) "$formatted kcal" else formatted
    }

    /**
     * 格式化步数
     * @param steps 步数
     * @param includeUnit 是否包含单位
     * @return 格式化后的步数字符串
     */
    fun formatSteps(steps: Int, includeUnit: Boolean = true): String {
        val formatted = formatNumber(steps)
        return if (includeUnit) "$formatted 步" else formatted
    }

    /**
     * 格式化心率
     * @param heartRate 心率
     * @param includeUnit 是否包含单位
     * @return 格式化后的心率字符串
     */
    fun formatHeartRate(heartRate: Int, includeUnit: Boolean = true): String {
        return if (includeUnit) "$heartRate bpm" else heartRate.toString()
    }

    /**
     * 格式化海拔
     * @param altitude 海拔（米）
     * @param includeUnit 是否包含单位
     * @return 格式化后的海拔字符串
     */
    fun formatAltitude(altitude: Float, includeUnit: Boolean = true): String {
        val formatted = formatNumber(altitude, 1)
        return if (includeUnit) "$formatted m" else formatted
    }

    /**
     * 格式化速度（米/秒转换为公里/小时）
     * @param metersPerSecond 速度（米/秒）
     * @param precision 小数位数
     * @param includeUnit 是否包含单位
     * @return 格式化后的速度字符串
     */
    fun formatSpeed(metersPerSecond: Float, precision: Int = 2, includeUnit: Boolean = true): String {
        val kmPerHour = metersPerSecond * 3.6f
        val format = "0.${"#".repeat(precision)}"
        val formatted = DecimalFormat(format).format(kmPerHour)
        return if (includeUnit) "$formatted km/h" else formatted
    }

    // MARK: - 百分比格式化

    /**
     * 格式化百分比
     * @param value 数值（0-1或0-100）
     * @param isDecimal 是否为小数形式（true: 0-1, false: 0-100）
     * @param precision 小数位数
     * @return 格式化后的百分比字符串
     */
    fun formatPercentage(value: Float, isDecimal: Boolean = true, precision: Int = 1): String {
        val percentage = if (isDecimal) value * 100 else value
        val format = "0.${"#".repeat(precision)}"
        return "${DecimalFormat(format).format(percentage)}%"
    }

    // MARK: - 文件大小格式化

    /**
     * 格式化文件大小
     * @param bytes 字节数
     * @param precision 小数位数
     * @return 格式化后的文件大小字符串
     */
    fun formatFileSize(bytes: Long, precision: Int = 2): String {
        if (bytes < 0) return "0 B"

        val units = arrayOf("B", "KB", "MB", "GB", "TB")
        var size = bytes.toDouble()
        var unitIndex = 0

        while (size >= 1024 && unitIndex < units.size - 1) {
            size /= 1024
            unitIndex++
        }

        val format = if (unitIndex == 0) "0" else "0.${"#".repeat(precision)}"
        return "${DecimalFormat(format).format(size)} ${units[unitIndex]}"
    }

    // MARK: - 辅助枚举

    enum class DurationFormat {
        FULL,    // 1小时23分45秒
        SHORT,   // 1h 23m 45s
        COMPACT  // 1:23:45 或 23:45
    }
}

// MARK: - 扩展函数

/**
 * Float扩展：格式化为距离
 */
fun Float.toDistanceString(precision: Int = 2, includeUnit: Boolean = true): String {
    return if (this >= 1000) {
        val km = this / 1000
        val format = "0.${"#".repeat(precision)}"
        val formatted = DecimalFormat(format).format(km)
        if (includeUnit) "$formatted km" else formatted
    } else {
        val formatted = DecimalFormat("0").format(this)
        if (includeUnit) "$formatted m" else formatted
    }
}

/**
 * Int扩展：格式化为时长
 */
fun Int.toDurationString(format: FormatUtils.DurationFormat = FormatUtils.DurationFormat.COMPACT): String {
    val hours = this / 3600
    val minutes = (this % 3600) / 60
    val seconds = this % 60

    return when (format) {
        FormatUtils.DurationFormat.FULL -> buildString {
            if (hours > 0) append("${hours}小时")
            if (minutes > 0) append("${minutes}分钟")
            if (seconds > 0 || (hours == 0 && minutes == 0)) append("${seconds}秒")
        }
        FormatUtils.DurationFormat.SHORT -> buildString {
            if (hours > 0) append("${hours}h ")
            if (minutes > 0) append("${minutes}m ")
            if (seconds > 0 || (hours == 0 && minutes == 0)) append("${seconds}s")
        }.trim()
        FormatUtils.DurationFormat.COMPACT -> {
            if (hours > 0) {
                String.format("%d:%02d:%02d", hours, minutes, seconds)
            } else {
                String.format("%02d:%02d", minutes, seconds)
            }
        }
    }
}

/**
 * Long扩展：格式化为相对时间
 */
fun Long.toRelativeTimeString(): String {
    val now = System.currentTimeMillis()
    val diff = now - this

    return when {
        diff < 0 -> "未来"
        diff < 60_000 -> "刚刚"
        diff < 3600_000 -> "${diff / 60_000}分钟前"
        diff < 86400_000 -> "${diff / 3600_000}小时前"
        diff < 172800_000 -> "昨天"
        diff < 259200_000 -> "前天"
        diff < 604800_000 -> "${diff / 86400_000}天前"
        diff < 2592000_000 -> "${diff / 604800_000}周前"
        diff < 31536000_000 -> "${diff / 2592000_000}个月前"
        else -> "${diff / 31536000_000}年前"
    }
}
