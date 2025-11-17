package com.runningapp.utils

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 网络状态监测工具
 * 监测网络连接状态变化
 */
@Singleton
class NetworkMonitor @Inject constructor(
    @ApplicationContext private val context: Context
) {

    private val connectivityManager =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    /**
     * 监听网络连接状态
     * @return Flow<Boolean> true表示已连接，false表示未连接
     */
    val isConnected: Flow<Boolean> = callbackFlow {
        val callback = object : ConnectivityManager.NetworkCallback() {
            private val networks = mutableSetOf<Network>()

            override fun onAvailable(network: Network) {
                networks.add(network)
                trySend(true)
            }

            override fun onLost(network: Network) {
                networks.remove(network)
                trySend(networks.isNotEmpty())
            }

            override fun onCapabilitiesChanged(
                network: Network,
                networkCapabilities: NetworkCapabilities
            ) {
                val hasInternet = networkCapabilities.hasCapability(
                    NetworkCapabilities.NET_CAPABILITY_INTERNET
                )
                val validated = networkCapabilities.hasCapability(
                    NetworkCapabilities.NET_CAPABILITY_VALIDATED
                )
                if (hasInternet && validated) {
                    networks.add(network)
                } else {
                    networks.remove(network)
                }
                trySend(networks.isNotEmpty())
            }
        }

        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()

        connectivityManager.registerNetworkCallback(request, callback)

        // 发送初始状态
        trySend(isCurrentlyConnected())

        awaitClose {
            connectivityManager.unregisterNetworkCallback(callback)
        }
    }.distinctUntilChanged()

    /**
     * 获取当前网络连接状态
     */
    fun isCurrentlyConnected(): Boolean {
        val network = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false

        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
    }

    /**
     * 获取网络类型
     */
    fun getNetworkType(): NetworkType {
        val network = connectivityManager.activeNetwork ?: return NetworkType.NONE
        val capabilities = connectivityManager.getNetworkCapabilities(network)
            ?: return NetworkType.NONE

        return when {
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ->
                NetworkType.WIFI

            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) ->
                NetworkType.CELLULAR

            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) ->
                NetworkType.ETHERNET

            else -> NetworkType.OTHER
        }
    }

    /**
     * 是否使用Wi-Fi
     */
    fun isWifi(): Boolean {
        return getNetworkType() == NetworkType.WIFI
    }

    /**
     * 是否使用移动数据
     */
    fun isCellular(): Boolean {
        return getNetworkType() == NetworkType.CELLULAR
    }

    /**
     * 网络类型枚举
     */
    enum class NetworkType {
        WIFI,       // Wi-Fi网络
        CELLULAR,   // 移动数据
        ETHERNET,   // 以太网
        OTHER,      // 其他类型
        NONE        // 无网络
    }
}

/**
 * 扩展函数：检查网络连接
 */
suspend fun <T> NetworkMonitor.requireNetwork(
    onNoNetwork: () -> Unit = {},
    block: suspend () -> T
): T? {
    return if (isCurrentlyConnected()) {
        block()
    } else {
        onNoNetwork()
        null
    }
}
