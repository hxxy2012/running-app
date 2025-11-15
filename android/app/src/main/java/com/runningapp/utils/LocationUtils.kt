package com.runningapp.utils

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.os.Build
import androidx.core.content.ContextCompat
import com.runningapp.data.local.entity.TrackPointEntity
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * 位置工具类
 */
object LocationUtils {

    /**
     * 检查位置权限
     */
    fun hasLocationPermission(context: Context): Boolean {
        val fineLocationGranted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        val coarseLocationGranted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        // Android 10及以上需要后台位置权限
        val backgroundLocationGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }

        return fineLocationGranted && coarseLocationGranted && backgroundLocationGranted
    }

    /**
     * 需要的位置权限
     */
    fun getRequiredLocationPermissions(): Array<String> {
        val permissions = mutableListOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            permissions.add(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
        }

        return permissions.toTypedArray()
    }

    /**
     * 计算两点间距离（米）
     */
    fun calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Float {
        val results = FloatArray(1)
        Location.distanceBetween(lat1, lon1, lat2, lon2, results)
        return results[0]
    }

    /**
     * 计算轨迹总距离
     */
    fun calculateTotalDistance(points: List<TrackPointEntity>): Float {
        if (points.size < 2) return 0f

        var totalDistance = 0f
        for (i in 0 until points.size - 1) {
            totalDistance += calculateDistance(
                points[i].latitude,
                points[i].longitude,
                points[i + 1].latitude,
                points[i + 1].longitude
            )
        }

        return totalDistance
    }

    /**
     * 计算配速（秒/公里）
     */
    fun calculatePace(distanceMeters: Float, durationSeconds: Int): Int {
        if (distanceMeters <= 0) return 0
        val distanceKm = distanceMeters / 1000
        return (durationSeconds / distanceKm).toInt()
    }

    /**
     * 计算速度（km/h）
     */
    fun calculateSpeed(distanceMeters: Float, durationSeconds: Int): Float {
        if (durationSeconds <= 0) return 0f
        val distanceKm = distanceMeters / 1000
        val durationHours = durationSeconds / 3600f
        return distanceKm / durationHours
    }

    /**
     * 计算卡路里
     * 简化公式: 卡路里 = 体重(kg) × 距离(km) × 1.036
     */
    fun calculateCalories(distanceMeters: Float, weightKg: Int = 70): Int {
        val distanceKm = distanceMeters / 1000
        return (weightKg * distanceKm * 1.036).toInt()
    }

    /**
     * 格式化距离
     */
    fun formatDistance(meters: Float): String {
        return if (meters < 1000) {
            String.format("%.0f 米", meters)
        } else {
            String.format("%.2f 公里", meters / 1000)
        }
    }

    /**
     * 格式化配速
     */
    fun formatPace(secondsPerKm: Int): String {
        if (secondsPerKm <= 0) return "--'--\""
        val minutes = secondsPerKm / 60
        val seconds = secondsPerKm % 60
        return String.format("%d'%02d\"", minutes, seconds)
    }

    /**
     * 格式化时长
     */
    fun formatDuration(seconds: Int): String {
        val hours = seconds / 3600
        val minutes = (seconds % 3600) / 60
        val secs = seconds % 60

        return if (hours > 0) {
            String.format("%02d:%02d:%02d", hours, minutes, secs)
        } else {
            String.format("%02d:%02d", minutes, secs)
        }
    }

    /**
     * 简化轨迹（道格拉斯-普克算法）
     * 用于减少轨迹点数量，提高性能
     */
    fun simplifyTrack(points: List<TrackPointEntity>, tolerance: Double = 0.00001): List<TrackPointEntity> {
        if (points.size < 3) return points

        val result = mutableListOf<TrackPointEntity>()
        douglasPeucker(points, 0, points.size - 1, tolerance, result)
        return result.sortedBy { it.timestamp }
    }

    private fun douglasPeucker(
        points: List<TrackPointEntity>,
        start: Int,
        end: Int,
        tolerance: Double,
        result: MutableList<TrackPointEntity>
    ) {
        var maxDistance = 0.0
        var index = 0

        for (i in start + 1 until end) {
            val distance = perpendicularDistance(
                points[i],
                points[start],
                points[end]
            )
            if (distance > maxDistance) {
                maxDistance = distance
                index = i
            }
        }

        if (maxDistance > tolerance) {
            douglasPeucker(points, start, index, tolerance, result)
            douglasPeucker(points, index, end, tolerance, result)
        } else {
            result.add(points[start])
            result.add(points[end])
        }
    }

    private fun perpendicularDistance(
        point: TrackPointEntity,
        lineStart: TrackPointEntity,
        lineEnd: TrackPointEntity
    ): Double {
        val x = point.latitude
        val y = point.longitude
        val x1 = lineStart.latitude
        val y1 = lineStart.longitude
        val x2 = lineEnd.latitude
        val y2 = lineEnd.longitude

        val A = x - x1
        val B = y - y1
        val C = x2 - x1
        val D = y2 - y1

        val dot = A * C + B * D
        val lenSq = C * C + D * D
        val param = if (lenSq != 0.0) dot / lenSq else -1.0

        val xx: Double
        val yy: Double

        when {
            param < 0 -> {
                xx = x1
                yy = y1
            }
            param > 1 -> {
                xx = x2
                yy = y2
            }
            else -> {
                xx = x1 + param * C
                yy = y1 + param * D
            }
        }

        val dx = x - xx
        val dy = y - yy

        return sqrt(dx * dx + dy * dy)
    }
}
