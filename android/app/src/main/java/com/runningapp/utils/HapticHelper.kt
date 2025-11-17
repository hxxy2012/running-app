package com.runningapp.utils

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.HapticFeedbackConstants
import android.view.View
import androidx.core.content.getSystemService
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 触觉反馈助手
 * 提供振动和触觉反馈功能
 */
@Singleton
class HapticHelper @Inject constructor(
    @ApplicationContext private val context: Context
) {

    private val vibrator: Vibrator? by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = context.getSystemService<VibratorManager>()
            vibratorManager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService<Vibrator>()
        }
    }

    companion object {
        // 预定义振动模式
        private val PATTERN_CLICK = longArrayOf(0, 10)
        private val PATTERN_DOUBLE_CLICK = longArrayOf(0, 10, 50, 10)
        private val PATTERN_LONG_PRESS = longArrayOf(0, 50)
        private val PATTERN_SUCCESS = longArrayOf(0, 20, 50, 20)
        private val PATTERN_ERROR = longArrayOf(0, 100, 100, 100)
        private val PATTERN_WARNING = longArrayOf(0, 50, 50, 50)
        private val PATTERN_NOTIFICATION = longArrayOf(0, 100, 50, 100)

        // 跑步相关振动模式
        private val PATTERN_RUNNING_START = longArrayOf(0, 100, 100, 100, 100, 100)
        private val PATTERN_RUNNING_PAUSE = longArrayOf(0, 50)
        private val PATTERN_RUNNING_RESUME = longArrayOf(0, 50, 50, 50)
        private val PATTERN_RUNNING_STOP = longArrayOf(0, 100, 100, 100)
        private val PATTERN_KILOMETER = longArrayOf(0, 50, 50, 50, 50, 50)
    }

    // MARK: - 基础振动

    /**
     * 简单振动
     */
    fun vibrate(duration: Long = 50) {
        if (!hasVibrator()) return

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(
                    VibrationEffect.createOneShot(duration, VibrationEffect.DEFAULT_AMPLITUDE)
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(duration)
            }
        } catch (e: Exception) {
            Logger.e("HapticHelper", "Vibrate failed", e)
        }
    }

    /**
     * 模式振动
     */
    fun vibrate(pattern: LongArray, repeat: Int = -1) {
        if (!hasVibrator()) return

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(
                    VibrationEffect.createWaveform(pattern, repeat)
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, repeat)
            }
        } catch (e: Exception) {
            Logger.e("HapticHelper", "Vibrate pattern failed", e)
        }
    }

    /**
     * 停止振动
     */
    fun cancel() {
        vibrator?.cancel()
    }

    // MARK: - 预定义触觉反馈

    /**
     * 点击反馈
     */
    fun click() {
        vibrate(PATTERN_CLICK)
    }

    /**
     * 双击反馈
     */
    fun doubleClick() {
        vibrate(PATTERN_DOUBLE_CLICK)
    }

    /**
     * 长按反馈
     */
    fun longPress() {
        vibrate(PATTERN_LONG_PRESS)
    }

    /**
     * 成功反馈
     */
    fun success() {
        vibrate(PATTERN_SUCCESS)
    }

    /**
     * 错误反馈
     */
    fun error() {
        vibrate(PATTERN_ERROR)
    }

    /**
     * 警告反馈
     */
    fun warning() {
        vibrate(PATTERN_WARNING)
    }

    /**
     * 通知反馈
     */
    fun notification() {
        vibrate(PATTERN_NOTIFICATION)
    }

    // MARK: - 跑步专用触觉反馈

    /**
     * 跑步开始
     */
    fun runningStart() {
        vibrate(PATTERN_RUNNING_START)
    }

    /**
     * 跑步暂停
     */
    fun runningPause() {
        vibrate(PATTERN_RUNNING_PAUSE)
    }

    /**
     * 跑步继续
     */
    fun runningResume() {
        vibrate(PATTERN_RUNNING_RESUME)
    }

    /**
     * 跑步结束
     */
    fun runningStop() {
        vibrate(PATTERN_RUNNING_STOP)
    }

    /**
     * 完成1公里
     */
    fun kilometerCompleted() {
        vibrate(PATTERN_KILOMETER)
    }

    // MARK: - View触觉反馈

    /**
     * 视图点击反馈
     */
    fun performViewHaptic(view: View, feedbackConstant: Int = HapticFeedbackConstants.VIRTUAL_KEY) {
        view.performHapticFeedback(feedbackConstant)
    }

    // MARK: - 高级振动（Android 8.0+）

    /**
     * 效果振动（需要Android O+）
     */
    fun vibrateEffect(effectId: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val effect = VibrationEffect.createPredefined(effectId)
                vibrator?.vibrate(effect)
            } catch (e: Exception) {
                Logger.e("HapticHelper", "Vibrate effect failed", e)
            }
        }
    }

    /**
     * 点击效果（Android 10+）
     */
    fun clickEffect() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            vibrateEffect(VibrationEffect.EFFECT_CLICK)
        } else {
            click()
        }
    }

    /**
     * 重击效果（Android 10+）
     */
    fun heavyClickEffect() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            vibrateEffect(VibrationEffect.EFFECT_HEAVY_CLICK)
        } else {
            vibrate(100)
        }
    }

    /**
     * 双击效果（Android 10+）
     */
    fun doubleClickEffect() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            vibrateEffect(VibrationEffect.EFFECT_DOUBLE_CLICK)
        } else {
            doubleClick()
        }
    }

    /**
     * 滴答效果（Android 10+）
     */
    fun tickEffect() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            vibrateEffect(VibrationEffect.EFFECT_TICK)
        } else {
            vibrate(10)
        }
    }

    // MARK: - 辅助方法

    /**
     * 检查是否有振动器
     */
    fun hasVibrator(): Boolean {
        return vibrator?.hasVibrator() ?: false
    }

    /**
     * 检查是否支持振幅控制（Android 8.0+）
     */
    fun hasAmplitudeControl(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.hasAmplitudeControl() ?: false
        } else {
            false
        }
    }

    /**
     * 检查是否支持特定效果（Android 11+）
     */
    fun areEffectsSupported(vararg effectIds: Int): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val supported = vibrator?.areEffectsSupported(*effectIds)
            supported?.all { it == Vibrator.VIBRATION_EFFECT_SUPPORT_YES } ?: false
        } else {
            false
        }
    }
}

/**
 * View扩展：触觉反馈
 */
fun View.hapticClick() {
    performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
}

fun View.hapticLongPress() {
    performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
}

fun View.hapticKeyboard() {
    performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
}

fun View.hapticContextClick() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        performHapticFeedback(HapticFeedbackConstants.CONTEXT_CLICK)
    }
}
