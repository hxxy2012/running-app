import SwiftUI
import MapKit

// MARK: - 跑步主界面
struct RunningView: View {
    @StateObject private var viewModel = RunningViewModel()
    @State private var showingFinishDialog = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 地图区域
                ZStack {
                    // TODO: 集成MapKit显示轨迹
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            VStack {
                                Image(systemName: "map")
                                    .font(.system(size: 64))
                                    .foregroundColor(.gray)
                                Text("地图区域")
                                    .foregroundColor(.gray)
                                Text("（需要集成MapKit）")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )

                    // 运动状态提示
                    if viewModel.runningState != .stopped {
                        VStack {
                            HStack {
                                Text(viewModel.runningState == .running ? "运动中" : "已暂停")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(viewModel.runningState == .running ? Color.green : Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                Spacer()
                            }
                            .padding()
                            Spacer()
                        }
                    }
                }
                .frame(maxHeight: .infinity)

                // 数据展示区域
                VStack(spacing: 20) {
                    // 主要数据：距离
                    VStack(spacing: 8) {
                        Text("距离 (km)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f", viewModel.runningData.distance / 1000))
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(.blue)
                    }

                    // 次要数据
                    HStack(spacing: 40) {
                        DataItem(label: "时长", value: LocationUtils.formatDuration(viewModel.runningData.duration))
                        DataItem(label: "配速", value: LocationUtils.formatPace(viewModel.runningData.avgPace))
                        DataItem(label: "卡路里", value: "\(viewModel.runningData.calories)")
                    }

                    // 控制按钮
                    HStack(spacing: 30) {
                        switch viewModel.runningState {
                        case .stopped:
                            Button(action: {
                                viewModel.startRunning()
                            }) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 32))
                                    .frame(width: 72, height: 72)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }

                        case .running:
                            Button(action: {
                                viewModel.pauseRunning()
                            }) {
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 28))
                                    .frame(width: 64, height: 64)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.blue, lineWidth: 2)
                                    )
                            }

                            Button(action: {
                                showingFinishDialog = true
                            }) {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 28))
                                    .frame(width: 64, height: 64)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.red, lineWidth: 2)
                                    )
                                    .foregroundColor(.red)
                            }

                        case .paused:
                            Button(action: {
                                viewModel.resumeRunning()
                            }) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 28))
                                    .frame(width: 64, height: 64)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }

                            Button(action: {
                                showingFinishDialog = true
                            }) {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 28))
                                    .frame(width: 64, height: 64)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.red, lineWidth: 2)
                                    )
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.vertical, 20)

                    // 错误提示
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    // 加载指示器
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("跑步")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 设置
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .alert("确认结束跑步？", isPresented: $showingFinishDialog) {
            Button("取消", role: .cancel) {}
            Button("结束", role: .destructive) {
                viewModel.stopRunning()
            }
        }
    }
}

// MARK: - 数据展示组件
struct DataItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
    }
}

struct RunningView_Previews: PreviewProvider {
    static var previews: some View {
        RunningView()
    }
}
