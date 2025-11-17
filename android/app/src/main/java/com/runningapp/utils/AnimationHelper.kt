package com.runningapp.utils

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.view.View
import android.view.animation.*
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.TransformOrigin
import androidx.core.view.isVisible
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 动画工具类
 * 提供常用的动画效果和动画工具
 */
@Singleton
class AnimationHelper @Inject constructor() {

    companion object {
        // 动画时长
        const val DURATION_SHORT = 200L
        const val DURATION_NORMAL = 300L
        const val DURATION_LONG = 500L

        // 插值器
        val INTERPOLATOR_DECELERATE = DecelerateInterpolator()
        val INTERPOLATOR_ACCELERATE = AccelerateInterpolator()
        val INTERPOLATOR_OVERSHOOT = OvershootInterpolator()
        val INTERPOLATOR_BOUNCE = BounceInterpolator()
    }

    // MARK: - View动画

    /**
     * 淡入动画
     */
    fun fadeIn(
        view: View,
        duration: Long = DURATION_NORMAL,
        onEnd: (() -> Unit)? = null
    ) {
        view.alpha = 0f
        view.isVisible = true
        view.animate()
            .alpha(1f)
            .setDuration(duration)
            .setInterpolator(INTERPOLATOR_DECELERATE)
            .setListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    onEnd?.invoke()
                }
            })
            .start()
    }

    /**
     * 淡出动画
     */
    fun fadeOut(
        view: View,
        duration: Long = DURATION_NORMAL,
        onEnd: (() -> Unit)? = null
    ) {
        view.animate()
            .alpha(0f)
            .setDuration(duration)
            .setInterpolator(INTERPOLATOR_ACCELERATE)
            .setListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    view.isVisible = false
                    onEnd?.invoke()
                }
            })
            .start()
    }

    /**
     * 缩放动画
     */
    fun scale(
        view: View,
        fromScale: Float = 0f,
        toScale: Float = 1f,
        duration: Long = DURATION_NORMAL,
        onEnd: (() -> Unit)? = null
    ) {
        view.scaleX = fromScale
        view.scaleY = fromScale
        view.isVisible = true
        view.animate()
            .scaleX(toScale)
            .scaleY(toScale)
            .setDuration(duration)
            .setInterpolator(INTERPOLATOR_OVERSHOOT)
            .setListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    onEnd?.invoke()
                }
            })
            .start()
    }

    /**
     * 滑入动画（从底部）
     */
    fun slideInFromBottom(
        view: View,
        duration: Long = DURATION_NORMAL,
        onEnd: (() -> Unit)? = null
    ) {
        view.translationY = view.height.toFloat()
        view.isVisible = true
        view.animate()
            .translationY(0f)
            .setDuration(duration)
            .setInterpolator(INTERPOLATOR_DECELERATE)
            .setListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    onEnd?.invoke()
                }
            })
            .start()
    }

    /**
     * 滑出动画（向底部）
     */
    fun slideOutToBottom(
        view: View,
        duration: Long = DURATION_NORMAL,
        onEnd: (() -> Unit)? = null
    ) {
        view.animate()
            .translationY(view.height.toFloat())
            .setDuration(duration)
            .setInterpolator(INTERPOLATOR_ACCELERATE)
            .setListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    view.isVisible = false
                    view.translationY = 0f
                    onEnd?.invoke()
                }
            })
            .start()
    }

    /**
     * 弹跳动画
     */
    fun bounce(
        view: View,
        duration: Long = DURATION_LONG,
        onEnd: (() -> Unit)? = null
    ) {
        val scaleX = ObjectAnimator.ofFloat(view, "scaleX", 1f, 1.2f, 0.8f, 1.1f, 0.9f, 1f)
        val scaleY = ObjectAnimator.ofFloat(view, "scaleY", 1f, 1.2f, 0.8f, 1.1f, 0.9f, 1f)

        AnimatorSet().apply {
            playTogether(scaleX, scaleY)
            this.duration = duration
            interpolator = LinearInterpolator()
            addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    onEnd?.invoke()
                }
            })
            start()
        }
    }

    /**
     * 摇晃动画
     */
    fun shake(
        view: View,
        duration: Long = DURATION_LONG,
        onEnd: (() -> Unit)? = null
    ) {
        val animator = ObjectAnimator.ofFloat(view, "translationX", 0f, 25f, -25f, 25f, -25f, 15f, -15f, 6f, -6f, 0f)
        animator.duration = duration
        animator.addListener(object : AnimatorListenerAdapter() {
            override fun onAnimationEnd(animation: Animator) {
                onEnd?.invoke()
            }
        })
        animator.start()
    }

    /**
     * 旋转动画
     */
    fun rotate(
        view: View,
        fromDegrees: Float = 0f,
        toDegrees: Float = 360f,
        duration: Long = DURATION_NORMAL,
        repeat: Boolean = false,
        onEnd: (() -> Unit)? = null
    ) {
        val animator = ObjectAnimator.ofFloat(view, "rotation", fromDegrees, toDegrees)
        animator.duration = duration
        if (repeat) {
            animator.repeatCount = ValueAnimator.INFINITE
            animator.repeatMode = ValueAnimator.RESTART
        }
        animator.addListener(object : AnimatorListenerAdapter() {
            override fun onAnimationEnd(animation: Animator) {
                onEnd?.invoke()
            }
        })
        animator.start()
    }

    /**
     * 脉冲动画（心跳效果）
     */
    fun pulse(
        view: View,
        duration: Long = DURATION_NORMAL,
        repeat: Boolean = true
    ) {
        val scaleX = ObjectAnimator.ofFloat(view, "scaleX", 1f, 1.1f, 1f)
        val scaleY = ObjectAnimator.ofFloat(view, "scaleY", 1f, 1.1f, 1f)

        AnimatorSet().apply {
            playTogether(scaleX, scaleY)
            this.duration = duration
            if (repeat) {
                scaleX.repeatCount = ValueAnimator.INFINITE
                scaleY.repeatCount = ValueAnimator.INFINITE
            }
            start()
        }
    }

    // MARK: - Compose动画

    /**
     * 淡入淡出过渡
     */
    @Composable
    fun fadeTransition(): EnterTransition to ExitTransition {
        return fadeIn(
            animationSpec = tween(durationMillis = DURATION_NORMAL.toInt())
        ) to fadeOut(
            animationSpec = tween(durationMillis = DURATION_NORMAL.toInt())
        )
    }

    /**
     * 滑动过渡
     */
    @Composable
    fun slideTransition(): EnterTransition to ExitTransition {
        return slideInVertically(
            initialOffsetY = { it },
            animationSpec = tween(durationMillis = DURATION_NORMAL.toInt())
        ) to slideOutVertically(
            targetOffsetY = { it },
            animationSpec = tween(durationMillis = DURATION_NORMAL.toInt())
        )
    }

    /**
     * 缩放过渡
     */
    @Composable
    fun scaleTransition(): EnterTransition to ExitTransition {
        return scaleIn(
            transformOrigin = TransformOrigin.Center,
            animationSpec = tween(durationMillis = DURATION_NORMAL.toInt())
        ) to scaleOut(
            transformOrigin = TransformOrigin.Center,
            animationSpec = tween(durationMillis = DURATION_NORMAL.toInt())
        )
    }

    /**
     * 创建无限循环动画
     */
    @Composable
    fun rememberInfiniteTransition(): InfiniteTransition {
        return rememberInfiniteTransition(label = "infiniteTransition")
    }

    /**
     * 创建弹簧动画规格
     */
    fun <T> springSpec(
        dampingRatio: Float = Spring.DampingRatioMediumBouncy,
        stiffness: Float = Spring.StiffnessLow
    ): SpringSpec<T> {
        return spring(
            dampingRatio = dampingRatio,
            stiffness = stiffness
        )
    }

    /**
     * 创建补间动画规格
     */
    fun <T> tweenSpec(
        durationMillis: Int = DURATION_NORMAL.toInt(),
        easing: Easing = FastOutSlowInEasing
    ): TweenSpec<T> {
        return tween(
            durationMillis = durationMillis,
            easing = easing
        )
    }
}

// MARK: - View扩展

/**
 * View扩展：淡入
 */
fun View.fadeIn(duration: Long = AnimationHelper.DURATION_NORMAL) {
    alpha = 0f
    isVisible = true
    animate()
        .alpha(1f)
        .setDuration(duration)
        .start()
}

/**
 * View扩展：淡出
 */
fun View.fadeOut(duration: Long = AnimationHelper.DURATION_NORMAL) {
    animate()
        .alpha(0f)
        .setDuration(duration)
        .withEndAction {
            isVisible = false
        }
        .start()
}

/**
 * View扩展：缩放进入
 */
fun View.scaleIn(duration: Long = AnimationHelper.DURATION_NORMAL) {
    scaleX = 0f
    scaleY = 0f
    isVisible = true
    animate()
        .scaleX(1f)
        .scaleY(1f)
        .setDuration(duration)
        .setInterpolator(OvershootInterpolator())
        .start()
}

/**
 * View扩展：缩放退出
 */
fun View.scaleOut(duration: Long = AnimationHelper.DURATION_NORMAL) {
    animate()
        .scaleX(0f)
        .scaleY(0f)
        .setDuration(duration)
        .setInterpolator(AccelerateInterpolator())
        .withEndAction {
            isVisible = false
        }
        .start()
}

// MARK: - Compose修饰符扩展

/**
 * Modifier扩展：脉冲动画
 */
fun Modifier.pulse(enabled: Boolean = true): Modifier {
    if (!enabled) return this

    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    val scale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.1f,
        animationSpec = infiniteRepeatable(
            animation = tween(600),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scale"
    )

    return this.scale(scale)
}

/**
 * Modifier扩展：闪烁动画
 */
fun Modifier.blink(enabled: Boolean = true): Modifier {
    if (!enabled) return this

    val infiniteTransition = rememberInfiniteTransition(label = "blink")
    val alpha by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 0.3f,
        animationSpec = infiniteRepeatable(
            animation = tween(800),
            repeatMode = RepeatMode.Reverse
        ),
        label = "alpha"
    )

    return this.alpha(alpha)
}
