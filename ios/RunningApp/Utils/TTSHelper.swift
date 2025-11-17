import Foundation
import AVFoundation

// MARK: - 语音播报助手
class TTSHelper: NSObject {

    static let shared = TTSHelper()

    private let synthesizer = AVSpeechSynthesizer()
    private var audioSession: AVAudioSession?

    override private init() {
        super.init()
        synthesizer.delegate = self
        audioSession = AVAudioSession.sharedInstance()
        setupAudioSession()
    }

    // MARK: - 音频会话设置

    private func setupAudioSession() {
        do {
            try audioSession?.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
            )
            try audioSession?.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            Logger.e("Setup audio session failed", error: error)
        }
    }

    // MARK: - 基础播报

    /// 播报文本
    /// - Parameters:
    ///   - text: 要播报的文本
    ///   - language: 语言（默认中文）
    ///   - rate: 语速（0.0-1.0，默认0.5）
    ///   - pitch: 音调（0.5-2.0，默认1.0）
    ///   - volume: 音量（0.0-1.0，默认1.0）
    func speak(
        _ text: String,
        language: String = "zh-CN",
        rate: Float = AVSpeechUtteranceDefaultSpeechRate,
        pitch: Float = 1.0,
        volume: Float = 1.0
    ) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.volume = volume

        synthesizer.speak(utterance)
        Logger.d("Speaking: \(text)")
    }

    /// 快速播报（使用默认设置）
    func speakQuick(_ text: String) {
        speak(text, rate: 0.5)
    }

    /// 停止播报
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// 暂停播报
    func pause() {
        synthesizer.pauseSpeaking(at: .immediate)
    }

    /// 继续播报
    func resume() {
        synthesizer.continueSpeaking()
    }

    // MARK: - 跑步专用播报

    /// 跑步开始播报
    func announceRunningStart() {
        speak("开始跑步，祝你好运")
    }

    /// 跑步暂停播报
    func announceRunningPause() {
        speak("跑步已暂停")
    }

    /// 跑步继续播报
    func announceRunningResume() {
        speak("继续跑步")
    }

    /// 跑步结束播报
    func announceRunningStop(distance: Double, duration: Int) {
        let distanceKm = String(format: "%.2f", distance / 1000)
        let durationText = duration.toDurationString(format: .short)
        speak("跑步结束，总距离\(distanceKm)公里，用时\(durationText)，辛苦了")
    }

    /// 完成公里数播报
    func announceKilometer(_ kilometer: Int, pace: Double, duration: Int) {
        let minutes = duration / 60
        let seconds = duration % 60
        let paceMinutes = Int(pace / 60)
        let paceSeconds = Int(pace.truncatingRemainder(dividingBy: 60))

        speak(
            "已完成\(kilometer)公里，" +
            "用时\(minutes)分\(seconds)秒，" +
            "配速\(paceMinutes)分\(paceSeconds)秒"
        )
    }

    /// 播报当前数据
    func announceCurrentData(
        distance: Double,
        duration: Int,
        pace: Double
    ) {
        let distanceKm = String(format: "%.2f", distance / 1000)
        let minutes = duration / 60
        let seconds = duration % 60
        let paceMin = Int(pace / 60)
        let paceSec = Int(pace.truncatingRemainder(dividingBy: 60))

        speak(
            "当前距离\(distanceKm)公里，" +
            "用时\(minutes)分\(seconds)秒，" +
            "配速\(paceMin)分\(paceSec)秒"
        )
    }

    /// 目标达成播报
    func announceGoalAchieved(_ goalType: String) {
        speak("恭喜你，\(goalType)目标达成")
    }

    /// 倒计时播报
    func announceCountdown(_ seconds: Int) {
        switch seconds {
        case 3:
            speak("3")
        case 2:
            speak("2")
        case 1:
            speak("1")
        case 0:
            speak("开始")
        default:
            speak("\(seconds)")
        }
    }

    /// 距离提醒
    func announceDistance(_ meters: Double) {
        if meters >= 1000 {
            let km = Int(meters / 1000)
            speak("已完成\(km)公里")
        } else {
            let m = Int(meters)
            speak("已完成\(m)米")
        }
    }

    /// 时间提醒
    func announceDuration(_ seconds: Int) {
        let minutes = seconds / 60
        if minutes > 0 {
            speak("已跑\(minutes)分钟")
        }
    }

    /// 配速提醒
    func announcePace(_ secondsPerMeter: Double) {
        let secondsPerKm = secondsPerMeter * 1000
        let minutes = Int(secondsPerKm / 60)
        let seconds = Int(secondsPerKm.truncatingRemainder(dividingBy: 60))
        speak("当前配速\(minutes)分\(seconds)秒")
    }

    // MARK: - 成就和挑战播报

    /// 成就解锁播报
    func announceAchievement(_ name: String) {
        speak("恭喜你解锁新成就，\(name)")
    }

    /// 挑战完成播报
    func announceChallengeComplete(_ name: String) {
        speak("挑战\(name)已完成，继续加油")
    }

    /// 排名提升播报
    func announceRankUp(_ rank: Int) {
        speak("你的排名提升到第\(rank)名")
    }

    // MARK: - 训练指导播报

    /// 训练提醒
    func announceTrainingReminder(_ planName: String) {
        speak("该开始\(planName)训练了")
    }

    /// 训练完成
    func announceTrainingComplete(_ planName: String) {
        speak("\(planName)训练已完成，做得很棒")
    }

    /// 休息提醒
    func announceRest(_ seconds: Int) {
        speak("请休息\(seconds)秒")
    }

    /// 热身提醒
    func announceWarmup() {
        speak("开始热身")
    }

    /// 拉伸提醒
    func announceStretch() {
        speak("记得做拉伸运动")
    }

    // MARK: - 辅助方法

    /// 检查是否正在播报
    var isSpeaking: Bool {
        return synthesizer.isSpeaking
    }

    /// 检查是否已暂停
    var isPaused: Bool {
        return synthesizer.isPaused
    }

    /// 获取可用语音列表
    func getAvailableVoices(for language: String = "zh-CN") -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices().filter { voice in
            voice.language.hasPrefix(language)
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TTSHelper: AVSpeechSynthesizerDelegate {

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Logger.d("TTS started")
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Logger.d("TTS finished")
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Logger.d("TTS paused")
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Logger.d("TTS continued")
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Logger.d("TTS cancelled")
    }
}

// MARK: - 便捷扩展

extension TTSHelper {

    /// 使用特定语音播报
    func speak(_ text: String, with voice: AVSpeechSynthesisVoice, rate: Float = 0.5) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = rate
        synthesizer.speak(utterance)
    }

    /// 播报数字
    func speakNumber(_ number: Int) {
        speak("\(number)")
    }

    /// 播报时间
    func speakTime(hour: Int, minute: Int) {
        speak("\(hour)点\(minute)分")
    }
}

// MARK: - 全局便捷函数

/// 快速语音播报
func speak(_ text: String) {
    TTSHelper.shared.speakQuick(text)
}

/// 停止语音播报
func stopSpeaking() {
    TTSHelper.shared.stop()
}
