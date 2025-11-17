import Foundation
import Combine
import UIKit

// MARK: - 个人中心ViewModel
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingLogoutAlert = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        loadProfile()
    }

    // MARK: - 加载个人信息
    func loadProfile() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let user: User = try await NetworkService.shared.request(
                    "user/profile",
                    method: .get
                )

                await MainActor.run {
                    self.user = user
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

    // MARK: - 更新个人信息
    func updateProfile(params: [String: Any]) {
        isLoading = true

        Task {
            do {
                let user: User = try await NetworkService.shared.request(
                    "user/profile",
                    method: .put,
                    parameters: params
                )

                await MainActor.run {
                    self.user = user
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

    // MARK: - 上传头像
    func uploadAvatar(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "图片处理失败"
            return
        }

        isLoading = true

        Task {
            do {
                let response: UploadResponse = try await NetworkService.shared.upload("user/uploadAvatar") { formData in
                    formData.append(imageData, withName: "avatar", fileName: "avatar.jpg", mimeType: "image/jpeg")
                }

                await MainActor.run {
                    // 更新本地用户头像
                    if var currentUser = self.user {
                        currentUser.avatar = response.url
                        self.user = currentUser
                    }
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

    // MARK: - 修改密码
    func changePassword(oldPassword: String, newPassword: String) {
        isLoading = true

        Task {
            do {
                let _: EmptyResponse = try await NetworkService.shared.request(
                    "user/changePassword",
                    method: .put,
                    parameters: [
                        "old_password": oldPassword,
                        "new_password": newPassword
                    ]
                )

                await MainActor.run {
                    isLoading = false
                    // 密码修改成功，可以显示提示
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.userFriendlyMessage
                    isLoading = false
                }
            }
        }
    }

    // MARK: - 退出登录
    func logout() {
        KeychainManager.shared.clearTokens()
        UserDefaults.standard.removeObject(forKey: "userId")
        NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)
    }
}

// MARK: - 上传响应
struct UploadResponse: Codable {
    let url: String
}
