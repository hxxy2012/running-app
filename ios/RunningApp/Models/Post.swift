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
    var likeCount: Int
    var commentCount: Int
    var isLiked: Bool
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

// MARK: - 训练计划
struct TrainingPlan: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let level: String
    let duration: Int
    let weekCount: Int
    let targetDistance: Int?
    let targetPace: Int?
    let createdAt: Int64

    enum CodingKeys: String, CodingKey {
        case id, name, description, level, duration
        case weekCount = "week_count"
        case targetDistance = "target_distance"
        case targetPace = "target_pace"
        case createdAt = "created_at"
    }
}

// MARK: - 挑战赛
struct Challenge: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let type: String
    let targetValue: Int
    let startDate: String
    let endDate: String
    let status: String
    let participantCount: Int
    let createdAt: Int64

    enum CodingKeys: String, CodingKey {
        case id, name, description, type, status
        case targetValue = "target_value"
        case startDate = "start_date"
        case endDate = "end_date"
        case participantCount = "participant_count"
        case createdAt = "created_at"
    }
}

// MARK: - 跑团
struct RunningClub: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let avatar: String?
    let city: String
    let memberCount: Int
    let creatorId: Int
    let createdAt: Int64

    enum CodingKeys: String, CodingKey {
        case id, name, description, avatar, city
        case memberCount = "member_count"
        case creatorId = "creator_id"
        case createdAt = "created_at"
    }
}

// MARK: - 成就
struct Achievement: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let icon: String
    let condition: String
    let type: String
    let createdAt: Int64

    enum CodingKeys: String, CodingKey {
        case id, name, description, icon, condition, type
        case createdAt = "created_at"
    }
}

