import Foundation

// MARK: - 动态帖子
struct Post: Codable, Identifiable {
    let id: Int
    let userId: Int
    let user: User?
    let content: String
    let images: [String]?
    let recordId: Int?
    let record: RunningRecord?
    let likeCount: Int
    let commentCount: Int
    let isLiked: Bool
    let createdAt: Int64
    let updatedAt: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case user, content, images
        case recordId = "record_id"
        case record
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case isLiked = "is_liked"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 评论
struct Comment: Codable, Identifiable {
    let id: Int
    let postId: Int
    let userId: Int
    let user: User?
    let content: String
    let replyToUserId: Int?
    let replyToUser: User?
    let createdAt: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case user, content
        case replyToUserId = "reply_to_user_id"
        case replyToUser = "reply_to_user"
        case createdAt = "created_at"
    }
}
