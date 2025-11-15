import Foundation
import Alamofire

// MARK: - 网络服务
class NetworkService {
    static let shared = NetworkService()

    private let baseURL = "http://your-api-domain.com/api/" // TODO: 替换为实际API地址
    private let session: Session

    private init() {
        // 配置Session
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30

        // 添加拦截器
        let interceptor = AuthInterceptor()
        session = Session(configuration: configuration, interceptor: interceptor)
    }

    // MARK: - 通用请求方法
    func request<T: Codable>(
        _ endpoint: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                baseURL + endpoint,
                method: method,
                parameters: parameters,
                encoding: encoding
            )
            .validate()
            .responseDecodable(of: ApiResponse<T>.self) { response in
                switch response.result {
                case .success(let apiResponse):
                    if apiResponse.code == 200, let data = apiResponse.data {
                        continuation.resume(returning: data)
                    } else {
                        continuation.resume(throwing: NetworkError.apiError(apiResponse.message))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - 上传文件
    func upload<T: Codable>(
        _ endpoint: String,
        multipartFormData: @escaping (MultipartFormData) -> Void
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            session.upload(
                multipartFormData: multipartFormData,
                to: baseURL + endpoint
            )
            .validate()
            .responseDecodable(of: ApiResponse<T>.self) { response in
                switch response.result {
                case .success(let apiResponse):
                    if apiResponse.code == 200, let data = apiResponse.data {
                        continuation.resume(returning: data)
                    } else {
                        continuation.resume(throwing: NetworkError.apiError(apiResponse.message))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - 认证拦截器
class AuthInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest

        // 从Keychain获取token
        if let token = KeychainManager.shared.getAccessToken() {
            urlRequest.headers.add(.authorization(bearerToken: token))
        }

        completion(.success(urlRequest))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        // Token过期处理
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401 else {
            completion(.doNotRetryWithError(error))
            return
        }

        // 实现Token刷新逻辑
        guard let refreshToken = KeychainManager.shared.getRefreshToken() else {
            // 没有refreshToken，直接失败
            completion(.doNotRetryWithError(error))
            return
        }

        // 调用刷新Token接口
        Task {
            do {
                let response: RefreshTokenResponse = try await NetworkService.shared.request(
                    "auth/refreshToken",
                    method: .post,
                    parameters: ["refresh_token": refreshToken]
                )

                // 保存新Token
                KeychainManager.shared.saveAccessToken(response.token)
                KeychainManager.shared.saveRefreshToken(response.refreshToken)

                // 重试原请求
                completion(.retry)
            } catch {
                // 刷新失败，需要重新登录
                KeychainManager.shared.clearTokens()
                NotificationCenter.default.post(name: NSNotification.Name("TokenRefreshFailed"), object: nil)
                completion(.doNotRetryWithError(error))
            }
        }
    }
}

// MARK: - 网络错误
enum NetworkError: LocalizedError {
    case apiError(String)
    case invalidResponse
    case decodingError

    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return message
        case .invalidResponse:
            return "无效的响应"
        case .decodingError:
            return "数据解析失败"
        }
    }
}

// MARK: - Keychain管理
class KeychainManager {
    static let shared = KeychainManager()

    private let service = "com.runningapp"
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"

    func saveAccessToken(_ token: String) {
        saveToKeychain(key: accessTokenKey, value: token)
    }

    func getAccessToken() -> String? {
        return getFromKeychain(key: accessTokenKey)
    }

    func saveRefreshToken(_ token: String) {
        saveToKeychain(key: refreshTokenKey, value: token)
    }

    func getRefreshToken() -> String? {
        return getFromKeychain(key: refreshTokenKey)
    }

    func clearTokens() {
        deleteFromKeychain(key: accessTokenKey)
        deleteFromKeychain(key: refreshTokenKey)
    }

    private func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func getFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)

        if let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
