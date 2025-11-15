import Foundation
import CoreLocation

// MARK: - 跑步记录
struct RunningRecord: Codable, Identifiable {
    let id: Int
    let userId: Int
    let distance: Float
    let duration: Int
    let calories: Int
    let avgPace: Int
    let avgSpeed: Float
    let maxSpeed: Float
    let steps: Int?
    let stepFrequency: Int?
    let startTime: Int64
    let endTime: Int64
    let trackData: String
    let elevationGain: Int?
    let elevationLoss: Int?
    let weather: String?
    let temperature: Int?
    let note: String?
    let images: String?
    let createdAt: Int64
    let updatedAt: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case distance, duration, calories
        case avgPace = "avg_pace"
        case avgSpeed = "avg_speed"
        case maxSpeed = "max_speed"
        case steps
        case stepFrequency = "step_frequency"
        case startTime = "start_time"
        case endTime = "end_time"
        case trackData = "track_data"
        case elevationGain = "elevation_gain"
        case elevationLoss = "elevation_loss"
        case weather, temperature, note, images
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 轨迹点
struct TrackPoint: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let speed: Float?
    let accuracy: Float?
    let timestamp: Int64

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - 开始跑步响应
struct StartRunningResponse: Codable {
    let recordId: Int

    enum CodingKeys: String, CodingKey {
        case recordId = "record_id"
    }
}

// MARK: - 跑步统计
struct RunningStatistics: Codable {
    let totalDistance: Float
    let totalDuration: Int
    let totalCalories: Int
    let totalCount: Int
    let avgDistance: Float
    let avgDuration: Int
    let avgPace: Int
    let bestPace: Int?
    let bestDistance: Float?
    let bestDuration: Int?

    enum CodingKeys: String, CodingKey {
        case totalDistance = "total_distance"
        case totalDuration = "total_duration"
        case totalCalories = "total_calories"
        case totalCount = "total_count"
        case avgDistance = "avg_distance"
        case avgDuration = "avg_duration"
        case avgPace = "avg_pace"
        case bestPace = "best_pace"
        case bestDistance = "best_distance"
        case bestDuration = "best_duration"
    }
}

// MARK: - 个人最佳记录
struct PersonalBest: Codable {
    let best5k: RunningRecord?
    let best10k: RunningRecord?
    let bestHalfMarathon: RunningRecord?
    let bestMarathon: RunningRecord?
    let longestDistance: RunningRecord?
    let longestDuration: RunningRecord?

    enum CodingKeys: String, CodingKey {
        case best5k = "best_5k"
        case best10k = "best_10k"
        case bestHalfMarathon = "best_half_marathon"
        case bestMarathon = "best_marathon"
        case longestDistance = "longest_distance"
        case longestDuration = "longest_duration"
    }
}
