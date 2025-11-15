package com.runningapp

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import dagger.hilt.android.AndroidEntryPoint

/**
 * 主Activity
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            RunningAppTheme {
                MainScreen()
            }
        }
    }
}

/**
 * 主界面
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        bottomBar = {
            NavigationBar {
                bottomNavItems.forEach { item ->
                    NavigationBarItem(
                        icon = { Icon(item.icon, contentDescription = item.label) },
                        label = { Text(item.label) },
                        selected = currentDestination?.hierarchy?.any { it.route == item.route } == true,
                        onClick = {
                            navController.navigate(item.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.Home.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Screen.Home.route) {
                // 首页 - 跑步界面
                Text("跑步界面")
            }
            composable(Screen.History.route) {
                // 历史记录
                Text("历史记录")
            }
            composable(Screen.Social.route) {
                // 社交
                Text("社交动态")
            }
            composable(Screen.Profile.route) {
                // 个人中心
                Text("个人中心")
            }
        }
    }
}

/**
 * Material 3主题
 */
@Composable
fun RunningAppTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = lightColorScheme(),
        content = content
    )
}

/**
 * 底部导航项
 */
val bottomNavItems = listOf(
    BottomNavItem("首页", Icons.Filled.Home, Screen.Home.route),
    BottomNavItem("记录", Icons.Filled.List, Screen.History.route),
    BottomNavItem("动态", Icons.Filled.People, Screen.Social.route),
    BottomNavItem("我的", Icons.Filled.Person, Screen.Profile.route)
)

data class BottomNavItem(
    val label: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector,
    val route: String
)

/**
 * 导航路由
 */
sealed class Screen(val route: String) {
    object Home : Screen("home")
    object History : Screen("history")
    object Social : Screen("social")
    object Profile : Screen("profile")
    object Login : Screen("login")
    object Running : Screen("running")
}
