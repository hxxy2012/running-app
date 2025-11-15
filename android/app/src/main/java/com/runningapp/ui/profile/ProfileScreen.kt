package com.runningapp.ui.profile

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

/**
 * 个人中心界面
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(
    viewModel: ProfileViewModel = hiltViewModel(),
    onEditProfile: () -> Unit = {},
    onSettings: () -> Unit = {},
    onMyRecords: () -> Unit = {},
    onMyPosts: () -> Unit = {},
    onFollowing: () -> Unit = {},
    onFollowers: () -> Unit = {},
    onAchievements: () -> Unit = {},
    onTrainingPlans: () -> Unit = {}
) {
    val user by viewModel.user.collectAsState()
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("我的") },
                actions = {
                    IconButton(onClick = onSettings) {
                        Icon(Icons.Default.Settings, contentDescription = "Settings")
                    }
                }
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // 用户信息卡片
            item {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    onClick = onEditProfile
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(20.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // 头像
                        Surface(
                            modifier = Modifier
                                .size(64.dp)
                                .clip(CircleShape),
                            color = MaterialTheme.colorScheme.primaryContainer
                        ) {
                            Icon(
                                Icons.Default.Person,
                                contentDescription = "Avatar",
                                modifier = Modifier.padding(12.dp),
                                tint = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                        }

                        Spacer(modifier = Modifier.width(16.dp))

                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = user?.nickname ?: "未设置昵称",
                                style = MaterialTheme.typography.titleLarge
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = user?.signature ?: "这个人很懒，什么都没留下",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }

                        Icon(
                            Icons.Default.ChevronRight,
                            contentDescription = "Edit"
                        )
                    }
                }
            }

            // 统计数据
            item {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(20.dp),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        StatItem(
                            value = "0",
                            label = "关注",
                            onClick = onFollowing
                        )
                        Divider(
                            modifier = Modifier
                                .height(40.dp)
                                .width(1.dp)
                        )
                        StatItem(
                            value = "0",
                            label = "粉丝",
                            onClick = onFollowers
                        )
                        Divider(
                            modifier = Modifier
                                .height(40.dp)
                                .width(1.dp)
                        )
                        StatItem(
                            value = "0",
                            label = "动态",
                            onClick = onMyPosts
                        )
                    }
                }
            }

            // 功能列表
            item {
                Spacer(modifier = Modifier.height(8.dp))
            }

            // 我的记录
            item {
                SettingItem(
                    icon = Icons.Default.DirectionsRun,
                    title = "我的记录",
                    onClick = onMyRecords
                )
                Divider()
            }

            // 我的成就
            item {
                SettingItem(
                    icon = Icons.Default.EmojiEvents,
                    title = "我的成就",
                    onClick = onAchievements
                )
                Divider()
            }

            // 训练计划
            item {
                SettingItem(
                    icon = Icons.Default.FitnessCenter,
                    title = "训练计划",
                    onClick = onTrainingPlans
                )
                Divider()
            }

            item {
                Spacer(modifier = Modifier.height(8.dp))
            }

            // 设置项
            item {
                SettingItem(
                    icon = Icons.Default.AccountCircle,
                    title = "账号与安全",
                    onClick = { /* 账号设置 */ }
                )
                Divider()
            }

            item {
                SettingItem(
                    icon = Icons.Default.Notifications,
                    title = "消息通知",
                    onClick = { /* 通知设置 */ }
                )
                Divider()
            }

            item {
                SettingItem(
                    icon = Icons.Default.Privacy,
                    title = "隐私设置",
                    onClick = { /* 隐私设置 */ }
                )
                Divider()
            }

            item {
                SettingItem(
                    icon = Icons.Default.Info,
                    title = "关于我们",
                    onClick = { /* 关于 */ }
                )
                Divider()
            }

            item {
                Spacer(modifier = Modifier.height(16.dp))
            }

            // 退出登录
            item {
                Button(
                    onClick = {
                        viewModel.logout()
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp)
                        .height(50.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer,
                        contentColor = MaterialTheme.colorScheme.onErrorContainer
                    )
                ) {
                    Text("退出登录")
                }
            }

            item {
                Spacer(modifier = Modifier.height(32.dp))
            }
        }
    }
}

@Composable
private fun StatItem(
    value: String,
    label: String,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.width(80.dp)
    ) {
        TextButton(onClick = onClick) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = value,
                    style = MaterialTheme.typography.titleLarge
                )
                Text(
                    text = label,
                    style = MaterialTheme.typography.bodySmall
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SettingItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    onClick: () -> Unit
) {
    ListItem(
        headlineContent = { Text(title) },
        leadingContent = {
            Icon(icon, contentDescription = title)
        },
        trailingContent = {
            Icon(Icons.Default.ChevronRight, contentDescription = "Go")
        },
        modifier = Modifier.clickable(onClick = onClick)
    )
}
