package com.runningapp

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

/**
 * Running App Application Class
 * 使用Hilt进行依赖注入
 */
@HiltAndroidApp
class RunningApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        // 初始化应用级别的配置
    }
}
