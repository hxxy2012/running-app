import Foundation
import Combine
import CoreLocation

// MARK: - 跑步ViewModel
class RunningViewModel: ObservableObject {
    @Published var runningState: RunningState = .stopped
    @Published var runningData = RunningData()
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let locationService = LocationTrackingService.shared
    private var currentRecordId: Int?
    private var cancellables = Set<AnyCancellable>()

    init() {
        // 监听位置服务数据
        locationService.$runningData
            .assign(to: &$runningData)
    }

    // MARK: - 开始跑步
    func startRunning() {
        isLoading = true

        Task {
            do {
                // 请求服务器分配记录ID
                let response: StartRunningResponse = try await NetworkService.shared.request(
                    "running/start",
                    method: .post
                )

                currentRecordId = response.recordId

                await MainActor.run {
                    // 启动GPS跟踪
                    locationService.startTracking()
                    runningState = .running
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

    // MARK: - 暂停跑步
    func pauseRunning() {
        locationService.pauseTracking()
        runningState = .paused
    }

    // MARK: - 恢复跑步
    func resumeRunning() {
        locationService.resumeTracking()
        runningState = .running
    }

    // MARK: - 停止跑步
    func stopRunning() {
        guard let recordId = currentRecordId else { return }

        isLoading = true

        Task {
            do {
                // 准备数据
                let trackData = try JSONEncoder().encode(locationService.trackPoints)
                let trackDataString = String(data: trackData, encoding: .utf8) ?? ""

                let parameters: [String: Any] = [
                    "record_id": recordId,
                    "distance": runningData.distance,
                    "duration": runningData.duration,
                    "calories": runningData.calories,
                    "track_data": trackDataString
                ]

                // 提交到服务器
                let _: RunningRecord = try await NetworkService.shared.request(
                    "running/finish",
                    method: .post,
                    parameters: parameters
                )

                await MainActor.run {
                    // 停止GPS跟踪
                    locationService.stopTracking()
                    runningState = .stopped
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

    // MARK: - 跑步状态枚举
    enum RunningState {
        case stopped
        case running
        case paused
    }
}
