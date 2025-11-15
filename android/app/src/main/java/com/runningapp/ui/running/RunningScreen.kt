package com.runningapp.ui.running

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.runningapp.utils.LocationUtils

/**
 * 跑步主界面
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RunningScreen(
    viewModel: RunningViewModel = hiltViewModel()
) {
    val runningState by viewModel.runningState.collectAsState()
    val runningData by viewModel.runningData.collectAsState()
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("跑步") },
                actions = {
                    IconButton(onClick = { /* 设置 */ }) {
                        Icon(Icons.Default.Settings, contentDescription = "Settings")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // 地图区域（占据上半部分）
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    .background(MaterialTheme.colorScheme.surfaceVariant),
                contentAlignment = Alignment.Center
            ) {
                // TODO: 集成地图组件显示轨迹
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Icon(
                        imageVector = Icons.Default.Map,
                        contentDescription = "Map",
                        modifier = Modifier.size(64.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = "地图区域",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = "（需要集成地图SDK）",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                // 运动数据浮层
                if (runningState != RunningViewModel.RunningState.STOPPED) {
                    Card(
                        modifier = Modifier
                            .align(Alignment.TopCenter)
                            .padding(16.dp)
                            .fillMaxWidth(0.9f)
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Text(
                                text = when (runningState) {
                                    RunningViewModel.RunningState.RUNNING -> "运动中"
                                    RunningViewModel.RunningState.PAUSED -> "已暂停"
                                    else -> ""
                                },
                                style = MaterialTheme.typography.labelMedium,
                                color = when (runningState) {
                                    RunningViewModel.RunningState.RUNNING -> Color.Green
                                    RunningViewModel.RunningState.PAUSED -> Color.Orange
                                    else -> Color.Gray
                                }
                            )
                        }
                    }
                }
            }

            // 数据展示区域（下半部分）
            Surface(
                modifier = Modifier.fillMaxWidth(),
                color = MaterialTheme.colorScheme.surface,
                tonalElevation = 2.dp
            ) {
                Column(
                    modifier = Modifier.padding(24.dp)
                ) {
                    // 主要数据：距离
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = "距离 (km)",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = String.format("%.2f", runningData.distance / 1000),
                            style = MaterialTheme.typography.displayLarge,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }

                    Spacer(modifier = Modifier.height(24.dp))

                    // 次要数据
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        DataItem(
                            label = "时长",
                            value = LocationUtils.formatDuration(runningData.duration)
                        )
                        DataItem(
                            label = "配速",
                            value = LocationUtils.formatPace(runningData.avgPace)
                        )
                        DataItem(
                            label = "卡路里",
                            value = "${runningData.calories}"
                        )
                    }

                    Spacer(modifier = Modifier.height(24.dp))

                    // 控制按钮
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        when (runningState) {
                            RunningViewModel.RunningState.STOPPED -> {
                                // 开始按钮
                                FilledIconButton(
                                    onClick = { viewModel.startRunning() },
                                    modifier = Modifier.size(72.dp),
                                    colors = IconButtonDefaults.filledIconButtonColors(
                                        containerColor = MaterialTheme.colorScheme.primary
                                    )
                                ) {
                                    Icon(
                                        Icons.Default.PlayArrow,
                                        contentDescription = "Start",
                                        modifier = Modifier.size(36.dp)
                                    )
                                }
                            }
                            RunningViewModel.RunningState.RUNNING -> {
                                // 暂停按钮
                                OutlinedIconButton(
                                    onClick = { viewModel.pauseRunning() },
                                    modifier = Modifier.size(64.dp)
                                ) {
                                    Icon(
                                        Icons.Default.Pause,
                                        contentDescription = "Pause",
                                        modifier = Modifier.size(32.dp)
                                    )
                                }

                                // 结束按钮
                                OutlinedIconButton(
                                    onClick = { viewModel.stopRunning() },
                                    modifier = Modifier.size(64.dp),
                                    colors = IconButtonDefaults.outlinedIconButtonColors(
                                        contentColor = MaterialTheme.colorScheme.error
                                    )
                                ) {
                                    Icon(
                                        Icons.Default.Stop,
                                        contentDescription = "Stop",
                                        modifier = Modifier.size(32.dp)
                                    )
                                }
                            }
                            RunningViewModel.RunningState.PAUSED -> {
                                // 继续按钮
                                FilledIconButton(
                                    onClick = { viewModel.resumeRunning() },
                                    modifier = Modifier.size(64.dp),
                                    colors = IconButtonDefaults.filledIconButtonColors(
                                        containerColor = MaterialTheme.colorScheme.primary
                                    )
                                ) {
                                    Icon(
                                        Icons.Default.PlayArrow,
                                        contentDescription = "Resume",
                                        modifier = Modifier.size(32.dp)
                                    )
                                }

                                // 结束按钮
                                OutlinedIconButton(
                                    onClick = { viewModel.stopRunning() },
                                    modifier = Modifier.size(64.dp),
                                    colors = IconButtonDefaults.outlinedIconButtonColors(
                                        contentColor = MaterialTheme.colorScheme.error
                                    )
                                ) {
                                    Icon(
                                        Icons.Default.Stop,
                                        contentDescription = "Stop",
                                        modifier = Modifier.size(32.dp)
                                    )
                                }
                            }
                        }
                    }

                    // 错误提示
                    if (uiState is RunningViewModel.UiState.Error) {
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = (uiState as RunningViewModel.UiState.Error).message,
                            color = MaterialTheme.colorScheme.error,
                            style = MaterialTheme.typography.bodySmall,
                            modifier = Modifier.fillMaxWidth()
                        )
                    }

                    // 加载中
                    if (uiState is RunningViewModel.UiState.Loading) {
                        Spacer(modifier = Modifier.height(16.dp))
                        LinearProgressIndicator(
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }
            }
        }
    }

    // 完成跑步的Dialog
    if (uiState is RunningViewModel.UiState.Finished) {
        val record = (uiState as RunningViewModel.UiState.Finished).record
        AlertDialog(
            onDismissRequest = { viewModel.dismissFinishDialog() },
            title = { Text("跑步完成！") },
            text = {
                Column {
                    Text("距离: ${String.format("%.2f", record.distance / 1000)} km")
                    Text("时长: ${LocationUtils.formatDuration(record.duration)}")
                    Text("配速: ${LocationUtils.formatPace(record.avgPace)}")
                    Text("卡路里: ${record.calories}")
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.dismissFinishDialog()
                    // TODO: 导航到记录详情页面
                }) {
                    Text("查看详情")
                }
            },
            dismissButton = {
                TextButton(onClick = { viewModel.dismissFinishDialog() }) {
                    Text("关闭")
                }
            }
        )
    }
}

@Composable
private fun DataItem(
    label: String,
    value: String
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = value,
            style = MaterialTheme.typography.titleLarge,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}
