import Foundation
import Network
import Combine

// MARK: - 网络状态监测工具
class NetworkMonitor: ObservableObject {

    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.runningapp.networkmonitor")

    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType = .unknown

    // 网络状态变化的Publisher
    var networkStatusPublisher: AnyPublisher<Bool, Never> {
        $isConnected.eraseToAnyPublisher()
    }

    private init() {
        startMonitoring()
    }

    /// 开始监听网络状态
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(from: path) ?? .unknown

                // 记录日志
                Logger.shared.network(
                    method: "STATUS",
                    url: "Network Monitor",
                    parameters: [
                        "connected": self?.isConnected ?? false,
                        "type": self?.connectionType.description ?? "unknown"
                    ]
                )
            }
        }

        monitor.start(queue: queue)
    }

    /// 停止监听
    func stopMonitoring() {
        monitor.cancel()
    }

    /// 获取连接类型
    private func getConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .other
        }
    }

    /// 是否使用Wi-Fi
    var isWifi: Bool {
        return connectionType == .wifi
    }

    /// 是否使用移动数据
    var isCellular: Bool {
        return connectionType == .cellular
    }

    /// 网络连接类型
    enum ConnectionType: CustomStringConvertible {
        case wifi
        case cellular
        case ethernet
        case other
        case unknown

        var description: String {
            switch self {
            case .wifi:
                return "Wi-Fi"
            case .cellular:
                return "Cellular"
            case .ethernet:
                return "Ethernet"
            case .other:
                return "Other"
            case .unknown:
                return "Unknown"
            }
        }
    }
}

// MARK: - 扩展：网络检查辅助方法
extension NetworkMonitor {

    /// 检查网络连接并执行操作
    /// - Parameters:
    ///   - onNoNetwork: 无网络时的回调
    ///   - action: 有网络时执行的操作
    /// - Returns: 操作结果
    func requireNetwork<T>(
        onNoNetwork: (() -> Void)? = nil,
        action: () async throws -> T
    ) async rethrows -> T? {
        guard isConnected else {
            onNoNetwork?()
            return nil
        }
        return try await action()
    }

    /// 等待网络连接
    /// - Parameter timeout: 超时时间（秒）
    /// - Returns: 是否在超时前连接成功
    func waitForConnection(timeout: TimeInterval = 10) async -> Bool {
        if isConnected {
            return true
        }

        return await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            var timeoutTask: Task<Void, Never>?

            // 设置超时
            timeoutTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                cancellable?.cancel()
                continuation.resume(returning: false)
            }

            // 监听网络状态变化
            cancellable = networkStatusPublisher
                .filter { $0 == true }
                .first()
                .sink { _ in
                    timeoutTask?.cancel()
                    continuation.resume(returning: true)
                }
        }
    }
}

// MARK: - 网络可达性检查
extension NetworkMonitor {

    /// 检查是否可以访问指定主机
    /// - Parameter host: 主机地址
    /// - Returns: 是否可达
    func canReach(host: String) async -> Bool {
        guard let url = URL(string: host) else {
            return false
        }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return (200...299).contains(httpResponse.statusCode)
            }
            return false
        } catch {
            Logger.e("Network reachability check failed for \(host)", error: error)
            return false
        }
    }

    /// 获取网络延迟（ping）
    /// - Parameter host: 主机地址
    /// - Returns: 延迟时间（毫秒），失败返回nil
    func ping(host: String) async -> TimeInterval? {
        guard let url = URL(string: host) else {
            return nil
        }

        let startTime = Date()

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                let duration = Date().timeIntervalSince(startTime)
                return duration * 1000 // 转换为毫秒
            }
            return nil
        } catch {
            return nil
        }
    }
}

// MARK: - 网络质量评估
extension NetworkMonitor {

    /// 网络质量等级
    enum NetworkQuality {
        case excellent  // 优秀 (<50ms)
        case good       // 良好 (50-100ms)
        case fair       // 一般 (100-200ms)
        case poor       // 较差 (>200ms)
        case unknown    // 未知

        var description: String {
            switch self {
            case .excellent:
                return "优秀"
            case .good:
                return "良好"
            case .fair:
                return "一般"
            case .poor:
                return "较差"
            case .unknown:
                return "未知"
            }
        }
    }

    /// 评估网络质量
    /// - Parameter host: 测试主机
    /// - Returns: 网络质量等级
    func assessQuality(host: String = "https://www.google.com") async -> NetworkQuality {
        guard let latency = await ping(host: host) else {
            return .unknown
        }

        switch latency {
        case ..<50:
            return .excellent
        case 50..<100:
            return .good
        case 100..<200:
            return .fair
        default:
            return .poor
        }
    }
}
