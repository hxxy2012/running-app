package com.runningapp.utils

import android.content.Context
import android.content.res.Configuration
import android.os.Build
import androidx.appcompat.app.AppCompatDelegate
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 主题管理器
 * 管理应用的主题切换和颜色方案
 */
@Singleton
class ThemeManager @Inject constructor(
    @ApplicationContext private val context: Context
) {

    companion object {
        private const val PREF_THEME_MODE = "theme_mode"
        private const val PREF_USE_DYNAMIC_COLOR = "use_dynamic_color"
    }

    // 主题模式
    enum class ThemeMode {
        LIGHT,      // 浅色主题
        DARK,       // 深色主题
        SYSTEM;     // 跟随系统

        companion object {
            fun fromString(value: String): ThemeMode {
                return try {
                    valueOf(value)
                } catch (e: Exception) {
                    SYSTEM
                }
            }
        }
    }

    private val prefs = context.getSharedPreferences("theme_prefs", Context.MODE_PRIVATE)

    private val _currentTheme = MutableStateFlow(loadThemeMode())
    val currentTheme: StateFlow<ThemeMode> = _currentTheme.asStateFlow()

    private val _useDynamicColor = MutableStateFlow(loadDynamicColorPreference())
    val useDynamicColor: StateFlow<Boolean> = _useDynamicColor.asStateFlow()

    init {
        applyTheme(loadThemeMode())
    }

    // MARK: - 主题切换

    /**
     * 设置主题模式
     */
    fun setThemeMode(mode: ThemeMode) {
        _currentTheme.value = mode
        saveThemeMode(mode)
        applyTheme(mode)
        Logger.d("ThemeManager", "Theme changed to: $mode")
    }

    /**
     * 切换到浅色主题
     */
    fun setLightTheme() {
        setThemeMode(ThemeMode.LIGHT)
    }

    /**
     * 切换到深色主题
     */
    fun setDarkTheme() {
        setThemeMode(ThemeMode.DARK)
    }

    /**
     * 跟随系统主题
     */
    fun setSystemTheme() {
        setThemeMode(ThemeMode.SYSTEM)
    }

    /**
     * 应用主题
     */
    private fun applyTheme(mode: ThemeMode) {
        val nightMode = when (mode) {
            ThemeMode.LIGHT -> AppCompatDelegate.MODE_NIGHT_NO
            ThemeMode.DARK -> AppCompatDelegate.MODE_NIGHT_YES
            ThemeMode.SYSTEM -> AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM
        }
        AppCompatDelegate.setDefaultNightMode(nightMode)
    }

    // MARK: - 动态颜色

    /**
     * 设置是否使用动态颜色（Android 12+）
     */
    fun setUseDynamicColor(use: Boolean) {
        _useDynamicColor.value = use
        saveDynamicColorPreference(use)
        Logger.d("ThemeManager", "Dynamic color: $use")
    }

    /**
     * 是否支持动态颜色
     */
    fun supportsDynamicColor(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
    }

    // MARK: - 主题判断

    /**
     * 当前是否为深色主题
     */
    fun isDarkTheme(): Boolean {
        return when (_currentTheme.value) {
            ThemeMode.LIGHT -> false
            ThemeMode.DARK -> true
            ThemeMode.SYSTEM -> isSystemInDarkMode()
        }
    }

    /**
     * 系统是否为深色模式
     */
    private fun isSystemInDarkMode(): Boolean {
        val nightModeFlags = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        return nightModeFlags == Configuration.UI_MODE_NIGHT_YES
    }

    // MARK: - 颜色方案

    /**
     * 获取颜色方案（Compose）
     */
    @Composable
    fun getColorScheme(): ColorScheme {
        val context = LocalContext.current
        val darkTheme = when (_currentTheme.value) {
            ThemeMode.LIGHT -> false
            ThemeMode.DARK -> true
            ThemeMode.SYSTEM -> isSystemInDarkTheme()
        }

        return when {
            _useDynamicColor.value && supportsDynamicColor() -> {
                if (darkTheme) {
                    dynamicDarkColorScheme(context)
                } else {
                    dynamicLightColorScheme(context)
                }
            }
            darkTheme -> darkColorScheme()
            else -> lightColorScheme()
        }
    }

    /**
     * 自定义浅色主题颜色方案
     */
    fun customLightColorScheme(): ColorScheme {
        return lightColorScheme(
            primary = Color(0xFF1E88E5),
            onPrimary = Color.White,
            primaryContainer = Color(0xFFBBDEFB),
            onPrimaryContainer = Color(0xFF0D47A1),

            secondary = Color(0xFF43A047),
            onSecondary = Color.White,
            secondaryContainer = Color(0xFFC8E6C9),
            onSecondaryContainer = Color(0xFF1B5E20),

            tertiary = Color(0xFFFFA726),
            onTertiary = Color.White,
            tertiaryContainer = Color(0xFFFFE0B2),
            onTertiaryContainer = Color(0xFFE65100),

            error = Color(0xFFE53935),
            onError = Color.White,
            errorContainer = Color(0xFFFFCDD2),
            onErrorContainer = Color(0xFFB71C1C),

            background = Color(0xFFFAFAFA),
            onBackground = Color(0xFF212121),

            surface = Color.White,
            onSurface = Color(0xFF212121),
            surfaceVariant = Color(0xFFF5F5F5),
            onSurfaceVariant = Color(0xFF616161),

            outline = Color(0xFFBDBDBD),
            outlineVariant = Color(0xFFE0E0E0)
        )
    }

    /**
     * 自定义深色主题颜色方案
     */
    fun customDarkColorScheme(): ColorScheme {
        return darkColorScheme(
            primary = Color(0xFF42A5F5),
            onPrimary = Color(0xFF0D47A1),
            primaryContainer = Color(0xFF1976D2),
            onPrimaryContainer = Color(0xFFBBDEFB),

            secondary = Color(0xFF66BB6A),
            onSecondary = Color(0xFF1B5E20),
            secondaryContainer = Color(0xFF388E3C),
            onSecondaryContainer = Color(0xFFC8E6C9),

            tertiary = Color(0xFFFFB74D),
            onTertiary = Color(0xFFE65100),
            tertiaryContainer = Color(0xFFFB8C00),
            onTertiaryContainer = Color(0xFFFFE0B2),

            error = Color(0xFFEF5350),
            onError = Color(0xFFB71C1C),
            errorContainer = Color(0xFFC62828),
            onErrorContainer = Color(0xFFFFCDD2),

            background = Color(0xFF121212),
            onBackground = Color(0xFFE0E0E0),

            surface = Color(0xFF1E1E1E),
            onSurface = Color(0xFFE0E0E0),
            surfaceVariant = Color(0xFF2C2C2C),
            onSurfaceVariant = Color(0xFFBDBDBD),

            outline = Color(0xFF616161),
            outlineVariant = Color(0xFF424242)
        )
    }

    // MARK: - 持久化

    /**
     * 保存主题模式
     */
    private fun saveThemeMode(mode: ThemeMode) {
        prefs.edit().putString(PREF_THEME_MODE, mode.name).apply()
    }

    /**
     * 加载主题模式
     */
    private fun loadThemeMode(): ThemeMode {
        val modeString = prefs.getString(PREF_THEME_MODE, ThemeMode.SYSTEM.name) ?: ThemeMode.SYSTEM.name
        return ThemeMode.fromString(modeString)
    }

    /**
     * 保存动态颜色偏好
     */
    private fun saveDynamicColorPreference(use: Boolean) {
        prefs.edit().putBoolean(PREF_USE_DYNAMIC_COLOR, use).apply()
    }

    /**
     * 加载动态颜色偏好
     */
    private fun loadDynamicColorPreference(): Boolean {
        return prefs.getBoolean(PREF_USE_DYNAMIC_COLOR, supportsDynamicColor())
    }

    // MARK: - 主题信息

    /**
     * 获取当前主题名称
     */
    fun getCurrentThemeName(): String {
        return when (_currentTheme.value) {
            ThemeMode.LIGHT -> "浅色主题"
            ThemeMode.DARK -> "深色主题"
            ThemeMode.SYSTEM -> "跟随系统"
        }
    }

    /**
     * 获取主题配置信息
     */
    fun getThemeInfo(): Map<String, String> {
        return mapOf(
            "themeMode" to _currentTheme.value.name,
            "themeName" to getCurrentThemeName(),
            "isDark" to isDarkTheme().toString(),
            "useDynamicColor" to _useDynamicColor.value.toString(),
            "supportsDynamicColor" to supportsDynamicColor().toString()
        )
    }
}

/**
 * 扩展函数：获取主题管理器
 */
fun Context.getThemeManager(): ThemeManager {
    // 需要通过依赖注入获取
    // 这里只是示例
    return ThemeManager(applicationContext)
}
