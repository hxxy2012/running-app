import Foundation
import UIKit

// MARK: - 崩溃处理器
class CrashHandler {

    static let shared = CrashHandler()

    private init() {}

    // 崩溃报告目录
    private let crashDirectory: URL = {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL.appendingPathComponent("Crashes", isDirectory: true)
    }()

    // MARK: - 初始化

    /// 初始化崩溃处理器
    func initialize() {
        // 创建崩溃目录
        createCrashDirectoryIfNeeded()

        // 设置异常处理器
        NSSetUncaughtExceptionHandler { exception in
            CrashHandler.shared.handleException(exception)
        }

        // 设置信号处理器
        setupSignalHandlers()

        Logger.d("CrashHandler initialized")
    }

    /// 创建崩溃目录
    private func createCrashDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: crashDirectory.path) {
            try? FileManager.default.createDirectory(
                at: crashDirectory,
                withIntermediateDirectories: true
            )
        }
    }

    /// 设置信号处理器
    private func setupSignalHandlers() {
        let signals = [SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGPIPE]

        for sig in signals {
            signal(sig) { signal in
                CrashHandler.shared.handleSignal(signal)
            }
        }
    }

    // MARK: - 异常处理

    /// 处理NSException
    func handleException(_ exception: NSException) {
        let crashInfo = CrashInfo(
            timestamp: Date(),
            type: .exception,
            name: exception.name.rawValue,
            reason: exception.reason ?? "No reason",
            callStack: exception.callStackSymbols,
            deviceInfo: collectDeviceInfo(),
            appVersion: DeviceHelper.shared.appVersion
        )

        saveCrashReport(crashInfo)
        Logger.e("Uncaught exception: \(exception.name.rawValue)")
    }

    /// 处理信号
    func handleSignal(_ signal: Int32) {
        let crashInfo = CrashInfo(
            timestamp: Date(),
            type: .signal,
            name: signalName(signal),
            reason: "Signal \(signal)",
            callStack: Thread.callStackSymbols,
            deviceInfo: collectDeviceInfo(),
            appVersion: DeviceHelper.shared.appVersion
        )

        saveCrashReport(crashInfo)
        Logger.e("Signal received: \(signal)")
    }

    /// 获取信号名称
    private func signalName(_ signal: Int32) -> String {
        switch signal {
        case SIGABRT: return "SIGABRT"
        case SIGILL: return "SIGILL"
        case SIGSEGV: return "SIGSEGV"
        case SIGFPE: return "SIGFPE"
        case SIGBUS: return "SIGBUS"
        case SIGPIPE: return "SIGPIPE"
        default: return "UNKNOWN"
        }
    }

    // MARK: - 信息收集

    /// 收集设备信息
    private func collectDeviceInfo() -> [String: String] {
        let deviceHelper = DeviceHelper.shared
        return [
            "deviceModel": deviceHelper.deviceTypeName,
            "systemVersion": deviceHelper.systemVersion,
            "appVersion": deviceHelper.appVersion,
            "buildNumber": deviceHelper.buildNumber,
            "deviceId": deviceHelper.deviceId,
            "freeMemory": "\(deviceHelper.freeMemorySize)MB",
            "totalMemory": "\(deviceHelper.totalMemorySize)MB",
            "freeDisk": "\(deviceHelper.freeDiskSize)MB"
        ]
    }

    // MARK: - 崩溃报告

    /// 保存崩溃报告
    private func saveCrashReport(_ crashInfo: CrashInfo) {
        do {
            let fileName = generateCrashFileName(crashInfo.timestamp)
            let fileURL = crashDirectory.appendingPathComponent(fileName)

            let reportContent = formatCrashReport(crashInfo)
            try reportContent.write(to: fileURL, atomically: true, encoding: .utf8)

            Logger.d("Crash report saved: \(fileURL.path)")

            // 异步上传崩溃报告
            uploadCrashReport(crashInfo)
        } catch {
            Logger.e("Failed to save crash report", error: error)
        }
    }

    /// 格式化崩溃报告
    private func formatCrashReport(_ crashInfo: CrashInfo) -> String {
        var report = "====== Crash Report ======\n\n"

        // 时间信息
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        report += "Time: \(dateFormatter.string(from: crashInfo.timestamp))\n\n"

        // 应用信息
        report += "--- App Info ---\n"
        report += "Version: \(crashInfo.appVersion)\n\n"

        // 设备信息
        report += "--- Device Info ---\n"
        crashInfo.deviceInfo.forEach { key, value in
            report += "\(key): \(value)\n"
        }
        report += "\n"

        // 崩溃信息
        report += "--- Crash Info ---\n"
        report += "Type: \(crashInfo.type.rawValue)\n"
        report += "Name: \(crashInfo.name)\n"
        report += "Reason: \(crashInfo.reason)\n\n"

        // 调用栈
        report += "--- Call Stack ---\n"
        crashInfo.callStack.forEach { symbol in
            report += "\(symbol)\n"
        }
        report += "\n"

        report += "=========================\n"

        return report
    }

    /// 生成崩溃文件名
    private func generateCrashFileName(_ timestamp: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        return "crash_\(dateFormatter.string(from: timestamp)).log"
    }

    /// 上传崩溃报告
    private func uploadCrashReport(_ crashInfo: CrashInfo) {
        Task {
            do {
                // 构建请求体
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

                let parameters: [String: Any] = [
                    "platform": "ios",
                    "app_version": DeviceHelper.shared.appVersion,
                    "os_version": DeviceHelper.shared.osVersion,
                    "device_model": DeviceHelper.shared.deviceModel,
                    "crash_time": dateFormatter.string(from: crashInfo.timestamp),
                    "log_content": crashInfo.stackTrace
                ]

                let jsonData = try JSONSerialization.data(withJSONObject: parameters)

                // 创建请求（需要替换为实际的API地址）
                guard let url = URL(string: "YOUR_API_BASE_URL/crash/upload") else {
                    Logger.e("Invalid crash upload URL")
                    return
                }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = jsonData

                // 发送请求
                let (data, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        Logger.d("Crash report uploaded successfully")
                    } else {
                        Logger.e("Failed to upload crash report: \(httpResponse.statusCode)")
                    }
                }
            } catch {
                Logger.e("Failed to upload crash report", error: error)
                // 上传失败不影响崩溃处理流程
            }
        }
    }

    // MARK: - 崩溃报告管理

    /// 获取所有崩溃报告
    func getAllCrashReports() -> [URL] {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: crashDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )

            return files
                .filter { $0.pathExtension == "log" }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    return date1 > date2
                }
        } catch {
            Logger.e("Failed to get crash reports", error: error)
            return []
        }
    }

    /// 读取崩溃报告内容
    func readCrashReport(_ fileURL: URL) -> String? {
        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            Logger.e("Failed to read crash report", error: error)
            return nil
        }
    }

    /// 删除崩溃报告
    func deleteCrashReport(_ fileURL: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: fileURL)
            Logger.d("Crash report deleted: \(fileURL.path)")
            return true
        } catch {
            Logger.e("Failed to delete crash report", error: error)
            return false
        }
    }

    /// 清理所有崩溃报告
    func clearAllCrashReports() {
        let reports = getAllCrashReports()
        reports.forEach { _ = deleteCrashReport($0) }
        Logger.d("All crash reports cleared")
    }

    /// 清理旧的崩溃报告（保留最近N个）
    func cleanOldCrashReports(keepCount: Int = 10) {
        let reports = getAllCrashReports()
        if reports.count > keepCount {
            let toDelete = reports.dropFirst(keepCount)
            toDelete.forEach { _ = deleteCrashReport($0) }
            Logger.d("Cleaned \(toDelete.count) old crash reports")
        }
    }

    /// 获取崩溃报告数量
    func getCrashReportCount() -> Int {
        return getAllCrashReports().count
    }

    /// 检查是否有新的崩溃报告
    func hasNewCrashReports(since lastCheckTime: Date) -> Bool {
        return getAllCrashReports().contains { url in
            guard let date = (try? url.resourceValues(forKeys: [.creationDateKey]))?.creationDate else {
                return false
            }
            return date > lastCheckTime
        }
    }

    /// 获取崩溃报告信息
    func getCrashReportInfo(_ fileURL: URL) -> [String: String] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let creationDate: Date
        if let resourceValues = try? fileURL.resourceValues(forKeys: [.creationDateKey]),
           let date = resourceValues.creationDate {
            creationDate = date
        } else {
            creationDate = Date()
        }

        let fileSize: Int64
        if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
           let size = resourceValues.fileSize {
            fileSize = Int64(size)
        } else {
            fileSize = 0
        }

        return [
            "name": fileURL.lastPathComponent,
            "date": dateFormatter.string(from: creationDate),
            "size": FormatUtils.shared.formatFileSize(fileSize)
        ]
    }

    // MARK: - 崩溃信息数据模型

    enum CrashType: String {
        case exception = "Exception"
        case signal = "Signal"
    }

    struct CrashInfo {
        let timestamp: Date
        let type: CrashType
        let name: String
        let reason: String
        let callStack: [String]
        let deviceInfo: [String: String]
        let appVersion: String
    }
}

// MARK: - 便捷扩展

extension CrashHandler {

    /// 手动记录错误（不会导致应用崩溃）
    func logError(
        name: String,
        reason: String,
        callStack: [String] = Thread.callStackSymbols
    ) {
        let crashInfo = CrashInfo(
            timestamp: Date(),
            type: .exception,
            name: name,
            reason: reason,
            callStack: callStack,
            deviceInfo: collectDeviceInfo(),
            appVersion: DeviceHelper.shared.appVersion
        )

        saveCrashReport(crashInfo)
    }

    /// 导出崩溃报告为ZIP
    func exportCrashReportsAsZip() -> URL? {
        do {
            let crashReports = getAllCrashReports()
            if crashReports.isEmpty {
                Logger.w("No crash reports to export")
                return nil
            }

            // 创建临时目录存放要压缩的文件
            let tempDirectory = FileManager.default.temporaryDirectory
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let exportFolderName = "crash_reports_\(dateFormatter.string(from: Date()))"
            let exportFolder = tempDirectory.appendingPathComponent(exportFolderName)

            // 删除已存在的目录
            if FileManager.default.fileExists(atPath: exportFolder.path) {
                try FileManager.default.removeItem(at: exportFolder)
            }

            // 创建导出目录
            try FileManager.default.createDirectory(at: exportFolder, withIntermediateDirectories: true)

            // 复制所有崩溃报告到导出目录
            for crashReport in crashReports {
                let destURL = exportFolder.appendingPathComponent(crashReport.lastPathComponent)
                try FileManager.default.copyItem(at: crashReport, to: destURL)
            }

            // 使用系统ZIP压缩
            let zipURL = tempDirectory.appendingPathComponent("\(exportFolderName).zip")

            // 删除已存在的ZIP文件
            if FileManager.default.fileExists(atPath: zipURL.path) {
                try FileManager.default.removeItem(at: zipURL)
            }

            // 执行ZIP压缩
            var coordinatorError: NSError?
            NSFileCoordinator().coordinate(readingItemAt: exportFolder, options: [.forUploading], error: &coordinatorError) { zipFileURL in
                do {
                    try FileManager.default.copyItem(at: zipFileURL, to: zipURL)
                    Logger.d("Crash reports exported to ZIP: \(exportFolderName).zip")
                } catch {
                    Logger.e("Failed to copy ZIP file", error: error)
                }
            }

            // 清理临时文件夹
            try? FileManager.default.removeItem(at: exportFolder)

            if let error = coordinatorError {
                Logger.e("File coordinator error", error: error)
                return nil
            }

            // 验证ZIP文件是否创建成功
            guard FileManager.default.fileExists(atPath: zipURL.path) else {
                Logger.e("ZIP file was not created")
                return nil
            }

            return zipURL

        } catch {
            Logger.e("Failed to export crash reports", error: error)
            return nil
        }
    }
}

// MARK: - 全局便捷函数

/// 初始化崩溃处理器
func initializeCrashHandler() {
    CrashHandler.shared.initialize()
}

/// 手动记录错误
func logCrashError(name: String, reason: String) {
    CrashHandler.shared.logError(name: name, reason: reason)
}
