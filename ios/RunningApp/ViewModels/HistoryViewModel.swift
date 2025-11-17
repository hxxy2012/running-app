import Foundation
import Combine

// MARK: - 历史记录ViewModel
class HistoryViewModel: ObservableObject {
    @Published var records: [RunningRecord] = []
    @Published var statistics: RunningStatistics?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private var currentPage = 1

    init() {
        loadRecords()
        loadStatistics()
    }

    // MARK: - 加载记录列表
    func loadRecords(page: Int = 1) {
        isLoading = true
        errorMessage = nil
        currentPage = page

        Task {
            do {
                let response: PageResponse<RunningRecord> = try await NetworkService.shared.request(
                    "running/records",
                    method: .get,
                    parameters: ["page": page, "page_size": 20]
                )

                await MainActor.run {
                    if page == 1 {
                        records = response.list
                    } else {
                        records.append(contentsOf: response.list)
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

    // MARK: - 加载统计数据
    func loadStatistics(type: String = "all") {
        Task {
            do {
                let stats: RunningStatistics = try await NetworkService.shared.request(
                    "running/statistics",
                    method: .get,
                    parameters: ["type": type]
                )

                await MainActor.run {
                    statistics = stats
                }
            } catch {
                // 静默处理统计数据错误
                print("Failed to load statistics: \(error)")
            }
        }
    }

    // MARK: - 删除记录
    func deleteRecord(_ recordId: Int) {
        Task {
            do {
                let _: EmptyResponse = try await NetworkService.shared.request(
                    "running/record/\(recordId)",
                    method: .delete
                )

                await MainActor.run {
                    records.removeAll { $0.id == recordId }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.userFriendlyMessage
                }
            }
        }
    }

    // MARK: - 加载更多
    func loadMore() {
        guard !isLoading else { return }
        loadRecords(page: currentPage + 1)
    }

    // MARK: - 刷新
    func refresh() {
        loadRecords(page: 1)
        loadStatistics()
    }
}
