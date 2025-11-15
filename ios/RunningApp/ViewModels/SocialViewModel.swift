import Foundation
import Combine

// MARK: - 社交ViewModel
class SocialViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private var currentPage = 1
    private var currentType = "following"

    init() {
        loadFeed()
    }

    // MARK: - 加载动态流
    func loadFeed(type: String = "following", page: Int = 1) {
        isLoading = true
        errorMessage = nil
        currentPage = page
        currentType = type

        Task {
            do {
                let endpoint = type == "following" ? "post/feed" : "post/square"
                let response: PageResponse<Post> = try await NetworkService.shared.request(
                    endpoint,
                    method: .get,
                    parameters: ["page": page, "page_size": 20]
                )

                await MainActor.run {
                    if page == 1 {
                        posts = response.list
                    } else {
                        posts.append(contentsOf: response.list)
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    // MARK: - 创建动态
    func createPost(content: String, images: [String]? = nil, recordId: Int? = nil) {
        isLoading = true

        Task {
            do {
                var parameters: [String: Any] = ["content": content]
                if let images = images {
                    parameters["images"] = images.joined(separator: ",")
                }
                if let recordId = recordId {
                    parameters["record_id"] = recordId
                }

                let post: Post = try await NetworkService.shared.request(
                    "post/create",
                    method: .post,
                    parameters: parameters
                )

                await MainActor.run {
                    posts.insert(post, at: 0)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    // MARK: - 点赞
    func likePost(_ postId: Int) {
        Task {
            do {
                let _: EmptyResponse = try await NetworkService.shared.request(
                    "post/like/\(postId)",
                    method: .post
                )

                await MainActor.run {
                    if let index = posts.firstIndex(where: { $0.id == postId }) {
                        var updatedPost = posts[index]
                        updatedPost.isLiked = true
                        updatedPost.likeCount += 1
                        posts[index] = updatedPost
                    }
                }
            } catch {
                print("Failed to like post: \(error)")
            }
        }
    }

    // MARK: - 取消点赞
    func unlikePost(_ postId: Int) {
        Task {
            do {
                let _: EmptyResponse = try await NetworkService.shared.request(
                    "post/unlike/\(postId)",
                    method: .delete
                )

                await MainActor.run {
                    if let index = posts.firstIndex(where: { $0.id == postId }) {
                        var updatedPost = posts[index]
                        updatedPost.isLiked = false
                        updatedPost.likeCount -= 1
                        posts[index] = updatedPost
                    }
                }
            } catch {
                print("Failed to unlike post: \(error)")
            }
        }
    }

    // MARK: - 加载评论
    func loadComments(postId: Int, page: Int = 1) {
        Task {
            do {
                let response: PageResponse<Comment> = try await NetworkService.shared.request(
                    "post/comments/\(postId)",
                    method: .get,
                    parameters: ["page": page, "page_size": 20]
                )

                await MainActor.run {
                    if page == 1 {
                        comments = response.list
                    } else {
                        comments.append(contentsOf: response.list)
                    }
                }
            } catch {
                print("Failed to load comments: \(error)")
            }
        }
    }

    // MARK: - 评论
    func comment(postId: Int, content: String, replyToUserId: Int? = nil) {
        Task {
            do {
                var parameters: [String: Any] = [
                    "post_id": postId,
                    "content": content
                ]
                if let replyToUserId = replyToUserId {
                    parameters["reply_to_user_id"] = replyToUserId
                }

                let comment: Comment = try await NetworkService.shared.request(
                    "post/comment",
                    method: .post,
                    parameters: parameters
                )

                await MainActor.run {
                    comments.insert(comment, at: 0)
                    // 更新帖子评论数
                    if let index = posts.firstIndex(where: { $0.id == postId }) {
                        var updatedPost = posts[index]
                        updatedPost.commentCount += 1
                        posts[index] = updatedPost
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - 加载更多
    func loadMore() {
        guard !isLoading else { return }
        loadFeed(type: currentType, page: currentPage + 1)
    }

    // MARK: - 刷新
    func refresh() {
        loadFeed(type: currentType, page: 1)
    }
}

// MARK: - 评论模型
struct Comment: Codable, Identifiable {
    let id: Int
    let postId: Int
    let userId: Int
    let content: String
    let replyToUserId: Int?
    let user: User?
    let replyToUser: User?
    let createdAt: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case content
        case replyToUserId = "reply_to_user_id"
        case user
        case replyToUser = "reply_to_user"
        case createdAt = "created_at"
    }
}
