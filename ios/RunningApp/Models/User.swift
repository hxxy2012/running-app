import Foundation

// MARK: - 用户模型
struct User: Codable, Identifiable {
    let id: Int
    let phone: String
    let nickname: String?
    let avatar: String?
    let gender: Int?
    let birthday: String?
    let height: Int?
    let weight: Int?
    let city: String?
    let signature: String?
    let isRealAuth: Bool
    let createdAt: Int64
    let updatedAt: Int64

    enum CodingKeys: String, CodingKey {
        case id, phone, nickname, avatar, gender, birthday
        case height, weight, city, signature
        case isRealAuth = "is_real_auth"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 登录响应
struct LoginResponse: Codable {
    let token: String
    let refreshToken: String
    let user: User

    enum CodingKeys: String, CodingKey {
        case token
        case refreshToken = "refresh_token"
        case user
    }
}

// MARK: - Token刷新响应
struct RefreshTokenResponse: Codable {
    let token: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case token
        case refreshToken = "refresh_token"
    }
}
