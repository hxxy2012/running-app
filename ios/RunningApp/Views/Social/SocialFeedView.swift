import SwiftUI

// MARK: - 社交动态页面
struct SocialFeedView: View {
    @State private var selectedTab = 0
    @State private var posts: [Post] = []
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab选择
                Picker("动态类型", selection: $selectedTab) {
                    Text("关注").tag(0)
                    Text("广场").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // 动态列表
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if posts.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        Text("暂无动态")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(posts) { post in
                                PostCard(post: post)
                                Divider()
                            }
                        }
                    }
                }
            }
            .navigationTitle("动态")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 发布动态
                    }) {
                        Image(systemName: "plus.circle")
                    }
                }
            }
        }
    }
}

// MARK: - 动态卡片
struct PostCard: View {
    let post: Post
    @State private var isLiked: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 用户信息
            HStack {
                // 头像
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(post.user?.nickname ?? "用户\(post.userId)")
                        .font(.headline)
                    Text(formatDate(post.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }

            // 内容
            Text(post.content)
                .font(.body)

            // 关联的跑步记录
            if let record = post.record {
                HStack(spacing: 12) {
                    Image(systemName: "figure.run")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(String(format: "%.2f", record.distance / 1000)) km")
                            .font(.headline)
                        Text("\(record.duration / 60) 分钟")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }

            // 互动按钮
            HStack(spacing: 0) {
                Button(action: {
                    isLiked.toggle()
                }) {
                    Label("\(post.likeCount)", systemImage: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .secondary)
                }
                .frame(maxWidth: .infinity)

                Button(action: {}) {
                    Label("\(post.commentCount)", systemImage: "bubble.left")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Button(action: {}) {
                    Label("分享", systemImage: "square.and.arrow.up")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .font(.subheadline)
        }
        .padding()
    }

    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Profile页面
struct ProfileTabView: View {
    @State private var showingLogoutAlert = false

    var body: some View {
        NavigationView {
            List {
                // 用户信息
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.blue)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("未设置昵称")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("这个人很懒，什么都没留下")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                // 统计
                Section {
                    HStack {
                        StatButton(value: "0", label: "关注")
                        Divider()
                        StatButton(value: "0", label: "粉丝")
                        Divider()
                        StatButton(value: "0", label: "动态")
                    }
                    .frame(height: 60)
                }

                // 功能列表
                Section {
                    NavigationLink(destination: Text("我的记录")) {
                        Label("我的记录", systemImage: "figure.run")
                    }
                    NavigationLink(destination: Text("我的成就")) {
                        Label("我的成就", systemImage: "trophy")
                    }
                    NavigationLink(destination: Text("训练计划")) {
                        Label("训练计划", systemImage: "calendar")
                    }
                }

                // 设置
                Section {
                    NavigationLink(destination: Text("账号与安全")) {
                        Label("账号与安全", systemImage: "person.circle")
                    }
                    NavigationLink(destination: Text("消息通知")) {
                        Label("消息通知", systemImage: "bell")
                    }
                    NavigationLink(destination: Text("隐私设置")) {
                        Label("隐私设置", systemImage: "hand.raised")
                    }
                    NavigationLink(destination: Text("关于我们")) {
                        Label("关于我们", systemImage: "info.circle")
                    }
                }

                // 退出登录
                Section {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        Text("退出登录")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("确认退出登录？", isPresented: $showingLogoutAlert) {
            Button("取消", role: .cancel) {}
            Button("退出", role: .destructive) {
                // 退出登录逻辑
            }
        }
    }
}

struct StatButton: View {
    let value: String
    let label: String

    var body: some View {
        Button(action: {}) {
            VStack(spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct SocialFeedView_Previews: PreviewProvider {
    static var previews: some View {
        SocialFeedView()
    }
}
