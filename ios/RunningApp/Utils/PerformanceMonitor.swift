import Foundation
import UIKit

// MARK: - 性能监控工具
class PerformanceMonitor {

    static let shared = PerformanceMonitor()

    private init() {}

    // 性能指标
    struct PerformanceMetrics {
        var memoryUsage: UInt64 = 0
        var cpuUsage: Double = 0
        var fps: Double = 0
        var networkLatency: TimeInterval = 0
    }

    private var currentMetrics = PerformanceMetrics()
    private var isMonitoring = false
    private var monitoringTimer: Timer?

    // MARK: - 内存监控

    /// 获取当前内存使用（MB）
    var currentMemoryUsage: UInt64 {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return taskInfo.resident_size / 1024 / 1024 // MB
        }
        return 0
    }

    /// 获取可用内存（MB）
    var availableMemory: UInt64 {
        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)

        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let freeMemory = UInt64(vmStats.free_count) * UInt64(pageSize)
            return freeMemory / 1024 / 1024 // MB
        }
        return 0
    }

    /// 获取总内存（MB）
    var totalMemory: UInt64 {
        return ProcessInfo.processInfo.physicalMemory / 1024 / 1024
    }

    /// 获取内存使用百分比
    var memoryUsagePercentage: Double {
        let total = Double(totalMemory)
        let used = Double(currentMemoryUsage)
        return total > 0 ? (used / total * 100) : 0
    }

    // MARK: - CPU监控

    /// 获取CPU使用率
    var cpuUsage: Double {
        var threadList: thread_act_array_t?
        var threadCount = mach_msg_type_number_t(0)
        let result = task_threads(mach_task_self_, &threadList, &threadCount)

        guard result == KERN_SUCCESS, let threads = threadList else {
            return 0
        }

        var totalUsage: Double = 0

        for index in 0..<Int(threadCount) {
            var threadInfo = thread_basic_info()
            var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)

            let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    thread_info(threads[index], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                }
            }

            guard infoResult == KERN_SUCCESS else {
                continue
            }

            let threadBasicInfo = threadInfo as thread_basic_info
            if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                totalUsage += Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
            }
        }

        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), vm_size_t(threadCount))
        return totalUsage
    }

    // MARK: - 性能测量

    /// 测量代码块执行时间
    func measurePerformance<T>(_ tag: String, block: () -> T) -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = block()
        let timeElapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        Logger.d("Performance: \(tag) took \(String(format: "%.2f", timeElapsed))ms")
        return result
    }

    /// 测量异步代码块执行时间
    func measurePerformanceAsync<T>(_ tag: String, block: () async -> T) async -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = await block()
        let timeElapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        Logger.d("Performance: \(tag) took \(String(format: "%.2f", timeElapsed))ms")
        return result
    }

    // MARK: - 启动时间追踪

    private var startupMarkers: [String: TimeInterval] = [:]

    /// 标记启动时间点
    func markStartupTime(_ marker: String) {
        startupMarkers[marker] = Date().timeIntervalSince1970
        Logger.d("Startup marker: \(marker)")
    }

    /// 获取启动耗时
    func getStartupDuration(from startMarker: String, to endMarker: String) -> TimeInterval? {
        guard let start = startupMarkers[startMarker],
              let end = startupMarkers[endMarker] else {
            return nil
        }
        return end - start
    }

    /// 获取所有启动标记
    func getAllStartupMarkers() -> [String: TimeInterval] {
        return startupMarkers
    }

    // MARK: - 网络性能监控

    struct NetworkMetric {
        let url: String
        let method: String
        let duration: TimeInterval
        let timestamp: Date
        let success: Bool
    }

    private var networkMetrics: [NetworkMetric] = []
    private let maxNetworkMetrics = 100

    /// 记录网络请求
    func recordNetworkRequest(
        url: String,
        method: String,
        duration: TimeInterval,
        success: Bool
    ) {
        let metric = NetworkMetric(
            url: url,
            method: method,
            duration: duration,
            timestamp: Date(),
            success: success
        )

        networkMetrics.append(metric)

        // 只保留最近100条
        if networkMetrics.count > maxNetworkMetrics {
            networkMetrics.removeFirst()
        }

        Logger.d("Network: \(method) \(url) - \(String(format: "%.0f", duration * 1000))ms")
    }

    /// 获取平均网络延迟
    var averageNetworkLatency: TimeInterval {
        guard !networkMetrics.isEmpty else { return 0 }
        let total = networkMetrics.reduce(0) { $0 + $1.duration }
        return total / Double(networkMetrics.count)
    }

    /// 获取网络请求成功率
    var networkSuccessRate: Double {
        guard !networkMetrics.isEmpty else { return 100 }
        let successCount = networkMetrics.filter { $0.success }.count
        return Double(successCount) / Double(networkMetrics.count) * 100
    }

    // MARK: - FPS监控

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var currentFPS: Double = 0

    /// 开始FPS监控
    func startFPSMonitoring() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkTick))
        displayLink?.add(to: .main, forMode: .common)
    }

    /// 停止FPS监控
    func stopFPSMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func displayLinkTick(_ link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }

        frameCount += 1
        let elapsed = link.timestamp - lastTimestamp

        if elapsed >= 1.0 {
            currentFPS = Double(frameCount) / elapsed
            frameCount = 0
            lastTimestamp = link.timestamp

            currentMetrics.fps = currentFPS
        }
    }

    // MARK: - 持续监控

    /// 开始性能监控
    func startMonitoring(interval: TimeInterval = 1.0) {
        guard !isMonitoring else { return }

        isMonitoring = true
        startFPSMonitoring()

        monitoringTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }

        Logger.d("Performance monitoring started")
    }

    /// 停止性能监控
    func stopMonitoring() {
        isMonitoring = false
        stopFPSMonitoring()
        monitoringTimer?.invalidate()
        monitoringTimer = nil

        Logger.d("Performance monitoring stopped")
    }

    /// 更新性能指标
    private func updateMetrics() {
        currentMetrics.memoryUsage = currentMemoryUsage
        currentMetrics.cpuUsage = cpuUsage
        currentMetrics.networkLatency = averageNetworkLatency
    }

    /// 获取当前性能指标
    func getCurrentMetrics() -> PerformanceMetrics {
        return currentMetrics
    }

    // MARK: - 性能报告

    /// 生成性能报告
    func generatePerformanceReport() -> String {
        var report = "=== Performance Report ===\n"
        report += "Memory Usage: \(currentMemoryUsage)MB / \(totalMemory)MB\n"
        report += "Memory Usage Percentage: \(String(format: "%.2f", memoryUsagePercentage))%\n"
        report += "CPU Usage: \(String(format: "%.2f", cpuUsage))%\n"
        report += "FPS: \(String(format: "%.1f", currentFPS))\n"
        report += "\nNetwork:\n"
        report += "  Average Latency: \(String(format: "%.0f", averageNetworkLatency * 1000))ms\n"
        report += "  Success Rate: \(String(format: "%.2f", networkSuccessRate))%\n"
        report += "  Total Requests: \(networkMetrics.count)\n"
        report += "========================\n"
        return report
    }

    /// 打印性能报告
    func printPerformanceReport() {
        print(generatePerformanceReport())
    }

    // MARK: - 清理

    /// 清理监控数据
    func cleanup() {
        stopMonitoring()
        networkMetrics.removeAll()
        startupMarkers.removeAll()
    }
}

// MARK: - 全局便捷函数

/// 测量代码块执行时间
func measureTime<T>(_ tag: String, block: () -> T) -> T {
    return PerformanceMonitor.shared.measurePerformance(tag, block: block)
}

/// 测量异步代码块执行时间
func measureTimeAsync<T>(_ tag: String, block: () async -> T) async -> T {
    return await PerformanceMonitor.shared.measurePerformanceAsync(tag, block: block)
}
