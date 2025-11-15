import SwiftUI

// MARK: - 主界面
struct ContentView: View {
    @StateObject private var loginViewModel = LoginViewModel()

    var body: some View {
        if loginViewModel.isLoggedIn {
            MainTabView()
        } else {
            LoginView()
                .environmentObject(loginViewModel)
        }
    }
}

// MARK: - 主标签页
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // 首页 - 跑步
            HomeView()
                .tabItem {
                    Image(systemName: "figure.run")
                    Text("跑步")
                }
                .tag(0)

            // 历史记录
            HistoryView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("记录")
                }
                .tag(1)

            // 社交动态
            SocialView()
                .tabItem {
                    Image(systemName: "person.2")
                    Text("动态")
                }
                .tag(2)

            // 个人中心
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("我的")
                }
                .tag(3)
        }
    }
}

// MARK: - 登录界面
struct LoginView: View {
    @EnvironmentObject var viewModel: LoginViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Running App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 60)

                Spacer()

                VStack(spacing: 15) {
                    TextField("手机号", text: $viewModel.phone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)

                    SecureField("密码", text: $viewModel.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal, 40)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: {
                    viewModel.login()
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("登录")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal, 40)
                .disabled(viewModel.isLoading)

                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - 首页
struct HomeView: View {
    @StateObject private var viewModel = RunningViewModel()

    var body: some View {
        NavigationView {
            VStack {
                Text("跑步界面")
                    .font(.title)
                    .padding()

                // TODO: 实现跑步界面UI
                Text("距离: \(String(format: "%.2f", viewModel.runningData.distance / 1000)) km")
                Text("时长: \(LocationUtils.formatDuration(viewModel.runningData.duration))")
                Text("配速: \(LocationUtils.formatPace(viewModel.runningData.avgPace))")

                Spacer()

                Button(action: {
                    switch viewModel.runningState {
                    case .stopped:
                        viewModel.startRunning()
                    case .running:
                        viewModel.pauseRunning()
                    case .paused:
                        viewModel.resumeRunning()
                    }
                }) {
                    Text(buttonTitle(for: viewModel.runningState))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
            }
            .navigationTitle("跑步")
        }
    }

    private func buttonTitle(for state: RunningViewModel.RunningState) -> String {
        switch state {
        case .stopped:
            return "开始跑步"
        case .running:
            return "暂停"
        case .paused:
            return "继续"
        }
    }
}

// MARK: - 历史记录
struct HistoryView: View {
    var body: some View {
        NavigationView {
            List {
                Text("历史记录列表")
            }
            .navigationTitle("记录")
        }
    }
}

// MARK: - 社交动态
struct SocialView: View {
    var body: some View {
        NavigationView {
            List {
                Text("社交动态列表")
            }
            .navigationTitle("动态")
        }
    }
}

// MARK: - 个人中心
struct ProfileView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("个人信息")) {
                    Text("昵称")
                    Text("头像")
                }

                Section(header: Text("设置")) {
                    Text("账号设置")
                    Text("隐私设置")
                }

                Section {
                    Button("退出登录") {
                        // TODO: 实现退出登录
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("我的")
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
