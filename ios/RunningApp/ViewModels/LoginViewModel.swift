import Foundation
import Combine

// MARK: - 登录ViewModel
class LoginViewModel: ObservableObject {
    @Published var phone = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isLoggedIn = false

    private var cancellables = Set<AnyCancellable>()

    // MARK: - 登录
    func login() {
        guard !phone.isEmpty, !password.isEmpty else {
            errorMessage = "请输入手机号和密码"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let parameters = [
                    "phone": phone,
                    "password": password
                ]

                let response: LoginResponse = try await NetworkService.shared.request(
                    "auth/login",
                    method: .post,
                    parameters: parameters
                )

                // 保存token
                KeychainManager.shared.saveAccessToken(response.token)
                KeychainManager.shared.saveRefreshToken(response.refreshToken)

                // 保存用户信息
                UserDefaults.standard.set(response.user.id, forKey: "userId")

                await MainActor.run {
                    isLoggedIn = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.userFriendlyMessage
                    isLoading = false
                }
            }
        }
    }

    // MARK: - 发送验证码
    func sendCode() {
        guard !phone.isEmpty else {
            errorMessage = "请输入手机号"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let _: EmptyResponse = try await NetworkService.shared.request(
                    "auth/sendCode",
                    method: .post,
                    parameters: ["phone": phone, "type": "login"]
                )

                await MainActor.run {
                    isLoading = false
                    // 显示验证码已发送提示
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.userFriendlyMessage
                    isLoading = false
                }
            }
        }
    }
}
