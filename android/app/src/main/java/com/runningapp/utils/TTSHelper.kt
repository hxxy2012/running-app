package com.runningapp.utils

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import dagger.hilt.android.qualifiers.ApplicationContext
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 语音播报助手（Text-To-Speech）
 * 提供语音播报功能，用于跑步过程中的语音提示
 */
@Singleton
class TTSHelper @Inject constructor(
    @ApplicationContext private val context: Context
) {

    private var tts: TextToSpeech? = null
    private var isInitialized = false
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    private val initListeners = mutableListOf<(Boolean) -> Unit>()

    init {
        audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        initializeTTS()
    }

    /**
     * 初始化TTS引擎
     */
    private fun initializeTTS() {
        tts = TextToSpeech(context) { status ->
            isInitialized = status == TextToSpeech.SUCCESS
            if (isInitialized) {
                tts?.language = Locale.CHINESE
                tts?.setSpeechRate(1.0f)
                tts?.setPitch(1.0f)

                // 设置音频属性
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    val audioAttributes = AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
                        .build()
                    tts?.setAudioAttributes(audioAttributes)
                }

                Logger.d("TTSHelper", "TTS initialized successfully")
            } else {
                Logger.e("TTSHelper", "TTS initialization failed")
            }

            // 通知所有等待的监听器
            initListeners.forEach { it(isInitialized) }
            initListeners.clear()
        }
    }

    /**
     * 等待TTS初始化
     */
    fun onInitialized(listener: (Boolean) -> Unit) {
        if (tts != null) {
            listener(isInitialized)
        } else {
            initListeners.add(listener)
        }
    }

    // MARK: - 基础播报

    /**
     * 播报文本
     */
    fun speak(text: String, queueMode: Int = TextToSpeech.QUEUE_FLUSH) {
        if (!isInitialized) {
            Logger.w("TTSHelper", "TTS not initialized")
            return
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                tts?.speak(text, queueMode, null, text.hashCode().toString())
            } else {
                @Suppress("DEPRECATION")
                tts?.speak(text, queueMode, null)
            }
            Logger.d("TTSHelper", "Speaking: $text")
        } catch (e: Exception) {
            Logger.e("TTSHelper", "Speak failed", e)
        }
    }

    /**
     * 添加到队列播报
     */
    fun speakQueue(text: String) {
        speak(text, TextToSpeech.QUEUE_ADD)
    }

    /**
     * 立即播报（打断当前播报）
     */
    fun speakNow(text: String) {
        speak(text, TextToSpeech.QUEUE_FLUSH)
    }

    /**
     * 停止播报
     */
    fun stop() {
        tts?.stop()
    }

    // MARK: - 跑步专用播报

    /**
     * 跑步开始播报
     */
    fun announceRunningStart() {
        speak("开始跑步，祝你好运")
    }

    /**
     * 跑步暂停播报
     */
    fun announceRunningPause() {
        speak("跑步已暂停")
    }

    /**
     * 跑步继续播报
     */
    fun announceRunningResume() {
        speak("继续跑步")
    }

    /**
     * 跑步结束播报
     */
    fun announceRunningStop(distance: Float, duration: Int) {
        val distanceText = distance.toDistanceString(includeUnit = false)
        val durationText = duration.toDurationString()
        speak("跑步结束，总距离${distanceText}公里，用时${durationText}，辛苦了")
    }

    /**
     * 完成公里数播报
     */
    fun announceKilometer(kilometer: Int, pace: Float, duration: Int) {
        val minutes = (duration / 60)
        val seconds = (duration % 60)
        val paceMinutes = (pace / 60).toInt()
        val paceSeconds = ((pace % 60)).toInt()

        speak(
            "已完成${kilometer}公里，" +
                    "用时${minutes}分${seconds}秒，" +
                    "配速${paceMinutes}分${paceSeconds}秒"
        )
    }

    /**
     * 播报当前数据
     */
    fun announceCurrentData(
        distance: Float,
        duration: Int,
        pace: Float
    ) {
        val distanceKm = (distance / 1000).let { String.format("%.2f", it) }
        val minutes = duration / 60
        val seconds = duration % 60
        val paceMin = (pace / 60).toInt()
        val paceSec = ((pace % 60)).toInt()

        speak(
            "当前距离${distanceKm}公里，" +
                    "用时${minutes}分${seconds}秒，" +
                    "配速${paceMin}分${paceSec}秒"
        )
    }

    /**
     * 目标达成播报
     */
    fun announceGoalAchieved(goalType: String) {
        speak("恭喜你，${goalType}目标达成")
    }

    /**
     * 倒计时播报
     */
    fun announceCountdown(seconds: Int) {
        when (seconds) {
            3 -> speak("3")
            2 -> speak("2")
            1 -> speak("1")
            0 -> speak("开始")
        }
    }

    // MARK: - 配置

    /**
     * 设置语速（0.5 - 2.0）
     */
    fun setSpeechRate(rate: Float) {
        tts?.setSpeechRate(rate.coerceIn(0.5f, 2.0f))
    }

    /**
     * 设置音调（0.5 - 2.0）
     */
    fun setPitch(pitch: Float) {
        tts?.setPitch(pitch.coerceIn(0.5f, 2.0f))
    }

    /**
     * 设置语言
     */
    fun setLanguage(locale: Locale = Locale.CHINESE): Boolean {
        val result = tts?.setLanguage(locale)
        return result == TextToSpeech.LANG_AVAILABLE ||
                result == TextToSpeech.LANG_COUNTRY_AVAILABLE ||
                result == TextToSpeech.LANG_COUNTRY_VAR_AVAILABLE
    }

    // MARK: - 音频焦点管理

    /**
     * 请求音频焦点
     */
    private fun requestAudioFocus(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (audioFocusRequest == null) {
                audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                            .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
                            .build()
                    )
                    .build()
            }
            val result = audioManager?.requestAudioFocus(audioFocusRequest!!)
            return result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        } else {
            @Suppress("DEPRECATION")
            val result = audioManager?.requestAudioFocus(
                null,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
            )
            return result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
    }

    /**
     * 释放音频焦点
     */
    private fun abandonAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { audioManager?.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            audioManager?.abandonAudioFocus(null)
        }
    }

    // MARK: - 监听器

    /**
     * 设置播报进度监听器
     */
    fun setOnUtteranceProgressListener(listener: UtteranceProgressListener) {
        tts?.setOnUtteranceProgressListener(listener)
    }

    // MARK: - 生命周期

    /**
     * 释放资源
     */
    fun shutdown() {
        stop()
        abandonAudioFocus()
        tts?.shutdown()
        tts = null
        isInitialized = false
    }

    /**
     * 检查TTS是否可用
     */
    fun isAvailable(): Boolean {
        return isInitialized
    }

    /**
     * 检查是否正在播报
     */
    fun isSpeaking(): Boolean {
        return tts?.isSpeaking ?: false
    }
}

/**
 * 扩展函数：快速播报
 */
fun Context.speak(text: String) {
    // 需要依赖注入的实例
    Logger.d("TTSHelper", "Quick speak: $text")
}
