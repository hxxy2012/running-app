package com.runningapp.utils

import android.app.Activity
import android.content.Context
import android.graphics.Rect
import android.view.View
import android.view.ViewTreeObserver
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalView
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 键盘管理器
 * 管理软键盘的显示、隐藏和状态监听
 */
@Singleton
class KeyboardManager @Inject constructor(
    @ApplicationContext private val context: Context
) {

    private val _isKeyboardVisible = MutableStateFlow(false)
    val isKeyboardVisible: StateFlow<Boolean> = _isKeyboardVisible.asStateFlow()

    private val _keyboardHeight = MutableStateFlow(0)
    val keyboardHeight: StateFlow<Int> = _keyboardHeight.asStateFlow()

    private var keyboardListeners = mutableListOf<KeyboardVisibilityListener>()

    // MARK: - 显示/隐藏键盘

    /**
     * 显示键盘
     */
    fun showKeyboard(view: View) {
        view.requestFocus()
        val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
        imm?.showSoftInput(view, InputMethodManager.SHOW_IMPLICIT)
        Logger.d("KeyboardManager", "Show keyboard")
    }

    /**
     * 隐藏键盘
     */
    fun hideKeyboard(view: View) {
        val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
        imm?.hideSoftInputFromWindow(view.windowToken, 0)
        Logger.d("KeyboardManager", "Hide keyboard")
    }

    /**
     * 隐藏键盘（Activity）
     */
    fun hideKeyboard(activity: Activity) {
        val view = activity.currentFocus ?: activity.window.decorView
        hideKeyboard(view)
    }

    /**
     * 切换键盘显示状态
     */
    fun toggleKeyboard() {
        val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
        imm?.toggleSoftInput(InputMethodManager.SHOW_FORCED, 0)
        Logger.d("KeyboardManager", "Toggle keyboard")
    }

    // MARK: - 键盘状态监听

    /**
     * 监听键盘可见性变化（使用WindowInsets - Android 11+）
     */
    fun observeKeyboardVisibility(view: View) {
        ViewCompat.setOnApplyWindowInsetsListener(view) { _, insets ->
            val imeVisible = insets.isVisible(WindowInsetsCompat.Type.ime())
            val imeHeight = insets.getInsets(WindowInsetsCompat.Type.ime()).bottom

            if (_isKeyboardVisible.value != imeVisible) {
                _isKeyboardVisible.value = imeVisible
                _keyboardHeight.value = imeHeight
                notifyListeners(imeVisible, imeHeight)
            }

            insets
        }
    }

    /**
     * 监听键盘可见性变化（兼容旧版本）
     */
    fun observeKeyboardVisibilityCompat(rootView: View) {
        rootView.viewTreeObserver.addOnGlobalLayoutListener(object : ViewTreeObserver.OnGlobalLayoutListener {
            private val rect = Rect()
            private var wasOpened = false

            override fun onGlobalLayout() {
                rootView.getWindowVisibleDisplayFrame(rect)

                val screenHeight = rootView.rootView.height
                val keypadHeight = screenHeight - rect.bottom

                val isOpen = keypadHeight > screenHeight * 0.15

                if (isOpen != wasOpened) {
                    wasOpened = isOpen
                    _isKeyboardVisible.value = isOpen
                    _keyboardHeight.value = if (isOpen) keypadHeight else 0
                    notifyListeners(isOpen, keypadHeight)
                }
            }
        })
    }

    /**
     * 添加键盘可见性监听器
     */
    fun addKeyboardVisibilityListener(listener: KeyboardVisibilityListener) {
        keyboardListeners.add(listener)
    }

    /**
     * 移除键盘可见性监听器
     */
    fun removeKeyboardVisibilityListener(listener: KeyboardVisibilityListener) {
        keyboardListeners.remove(listener)
    }

    /**
     * 通知所有监听器
     */
    private fun notifyListeners(isVisible: Boolean, height: Int) {
        keyboardListeners.forEach { listener ->
            if (isVisible) {
                listener.onKeyboardShown(height)
            } else {
                listener.onKeyboardHidden()
            }
        }
    }

    // MARK: - 辅助方法

    /**
     * 检查键盘是否显示
     */
    fun isKeyboardShowing(): Boolean {
        return _isKeyboardVisible.value
    }

    /**
     * 获取键盘高度
     */
    fun getKeyboardHeight(): Int {
        return _keyboardHeight.value
    }

    /**
     * 清除EditText焦点并隐藏键盘
     */
    fun clearFocusAndHideKeyboard(editText: EditText) {
        editText.clearFocus()
        hideKeyboard(editText)
    }

    /**
     * 延迟显示键盘
     */
    fun showKeyboardDelayed(view: View, delayMillis: Long = 100) {
        view.postDelayed({
            showKeyboard(view)
        }, delayMillis)
    }

    /**
     * 键盘可见性监听器
     */
    interface KeyboardVisibilityListener {
        fun onKeyboardShown(height: Int)
        fun onKeyboardHidden()
    }
}

// MARK: - View扩展

/**
 * View扩展：显示键盘
 */
fun View.showKeyboard() {
    val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
    requestFocus()
    imm?.showSoftInput(this, InputMethodManager.SHOW_IMPLICIT)
}

/**
 * View扩展：隐藏键盘
 */
fun View.hideKeyboard() {
    val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
    imm?.hideSoftInputFromWindow(windowToken, 0)
}

/**
 * EditText扩展：显示键盘并将光标移到末尾
 */
fun EditText.showKeyboardWithCursor() {
    requestFocus()
    setSelection(text.length)
    showKeyboard()
}

// MARK: - Compose支持

/**
 * Composable: 观察键盘状态
 */
@Composable
fun rememberKeyboardState(): State<Boolean> {
    val view = LocalView.current
    val keyboardState = remember { mutableStateOf(false) }

    DisposableEffect(view) {
        val listener = ViewTreeObserver.OnGlobalLayoutListener {
            val rect = Rect()
            view.getWindowVisibleDisplayFrame(rect)
            val screenHeight = view.rootView.height
            val keypadHeight = screenHeight - rect.bottom
            keyboardState.value = keypadHeight > screenHeight * 0.15
        }

        view.viewTreeObserver.addOnGlobalLayoutListener(listener)

        onDispose {
            view.viewTreeObserver.removeOnGlobalLayoutListener(listener)
        }
    }

    return keyboardState
}

/**
 * Composable: 观察键盘高度
 */
@Composable
fun rememberKeyboardHeight(): State<Int> {
    val view = LocalView.current
    val keyboardHeight = remember { mutableStateOf(0) }

    DisposableEffect(view) {
        val listener = ViewTreeObserver.OnGlobalLayoutListener {
            val rect = Rect()
            view.getWindowVisibleDisplayFrame(rect)
            val screenHeight = view.rootView.height
            val keypadHeight = screenHeight - rect.bottom
            keyboardHeight.value = if (keypadHeight > screenHeight * 0.15) keypadHeight else 0
        }

        view.viewTreeObserver.addOnGlobalLayoutListener(listener)

        onDispose {
            view.viewTreeObserver.removeOnGlobalLayoutListener(listener)
        }
    }

    return keyboardHeight
}

/**
 * Composable: 当键盘显示时隐藏
 */
@Composable
fun HideKeyboardOnCompose(view: View) {
    DisposableEffect(Unit) {
        onDispose {
            view.hideKeyboard()
        }
    }
}
