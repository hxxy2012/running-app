package com.runningapp.utils

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 通知助手
 * 管理本地通知的创建和显示
 */
@Singleton
class NotificationHelper @Inject constructor(
    @ApplicationContext private val context: Context
) {

    companion object {
        // 通知渠道
        const val CHANNEL_RUNNING = "running"
        const val CHANNEL_TRAINING = "training"
        const val CHANNEL_SOCIAL = "social"
        const val CHANNEL_ACHIEVEMENT = "achievement"
        const val CHANNEL_SYSTEM = "system"

        // 通知ID范围
        const val NOTIFICATION_ID_RUNNING = 1000
        const val NOTIFICATION_ID_TRAINING = 2000
        const val NOTIFICATION_ID_SOCIAL = 3000
        const val NOTIFICATION_ID_ACHIEVEMENT = 4000
        const val NOTIFICATION_ID_SYSTEM = 5000
    }

    init {
        createNotificationChannels()
    }

    /**
     * 创建通知渠道（Android 8.0+）
     */
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channels = listOf(
                NotificationChannel(
                    CHANNEL_RUNNING,
                    "跑步通知",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "跑步过程中的通知"
                    setShowBadge(true)
                },
                NotificationChannel(
                    CHANNEL_TRAINING,
                    "训练提醒",
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "训练计划提醒"
                    setShowBadge(true)
                },
                NotificationChannel(
                    CHANNEL_SOCIAL,
                    "社交消息",
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "点赞、评论等社交互动"
                    setShowBadge(true)
                },
                NotificationChannel(
                    CHANNEL_ACHIEVEMENT,
                    "成就解锁",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "成就解锁通知"
                    setShowBadge(true)
                },
                NotificationChannel(
                    CHANNEL_SYSTEM,
                    "系统通知",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "系统消息"
                    setShowBadge(false)
                }
            )

            val manager = context.getSystemService(NotificationManager::class.java)
            channels.forEach { manager.createNotificationChannel(it) }
        }
    }

    /**
     * 显示跑步通知（用于前台服务）
     */
    fun showRunningNotification(
        id: Int = NOTIFICATION_ID_RUNNING,
        title: String,
        content: String,
        pendingIntent: PendingIntent? = null
    ) {
        val notification = NotificationCompat.Builder(context, CHANNEL_RUNNING)
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setContentTitle(title)
            .setContentText(content)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setOngoing(true)
            .apply {
                pendingIntent?.let { setContentIntent(it) }
            }
            .build()

        NotificationManagerCompat.from(context).notify(id, notification)
    }

    /**
     * 显示训练提醒通知
     */
    fun showTrainingReminder(
        id: Int = NOTIFICATION_ID_TRAINING,
        title: String = "训练提醒",
        content: String,
        autoCancel: Boolean = true
    ) {
        val notification = NotificationCompat.Builder(context, CHANNEL_TRAINING)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(content)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(autoCancel)
            .build()

        NotificationManagerCompat.from(context).notify(id, notification)
    }

    /**
     * 显示成就解锁通知
     */
    fun showAchievementNotification(
        id: Int = NOTIFICATION_ID_ACHIEVEMENT,
        achievementName: String,
        achievementDescription: String
    ) {
        val notification = NotificationCompat.Builder(context, CHANNEL_ACHIEVEMENT)
            .setSmallIcon(android.R.drawable.star_on)
            .setContentTitle("🏆 解锁新成就！")
            .setContentText(achievementName)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText("$achievementName\n$achievementDescription")
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompat.from(context).notify(id, notification)
    }

    /**
     * 显示社交通知
     */
    fun showSocialNotification(
        id: Int = NOTIFICATION_ID_SOCIAL,
        title: String,
        content: String,
        autoCancel: Boolean = true
    ) {
        val notification = NotificationCompat.Builder(context, CHANNEL_SOCIAL)
            .setSmallIcon(android.R.drawable.ic_dialog_email)
            .setContentTitle(title)
            .setContentText(content)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(autoCancel)
            .build()

        NotificationManagerCompat.from(context).notify(id, notification)
    }

    /**
     * 取消通知
     */
    fun cancelNotification(id: Int) {
        NotificationManagerCompat.from(context).cancel(id)
    }

    /**
     * 取消所有通知
     */
    fun cancelAllNotifications() {
        NotificationManagerCompat.from(context).cancelAll()
    }

    /**
     * 检查通知权限是否已授予
     */
    fun areNotificationsEnabled(): Boolean {
        return NotificationManagerCompat.from(context).areNotificationsEnabled()
    }
}
