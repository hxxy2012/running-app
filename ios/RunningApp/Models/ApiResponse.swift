import Foundation

// MARK: - API统一响应格式
struct ApiResponse<T: Codable>: Codable {
    let code: Int
    let message: String
    let data: T?
}

// MARK: - 分页响应
struct PageResponse<T: Codable>: Codable {
    let list: [T]
    let total: Int
    let page: Int
    let pageSize: Int

    enum CodingKeys: String, CodingKey {
        case list, total, page
        case pageSize = "page_size"
    }
}

// MARK: - 空响应
struct EmptyResponse: Codable {}
