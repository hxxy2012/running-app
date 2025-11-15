import SwiftUI
import Combine

// MARK: - 主界面
struct ContentView: View {
    @StateObject private var loginViewModel = LoginViewModel()

    var body: some View {
        if loginViewModel.isLoggedIn {
            MainTabView()
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogout"))) { _ in
                    loginViewModel.isLoggedIn = false
                }
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
            RunningView()
                .tabItem {
                    Image(systemName: "figure.run")
                    Text("跑步")
                }
                .tag(0)

            // 历史记录
            HistoryListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("记录")
                }
                .tag(1)

            // 社交动态
            SocialFeedView()
                .tabItem {
                    Image(systemName: "person.2")
                    Text("动态")
                }
                .tag(2)

            // 个人中心
            ProfileTabView()
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


// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
