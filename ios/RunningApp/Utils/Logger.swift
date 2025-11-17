import Foundation
import os.log

// MARK: - 日志工具类
class Logger {

    static let shared = Logger()

    private let subsystem = "com.runningapp"
    private var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    // MARK: - Log Categories
    private enum Category: String {
        case network = "Network"
        case database = "Database"
        case lifecycle = "Lifecycle"
        case navigation = "Navigation"
        case performance = "Performance"
        case error = "Error"
        case general = "General"
    }

    // MARK: - Private Methods
    private func log(_ message: String, category: Category, type: OSLogType) {
        guard isDebug else { return }

        let log = OSLog(subsystem: subsystem, category: category.rawValue)
        os_log("%{public}@", log: log, type: type, message)
    }

    // MARK: - Public Methods

    /// Verbose日志
    func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        log("[\(fileName):\(line)] \(function) - \(message)", category: .general, type: .debug)
    }

    /// Debug日志
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        log("[\(fileName):\(line)] \(function) - \(message)", category: .general, type: .debug)
    }

    /// Info日志
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        log("[\(fileName):\(line)] \(function) - \(message)", category: .general, type: .info)
    }

    /// Warning日志
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        log("[\(fileName):\(line)] \(function) - \(message)", category: .general, type: .error)
    }

    /// Error日志
    func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        var logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        if let error = error {
            logMessage += "\nError: \(error.localizedDescription)"
        }
        log(logMessage, category: .error, type: .error)
    }

    /// 网络请求日志
    func network(method: String, url: String, parameters: [String: Any]? = nil) {
        guard isDebug else { return }

        var message = "\(method) \(url)"
        if let parameters = parameters {
            message += "\nParameters: \(parameters)"
        }
        log(message, category: .network, type: .debug)
    }

    /// 网络响应日志
    func networkResponse(url: String, statusCode: Int, data: Any?) {
        guard isDebug else { return }

        var message = "Response from \(url)\nStatus: \(statusCode)"
        if let data = data {
            message += "\nData: \(data)"
        }
        log(message, category: .network, type: .debug)
    }

    /// 网络错误日志
    func networkError(url: String, error: Error) {
        guard isDebug else { return }

        let message = "Network error from \(url)\nError: \(error.localizedDescription)"
        log(message, category: .network, type: .error)
    }

    /// 数据库操作日志
    func database(operation: String, entity: String, details: String? = nil) {
        guard isDebug else { return }

        var message = "DB: \(operation) on \(entity)"
        if let details = details {
            message += " - \(details)"
        }
        log(message, category: .database, type: .debug)
    }

    /// 生命周期日志
    func lifecycle(event: String, object: String) {
        guard isDebug else { return }

        let message = "Lifecycle: \(object) - \(event)"
        log(message, category: .lifecycle, type: .info)
    }

    /// 导航日志
    func navigation(from: String, to: String) {
        guard isDebug else { return }

        let message = "Navigation: \(from) -> \(to)"
        log(message, category: .navigation, type: .info)
    }

    /// 性能日志
    func performance(operation: String, duration: TimeInterval) {
        guard isDebug else { return }

        let message = "Performance: \(operation) took \(String(format: "%.2f", duration * 1000))ms"
        log(message, category: .performance, type: .info)
    }

    /// JSON日志
    func json(data: Data, prefix: String = "") {
        guard isDebug else { return }

        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            if let jsonString = String(data: prettyData, encoding: .utf8) {
                let message = prefix.isEmpty ? "JSON:\n\(jsonString)" : "\(prefix)\n\(jsonString)"
                log(message, category: .general, type: .debug)
            }
        } catch {
            if let jsonString = String(data: data, encoding: .utf8) {
                let message = prefix.isEmpty ? "JSON: \(jsonString)" : "\(prefix) \(jsonString)"
                log(message, category: .general, type: .debug)
            }
        }
    }
}

// MARK: - 便捷方法
extension Logger {
    /// 快捷debug方法
    static func d(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.debug(message, file: file, function: function, line: line)
    }

    /// 快捷info方法
    static func i(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.info(message, file: file, function: function, line: line)
    }

    /// 快捷warning方法
    static func w(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.warning(message, file: file, function: function, line: line)
    }

    /// 快捷error方法
    static func e(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        shared.error(message, error: error, file: file, function: function, line: line)
    }
}

// MARK: - 性能测量工具
class PerformanceMeasure {
    private let operation: String
    private let startTime: Date

    init(_ operation: String) {
        self.operation = operation
        self.startTime = Date()
    }

    func finish() {
        let duration = Date().timeIntervalSince(startTime)
        Logger.shared.performance(operation: operation, duration: duration)
    }
}

// MARK: - 便捷函数
func measure(_ operation: String, block: () -> Void) {
    let measure = PerformanceMeasure(operation)
    block()
    measure.finish()
}

func measureAsync(_ operation: String, block: () async -> Void) async {
    let measure = PerformanceMeasure(operation)
    await block()
    measure.finish()
}
