import SwiftUI

// MARK: - 历史记录列表
struct HistoryListView: View {
    @State private var selectedTab = 0
    @State private var records: [RunningRecord] = []
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 统计卡片
                if !records.isEmpty {
                    VStack(spacing: 12) {
                        Text("累计数据")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 0) {
                            StatisticItem(label: "总距离", value: "0.0 km")
                            Divider()
                            StatisticItem(label: "总时长", value: "0 小时")
                            Divider()
                            StatisticItem(label: "次数", value: "0")
                        }
                        .frame(height: 60)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding()
                }

                // Tab选择
                Picker("时间范围", selection: $selectedTab) {
                    Text("全部").tag(0)
                    Text("本周").tag(1)
                    Text("本月").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                // 记录列表
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if records.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        Text("暂无运动记录")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    List(records) { record in
                        NavigationLink(destination: RecordDetailView(record: record)) {
                            RecordRow(record: record)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("运动记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {}) {
                            Label("日历视图", systemImage: "calendar")
                        }
                        Button(action: {}) {
                            Label("数据统计", systemImage: "chart.bar")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

// MARK: - 统计项
struct StatisticItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 记录行
struct RecordRow: View {
    let record: RunningRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(formatDate(record.startTime))
                    .font(.headline)

                HStack(spacing: 16) {
                    Label("\(String(format: "%.2f", record.distance / 1000)) km", systemImage: "figure.run")
                        .font(.subheadline)
                    Label(LocationUtils.formatDuration(record.duration), systemImage: "clock")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(LocationUtils.formatPace(record.avgPace))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                Text("配速")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 记录详情
struct RecordDetailView: View {
    let record: RunningRecord

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // TODO: 地图轨迹
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .overlay(
                        VStack {
                            Image(systemName: "map")
                                .font(.largeTitle)
                            Text("轨迹地图")
                        }
                        .foregroundColor(.gray)
                    )

                // 数据详情
                VStack(spacing: 16) {
                    DataRow(label: "距离", value: "\(String(format: "%.2f", record.distance / 1000)) km")
                    Divider()
                    DataRow(label: "时长", value: LocationUtils.formatDuration(record.duration))
                    Divider()
                    DataRow(label: "配速", value: LocationUtils.formatPace(record.avgPace))
                    Divider()
                    DataRow(label: "平均速度", value: String(format: "%.2f km/h", record.avgSpeed))
                    Divider()
                    DataRow(label: "卡路里", value: "\(record.calories) kcal")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding()
            }
        }
        .navigationTitle("记录详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

struct HistoryListView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryListView()
    }
}
